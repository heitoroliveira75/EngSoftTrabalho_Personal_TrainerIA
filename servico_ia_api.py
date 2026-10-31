"""
Serviço Central de Sessões de IA em Memória (Back-end).
Responsável por gerenciar sessões ativas do OrquestradorSessao por usuário,
decodificar imagens JPEG/PNG diretamente em RAM e expor operações
para consumo transparente pelo FastAPI e aplicativo móvel.
"""

import os
from typing import Dict, Any, Optional, List
import numpy as np
import cv2

from calculo_angulos import extrair_angulos_exercicio
from exercicios_fsm import CATALOGO_EXERCICIOS, obter_config_exercicio
from avaliador_pontuacao import (
    OrquestradorSessao,
    ResultadoPontuacaoRepeticao,
    ResumoPontuacaoSessao,
)

DIRETORIO_RAIZ = os.path.dirname(os.path.abspath(__file__))
MODELO_ARQUIVO_PADRAO = os.path.join(DIRETORIO_RAIZ, "pose_landmarker_lite.task")


def serializar_resultado_repeticao(res: Optional[ResultadoPontuacaoRepeticao]) -> Optional[Dict[str, Any]]:
    """Converte a dataclass ResultadoPontuacaoRepeticao em dicionário serializável em JSON."""
    if res is None:
        return None
    return {
        "numero_repeticao": res.numero_repeticao,
        "score_final": round(float(res.score_final), 1),
        "score_dtw": round(float(res.score_dtw), 1),
        "penalidade_fsm": round(float(res.penalidade_fsm), 1),
        "aprovado": bool(res.aprovado),
        "classificacao": res.classificacao,
        "erros_fsm": list(res.erros_fsm),
        "mensagens_erros_fsm": list(res.mensagens_erros_fsm),
        "desvios_por_articulacao": {k: round(float(v), 1) for k, v in res.desvios_por_articulacao.items()},
        "amplitudes_usuario": {k: round(float(v), 1) for k, v in res.amplitudes_usuario.items()},
        "amplitudes_gabarito": {k: round(float(v), 1) for k, v in res.amplitudes_gabarito.items()},
        "razao_cadencia": round(float(res.razao_cadencia), 2),
        "feedback_principal": res.feedback_principal,
    }


def serializar_resumo_sessao(resumo: ResumoPontuacaoSessao) -> Dict[str, Any]:
    """Converte a dataclass ResumoPontuacaoSessao em dicionário serializável em JSON."""
    return {
        "id_exercicio": resumo.id_exercicio,
        "nome_exercicio": resumo.nome_exercicio,
        "total_repeticoes": int(resumo.total_repeticoes),
        "repeticoes_aprovadas": int(resumo.repeticoes_aprovadas),
        "repeticoes_reprovadas": int(resumo.repeticoes_reprovadas),
        "taxa_aprovacao": round(float(resumo.taxa_aprovacao), 1),
        "score_medio": round(float(resumo.score_medio), 1),
        "pontos_gamificacao": round(float(resumo.pontos_gamificacao), 1),
        "recomendacao_prioritaria": resumo.recomendacao_prioritaria,
        "historico_repeticoes": [
            serializar_resultado_repeticao(rep) for rep in resumo.historico_repeticoes
        ],
    }


class ServicoIA:
    """
    Gerenciador singleton em memória das instâncias do OrquestradorSessao por usuário.
    Processa imagens e séries temporais com isolamento total por sessão de atleta.
    """

    _instancia: Optional["ServicoIA"] = None

    def __init__(self, caminho_modelo: str = MODELO_ARQUIVO_PADRAO):
        self.caminho_modelo = caminho_modelo
        self.sessoes: Dict[str, OrquestradorSessao] = {}
        self.detector_pose = None  # Inicialização preguiçosa (Lazy loading)

    @classmethod
    def obter_instancia(cls, caminho_modelo: str = MODELO_ARQUIVO_PADRAO) -> "ServicoIA":
        if cls._instancia is None:
            cls._instancia = cls(caminho_modelo=caminho_modelo)
        return cls._instancia

    def _inicializar_detector(self) -> None:
        """Carrega o modelo oficial do MediaPipe Tasks na memória se ainda não inicializado."""
        if self.detector_pose is not None:
            return

        import mediapipe as mp
        from mediapipe.tasks import python
        from mediapipe.tasks.python import vision

        if not os.path.exists(self.caminho_modelo):
            # Se não existir localmente, tenta baixar o arquivo padrão
            import urllib.request
            url = (
                "https://storage.googleapis.com/mediapipe-models/pose_landmarker/"
                "pose_landmarker_lite/float16/latest/pose_landmarker_lite.task"
            )
            print(f"Baixando modelo PoseLandmarker em {self.caminho_modelo}...")
            urllib.request.urlretrieve(url, self.caminho_modelo)

        base_options = python.BaseOptions(model_asset_path=self.caminho_modelo)
        options = vision.PoseLandmarkerOptions(
            base_options=base_options,
            running_mode=vision.RunningMode.IMAGE,
            num_poses=1,
            min_pose_detection_confidence=0.5,
            min_tracking_confidence=0.5,
        )
        self.detector_pose = vision.PoseLandmarker.create_from_options(options)

    def obter_ou_criar_sessao(
        self,
        usuario_id: str,
        exercicio_id: str = "1",
    ) -> OrquestradorSessao:
        """Garante a existência de uma sessão ativa para o usuário no exercício indicado."""
        config = obter_config_exercicio(exercicio_id, permitir_fallback=True)
        id_canonica = config["id"]

        if usuario_id not in self.sessoes:
            self.sessoes[usuario_id] = OrquestradorSessao(identificador_exercicio=id_canonica)
        else:
            sessao = self.sessoes[usuario_id]
            if sessao.id_exercicio != id_canonica:
                sessao.trocar_exercicio(novo_identificador=id_canonica)

        return self.sessoes[usuario_id]

    def reiniciar_sessao(
        self,
        usuario_id: str,
        exercicio_id: str = "1",
    ) -> Dict[str, Any]:
        """Reinicia o contador e o histórico de uma série para o usuário."""
        config = obter_config_exercicio(exercicio_id, permitir_fallback=True)
        id_canonica = config["id"]

        if usuario_id in self.sessoes:
            sessao = self.sessoes[usuario_id]
            if sessao.id_exercicio == id_canonica:
                sessao.reiniciar_serie()
            else:
                sessao.trocar_exercicio(id_canonica)
        else:
            self.sessoes[usuario_id] = OrquestradorSessao(identificador_exercicio=id_canonica)

        sessao = self.sessoes[usuario_id]
        return {
            "sucesso": True,
            "mensagem": f"Sessão reiniciada para o exercício '{sessao.nome_exercicio}'.",
            "usuario_id": usuario_id,
            "exercicio_id": sessao.id_exercicio,
            "exercicio_nome": sessao.nome_exercicio,
            "repeticoes": 0,
        }

    def processar_frame_imagem(
        self,
        conteudo_bytes: bytes,
        usuario_id: str,
        exercicio_id: str = "1",
        lado: str = "direito",
    ) -> Dict[str, Any]:
        """
        Recebe fotograma em bytes (JPG/PNG), decodifica em memória, extrai a pose
        e avalia biomecanicamente via OrquestradorSessao.
        """
        orquestrador = self.obter_ou_criar_sessao(usuario_id=usuario_id, exercicio_id=exercicio_id)

        # 1. Decodificação da imagem diretamente da memória RAM
        array_np = np.frombuffer(conteudo_bytes, np.uint8)
        frame_bgr = cv2.imdecode(array_np, cv2.IMREAD_COLOR)

        if frame_bgr is None:
            return {
                "sucesso": False,
                "mensagem": "Falha na decodificação do fotograma. Formato de imagem inválido.",
                "corpo_visivel": False,
                "alerta_imediato": "Erro na captura do fotograma",
                "repeticoes": len(orquestrador.historico_repeticoes),
                "fase_numero": orquestrador.fsm.fases[1],
                "fase_nome": orquestrador.fsm.nome_fase_atual,
                "repeticao_concluida": False,
                "ultima_repeticao": None,
            }

        # 2. Extração de Pose com MediaPipe (com proteção contra ausência de drivers de vídeo)
        try:
            self._inicializar_detector()
        except Exception as e:
            return {
                "sucesso": False,
                "mensagem": f"Motor de visão computacional indisponível no servidor: {e}. Utilize o modo de simulação.",
                "corpo_visivel": False,
                "alerta_imediato": "IA em modo simulado",
                "repeticoes": len(orquestrador.historico_repeticoes),
                "fase_numero": orquestrador.fsm.fases[1],
                "fase_nome": orquestrador.fsm.nome_fase_atual,
                "angulos": {},
                "repeticao_concluida": False,
                "ultima_repeticao": None,
            }
        import mediapipe as mp

        frame_rgb = cv2.cvtColor(frame_bgr, cv2.COLOR_BGR2RGB)
        mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=frame_rgb)
        resultado_pose = self.detector_pose.detect(mp_image)

        if not resultado_pose.pose_landmarks or len(resultado_pose.pose_landmarks) == 0:
            alerta, res_rep = orquestrador.processar_frame(angulos={}, visivel=False)
            return {
                "sucesso": True,
                "corpo_visivel": False,
                "alerta_imediato": alerta or "Nenhum atleta detectado na câmera",
                "repeticoes": len(orquestrador.historico_repeticoes),
                "fase_numero": orquestrador.fsm.fases[1],
                "fase_nome": orquestrador.fsm.nome_fase_atual,
                "angulos": {},
                "repeticao_concluida": False,
                "ultima_repeticao": None,
            }

        # 3. Extração dos ângulos biomecânicos
        landmarks = resultado_pose.pose_landmarks[0]
        angulos, visivel = extrair_angulos_exercicio(
            landmarks=landmarks,
            articulacoes=orquestrador.articulacoes,
            lado=lado,
        )

        # Suporte inteligente a membros contralaterais e webcams espelhadas (Rosca e Desenvolvimento):
        if "cotovelo" in orquestrador.articulacoes:
            outro_lado = "esquerdo" if str(lado).lower() == "direito" else "direito"
            try:
                angulos_outro, visivel_outro = extrair_angulos_exercicio(
                    landmarks=landmarks,
                    articulacoes=orquestrador.articulacoes,
                    lado=outro_lado,
                )
                cotovelo_atual = angulos.get("cotovelo", 180.0)
                cotovelo_outro = angulos_outro.get("cotovelo", 180.0)

                # Prioriza o braço que está ativamente executando o movimento ou o único visível
                if (not visivel and visivel_outro) or (visivel_outro and cotovelo_outro < (cotovelo_atual - 8.0)):
                    angulos = angulos_outro
                    visivel = visivel_outro
            except Exception:
                pass

        # 4. Avaliação no motor
        alerta, res_rep = orquestrador.processar_frame(angulos=angulos, visivel=visivel)

        ultima_rep = res_rep or (
            orquestrador.historico_repeticoes[-1] if orquestrador.historico_repeticoes else None
        )

        return {
            "sucesso": True,
            "usuario_id": usuario_id,
            "exercicio_id": orquestrador.id_exercicio,
            "exercicio_nome": orquestrador.nome_exercicio,
            "corpo_visivel": visivel,
            "repeticoes": len(orquestrador.historico_repeticoes),
            "fase_numero": orquestrador.fsm.fases[1],
            "fase_nome": orquestrador.fsm.nome_fase_atual,
            "alerta_imediato": alerta,
            "angulos": {k: round(float(v), 1) for k, v in angulos.items()},
            "repeticao_concluida": res_rep is not None,
            "ultima_repeticao": serializar_resultado_repeticao(ultima_rep),
        }

    def processar_frame_angulos(
        self,
        angulos: Dict[str, float],
        usuario_id: str,
        exercicio_id: str = "1",
        visivel: bool = True,
    ) -> Dict[str, Any]:
        """Permite alimentar o orquestrador diretamente com dicionário de ângulos (offline/testes)."""
        orquestrador = self.obter_ou_criar_sessao(usuario_id=usuario_id, exercicio_id=exercicio_id)
        alerta, res_rep = orquestrador.processar_frame(angulos=angulos, visivel=visivel)

        ultima_rep = res_rep or (
            orquestrador.historico_repeticoes[-1] if orquestrador.historico_repeticoes else None
        )

        return {
            "sucesso": True,
            "usuario_id": usuario_id,
            "exercicio_id": orquestrador.id_exercicio,
            "exercicio_nome": orquestrador.nome_exercicio,
            "corpo_visivel": visivel,
            "repeticoes": len(orquestrador.historico_repeticoes),
            "fase_numero": orquestrador.fsm.fases[1],
            "fase_nome": orquestrador.fsm.nome_fase_atual,
            "alerta_imediato": alerta,
            "angulos": {k: round(float(v), 1) for k, v in angulos.items()},
            "repeticao_concluida": res_rep is not None,
            "ultima_repeticao": serializar_resultado_repeticao(ultima_rep),
        }

    def simular_repeticao(
        self,
        usuario_id: str,
        exercicio_id: str = "1",
        tipo_cenario: str = "ideal",
    ) -> Dict[str, Any]:
        """
        Injeta uma repetição canônica completa no orquestrador do usuário para
        demonstrações instantâneas da banca sem depender de câmera física.
        """
        orquestrador = self.obter_ou_criar_sessao(usuario_id=usuario_id, exercicio_id=exercicio_id)
        gabarito = orquestrador.gabarito
        articulacoes = orquestrador.articulacoes

        dados_base = gabarito.dados
        n_frames = dados_base.shape[0]

        # Processa cada frame da série canônica
        ultimo_alerta = None
        resultado_rep = None

        for i in range(n_frames):
            frame_angulos = {}
            for col_idx, art in enumerate(articulacoes):
                val = float(dados_base[i, col_idx])

                # No cenário postural, introduz erro biomecânico proposital
                if tipo_cenario == "postural" and "ombro" in art and i > n_frames // 3:
                    val = max(10.0, val - 35.0)

                frame_angulos[art] = val

            alerta, res = orquestrador.processar_frame(angulos=frame_angulos, visivel=True)
            if alerta:
                ultimo_alerta = alerta
            if res:
                resultado_rep = res

        # Se por discretização de FSM não fechou, força fechamento retornando à base
        if resultado_rep is None:
            frame_repouso = {art: float(dados_base[0, c]) for c, art in enumerate(articulacoes)}
            for _ in range(5):
                _, res = orquestrador.processar_frame(angulos=frame_repouso, visivel=True)
                if res:
                    resultado_rep = res
                    break

        return {
            "sucesso": True,
            "usuario_id": usuario_id,
            "exercicio_id": orquestrador.id_exercicio,
            "exercicio_nome": orquestrador.nome_exercicio,
            "tipo_cenario": tipo_cenario,
            "repeticoes": len(orquestrador.historico_repeticoes),
            "alerta_imediato": ultimo_alerta,
            "ultima_repeticao": serializar_resultado_repeticao(resultado_rep),
        }

    def obter_resumo_sessao(self, usuario_id: str) -> Dict[str, Any]:
        """Retorna o resumo consolidado da sessão ativa do usuário com gamificação e laudo."""
        if usuario_id not in self.sessoes:
            return {
                "sucesso": False,
                "mensagem": f"Nenhuma sessão ativa encontrada para o usuário '{usuario_id}'.",
                "dados": None,
            }

        orquestrador = self.sessoes[usuario_id]
        resumo = orquestrador.gerar_resumo_sessao()
        return {
            "sucesso": True,
            "usuario_id": usuario_id,
            "dados": serializar_resumo_sessao(resumo),
        }

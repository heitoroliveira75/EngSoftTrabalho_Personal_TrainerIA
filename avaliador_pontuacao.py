"""
Módulo Central de Avaliação de Pontuação e Orquestração de Sessão.
Consolida o cálculo de pontuação biomecânica (DTW + penalidades FSM)
e gerencia a sessão de treino multi-exercício frame a frame sem acoplamento a hardware.
"""

from collections import Counter
from dataclasses import dataclass, field
from typing import Dict, List, Optional, Tuple, Any
import numpy as np

from calculo_angulos import calcular_deltas_angulares
from buffer_repeticao import BufferRepeticao
from exercicios_fsm import ExercicioBaseFSM, obter_config_exercicio
from gabarito import GabaritoExercicio
from dtw_evaluator import DTWComparator, DTWResult


@dataclass
class ResultadoPontuacaoRepeticao:
    """
    Consolida as métricas objetivas e diagnósticos pedagógicos de uma repetição concluída.
    """
    numero_repeticao: int
    score_final: float
    score_dtw: float
    penalidade_fsm: float
    aprovado: bool
    classificacao: str
    erros_fsm: List[str] = field(default_factory=list)
    mensagens_erros_fsm: List[str] = field(default_factory=list)
    desvios_por_articulacao: Dict[str, float] = field(default_factory=dict)
    amplitudes_usuario: Dict[str, float] = field(default_factory=dict)
    amplitudes_gabarito: Dict[str, float] = field(default_factory=dict)
    razao_cadencia: float = 1.0
    feedback_principal: str = ""
    resultado_dtw: Optional[DTWResult] = None


@dataclass
class ResumoPontuacaoSessao:
    """
    Resumo consolidado da série/sessão de treino para relatórios e APIs de gamificação.
    """
    id_exercicio: str
    nome_exercicio: str
    total_repeticoes: int
    repeticoes_aprovadas: int
    repeticoes_reprovadas: int
    taxa_aprovacao: float
    score_medio: float
    pontos_gamificacao: float
    recomendacao_prioritaria: str
    historico_repeticoes: List[ResultadoPontuacaoRepeticao] = field(default_factory=list)


def classificar_score(score: float) -> str:
    """Classifica a pontuação em faixas qualitativas padronizadas."""
    if score >= 85.0:
        return "EXCELENTE"
    elif score >= 70.0:
        return "BOM"
    elif score >= 50.0:
        return "REGULAR"
    return "INCORRETO"


def calcular_pontuacao(
    dados_usuario: np.ndarray,
    gabarito: GabaritoExercicio,
    erros_fsm: List[str],
    fsm_ou_config: Any,
    numero_repeticao: int = 1,
    tolerancia: float = 15.0,
    janela_sakoe_chiba: Optional[float] = 0.20,
    limiar_aprovacao: float = 70.0,
) -> ResultadoPontuacaoRepeticao:
    """
    Função pura desacoplada que calcula a pontuação técnica da repetição.

    Regras:
    1. Score DTW: S_dtw = 100 * exp(-distancia_normalizada / tau), tau = 15.0 graus.
    2. Penalidades FSM: somatório dos erros únicos cometidos na repetição.
    3. Score Final: clip(S_dtw - P_fsm, 0.0, 100.0).
    4. Feedback Hierárquico: 1º erro FSM amigável -> 2º desvio articular > 12° -> 3º reforço motivacional.
    """
    dtw = DTWComparator(tolerancia=tolerancia, janela=janela_sakoe_chiba)
    res_dtw = dtw.compute(gabarito.dados, dados_usuario, nomes_articulacoes=gabarito.articulacoes)
    score_dtw = float(res_dtw.score_similaridade)

    # Identifica mapeamentos de penalidades e mensagens da FSM
    if isinstance(fsm_ou_config, dict):
        classe_fsm = fsm_ou_config.get("classe_fsm")
        penalidades_map = getattr(classe_fsm, "PENALIDADES_ERRO", {})
        mensagens_map = getattr(classe_fsm, "MENSAGENS_ERRO", {})
    else:
        penalidades_map = getattr(fsm_ou_config, "PENALIDADES_ERRO", {})
        mensagens_map = getattr(fsm_ou_config, "MENSAGENS_ERRO", {})

    # Deduplicação de erros garantindo desconto justo por tipo único de infração
    erros_unicos = list(dict.fromkeys(erros_fsm))
    penalidade_total = float(sum(penalidades_map.get(err, 15.0) for err in erros_unicos))

    score_final = float(np.clip(score_dtw - penalidade_total, 0.0, 100.0))
    score_final = round(score_final, 1)
    aprovado = bool(score_final >= limiar_aprovacao)
    classificacao = classificar_score(score_final)

    # Cálculo informativo de amplitudes articulares (ROM)
    amplitudes_usuario: Dict[str, float] = {}
    amplitudes_gabarito: Dict[str, float] = {}
    for i, art in enumerate(gabarito.articulacoes):
        col_u = dados_usuario[:, i]
        col_g = gabarito.dados[:, i]
        amplitudes_usuario[art] = round(float(np.max(col_u) - np.min(col_u)), 1)
        amplitudes_gabarito[art] = round(float(np.max(col_g) - np.min(col_g)), 1)

    razao_cadencia = round(float(dados_usuario.shape[0]) / max(1, gabarito.total_frames), 2)
    mensagens_erros = [mensagens_map.get(err, err) for err in erros_unicos]

    # Formulação do Feedback Hierárquico
    if mensagens_erros:
        feedback_principal = mensagens_erros[0]
    else:
        # Verifica se alguma articulação teve desvio significativo (> 12°)
        desvios = res_dtw.desvios_por_articulacao or {}
        art_critica = None
        desv_max = 0.0
        if desvios:
            art_critica, desv_max = max(desvios.items(), key=lambda x: x[1])

        if art_critica and desv_max > 12.0:
            feedback_principal = f"Ajuste a trajetória do {art_critica}: desvio médio de {desv_max:.1f}° em relação à referência."
        else:
            if score_final >= 85.0:
                feedback_principal = "Excelente repetição! Padrão motor e amplitude alinhados à referência."
            elif score_final >= 70.0:
                feedback_principal = "Boa repetição! Mantenha a cadência e a estabilidade articular."
            else:
                feedback_principal = "Repetição concluída, mas atente-se à forma e ao alinhamento geral."

    return ResultadoPontuacaoRepeticao(
        numero_repeticao=numero_repeticao,
        score_final=score_final,
        score_dtw=score_dtw,
        penalidade_fsm=penalidade_total,
        aprovado=aprovado,
        classificacao=classificacao,
        erros_fsm=erros_unicos,
        mensagens_erros_fsm=mensagens_erros,
        desvios_por_articulacao=res_dtw.desvios_por_articulacao,
        amplitudes_usuario=amplitudes_usuario,
        amplitudes_gabarito=amplitudes_gabarito,
        razao_cadencia=razao_cadencia,
        feedback_principal=feedback_principal,
        resultado_dtw=res_dtw,
    )


class OrquestradorSessao:
    """
    Gerenciador desacoplado da sessão de treino para qualquer exercício do catálogo.
    Recebe frames fotograma por fotograma (angulos, visivel), controla deltas, FSM,
    buffer, cálculo de notas e resumos sem acoplamento a OpenCV ou MediaPipe.
    """

    def __init__(
        self,
        identificador_exercicio: str,
        gabarito_customizado: Optional[GabaritoExercicio] = None,
        tolerancia_dtw: float = 15.0,
        limiar_aprovacao: float = 70.0,
        janela_sakoe_chiba: Optional[float] = 0.20,
        limite_frames_invisivel: int = 30,
    ):
        self.tolerancia_dtw = tolerancia_dtw
        self.limiar_aprovacao = limiar_aprovacao
        self.janela_sakoe_chiba = janela_sakoe_chiba
        self.limite_frames_invisivel = limite_frames_invisivel

        self.historico_repeticoes: List[ResultadoPontuacaoRepeticao] = []
        self.frames_consecutivos_invisivel = 0
        self.referencia_deltas: Dict[str, float] = {}

        self._configurar_exercicio(identificador_exercicio, gabarito_customizado)

    def _configurar_exercicio(
        self,
        identificador_exercicio: str,
        gabarito_customizado: Optional[GabaritoExercicio] = None,
    ) -> None:
        """Inicializa as instâncias de FSM, Buffer e Gabarito para o exercício escolhido."""
        self.config = obter_config_exercicio(identificador_exercicio)
        self.id_exercicio = self.config["id"]
        self.nome_exercicio = self.config["nome"]
        self.articulacoes = list(self.config["articulacoes"])
        self.fsm: ExercicioBaseFSM = self.config["classe_fsm"]()
        self.buffer = BufferRepeticao(fsm=self.fsm, articulacoes=self.articulacoes)

        if gabarito_customizado is not None:
            self.gabarito = gabarito_customizado
        else:
            self.gabarito = GabaritoExercicio.carregar_json(self.config["arquivo_gabarito"])

        self.referencia_deltas = {}
        self.frames_consecutivos_invisivel = 0

    def reiniciar_serie(self) -> None:
        """Reinicia o contador e o histórico de notas para uma nova série do mesmo exercício."""
        self.fsm = self.config["classe_fsm"]()
        self.buffer = BufferRepeticao(fsm=self.fsm, articulacoes=self.articulacoes)
        self.referencia_deltas = {}
        self.frames_consecutivos_invisivel = 0
        self.historico_repeticoes = []

    def trocar_exercicio(
        self,
        novo_identificador: str,
        gabarito_customizado: Optional[GabaritoExercicio] = None,
    ) -> None:
        """Alterna a sessão para outro exercício do catálogo mantendo a mesma instância."""
        self._configurar_exercicio(novo_identificador, gabarito_customizado)
        self.historico_repeticoes = []

    def processar_frame(
        self,
        angulos: Dict[str, float],
        visivel: bool = True,
    ) -> Tuple[Optional[str], Optional[ResultadoPontuacaoRepeticao]]:
        """
        Processa um único fotograma recebido do pipeline (Webcam, Vídeo ou Teste).

        Retorno:
            Tuple[alerta_imediato, resultado_repeticao]:
            - alerta_imediato: Mensagem de erro postural da FSM ou alerta de visibilidade no frame atual.
            - resultado_repeticao: Objeto ResultadoPontuacaoRepeticao gerado no instante em que o ciclo é concluído.
        """
        # 1. Tratamento de visibilidade
        if not visivel:
            self.frames_consecutivos_invisivel += 1
            if self.frames_consecutivos_invisivel > self.limite_frames_invisivel:
                # Perda prolongada de visão: reseta a repetição atual por segurança
                self.buffer.frames_atuais = []
                self.fsm.fases[0] = 0
                self.fsm.fases[1] = 0
                self.fsm.erros_repeticao_atual = []
                return "ATENÇÃO: Visão perdida por muito tempo; repetição reiniciada", None
            return "ATENÇÃO: Articulação fora de visão", None

        self.frames_consecutivos_invisivel = 0

        # 2. Cálculo dos deltas angulares com âncora de ruído centralizada
        deltas = calcular_deltas_angulares(angulos, self.referencia_deltas, limiar_graus=1.2)

        # 3. Processamento no Buffer e classificação na FSM
        dados_rep, erro_imediato = self.buffer.processar_frame(angulos=angulos, angulos_deltas=deltas)

        # 4. Se a repetição foi concluída neste frame, avalia e gera o laudo
        if dados_rep is not None:
            erros_fsm = self.fsm.consumir_erros_repeticao()
            num_rep = len(self.historico_repeticoes) + 1
            resultado = calcular_pontuacao(
                dados_usuario=dados_rep,
                gabarito=self.gabarito,
                erros_fsm=erros_fsm,
                fsm_ou_config=self.config,
                numero_repeticao=num_rep,
                tolerancia=self.tolerancia_dtw,
                janela_sakoe_chiba=self.janela_sakoe_chiba,
                limiar_aprovacao=self.limiar_aprovacao,
            )
            self.historico_repeticoes.append(resultado)
            return erro_imediato, resultado

        return erro_imediato, None

    def gerar_resumo_sessao(self) -> ResumoPontuacaoSessao:
        """
        Compila todas as repetições realizadas na série em um resumo estatístico
        com pontuação de gamificação e diagnóstico de erro mais frequente.
        """
        total_reps = len(self.historico_repeticoes)
        if total_reps == 0:
            return ResumoPontuacaoSessao(
                id_exercicio=self.id_exercicio,
                nome_exercicio=self.nome_exercicio,
                total_repeticoes=0,
                repeticoes_aprovadas=0,
                repeticoes_reprovadas=0,
                taxa_aprovacao=0.0,
                score_medio=0.0,
                pontos_gamificacao=0.0,
                recomendacao_prioritaria="Nenhuma repetição registrada na sessão.",
                historico_repeticoes=[],
            )

        aprovadas = [r for r in self.historico_repeticoes if r.aprovado]
        reprovadas = [r for r in self.historico_repeticoes if not r.aprovado]
        total_aprovadas = len(aprovadas)
        total_reprovadas = len(reprovadas)
        taxa_aprovacao = round((total_aprovadas / total_reps) * 100.0, 1)
        score_medio = round(float(np.mean([r.score_final for r in self.historico_repeticoes])), 1)

        # Gamificação: proporcional à qualidade das repetições aprovadas
        pontos_gamificacao = round(float(sum(r.score_final / 10.0 for r in aprovadas)), 1)

        # Diagnóstico prioritário: identifica o erro FSM mais frequente
        todos_erros = [err for r in self.historico_repeticoes for err in r.erros_fsm]
        mensagens_map = getattr(self.config.get("classe_fsm"), "MENSAGENS_ERRO", {})
        if todos_erros:
            contagem = Counter(todos_erros)
            erro_comum, qtd = contagem.most_common(1)[0]
            msg_amigavel = mensagens_map.get(erro_comum, erro_comum)
            recomendacao = f"Atenção recorrente ({qtd}/{total_reps} reps): {msg_amigavel}"
        else:
            if score_medio >= 85.0:
                recomendacao = "Excelente consistência técnica em toda a série! Padrão motor exemplar."
            elif score_medio >= 70.0:
                recomendacao = "Boa série! Continue mantendo a cadência e a estabilidade articular."
            else:
                recomendacao = "Série finalizada. Foque na amplitude e controle do movimento na próxima."

        return ResumoPontuacaoSessao(
            id_exercicio=self.id_exercicio,
            nome_exercicio=self.nome_exercicio,
            total_repeticoes=total_reps,
            repeticoes_aprovadas=total_aprovadas,
            repeticoes_reprovadas=total_reprovadas,
            taxa_aprovacao=taxa_aprovacao,
            score_medio=score_medio,
            pontos_gamificacao=pontos_gamificacao,
            recomendacao_prioritaria=recomendacao,
            historico_repeticoes=list(self.historico_repeticoes),
        )

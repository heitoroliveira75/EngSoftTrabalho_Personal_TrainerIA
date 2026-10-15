"""
Módulo de Buffer de Repetição

Responsável por acumular os frames capturados da câmera durante a execução
de um exercício, utilizando a Máquina de Estados (FSM) para segmentar
o início e o fim de cada repetição completa antes de enviá-la ao DTW.
"""

import importlib
from typing import Dict, List, Optional, Tuple, Any
import numpy as np

# Importação dinâmica da máquina de estados (devido ao hífen no nome do arquivo)
_dev_modulo = importlib.import_module("dev_ombro-inicial")
DesenvolvimentoOmbro = _dev_modulo.DesenvolvimentoOmbro


class BufferRepeticao:
    """
    Acumula os dados da câmera frame a frame enquanto uma repetição
    estiver em andamento. Ao término do movimento, entrega a série temporal
    completa formatada em matriz (T x D) para avaliação pelo DTW.
    """

    def __init__(self, fsm: Any, articulacoes: List[str]):
        """
        Args:
            fsm: Instância da máquina de estados do exercício (ex: DesenvolvimentoOmbro()).
            articulacoes: Lista com a ordem das articulações esperadas pelo gabarito (ex: ['cotovelo', 'ombro']).
        """
        self.fsm = fsm
        self.articulacoes = articulacoes
        self.frames_atuais: List[List[float]] = []

    def _extrair_vetor(self, angulos: Dict[str, float]) -> List[float]:
        """Extrai os valores das articulações na ordem especificada."""
        if isinstance(angulos, dict):
            return [float(angulos.get(art, 0.0)) for art in self.articulacoes]
        # Caso já venha como lista ou array numérico
        return [float(v) for v in angulos]

    def processar_frame(
        self,
        angulos: Dict[str, float],
        posicoes: Optional[Dict[str, Any]] = None,
        angulos_deltas: Optional[Dict[str, float]] = None
    ) -> Tuple[Optional[np.ndarray], Optional[str]]:
        """
        Processa um único frame vindo do estimador de pose (ex: MediaPipe).

        Args:
            angulos: Dicionário contendo os ângulos articulares atuais (ex: {'cotovelo': 120.0, 'ombro': 110.0}).
            posicoes: Coordenadas espaciais dos landmarks (opcional).
            angulos_deltas: Variação dos ângulos em relação ao frame anterior (positivo = subindo, negativo = descendo).

        Returns:
            (repeticao_dados, erro_imediato)
            - repeticao_dados: Matriz (T x D) com os frames da repetição finalizada, ou None se a repetição ainda estiver ocorrendo.
            - erro_imediato: Erro imediato de execução detectado pela FSM (se houver).
        """
        posicoes = posicoes or {}
        angulos_deltas = angulos_deltas or {}

        fase_anterior = self.fsm.fases[1]
        reps_anteriores = self.fsm.repeticoes

        # Classificação e atualização da máquina de estados
        erro_imediato = self.fsm.classificar(angulos, posicoes, angulos_deltas)
        fase_atual = self.fsm.fases[1]

        vetor_frame = self._extrair_vetor(angulos)

        # 1. Início da repetição: saiu do repouso (fase 0) para a fase concêntrica (fase 1)
        if fase_anterior == 0 and fase_atual == 1:
            self.frames_atuais = [vetor_frame]

        # 2. Movimento em andamento (fases 1, 2 ou 3)
        elif fase_atual != 0:
            self.frames_atuais.append(vetor_frame)

        # 3. Repetição concluída: a FSM incrementou o contador de repetições
        if self.fsm.repeticoes > reps_anteriores and len(self.frames_atuais) > 0:
            self.frames_atuais.append(vetor_frame)  # inclui o frame de fechamento

            # Converte para array numpy estruturado (T x D)
            repeticao_completa = np.asarray(self.frames_atuais, dtype=float)
            self.frames_atuais = []  # reseta o acumulador para a próxima repetição

            return repeticao_completa, erro_imediato

        return None, erro_imediato


if __name__ == "__main__":
    # Demonstração: Alimentando o buffer frame a frame (como em um loop de câmera)
    from dtw_inicial import DTW
    from gabarito import GabaritoExercicio

    # 1. Carrega o gabarito gravado pelo especialista
    gabarito = GabaritoExercicio.carregar_json("gabarito_especialista_ombro.json")

    # 2. Instancia a máquina de estados, o avaliador DTW e o Buffer
    fsm_ombro = DesenvolvimentoOmbro()
    dtw = DTW(tolerancia=15.0)
    buffer = BufferRepeticao(fsm=fsm_ombro, articulacoes=gabarito.articulacoes)

    print("=== Simulação de Fluxo de Câmera com Segmentação de Repetição ===")

    # Simulação de frames consecutivos (passagem do tempo):
    # Repouso -> Subida -> Pico -> Descida -> Repouso
    historico_cotovelo = [90, 90, 110, 130, 150, 165, 165, 150, 130, 110, 95, 90]
    historico_ombro =    [80, 80,  95, 115, 135, 150, 150, 135, 115,  95, 85, 80]

    cotovelo_anterior = 90.0

    for i in range(len(historico_cotovelo)):
        c = float(historico_cotovelo[i])
        o = float(historico_ombro[i])
        delta_c = c - cotovelo_anterior

        angulos = {"cotovelo": c, "ombro": o}
        deltas = {"cotovelo": delta_c, "ombro": 0.0}

        # Envia frame para o buffer
        dados_rep, erro_fsm = buffer.processar_frame(
            angulos=angulos,
            posicoes={},
            angulos_deltas=deltas
        )

        cotovelo_anterior = c

        # Se o buffer indicou o fim de uma repetição completa:
        if dados_rep is not None:
            print(f"\n[SUCESSO] Repetição #{fsm_ombro.repeticoes} concluída!")
            print(f"Total de frames acumulados na repetição: {dados_rep.shape[0]}")
            print(f"Status imediato da FSM: {erro_fsm or 'Movimento Válido'}")

            # Compara imediatamente com o especialista gravado
            dist_tot, dist_norm, score, caminho, desvios = dtw.calcular(
                serie_a=dados_rep,
                serie_b=gabarito.dados,
                nomes_articulacoes=gabarito.articulacoes
            )

            print(f"\nResultado da Avaliação com Especialista (DTW):")
            print(f"  - Score de Técnica: {score:.1f}%")
            print(f"  - Erro Médio Normalizado: {dist_norm:.2f}°")
            print(f"  - Desvios por articulação: {desvios}")

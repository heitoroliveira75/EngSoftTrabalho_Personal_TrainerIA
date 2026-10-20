"""
Módulo de Buffer de Repetição.
Acumula os fotogramas capturados durante a execução de qualquer exercício,
utilizando a Máquina de Estados (FSM) ativa para recortar cada repetição completa.
"""

from typing import Dict, List, Optional, Tuple, Any
import numpy as np


class BufferRepeticao:
    """
    Acumula os dados da câmara fotograma a fotograma enquanto uma repetição
    estiver em andamento e entrega a matriz (T x D) ao término do ciclo.
    """

    def __init__(self, fsm: Any, articulacoes: List[str]):
        self.fsm = fsm
        self.articulacoes = articulacoes
        self.frames_atuais: List[List[float]] = []

    def _extrair_vetor(self, angulos: Dict[str, float]) -> List[float]:
        """Extrai os valores das articulações na ordem especificada pelo gabarito."""
        if isinstance(angulos, dict):
            return [float(angulos.get(art, 0.0)) for art in self.articulacoes]
        return [float(v) for v in angulos]

    def processar_frame(
        self,
        angulos: Dict[str, float],
        posicoes: Optional[Dict[str, Any]] = None,
        angulos_deltas: Optional[Dict[str, float]] = None
    ) -> Tuple[Optional[np.ndarray], Optional[str]]:
        """
        Processa um único fotograma vindo da webcam ou de um vídeo.
        Retorna (matriz_repeticao_concluida, erro_imediato_fsm).
        """
        posicoes = posicoes or {}
        angulos_deltas = angulos_deltas or {}

        fase_anterior = self.fsm.fases[1]
        reps_anteriores = self.fsm.repeticoes

        erro_imediato = self.fsm.classificar(angulos, posicoes, angulos_deltas)
        fase_atual = self.fsm.fases[1]

        vetor_frame = self._extrair_vetor(angulos)

        # 1. Início da repetição: saiu do repouso (fase 0) para a fase 1
        if fase_anterior == 0 and fase_atual == 1:
            self.frames_atuais = [vetor_frame]

        # 2. Movimento em andamento (fases 1, 2 ou 3)
        elif fase_atual != 0:
            self.frames_atuais.append(vetor_frame)

        # 3. Repetição concluída: a FSM incrementou o contador de repetições
        if self.fsm.repeticoes > reps_anteriores and len(self.frames_atuais) > 0:
            self.frames_atuais.append(vetor_frame)
            repeticao_completa = np.asarray(self.frames_atuais, dtype=float)
            self.frames_atuais = []
            return repeticao_completa, erro_imediato

        return None, erro_imediato
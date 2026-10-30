"""
Módulo de Buffer de Repetição.
Acumula os fotogramas capturados durante a execução de qualquer exercício,
utilizando a Máquina de Estados (FSM) ativa para recortar cada repetição completa.
"""

from typing import Dict, List, Optional, Tuple, Any, Union, Type
import numpy as np

from calculo_angulos import calcular_deltas_angulares
from exercicios_fsm import ExercicioBaseFSM, obter_config_exercicio


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


def extrair_primeira_repeticao(
    fsm_ou_id: Union[ExercicioBaseFSM, Type[ExercicioBaseFSM], str],
    articulacoes: Optional[List[str]] = None,
    serie_angulos: Optional[List[Dict[str, float]]] = None,
    lancar_excecao: bool = False,
) -> Optional[np.ndarray]:
    """
    Segmenta e extrai a primeira repetição completa de uma série temporal de ângulos.

    Utiliza a FSM do exercício e o BufferRepeticao para determinar com exatidão
    o fotograma em que o movimento sai do repouso (fase 0 -> 1) até o retorno ao repouso (fase 3 -> 0).
    Os deltas angulares são calculados internamente via calcular_deltas_angulares() com âncora de 1.2 graus.

    Parâmetros:
        fsm_ou_id: Instância de ExercicioBaseFSM, classe da FSM ou identificador (ex: 'desenvolvimento_ombro', '1').
        articulacoes: Lista com os nomes das articulações a extrair. Se omitido e fsm_ou_id for str,
                      as articulações são inferidas automaticamente via obter_config_exercicio().
        serie_angulos: Lista sequencial de dicionários contendo os ângulos calculados em cada fotograma.
        lancar_excecao: Se True, dispara ValueError quando nenhuma repetição completa for detectada.
                        Se False, retorna None graciosamente.

    Retorno:
        np.ndarray de formato (T, D) contendo os frames da primeira repetição, ou None se incompleto.
    """
    fsm_instancia: ExercicioBaseFSM
    if isinstance(fsm_ou_id, str):
        cfg = obter_config_exercicio(fsm_ou_id)
        fsm_instancia = cfg["classe_fsm"]()
        if articulacoes is None:
            articulacoes = list(cfg["articulacoes"])
    elif isinstance(fsm_ou_id, type) and issubclass(fsm_ou_id, ExercicioBaseFSM):
        fsm_instancia = fsm_ou_id()
    elif isinstance(fsm_ou_id, ExercicioBaseFSM):
        fsm_instancia = fsm_ou_id
    else:
        raise TypeError(
            f"fsm_ou_id deve ser uma instância/classe de ExercicioBaseFSM ou str identificadora, "
            f"recebido: {type(fsm_ou_id)}"
        )

    if not articulacoes:
        raise ValueError(
            "A lista de articulações não pode ser vazia ou nula quando não puder ser "
            "inferida a partir do identificador do exercício."
        )

    if not serie_angulos:
        if lancar_excecao:
            raise ValueError("A série de ângulos fornecida está vazia.")
        return None

    buffer = BufferRepeticao(fsm=fsm_instancia, articulacoes=articulacoes)
    referencia_deltas: Dict[str, float] = {}

    for frame_angulos in serie_angulos:
        deltas = calcular_deltas_angulares(frame_angulos, referencia_deltas, limiar_graus=1.2)
        dados_rep, _ = buffer.processar_frame(
            angulos=frame_angulos,
            angulos_deltas=deltas
        )
        if dados_rep is not None:
            return dados_rep

    if lancar_excecao:
        raise ValueError("Nenhuma repetição completa foi detectada na série de ângulos informada.")

    return None

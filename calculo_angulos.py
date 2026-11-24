"""
Módulo de Cálculo de Ângulos Articulares Multi-Exercícios.
Expande o cálculo vetorial 2D para suportar membros superiores e inferiores,
incluindo verificação de visibilidade dos pontos do MediaPipe.
"""

from typing import Dict, List, Tuple
import numpy as np

# Índices anatómicos oficiais do MediaPipe Pose (Ponto A, Vértice Central B, Ponto C)
MAPA_ARTICULACOES = {
    "direito": {
        "cotovelo": (12, 14, 16),  # ombro -> cotovelo -> punho
        "ombro": (24, 12, 14),     # quadril -> ombro -> cotovelo
        "joelho": (24, 26, 28),    # quadril -> joelho -> tornozelo
        "quadril": (12, 24, 26),   # ombro -> quadril -> joelho
    },
    "esquerdo": {
        "cotovelo": (11, 13, 15),  # ombro -> cotovelo -> punho
        "ombro": (23, 11, 13),     # quadril -> ombro -> cotovelo
        "joelho": (23, 25, 27),    # quadril -> joelho -> tornozelo
        "quadril": (11, 23, 25),   # ombro -> quadril -> joelho
    },
}


def calcular_angulo(ponto_a, ponto_b, ponto_c, com_sinal: bool = False) -> float:
    """
    Calcula o ângulo formado no ponto B (vértice) entre as retas BA e BC.
    Se com_sinal=False (padrão): Retorna o ângulo em graus no intervalo [0.0, 180.0].
    Se com_sinal=True: Retorna o ângulo orientado em graus no intervalo [-180.0, 180.0],
    preservando o sinal do produto vetorial 2D (sentido horário vs anti-horário).
    """
    a = np.array(ponto_a[:2], dtype=float)
    b = np.array(ponto_b[:2], dtype=float)
    c = np.array(ponto_c[:2], dtype=float)

    vetor_ba = a - b
    vetor_bc = c - b

    cross_2d = float(vetor_ba[0] * vetor_bc[1] - vetor_ba[1] * vetor_bc[0])
    dot_2d = float(np.dot(vetor_ba, vetor_bc))

    angulo_rad = np.arctan2(cross_2d, dot_2d)
    angulo_graus = np.degrees(angulo_rad)

    if not com_sinal:
        angulo_graus = np.abs(angulo_graus)

    return round(float(angulo_graus), 2)


def calcular_angulo_orientado(ponto_a, ponto_b, ponto_c) -> float:
    """
    Calcula o ângulo orientado com sinal no intervalo [-180.0, 180.0] graus.
    Preserva a rotação e sentido da articulação via produto vetorial 2D.
    Permite diferenciar flexão de hiperextensão e inclinação anterior de posterior.
    """
    return calcular_angulo(ponto_a, ponto_b, ponto_c, com_sinal=True)


def extrair_angulos_exercicio(
    landmarks,
    articulacoes: List[str],
    lado: str = "direito",
    visibilidade_minima: float = 0.5,
    com_sinal: bool = False
) -> Tuple[Dict[str, float], bool]:
    """
    Extrai apenas os ângulos exigidos pelo exercício ativo e verifica se
    todas as articulações necessárias estão visíveis no enquadramento.

    Returns:
        (dicionario_angulos, corpo_visivel)
    """
    lado_chave = "direito" if lado.lower() == "direito" else "esquerdo"
    mapa_lado = MAPA_ARTICULACOES[lado_chave]

    angulos: Dict[str, float] = {}
    visivel = True

    for nome_art in articulacoes:
        if nome_art not in mapa_lado:
            raise ValueError(f"Articulação '{nome_art}' não configurada no mapa anatómico.")

        idx_a, idx_b, idx_c = mapa_lado[nome_art]
        pts = (landmarks[idx_a], landmarks[idx_b], landmarks[idx_c])

        # Verifica se os 3 pontos da articulação estão visíveis na câmara
        if any(getattr(p, "visibility", 1.0) < visibilidade_minima for p in pts):
            visivel = False

        ponto_a = [pts[0].x, pts[0].y]
        ponto_b = [pts[1].x, pts[1].y]
        ponto_c = [pts[2].x, pts[2].y]

        angulos[nome_art] = calcular_angulo(ponto_a, ponto_b, ponto_c, com_sinal=com_sinal)

    return angulos, visivel


def calcular_deltas_angulares(
    angulos: Dict[str, float],
    referencia: Dict[str, float],
    limiar_graus: float = 1.2
) -> Dict[str, float]:
    """
    Calcula os deltas de variação angular em graus em relação a um dicionário de referência (âncora).
    Atualiza a referência da articulação APENAS quando a diferença absoluta for maior ou igual a limiar_graus.
    Isso impede que variações lentas (graduais) sejam zeradas e perdidas ao longo dos fotogramas.

    Args:
        angulos: Dicionário com os ângulos atuais {nome_art: valor_graus}.
        referencia: Dicionário mutável {nome_art: valor_referencia_graus} mantido ao longo da sessão.
        limiar_graus: Limiar mínimo em graus para registrar movimento (rejeição de ruído/jitter).

    Returns:
        Dicionário {nome_art: delta_graus}.
    """
    deltas: Dict[str, float] = {}
    for art, valor in angulos.items():
        if art not in referencia:
            referencia[art] = float(valor)
            deltas[art] = 0.0
        else:
            diff = float(valor) - referencia[art]
            if abs(diff) >= limiar_graus:
                deltas[art] = round(diff, 2)
                referencia[art] = float(valor)
            else:
                deltas[art] = 0.0
    return deltas

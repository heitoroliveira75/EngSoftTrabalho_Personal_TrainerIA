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


def calcular_angulo(ponto_a, ponto_b, ponto_c) -> float:
    """
    Calcula o ângulo formado no ponto B (vértice) entre as retas BA e BC.
    Retorna o ângulo em graus no intervalo [0.0, 180.0].
    """
    a = np.array(ponto_a[:2], dtype=float)
    b = np.array(ponto_b[:2], dtype=float)
    c = np.array(ponto_c[:2], dtype=float)

    vetor_ba = a - b
    vetor_bc = c - b

    rad_ba = np.arctan2(vetor_ba[1], vetor_ba[0])
    rad_bc = np.arctan2(vetor_bc[1], vetor_bc[0])

    diferenca = np.abs(rad_ba - rad_bc)
    angulo_graus = np.degrees(diferenca)

    if angulo_graus > 180.0:
        angulo_graus = 360.0 - angulo_graus

    return round(float(angulo_graus), 2)


def extrair_angulos_exercicio(
    landmarks,
    articulacoes: List[str],
    lado: str = "direito",
    visibilidade_minima: float = 0.5
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

        angulos[nome_art] = calcular_angulo(ponto_a, ponto_b, ponto_c)

    return angulos, visivel
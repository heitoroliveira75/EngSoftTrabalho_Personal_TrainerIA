"""
Módulo de Cálculo de Ângulos Articulares

Fornece funções matemáticas simples e intuitivas para calcular ângulos
entre landmarks anatômicos detectados pelo MediaPipe (ex: ombro, cotovelo, punho).
"""

import numpy as np


def calcular_angulo(ponto_a, ponto_b, ponto_c) -> float:
    """
    Calcula o ângulo formado no ponto B (vértice) entre as retas BA e BC.

    Args:
        ponto_a: Coordenadas [x, y] do primeiro ponto (ex: ombro).
        ponto_b: Coordenadas [x, y] do vértice central (ex: cotovelo).
        ponto_c: Coordenadas [x, y] do terceiro ponto (ex: punho).

    Returns:
        Ângulo em graus no intervalo [0.0, 180.0].
    """
    a = np.array(ponto_a[:2], dtype=float)
    b = np.array(ponto_b[:2], dtype=float)
    c = np.array(ponto_c[:2], dtype=float)

    # Vetores que partem do vértice central B
    vetor_ba = a - b
    vetor_bc = c - b

    # Cálculo dos ângulos polares em relação ao eixo X
    rad_ba = np.arctan2(vetor_ba[1], vetor_ba[0])
    rad_bc = np.arctan2(vetor_bc[1], vetor_bc[0])

    # Diferença absoluta entre os ângulos
    diferenca = np.abs(rad_ba - rad_bc)
    angulo_graus = np.degrees(diferenca)

    # Garante que o ângulo seja o menor arco (entre 0 e 180 graus)
    if angulo_graus > 180.0:
        angulo_graus = 360.0 - angulo_graus

    return round(float(angulo_graus), 2)


def extrair_angulos_ombro_e_cotovelo(landmarks, lado: str = "direito") -> dict:
    """
    Extrai os ângulos articulares de ombro e cotovelo a partir dos landmarks do MediaPipe.

    Args:
        landmarks: Lista de pontos detectados pelo MediaPipe Pose.
        lado: 'direito' ou 'esquerdo' (define se analisa o braço direito ou esquerdo).

    Returns:
        Dicionário com os ângulos calculados: {'cotovelo': float, 'ombro': float}
    """
    # Índices anatômicos oficiais do MediaPipe Pose:
    if lado.lower() == "direito":
        idx_ombro = 12
        idx_cotovelo = 14
        idx_punho = 16
        idx_quadril = 24
    else:  # esquerdo
        idx_ombro = 11
        idx_cotovelo = 13
        idx_punho = 15
        idx_quadril = 23

    # Coordenadas normalizadas [x, y] extraídas do MediaPipe
    ombro = [landmarks[idx_ombro].x, landmarks[idx_ombro].y]
    cotovelo = [landmarks[idx_cotovelo].x, landmarks[idx_cotovelo].y]
    punho = [landmarks[idx_punho].x, landmarks[idx_punho].y]
    quadril = [landmarks[idx_quadril].x, landmarks[idx_quadril].y]

    # 1. Cotovelo: ângulo formado por ombro -> cotovelo -> punho
    angulo_cotovelo = calcular_angulo(ombro, cotovelo, punho)

    # 2. Ombro: ângulo formado por quadril -> ombro -> cotovelo
    angulo_ombro = calcular_angulo(quadril, ombro, cotovelo)

    return {
        "cotovelo": angulo_cotovelo,
        "ombro": angulo_ombro
    }


if __name__ == "__main__":
    # Teste rápido: simulação de um braço posicionado em ângulo reto (90 graus)
    ombro_teste = [0.0, 1.0]      # Ponto superior
    cotovelo_teste = [0.0, 0.0]   # Vértice
    punho_teste = [1.0, 0.0]      # Ponto lateral

    resultado = calcular_angulo(ombro_teste, cotovelo_teste, punho_teste)

    print("=== Teste do Módulo calculo_angulos.py ===")
    print(f"Ângulo calculado para cotovelo em 90°: {resultado}° (Esperado: 90.0°)")

"""
Módulo Inicial de Dynamic Time Warping (DTW)

implementação inicial do DTW, vai ser útil para comparar execuções posteriormente.
"""

import numpy as np


class DTW:
    """
    Classe responsável pelo cálculo do DTW
    """

    def __init__(self):
        self.distancia_total = 0.0
        self.distancia_normalizada = 0.0
        self.caminho = []

    def calcular(self, serie_a, serie_b):
        """
        Calcula o alinhamento temporal ótimo e as distâncias (acumulada e normalizada)
        entre duas séries temporais (unidimensionais ou multidimensionais).

        Args:
            serie_a: Sequência do usuário. Shape (N,) para 1D ou (N, D) para D features/articulações.
            serie_b: Sequência de referência. Shape (M,) para 1D ou (M, D) para D features/articulações.

        Returns:
            distancia_total: Custo acumulado total de alinhamento temporal.
            distancia_normalizada: Custo médio por frame alinhado (distancia_total / len(caminho)).
            caminho: Lista de pares de índices alinhados [(idx_a, idx_b), ...].
        """
        a = np.asarray(serie_a, dtype=float)
        b = np.asarray(serie_b, dtype=float)

        # Garante shape 2D (T, D), compatível tanto com 1D quanto com D dimensões
        if a.ndim == 1:
            a = a[:, np.newaxis]
        if b.ndim == 1:
            b = b[:, np.newaxis]

        n, dims_a = a.shape
        m, dims_b = b.shape

        if dims_a != dims_b:
            raise ValueError(
                f"Dimensões incompatíveis: serie_a possui {dims_a} dimensões e serie_b possui {dims_b}."
            )

        # matriz de custo local (distância Euclidiana para D dimensões)
        custo = np.zeros((n, m))
        for i in range(n):
            for j in range(m):
                custo[i, j] = np.linalg.norm(a[i] - b[j])

        # matriz de custo acumulado
        acumulado = np.zeros((n, m))
        acumulado[0, 0] = custo[0, 0]

        # inicializacao da primeira linha e coluna
        for i in range(1, n):
            acumulado[i, 0] = acumulado[i - 1, 0] + custo[i, 0]

        for j in range(1, m):
            acumulado[0, j] = acumulado[0, j - 1] + custo[0, j]

        # preenchimento das transições: inserção, deleção e correspondência
        for i in range(1, n):
            for j in range(1, m):
                menor_vizinho = min(
                    acumulado[i - 1, j],      # inserção
                    acumulado[i, j - 1],      # deleção
                    acumulado[i - 1, j - 1]   # correspondência
                )
                acumulado[i, j] = custo[i, j] + menor_vizinho

        # backtracking para encontrar o warping path
        i, j = n - 1, m - 1
        caminho = [(i, j)]

        while i > 0 or j > 0:
            if i == 0:
                j -= 1
            elif j == 0:
                i -= 1
            else:
                opcoes = [
                    (acumulado[i - 1, j - 1], i - 1, j - 1),
                    (acumulado[i - 1, j], i - 1, j),
                    (acumulado[i, j - 1], i, j - 1),
                ]
                _, i, j = min(opcoes, key=lambda x: x[0])
            caminho.append((i, j))

        caminho.reverse()

        self.distancia_total = float(acumulado[n - 1, m - 1])
        self.caminho = caminho
        self.distancia_normalizada = self.distancia_total / max(1, len(caminho))

        return self.distancia_total, self.distancia_normalizada, self.caminho


if __name__ == "__main__":
    # Exemplo multidimensional: cada frame contém [angulo_cotovelo, angulo_ombro]
    # Gabarito de referência: subida e descida padrão (7 frames)
    referencia = [
        [90, 80],
        [115, 105],
        [145, 135],
        [165, 155],
        [145, 135],
        [115, 105],
        [90, 80]
    ]

    # Execução do usuário: mesmo movimento, mas executado mais lentamente (11 frames)
    usuario_lento = [
        [90, 80],
        [95, 85],
        [110, 100],
        [125, 115],
        [145, 135],
        [155, 145],
        [165, 155],
        [150, 140],
        [130, 120],
        [105, 95],
        [90, 80]
    ]

    dtw = DTW()
    dist_total, dist_norm, path = dtw.calcular(usuario_lento, referencia)

    print("=== Teste DTW Multidimensional com Normalização ===")
    print(f"Distância Total Acumulada: {dist_total:.2f}")
    print(f"Distância Normalizada (erro médio/frame): {dist_norm:.2f}°")
    print(f"Pares alinhados no caminho: {len(path)}")
    print(f"Primeiros alinhamentos (usuario, referencia): {path[:4]}")

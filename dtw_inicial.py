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
        self.caminho = []

    def calcular(self, serie_a, serie_b):
        """
        Calcula a distância mínima acumulada entre duas séries temporais.

        Args:
            serie_a: Lista ou array com a primeira sequência (ex: execução do usuário).
            serie_b: Lista ou array com a segunda sequência (ex: gabarito de referência).

        Returns:
            distancia_total: Custo acumulado total de alinhamento temporal.
            caminho: Lista de pares de índices alinhados [(idx_a, idx_b), ...].
        """
        a = np.array(serie_a, dtype=float)
        b = np.array(serie_b, dtype=float)

        n = len(a)
        m = len(b)

        # matriz de custo local
        custo = np.zeros((n, m))
        for i in range(n):
            for j in range(m):
                custo[i, j] = abs(a[i] - b[j])

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

        return self.distancia_total, self.caminho


if __name__ == "__main__":
    # Exemplo simples de uso: mesmo movimento (subida e descida do braço),
    # porém executado com cadências (velocidades) diferentes.
    referencia = [90, 115, 145, 165, 145, 115, 90]                # 7 frames
    usuario = [90, 95, 110, 125, 145, 155, 165, 150, 130, 105, 90]  # 11 frames

    dtw = DTW()
    dist, path = dtw.calcular(usuario, referencia)

    print("=== Teste DTW Inicial ===")
    print(f"Distância Acumulada: {dist:.2f}")
    print(f"Pares alinhados no caminho: {len(path)}")
    print(f"Primeiros alinhamentos: {path[:4]}")

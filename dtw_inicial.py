"""
Módulo de Dynamic Time Warping (DTW).
Calcula o alinhamento temporal ótimo entre a repetição do utilizador e o gabarito,
gerando o score percentual de técnica (0 a 100%) e o desvio médio por articulação.
"""

import numpy as np


class DTW:
    def __init__(self, tolerancia: float = 15.0):
        self.tolerancia = float(tolerancia)
        self.distancia_total = 0.0
        self.distancia_normalizada = 0.0
        self.score_similaridade = 0.0
        self.caminho = []
        self.desvios_por_articulacao = {}

    def calcular(self, serie_a, serie_b, nomes_articulacoes=None):
        a = np.asarray(serie_a, dtype=float)
        b = np.asarray(serie_b, dtype=float)

        if a.ndim == 1:
            a = a[:, np.newaxis]
        if b.ndim == 1:
            b = b[:, np.newaxis]

        n, dims_a = a.shape
        m, dims_b = b.shape

        if dims_a != dims_b:
            raise ValueError(
                f"Dimensões incompatíveis: serie_a possui {dims_a} e serie_b possui {dims_b}."
            )

        custo = np.zeros((n, m))
        for i in range(n):
            for j in range(m):
                custo[i, j] = np.linalg.norm(a[i] - b[j])

        acumulado = np.zeros((n, m))
        acumulado[0, 0] = custo[0, 0]

        for i in range(1, n):
            acumulado[i, 0] = acumulado[i - 1, 0] + custo[i, 0]

        for j in range(1, m):
            acumulado[0, j] = acumulado[0, j - 1] + custo[0, j]

        for i in range(1, n):
            for j in range(1, m):
                menor_vizinho = min(
                    acumulado[i - 1, j],
                    acumulado[i, j - 1],
                    acumulado[i - 1, j - 1]
                )
                acumulado[i, j] = custo[i, j] + menor_vizinho

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

        score = 100.0 * np.exp(-self.distancia_normalizada / max(1e-6, self.tolerancia))
        self.score_similaridade = round(float(np.clip(score, 0.0, 100.0)), 2)

        indices_a = [par[0] for par in caminho]
        indices_b = [par[1] for par in caminho]
        alinhado_a = a[indices_a]
        alinhado_b = b[indices_b]

        desvios_medios = np.mean(np.abs(alinhado_a - alinhado_b), axis=0)

        if nomes_articulacoes and len(nomes_articulacoes) == dims_a:
            self.desvios_por_articulacao = {
                str(nome): round(float(desvios_medios[k]), 2)
                for k, nome in enumerate(nomes_articulacoes)
            }
        else:
            self.desvios_por_articulacao = {
                f"articulacao_{k}": round(float(desvios_medios[k]), 2)
                for k in range(dims_a)
            }

        return (
            self.distancia_total,
            self.distancia_normalizada,
            self.score_similaridade,
            self.caminho,
            self.desvios_por_articulacao,
        )
"""
Módulo Inicial de Dynamic Time Warping (DTW)

implementação inicial do DTW, vai ser útil para comparar execuções posteriormente.
"""

import numpy as np


class DTW:
    """
    Classe responsável pelo cálculo do DTW
    """

    def __init__(self, tolerancia=15.0):
        """
        Args:
            tolerancia: Fator de escala (em graus) para a conversão de distância em score.
                        Quanto maior o valor, mais tolerante é a pontuação a pequenas variações.
        """
        self.tolerancia = float(tolerancia)
        self.distancia_total = 0.0
        self.distancia_normalizada = 0.0
        self.score_similaridade = 0.0
        self.caminho = []
        self.desvios_por_articulacao = {}

    def calcular(self, serie_a, serie_b, nomes_articulacoes=None):
        """
        Calcula o alinhamento temporal ótimo, as distâncias (acumulada e normalizada),
        o score de similaridade percentual e o desvio médio individual por articulação.

        Args:
            serie_a: Sequência do usuário. Shape (N,) para 1D ou (N, D) para D features/articulações.
            serie_b: Sequência de referência (especialista). Shape (M,) para 1D ou (M, D) para D features/articulações.
            nomes_articulacoes: Lista opcional com os identificadores das articulações (ex: ["cotovelo", "ombro"]).

        Returns:
            distancia_total: Custo acumulado total de alinhamento temporal.
            distancia_normalizada: Custo médio por frame alinhado (distancia_total / len(caminho)).
            score_similaridade: Score percentual de técnica de 0 a 100%.
            caminho: Lista de pares de índices alinhados [(idx_a, idx_b), ...].
            desvios_por_articulacao: Dicionário com a diferença média individual de cada articulação ao longo do caminho.
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

        # calculo do score percentual de similaridade técnica (0 a 100%)
        # decaimento exponencial: score diminui suavemente conforme o erro médio aumenta
        score = 100.0 * np.exp(-self.distancia_normalizada / max(1e-6, self.tolerancia))
        self.score_similaridade = round(float(np.clip(score, 0.0, 100.0)), 2)

        # calculo do desvio medio individual por articulacao ao longo do caminho alinhado
        indices_a = [par[0] for par in caminho]
        indices_b = [par[1] for par in caminho]
        alinhado_a = a[indices_a]
        alinhado_b = b[indices_b]

        # diferenca absoluta media de cada coluna ao longo do alinhamento otimo
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


if __name__ == "__main__":
    articulacoes = ["cotovelo", "ombro"]

    # Gabarito gravado pelo especialista: subida e descida ideal (7 frames)
    # Formato: [angulo_cotovelo, angulo_ombro]
    gabarito_especialista = [
        [90, 80],
        [115, 105],
        [145, 135],
        [165, 155],
        [145, 135],
        [115, 105],
        [90, 80]
    ]

    # Execução do usuário pela câmera:
    # - Fez o movimento mais lento (11 frames)
    # - O cotovelo acompanhou bem o gabarito
    # - O ombro abriu de forma errada (valores bem abaixo do especialista)
    usuario_camera = [
        [90, 78],
        [95, 82],
        [110, 88],
        [125, 95],
        [145, 110],
        [155, 118],
        [165, 120],  # pico com cotovelo correto (~165), mas ombro muito abaixo do ideal (120 vs 155)
        [150, 115],
        [130, 100],
        [105, 88],
        [90, 78]
    ]

    dtw = DTW(tolerancia=15.0)
    dist_total, dist_norm, score, path, desvios = dtw.calcular(
        usuario_camera,
        gabarito_especialista,
        nomes_articulacoes=articulacoes
    )

    print("=== Teste DTW: Diagnóstico com Score Percentual ===")
    print(f"Similaridade Técnica: {score:.1f}%")
    print(f"Distância Normalizada (erro global médio): {dist_norm:.2f}°")
    print(f"Distância Total Acumulada: {dist_total:.2f}")
    print(f"Frames alinhados: {len(path)}")
    print("\nDesvio médio individual por articulação:")
    for art, erro in desvios.items():
        print(f"  - {art.capitalize()}: desvio médio de {erro}° em relação ao especialista")

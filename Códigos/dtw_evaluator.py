"""
Módulo de Dynamic Time Warping (DTW) Vetorizado e Avaliação Temporal.
Fornece alinhamento ótimo multivariado entre séries temporais de repetições
e gabaritos biomecânicos de referência, suportando janelas de Sakoe-Chiba,
vetorização via NumPy broadcasting e degradação graciosa para tempo real.
"""

from dataclasses import dataclass, field
from typing import Dict, List, Optional, Tuple, Union, Iterator, Any
import numpy as np


@dataclass
class DTWResult:
    """
    Estrutura de dados com os resultados de alinhamento temporal DTW.
    Suporta tanto acesso orientado a objetos por atributos tipados
    quanto desempacotamento de 5 elementos para compatibilidade retroativa:
    (distancia_total, distancia_normalizada, score_similaridade, caminho, desvios_por_articulacao).
    """
    distancia_total: float
    distancia_normalizada: float
    score_similaridade: float
    caminho: List[Tuple[int, int]]
    desvios_por_articulacao: Dict[str, float]
    valido: bool = True
    mensagem_erro: Optional[str] = None

    def __iter__(self) -> Iterator[Any]:
        """Permite desempacotamento como tupla compatível com o formato legado."""
        yield self.distancia_total
        yield self.distancia_normalizada
        yield self.score_similaridade
        yield self.caminho
        yield self.desvios_por_articulacao

    def __getitem__(self, index: int) -> Any:
        """Permite indexação posicional legada (ex.: resultado[2] para score_similaridade)."""
        campos = [
            self.distancia_total,
            self.distancia_normalizada,
            self.score_similaridade,
            self.caminho,
            self.desvios_por_articulacao,
        ]
        return campos[index]


class DTWComparator:
    """
    Motor de Dynamic Time Warping vetorizado de alta performance.
    
    Utiliza broadcasting tridimensional em NumPy para cálculo instantâneo
    da matriz de distâncias locais e programação dinâmica com suporte
    à faixa de restrição temporal de Sakoe-Chiba.
    """

    def __init__(
        self,
        tolerancia: float = 15.0,
        janela: Optional[Union[int, float]] = None
    ):
        """
        Args:
            tolerancia: Fator tau de tolerância angular em graus para o decaimento exponencial.
            janela: Restrição de Sakoe-Chiba. Se float (ex.: 0.20), representa proporção (20%)
                    da série máxima; se int, representa o número absoluto de frames; se None,
                    executa alinhamento global irrestrito.
        """
        self.tolerancia = float(tolerancia)
        self.janela = janela

    def compute(
        self,
        serie_a: Union[np.ndarray, List[List[float]]],
        serie_b: Union[np.ndarray, List[List[float]]],
        nomes_articulacoes: Optional[List[str]] = None,
        tolerancia: Optional[float] = None,
        janela: Optional[Union[int, float]] = None,
        lancar_excecao: bool = False
    ) -> DTWResult:
        """
        Calcula o alinhamento temporal ótimo entre serie_a (ex.: aluno) e serie_b (ex.: gabarito).

        Args:
            serie_a: Matriz (N x D) ou sequência de fotogramas da repetição.
            serie_b: Matriz (M x D) ou sequência de fotogramas do gabarito.
            nomes_articulacoes: Nomes das D articulações para o mapa de desvios.
            tolerancia: Sobrescrita pontual do fator tau de tolerância angular em graus.
            janela: Sobrescrita pontual da janela de Sakoe-Chiba.
            lancar_excecao: Se True, lança ValueError em dados inválidos. Se False (padrão),
                            degrada graciosamente retornando DTWResult com valido=False.

        Returns:
            DTWResult com pontuação de 0 a 100, métricas de distância, caminho e desvios.
        """
        # 1. Conversão e normalização de formato
        a = np.asarray(serie_a, dtype=float)
        b = np.asarray(serie_b, dtype=float)

        if a.ndim == 1:
            a = a[:, np.newaxis]
        if b.ndim == 1:
            b = b[:, np.newaxis]

        # 2. Validação de integridade e tratamento gracioso de casos limítrofes
        erro_validacao: Optional[str] = None
        if a.size == 0 or b.size == 0:
            erro_validacao = "Série temporal vazia fornecida para alinhamento DTW."
        elif a.shape[0] < 3 or b.shape[0] < 3:
            erro_validacao = (
                f"Série com comprimento insuficiente (< 3 frames): "
                f"serie_a={a.shape[0]}, serie_b={b.shape[0]}."
            )
        elif a.shape[1] != b.shape[1]:
            erro_validacao = (
                f"Dimensões incompatíveis: serie_a possui {a.shape[1]} articulações "
                f"e serie_b possui {b.shape[1]}."
            )

        if erro_validacao:
            if lancar_excecao:
                raise ValueError(erro_validacao)
            return DTWResult(
                distancia_total=float("inf"),
                distancia_normalizada=float("inf"),
                score_similaridade=0.0,
                caminho=[],
                desvios_por_articulacao={},
                valido=False,
                mensagem_erro=erro_validacao,
            )

        n, dims = a.shape
        m, _ = b.shape

        # 3. Definição da restrição de Sakoe-Chiba
        param_janela = self.janela if janela is None else janela
        if param_janela is not None:
            if isinstance(param_janela, float):
                w_base = int(round(param_janela * max(n, m)))
            else:
                w_base = int(param_janela)
            w_eff = max(max(1, w_base), abs(n - m))
        else:
            w_eff = max(n, m)  # Sem restrição prática, cobre toda a matriz

        # 4. Matriz de Custo Local Vetorizada via NumPy 3D Broadcasting
        # a[:, None, :] -> (n, 1, dims); b[None, :, :] -> (1, m, dims)
        diferencas = a[:, None, :] - b[None, :, :]
        custo = np.linalg.norm(diferencas, axis=2)

        # 5. Programação Dinâmica da Matriz de Custo Acumulado
        acumulado = np.full((n, m), np.inf, dtype=float)
        acumulado[0, 0] = custo[0, 0]

        for i in range(n):
            j_inicio = max(0, i - w_eff)
            j_fim = min(m, i + w_eff + 1)
            for j in range(j_inicio, j_fim):
                if i == 0 and j == 0:
                    continue
                v_esq = acumulado[i, j - 1] if j > 0 else np.inf
                v_cim = acumulado[i - 1, j] if i > 0 else np.inf
                v_diag = acumulado[i - 1, j - 1] if (i > 0 and j > 0) else np.inf
                menor_vizinho = min(v_diag, v_cim, v_esq)
                if menor_vizinho < np.inf:
                    acumulado[i, j] = custo[i, j] + menor_vizinho

        # 6. Backtracking do Caminho Ótimo
        i, j = n - 1, m - 1
        caminho: List[Tuple[int, int]] = [(i, j)]

        while i > 0 or j > 0:
            if i == 0:
                j -= 1
            elif j == 0:
                i -= 1
            else:
                opcoes = [
                    (acumulado[i - 1, j - 1], i - 1, j - 1),  # Diagonal prioritária
                    (acumulado[i - 1, j], i - 1, j),          # Cima
                    (acumulado[i, j - 1], i, j - 1),          # Esquerda
                ]
                _, i, j = min(opcoes, key=lambda x: x[0])
            caminho.append((i, j))

        caminho.reverse()

        # 7. Métricas de Distância e Score Exponencial
        distancia_total = float(acumulado[n - 1, m - 1])
        caminho_len = max(1, len(caminho))
        distancia_normalizada = distancia_total / caminho_len

        tau = self.tolerancia if tolerancia is None else float(tolerancia)
        score_bruto = 100.0 * np.exp(-distancia_normalizada / max(1e-6, tau))
        score_similaridade = round(float(np.clip(score_bruto, 0.0, 100.0)), 2)

        # 8. Desvio Médio Absoluto por Articulação ao Longo do Caminho
        idx_a = [p[0] for p in caminho]
        idx_b = [p[1] for p in caminho]
        alinhado_a = a[idx_a]
        alinhado_b = b[idx_b]
        desvios_medios = np.mean(np.abs(alinhado_a - alinhado_b), axis=0)

        if nomes_articulacoes and len(nomes_articulacoes) == dims:
            desvios_dict = {
                str(nome): round(float(desvios_medios[k]), 2)
                for k, nome in enumerate(nomes_articulacoes)
            }
        else:
            desvios_dict = {
                f"articulacao_{k}": round(float(desvios_medios[k]), 2)
                for k in range(dims)
            }

        return DTWResult(
            distancia_total=round(distancia_total, 4),
            distancia_normalizada=round(distancia_normalizada, 4),
            score_similaridade=score_similaridade,
            caminho=caminho,
            desvios_por_articulacao=desvios_dict,
            valido=True,
            mensagem_erro=None,
        )

    def calcular(
        self,
        serie_a: Union[np.ndarray, List[List[float]]],
        serie_b: Union[np.ndarray, List[List[float]]],
        nomes_articulacoes: Optional[List[str]] = None
    ) -> DTWResult:
        """Alias para compatibilidade direta com a assinatura do dtw_inicial.py."""
        return self.compute(serie_a, serie_b, nomes_articulacoes=nomes_articulacoes)


# Alias para instanciação semântica limpa
DTW = DTWComparator

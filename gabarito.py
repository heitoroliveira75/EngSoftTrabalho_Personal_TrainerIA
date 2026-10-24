"""
Módulo de Gabarito do Especialista.
Persiste e carrega séries temporais de referência em JSON e gera gabaritos
biomecânicos padrão caso ainda não existam no disco.
"""

import json
import os
from typing import List, Union, Dict
import numpy as np

from buffer_repeticao import extrair_primeira_repeticao


class GabaritoExercicio:
    def __init__(
        self,
        nome_exercicio: str,
        articulacoes: List[str],
        dados: Union[np.ndarray, List[List[float]]],
        descricao: str = ""
    ):
        self.nome_exercicio = nome_exercicio
        self.articulacoes = articulacoes
        self.descricao = descricao
        self.dados = np.asarray(dados, dtype=float)

        if self.dados.ndim == 1:
            self.dados = self.dados[:, np.newaxis]

        if self.dados.shape[1] != len(self.articulacoes):
            raise ValueError(
                f"Quantidade de articulações ({len(self.articulacoes)}) diverge "
                f"do número de colunas nos dados ({self.dados.shape[1]})."
            )

    @property
    def total_frames(self) -> int:
        return self.dados.shape[0]

    @property
    def total_articulacoes(self) -> int:
        return self.dados.shape[1]

    def salvar_json(self, caminho_arquivo: str) -> None:
        conteudo = {
            "nome_exercicio": self.nome_exercicio,
            "descricao": self.descricao,
            "articulacoes": self.articulacoes,
            "dados": self.dados.tolist(),
        }
        with open(caminho_arquivo, "w", encoding="utf-8") as f:
            json.dump(conteudo, f, indent=4, ensure_ascii=False)

    @classmethod
    def carregar_json(cls, caminho_arquivo: str) -> "GabaritoExercicio":
        with open(caminho_arquivo, "r", encoding="utf-8") as f:
            conteudo = json.load(f)

        return cls(
            nome_exercicio=conteudo["nome_exercicio"],
            articulacoes=conteudo["articulacoes"],
            dados=conteudo["dados"],
            descricao=conteudo.get("descricao", ""),
        )


def garantir_gabaritos_padrao(sobrescrever: bool = False) -> None:
    """
    Cria ou regenera os arquivos JSON de referência para Desenvolvimento de Ombro,
    Agachamento e Rosca de Bíceps utilizando o segmentador canônico da FSM.

    Parâmetros:
        sobrescrever: Se True, recria os gabaritos no disco mesmo se já existirem.
    """
    frames_movimento = 45
    t = np.linspace(0, np.pi, frames_movimento)

    # 1. Desenvolvimento de Ombro: Cotovelo (90° -> 165° -> 90°), Ombro (80° -> 155° -> 80°)
    arq_ombro = "gabarito_especialista_ombro.json"
    if sobrescrever or not os.path.exists(arq_ombro):
        serie_ombro: List[Dict[str, float]] = []
        for _ in range(5):
            serie_ombro.append({"cotovelo": 90.0, "ombro": 80.0})
        for val_t in t:
            serie_ombro.append({
                "cotovelo": float(90.0 + 75.0 * np.sin(val_t)),
                "ombro": float(80.0 + 75.0 * np.sin(val_t)),
            })
        for _ in range(5):
            serie_ombro.append({"cotovelo": 90.0, "ombro": 80.0})

        dados_ombro = extrair_primeira_repeticao("desenvolvimento_ombro", serie_angulos=serie_ombro, lancar_excecao=True)
        GabaritoExercicio(
            nome_exercicio="desenvolvimento_ombro",
            articulacoes=["cotovelo", "ombro"],
            dados=dados_ombro,
            descricao="Gabarito padrão ouro para Desenvolvimento de Ombro (recorte FSM).",
        ).salvar_json(arq_ombro)

    # 2. Agachamento Livre: Joelho (170° -> 90° -> 170°), Quadril (170° -> 85° -> 170°)
    arq_agachamento = "gabarito_especialista_agachamento.json"
    if sobrescrever or not os.path.exists(arq_agachamento):
        serie_agach: List[Dict[str, float]] = []
        for _ in range(5):
            serie_agach.append({"joelho": 170.0, "quadril": 170.0})
        for val_t in t:
            serie_agach.append({
                "joelho": float(170.0 - 80.0 * np.sin(val_t)),
                "quadril": float(170.0 - 85.0 * np.sin(val_t)),
            })
        for _ in range(5):
            serie_agach.append({"joelho": 170.0, "quadril": 170.0})

        dados_agach = extrair_primeira_repeticao("agachamento", serie_angulos=serie_agach, lancar_excecao=True)
        GabaritoExercicio(
            nome_exercicio="agachamento",
            articulacoes=["joelho", "quadril"],
            dados=dados_agach,
            descricao="Gabarito padrão ouro para Agachamento Livre (recorte FSM).",
        ).salvar_json(arq_agachamento)

    # 3. Rosca Direta de Bíceps: Cotovelo (165° -> 50° -> 165°), Ombro estável (~15°)
    arq_rosca = "gabarito_especialista_rosca.json"
    if sobrescrever or not os.path.exists(arq_rosca):
        serie_rosca: List[Dict[str, float]] = []
        for _ in range(5):
            serie_rosca.append({"cotovelo": 165.0, "ombro": 15.0})
        for val_t in t:
            serie_rosca.append({
                "cotovelo": float(165.0 - 115.0 * np.sin(val_t)),
                "ombro": float(15.0 + 3.0 * np.sin(val_t)),
            })
        for _ in range(5):
            serie_rosca.append({"cotovelo": 165.0, "ombro": 15.0})

        dados_rosca = extrair_primeira_repeticao("rosca_biceps", serie_angulos=serie_rosca, lancar_excecao=True)
        GabaritoExercicio(
            nome_exercicio="rosca_biceps",
            articulacoes=["cotovelo", "ombro"],
            dados=dados_rosca,
            descricao="Gabarito padrão ouro para Rosca Direta de Bíceps (recorte FSM).",
        ).salvar_json(arq_rosca)


if __name__ == "__main__":
    garantir_gabaritos_padrao(sobrescrever=True)
    print("Gabaritos padrão verificados/gerados com sucesso via FSM canônica!")

"""
Módulo de Gabarito do Especialista.
Persiste e carrega séries temporais de referência em JSON e gera gabaritos
biomecânicos padrão caso ainda não existam no disco.
"""

import json
import os
from typing import List, Union
import numpy as np


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


def garantir_gabaritos_padrao() -> None:
    """
    Cria os ficheiros JSON de referência para Desenvolvimento de Ombro,
    Agachamento e Rosca de Bíceps caso ainda não existam na pasta.
    """
    frames = 40
    t = np.linspace(0, np.pi, frames)

    # 1. Desenvolvimento de Ombro: Cotovelo (90° -> 165° -> 90°), Ombro (80° -> 155° -> 80°)
    arq_ombro = "gabarito_especialista_ombro.json"
    if not os.path.exists(arq_ombro):
        dados_ombro = np.column_stack((90.0 + 75.0 * np.sin(t), 80.0 + 75.0 * np.sin(t)))
        GabaritoExercicio(
            nome_exercicio="desenvolvimento_ombro",
            articulacoes=["cotovelo", "ombro"],
            dados=dados_ombro,
            descricao="Gabarito padrão ouro para Desenvolvimento de Ombro.",
        ).salvar_json(arq_ombro)

    # 2. Agachamento Livre: Joelho (170° -> 90° -> 170°), Quadril (170° -> 85° -> 170°)
    arq_agachamento = "gabarito_especialista_agachamento.json"
    if not os.path.exists(arq_agachamento):
        dados_agach = np.column_stack((170.0 - 80.0 * np.sin(t), 170.0 - 85.0 * np.sin(t)))
        GabaritoExercicio(
            nome_exercicio="agachamento",
            articulacoes=["joelho", "quadril"],
            dados=dados_agach,
            descricao="Gabarito padrão ouro para Agachamento Livre.",
        ).salvar_json(arq_agachamento)

    # 3. Rosca Direta de Bíceps: Cotovelo (165° -> 50° -> 165°), Ombro estável (~15°)
    arq_rosca = "gabarito_especialista_rosca.json"
    if not os.path.exists(arq_rosca):
        dados_rosca = np.column_stack((165.0 - 115.0 * np.sin(t), 15.0 + 5.0 * np.sin(t)))
        GabaritoExercicio(
            nome_exercicio="rosca_biceps",
            articulacoes=["cotovelo", "ombro"],
            dados=dados_rosca,
            descricao="Gabarito padrão ouro para Rosca Direta de Bíceps.",
        ).salvar_json(arq_rosca)


if __name__ == "__main__":
    garantir_gabaritos_padrao()
    print("Gabaritos padrão verificados/gerados com sucesso!")
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
        caminho_final = caminho_arquivo
        if not os.path.exists(caminho_final):
            raiz_projeto = os.path.dirname(os.path.abspath(__file__))
            nome_base = os.path.basename(caminho_arquivo)
            raiz_repo = os.path.dirname(raiz_projeto)
            candidato = os.path.join(raiz_projeto, nome_base)
            for cand in [os.path.join("Gabaritos", nome_base), os.path.join(raiz_repo, "Gabaritos", nome_base), candidato]:
                if os.path.exists(cand):
                    candidato = cand
                    break
            if os.path.exists(candidato):
                caminho_final = candidato
        with open(caminho_final, "r", encoding="utf-8") as f:
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

    # 4. Elevação Lateral: Ombro (20° -> 90° -> 20°), Cotovelo estável (~160°)
    pasta_gabaritos = "Gabaritos" if os.path.exists("Gabaritos") else "."
    arq_elevacao = os.path.join(pasta_gabaritos, "gabarito_especialista_elevacao_lateral.json")
    if sobrescrever or not os.path.exists(arq_elevacao):
        serie_elev: List[Dict[str, float]] = []
        for _ in range(5):
            serie_elev.append({"ombro": 20.0, "cotovelo": 160.0})
        for val_t in t:
            serie_elev.append({
                "ombro": float(20.0 + 70.0 * np.sin(val_t)),
                "cotovelo": float(160.0 - 5.0 * np.sin(val_t)),
            })
        for _ in range(5):
            serie_elev.append({"ombro": 20.0, "cotovelo": 160.0})

        dados_elev = extrair_primeira_repeticao("elevacao_lateral", serie_angulos=serie_elev, lancar_excecao=True)
        GabaritoExercicio(
            nome_exercicio="elevacao_lateral",
            articulacoes=["ombro", "cotovelo"],
            dados=dados_elev,
            descricao="Gabarito padrão ouro para Elevação Lateral (recorte FSM).",
        ).salvar_json(arq_elevacao)

    # 5. Puxada Alta com Halteres: Ombro (20° -> 110° -> 20°), Cotovelo (165° -> 60° -> 165°)
    arq_puxada = os.path.join(pasta_gabaritos, "gabarito_especialista_puxada_alta.json")
    if sobrescrever or not os.path.exists(arq_puxada):
        serie_puxada: List[Dict[str, float]] = []
        for _ in range(5):
            serie_puxada.append({"ombro": 20.0, "cotovelo": 165.0})
        for val_t in t:
            serie_puxada.append({
                "ombro": float(20.0 + 90.0 * np.sin(val_t)),
                "cotovelo": float(165.0 - 105.0 * np.sin(val_t)),
            })
        for _ in range(5):
            serie_puxada.append({"ombro": 20.0, "cotovelo": 165.0})

        dados_puxada = extrair_primeira_repeticao("puxada_alta_halteres", serie_angulos=serie_puxada, lancar_excecao=True)
        GabaritoExercicio(
            nome_exercicio="puxada_alta_halteres",
            articulacoes=["ombro", "cotovelo"],
            dados=dados_puxada,
            descricao="Gabarito padrão ouro para Puxada Alta com Halteres (recorte FSM).",
        ).salvar_json(arq_puxada)


if __name__ == "__main__":
    garantir_gabaritos_padrao(sobrescrever=True)
    print("Gabaritos padrão verificados/gerados com sucesso via FSM canônica!")

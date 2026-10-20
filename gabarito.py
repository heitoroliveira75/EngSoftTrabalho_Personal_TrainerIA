"""
Módulo de Gabarito do Especialista

Responsável por encapsular, persistir (salvar) e carregar as séries temporais
de referência gravadas por especialistas para qualquer exercício físico.
"""

import json
from typing import List, Union
import numpy as np


class GabaritoExercicio:
    """
    Representa a execução de referência ("padrão ouro") de um exercício.
    """

    def __init__(
        self,
        nome_exercicio: str,
        articulacoes: List[str],
        dados: Union[np.ndarray, List[List[float]]],
        descricao: str = ""
    ):
        """
        Args:
            nome_exercicio: Nome do exercício (ex: 'desenvolvimento_ombro', 'agachamento').
            articulacoes: Lista com os nomes das articulações analisadas (ex: ['cotovelo', 'ombro']).
            dados: Matriz (T x D) com as curvas angulares de referência ao longo do tempo.
            descricao: Informações adicionais sobre a gravação do especialista.
        """
        self.nome_exercicio = nome_exercicio
        self.articulacoes = articulacoes
        self.descricao = descricao
        self.dados = np.asarray(dados, dtype=float)

        # Garante shape 2D (T, D)
        if self.dados.ndim == 1:
            self.dados = self.dados[:, np.newaxis]

        if self.dados.shape[1] != len(self.articulacoes):
            raise ValueError(
                f"Quantidade de articulações ({len(self.articulacoes)}) diverge "
                f"do número de colunas nos dados ({self.dados.shape[1]})."
            )

    @property
    def total_frames(self) -> int:
        """Quantidade total de frames contidos na repetição de referência."""
        return self.dados.shape[0]

    @property
    def total_articulacoes(self) -> int:
        """Quantidade de articulações monitoradas simultaneamente."""
        return self.dados.shape[1]

    def salvar_json(self, caminho_arquivo: str) -> None:
        """
        Exporta o gabarito para um arquivo JSON legível e portátil.
        """
        conteudo = {
            "nome_exercicio": self.nome_exercicio,
            "descricao": self.descricao,
            "articulacoes": self.articulacoes,
            "dados": self.dados.tolist()
        }
        with open(caminho_arquivo, "w", encoding="utf-8") as f:
            json.dump(conteudo, f, indent=4, ensure_ascii=False)

    @classmethod
    def carregar_json(cls, caminho_arquivo: str) -> "GabaritoExercicio":
        """
        Carrega um gabarito previamente gravado a partir de um arquivo JSON.
        """
        with open(caminho_arquivo, "r", encoding="utf-8") as f:
            conteudo = json.load(f)

        return cls(
            nome_exercicio=conteudo["nome_exercicio"],
            articulacoes=conteudo["articulacoes"],
            dados=conteudo["dados"],
            descricao=conteudo.get("descricao", "")
        )


if __name__ == "__main__":
    # Exemplo: criando e persistindo a gravação de um especialista
    # para uma repetição padrão de desenvolvimento de ombro:
    articulacoes_ombro = ["cotovelo", "ombro"]

    # Simulação dos ângulos gravados pelo especialista ao longo de 40 frames:
    frames = 40
    t = np.linspace(0, np.pi, frames)
    curva_cotovelo = 90.0 + 75.0 * np.sin(t)   # sai de 90°, atinge 165° no pico, volta a 90°
    curva_ombro = 80.0 + 75.0 * np.sin(t)      # sai de 80°, atinge 155° no pico, volta a 80°
    dados_referencia = np.column_stack((curva_cotovelo, curva_ombro))

    # 1. Instanciação do gabarito
    gabarito = GabaritoExercicio(
        nome_exercicio="desenvolvimento_ombro",
        articulacoes=articulacoes_ombro,
        dados=dados_referencia,
        descricao="Repetição de referência padrão ouro gravada por especialista credenciado."
    )

    # 2. Salva em disco
    arquivo_saida = "gabarito_especialista_ombro.json"
    gabarito.salvar_json(arquivo_saida)
    print(f"Gabarito salvo com sucesso em '{arquivo_saida}'.")

    # 3. Carrega de volta do disco para validação
    gabarito_carregado = GabaritoExercicio.carregar_json(arquivo_saida)
    print(f"\nGabarito Carregado:")
    print(f"  - Exercício: {gabarito_carregado.nome_exercicio}")
    print(f"  - Descrição: {gabarito_carregado.descricao}")
    print(f"  - Articulações: {gabarito_carregado.articulacoes}")
    print(f"  - Total de Frames: {gabarito_carregado.total_frames}")
    print(f"  - Frame Inicial: {gabarito_carregado.dados[0]}")
    print(f"  - Frame no Pico: {gabarito_carregado.dados[frames // 2]}")

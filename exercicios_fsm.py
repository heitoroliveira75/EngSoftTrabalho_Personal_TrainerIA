"""
Módulo de Máquinas de Estados Finitos (FSM) por Exercício.
Todas as classes seguem o mesmo contrato para integração transparente
com o BufferRepeticao, com o avaliador de pontuação e com a interface em tempo real.
"""

from typing import Dict, Any, Optional, List


class ExercicioBaseFSM:
    """Contrato padrão que todas as máquinas de estados devem seguir."""

    NOMES_FASES = {
        0: "Repouso",
        1: "Fase Inicial",
        2: "Pico do Movimento",
        3: "Retorno",
    }
    MENSAGENS_ERRO: Dict[str, str] = {}
    PENALIDADES_ERRO: Dict[str, float] = {}

    def __init__(self):
        self.fases = [0, 0]  # [fase_anterior, fase_atual]
        self.repeticoes = 0
        self.erros: List[str] = []
        self.erros_repeticao_atual: List[str] = []

    @property
    def nome_fase_atual(self) -> str:
        return self.NOMES_FASES.get(self.fases[1], "Em Analise")

    def traduzir_erro(self, codigo_erro: Optional[str]) -> str:
        if not codigo_erro:
            return "Movimento dentro dos parametros."
        return self.MENSAGENS_ERRO.get(codigo_erro, codigo_erro)

    def registrar_erro(self, codigo_erro: str) -> None:
        """Registra erro no histórico global e na repetição atual (sem duplicatas na repetição)."""
        self.erros.append(codigo_erro)
        if codigo_erro not in self.erros_repeticao_atual:
            self.erros_repeticao_atual.append(codigo_erro)

    def consumir_erros_repeticao(self) -> List[str]:
        """Retorna todos os erros ocorridos durante a repetição concluída e limpa o buffer da rep."""
        erros = list(self.erros_repeticao_atual)
        self.erros_repeticao_atual = []
        return erros

    def identificar_fase(self, angulos: dict, posicoes: dict, angulos_deltas: dict) -> int:
        raise NotImplementedError

    def classificar(self, angulos: dict, posicoes: dict, angulos_deltas: dict) -> Optional[str]:
        raise NotImplementedError


class DesenvolvimentoOmbro(ExercicioBaseFSM):
    """
    Avalia o Desenvolvimento de Ombros (Shoulder Press).
    Articulações: ['cotovelo', 'ombro']
    """

    NOMES_FASES = {
        0: "Repouso (Bracos a 90 graus)",
        1: "Subindo (Concentrica)",
        2: "Topo (Contracao Maxima)",
        3: "Descendo (Excentrica)",
    }

    MENSAGENS_ERRO = {
        "REPETICAO_INCOMPLETA": "Subida interrompida antes de estender os bracos no topo.",
        "DESCIDA_EXCESSIVA": "Cotovelo desceu demasiado (< 70 graus) na fase de retorno.",
        "OMBRO_CAIDO": "Mantenha os ombros alinhados acima de 60 graus durante a execucao.",
    }

    PENALIDADES_ERRO = {
        "REPETICAO_INCOMPLETA": 25.0,
        "DESCIDA_EXCESSIVA": 15.0,
        "OMBRO_CAIDO": 15.0,
    }

    def identificar_fase(self, angulos: dict, posicoes: dict, angulos_deltas: dict) -> int:
        cotovelo = angulos.get("cotovelo", 0.0)
        delta_cotovelo = angulos_deltas.get("cotovelo", 0.0)
        fase = self.fases[1]

        if fase == 0:
            if cotovelo > 100.0 and delta_cotovelo > 0:
                fase = 1
                self.erros_repeticao_atual = []
        elif fase == 1:
            if cotovelo >= 150.0:
                fase = 2
            elif delta_cotovelo < 0 and cotovelo < 130.0:
                fase = 3
        elif fase == 2:
            if cotovelo < 140.0 or delta_cotovelo < 0:
                fase = 3
        elif fase == 3:
            if cotovelo <= 100.0:
                fase = 0
                self.repeticoes += 1

        return fase

    def classificar(self, angulos: dict, posicoes: dict, angulos_deltas: dict) -> Optional[str]:
        fase_anterior = self.fases[1]
        fase_atual = self.identificar_fase(angulos, posicoes, angulos_deltas)

        self.fases[0] = fase_anterior
        self.fases[1] = fase_atual

        erros_no_frame = []
        if self.fases[0] == 1 and self.fases[1] == 3:
            erros_no_frame.append("REPETICAO_INCOMPLETA")
        if self.fases[1] == 3 and angulos.get("cotovelo", 100.0) < 70.0:
            erros_no_frame.append("DESCIDA_EXCESSIVA")
        if self.fases[1] in (1, 2, 3) and angulos.get("ombro", 90.0) < 60.0:
            erros_no_frame.append("OMBRO_CAIDO")

        for err in erros_no_frame:
            self.registrar_erro(err)

        return erros_no_frame[0] if erros_no_frame else None


class Agachamento(ExercicioBaseFSM):
    """
    Avalia o Agachamento Livre (Squat).
    Articulações: ['joelho', 'quadril']
    """

    NOMES_FASES = {
        0: "Em Pe (Posicao Inicial)",
        1: "Descendo (Excentrica)",
        2: "Fundo do Agachamento",
        3: "Subindo (Concentrica)",
    }

    MENSAGENS_ERRO = {
        "AGACHAMENTO_CURTO": "Subiu antes de atingir a profundidade adequada do joelho.",
        "TRONCO_MUITO_INCLINADO": "Quadril fechou demasiado (< 55 graus); mantenha o peito aberto.",
    }

    PENALIDADES_ERRO = {
        "AGACHAMENTO_CURTO": 25.0,
        "TRONCO_MUITO_INCLINADO": 15.0,
    }

    def identificar_fase(self, angulos: dict, posicoes: dict, angulos_deltas: dict) -> int:
        joelho = angulos.get("joelho", 180.0)
        delta_joelho = angulos_deltas.get("joelho", 0.0)
        fase = self.fases[1]

        if fase == 0:
            if joelho < 155.0 and delta_joelho < 0:
                fase = 1
                self.erros_repeticao_atual = []
        elif fase == 1:
            if joelho <= 105.0:
                fase = 2
            elif delta_joelho > 0 and joelho > 120.0:
                fase = 3
        elif fase == 2:
            if joelho > 112.0 or delta_joelho > 0:
                fase = 3
        elif fase == 3:
            if joelho >= 160.0:
                fase = 0
                self.repeticoes += 1

        return fase

    def classificar(self, angulos: dict, posicoes: dict, angulos_deltas: dict) -> Optional[str]:
        fase_anterior = self.fases[1]
        fase_atual = self.identificar_fase(angulos, posicoes, angulos_deltas)

        self.fases[0] = fase_anterior
        self.fases[1] = fase_atual

        erros_no_frame = []
        if self.fases[0] == 1 and self.fases[1] == 3:
            erros_no_frame.append("AGACHAMENTO_CURTO")
        if self.fases[1] in (1, 2, 3) and angulos.get("quadril", 180.0) < 55.0:
            erros_no_frame.append("TRONCO_MUITO_INCLINADO")

        for err in erros_no_frame:
            self.registrar_erro(err)

        return erros_no_frame[0] if erros_no_frame else None


class RoscaBiceps(ExercicioBaseFSM):
    """
    Avalia a Rosca Direta de Bíceps (Bicep Curl).
    Articulações: ['cotovelo', 'ombro']
    """

    NOMES_FASES = {
        0: "Braco Estendido (Repouso)",
        1: "Subindo (Flexao do Cotovelo)",
        2: "Topo (Contracao do Biceps)",
        3: "Descendo (Extensao Controlada)",
    }

    MENSAGENS_ERRO = {
        "SUBIDA_INCOMPLETA": "Flexione mais o cotovelo antes de iniciar a descida.",
        "OMBRO_INSTAVEL": "Evite projetar o ombro (> 40 graus); mantenha o cotovelo fixo ao tronco.",
    }

    PENALIDADES_ERRO = {
        "SUBIDA_INCOMPLETA": 25.0,
        "OMBRO_INSTAVEL": 15.0,
    }

    def identificar_fase(self, angulos: dict, posicoes: dict, angulos_deltas: dict) -> int:
        cotovelo = angulos.get("cotovelo", 180.0)
        delta_cotovelo = angulos_deltas.get("cotovelo", 0.0)
        fase = self.fases[1]

        if fase == 0:
            if cotovelo < 145.0 and delta_cotovelo < 0:
                fase = 1
                self.erros_repeticao_atual = []
        elif fase == 1:
            if cotovelo <= 65.0:
                fase = 2
            elif delta_cotovelo > 0 and cotovelo > 95.0:
                fase = 3
        elif fase == 2:
            if cotovelo > 75.0 or delta_cotovelo > 0:
                fase = 3
        elif fase == 3:
            if cotovelo >= 150.0:
                fase = 0
                self.repeticoes += 1

        return fase

    def classificar(self, angulos: dict, posicoes: dict, angulos_deltas: dict) -> Optional[str]:
        fase_anterior = self.fases[1]
        fase_atual = self.identificar_fase(angulos, posicoes, angulos_deltas)

        self.fases[0] = fase_anterior
        self.fases[1] = fase_atual

        erros_no_frame = []
        if self.fases[0] == 1 and self.fases[1] == 3:
            erros_no_frame.append("SUBIDA_INCOMPLETA")
        if self.fases[1] in (1, 2, 3) and angulos.get("ombro", 15.0) > 40.0:
            erros_no_frame.append("OMBRO_INSTAVEL")

        for err in erros_no_frame:
            self.registrar_erro(err)

        return erros_no_frame[0] if erros_no_frame else None


# Catálogo central que liga os IDs do banco aos componentes de cada exercício de IA
# IDs oficiais conforme tabela 'exercicios' (Exercicios.txt):
#   - 16: Desenvolvimento com Halteres
#   - 11: Agachamento Livre
#   - 20: Rosca Direta
CATALOGO_EXERCICIOS: Dict[str, Dict[str, Any]] = {
    "16": {
        "id": "desenvolvimento_ombro",
        "nome": "Desenvolvimento com Halteres",
        "classe_fsm": DesenvolvimentoOmbro,
        "articulacoes": ["cotovelo", "ombro"],
        "arquivo_gabarito": "gabarito_especialista_ombro.json",
        "aliases": ["1", "16", "desenvolvimento_ombro", "ombro", "desenvolvimento", "desenvolvimento com halteres"],
    },
    "11": {
        "id": "agachamento",
        "nome": "Agachamento Livre",
        "classe_fsm": Agachamento,
        "articulacoes": ["joelho", "quadril"],
        "arquivo_gabarito": "gabarito_especialista_agachamento.json",
        "aliases": ["2", "11", "agachamento", "agachamento_livre", "squat", "pernas"],
    },
    "20": {
        "id": "rosca_biceps",
        "nome": "Rosca Direta",
        "classe_fsm": RoscaBiceps,
        "articulacoes": ["cotovelo", "ombro"],
        "arquivo_gabarito": "gabarito_especialista_rosca.json",
        "aliases": ["3", "20", "rosca_biceps", "rosca", "rosca_direta", "biceps", "bíceps"],
    },
}

# Aliases diretos para total retrocompatibilidade ('1', '2', '3')
CATALOGO_EXERCICIOS["1"] = CATALOGO_EXERCICIOS["16"]
CATALOGO_EXERCICIOS["2"] = CATALOGO_EXERCICIOS["11"]
CATALOGO_EXERCICIOS["3"] = CATALOGO_EXERCICIOS["20"]


def obter_config_exercicio(identificador: str) -> Dict[str, Any]:
    """
    Busca a configuração do exercício por chave numérica ('16', '11', '20' ou '1', '2', '3')
    ou por identificador de texto ('desenvolvimento_ombro', 'agachamento', 'rosca_biceps').
    Suporta resolução por aliases e palavras-chave.
    """
    chave = str(identificador).strip().lower()
    if chave in CATALOGO_EXERCICIOS:
        return CATALOGO_EXERCICIOS[chave]

    for item in CATALOGO_EXERCICIOS.values():
        if item["id"].lower() == chave or chave in item.get("aliases", []):
            return item

    # Mapeamento semântico por palavras-chave se vier nome textual
    if any(w in chave for w in ["agacha", "squat", "perna", "inferior", "coxa"]):
        return CATALOGO_EXERCICIOS["11"]
    if any(w in chave for w in ["rosca", "biceps", "bíceps", "braço", "braco"]):
        return CATALOGO_EXERCICIOS["20"]
    if any(w in chave for w in ["ombro", "desenvolvimento", "superior", "deltoide", "peito", "costas"]):
        return CATALOGO_EXERCICIOS["16"]

    # Fallback seguro para evitar HTTP 500 no servidor
    import logging
    logging.warning(f"Exercício '{identificador}' não mapeado na FSM. Adotando fallback seguro para Desenvolvimento com Halteres (16).")
    return CATALOGO_EXERCICIOS["16"]

"""
Módulo de Máquinas de Estados Finitos (FSM) por Exercício.
Todas as classes seguem o mesmo contrato para integração transparente
com o BufferRepeticao e com a interface em tempo real.
"""

from typing import Dict, Any, Optional


class ExercicioBaseFSM:
    """Contrato padrão que todas as máquinas de estados devem seguir."""

    NOMES_FASES = {
        0: "Repouso",
        1: "Fase Inicial",
        2: "Pico do Movimento",
        3: "Retorno",
    }
    MENSAGENS_ERRO: Dict[str, str] = {}

    def __init__(self):
        self.fases = [0, 0]  # [fase_anterior, fase_atual]
        self.repeticoes = 0
        self.erros = []

    @property
    def nome_fase_atual(self) -> str:
        return self.NOMES_FASES.get(self.fases[1], "Em Analise")

    def traduzir_erro(self, codigo_erro: Optional[str]) -> str:
        if not codigo_erro:
            return "Movimento dentro dos parametros."
        return self.MENSAGENS_ERRO.get(codigo_erro, codigo_erro)

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

    def identificar_fase(self, angulos: dict, posicoes: dict, angulos_deltas: dict) -> int:
        cotovelo = angulos.get("cotovelo", 0.0)
        delta_cotovelo = angulos_deltas.get("cotovelo", 0.0)
        fase = self.fases[1]

        if fase == 0:
            if cotovelo > 100.0 and delta_cotovelo > 0:
                fase = 1
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

        erro_detectado = None
        if self.fases[0] == 1 and self.fases[1] == 3:
            erro_detectado = "REPETICAO_INCOMPLETA"
        elif self.fases[1] == 3 and angulos.get("cotovelo", 100.0) < 70.0:
            erro_detectado = "DESCIDA_EXCESSIVA"
        elif self.fases[1] in (1, 2, 3) and angulos.get("ombro", 90.0) < 60.0:
            erro_detectado = "OMBRO_CAIDO"

        if erro_detectado:
            self.erros.append(erro_detectado)

        return erro_detectado


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

    def identificar_fase(self, angulos: dict, posicoes: dict, angulos_deltas: dict) -> int:
        joelho = angulos.get("joelho", 180.0)
        delta_joelho = angulos_deltas.get("joelho", 0.0)
        fase = self.fases[1]

        if fase == 0:
            if joelho < 155.0 and delta_joelho < 0:
                fase = 1
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

        erro_detectado = None
        if self.fases[0] == 1 and self.fases[1] == 3:
            erro_detectado = "AGACHAMENTO_CURTO"
        elif self.fases[1] in (1, 2, 3) and angulos.get("quadril", 180.0) < 55.0:
            erro_detectado = "TRONCO_MUITO_INCLINADO"

        if erro_detectado:
            self.erros.append(erro_detectado)

        return erro_detectado


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

    def identificar_fase(self, angulos: dict, posicoes: dict, angulos_deltas: dict) -> int:
        cotovelo = angulos.get("cotovelo", 180.0)
        delta_cotovelo = angulos_deltas.get("cotovelo", 0.0)
        fase = self.fases[1]

        if fase == 0:
            if cotovelo < 145.0 and delta_cotovelo < 0:
                fase = 1
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

        erro_detectado = None
        if self.fases[0] == 1 and self.fases[1] == 3:
            erro_detectado = "SUBIDA_INCOMPLETA"
        elif self.fases[1] in (1, 2, 3) and angulos.get("ombro", 15.0) > 40.0:
            erro_detectado = "OMBRO_INSTAVEL"

        if erro_detectado:
            self.erros.append(erro_detectado)

        return erro_detectado


# Catálogo central que liga as teclas de atalho aos componentes de cada exercício
CATALOGO_EXERCICIOS: Dict[str, Dict[str, Any]] = {
    "1": {
        "id": "desenvolvimento_ombro",
        "nome": "Desenvolvimento de Ombro",
        "classe_fsm": DesenvolvimentoOmbro,
        "articulacoes": ["cotovelo", "ombro"],
        "arquivo_gabarito": "gabarito_especialista_ombro.json",
    },
    "2": {
        "id": "agachamento",
        "nome": "Agachamento Livre",
        "classe_fsm": Agachamento,
        "articulacoes": ["joelho", "quadril"],
        "arquivo_gabarito": "gabarito_especialista_agachamento.json",
    },
    "3": {
        "id": "rosca_biceps",
        "nome": "Rosca Direta de Biceps",
        "classe_fsm": RoscaBiceps,
        "articulacoes": ["cotovelo", "ombro"],
        "arquivo_gabarito": "gabarito_especialista_rosca.json",
    },
}
"""
Módulo de Máquinas de Estados Finitos (FSM) por Exercício com Histerese e Calibração.
Todas as classes seguem o mesmo contrato para integração transparente
com o BufferRepeticao, com o avaliador de pontuação e com a interface em tempo real.
Aplica histerese direcional nas transições 0 -> 1 e 1 -> 3 para eliminar falsos positivos
e contagens espúrias causadas por ruído estático na postura de repouso.
"""

from typing import Dict, Any, Optional, List


class ExercicioBaseFSM:
    """Contrato padrão que todas as máquinas de estados devem seguir."""

    ISOMETRICO: bool = False

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
            elif delta_cotovelo < 0:
                if cotovelo >= 115.0:
                    fase = 3
                elif cotovelo <= 102.0:
                    fase = 0
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
        if (self.fases[0] == 3 or self.fases[1] == 3) and angulos.get("cotovelo", 90.0) < 70.0:
            erros_no_frame.append("DESCIDA_EXCESSIVA")
        if self.fases[1] in (1, 2) and angulos.get("ombro", 90.0) < 60.0:
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
        "HIPEREXTENSAO_JOELHO": "Evite travar os joelhos para tras ao ficar em pe; preserve a articulacao.",
    }

    PENALIDADES_ERRO = {
        "AGACHAMENTO_CURTO": 25.0,
        "TRONCO_MUITO_INCLINADO": 15.0,
        "HIPEREXTENSAO_JOELHO": 15.0,
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
            elif delta_joelho > 0:
                if joelho <= 135.0:
                    fase = 3
                elif joelho >= 150.0:
                    fase = 0
        elif fase == 2:
            if joelho > 112.0 or delta_joelho > 0:
                fase = 3
        elif fase == 3:
            if joelho >= 158.0:
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
        if self.fases[1] in (0, 3) and (angulos.get("joelho", 170.0) > 178.0 or angulos.get("joelho_orientado", 0.0) < -2.0):
            erros_no_frame.append("HIPEREXTENSAO_JOELHO")

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
        1: "Subindo (Flexao)",
        2: "Topo (Contracao Maxima)",
        3: "Descendo (Extensao)",
    }

    MENSAGENS_ERRO = {
        "SUBIDA_INCOMPLETA": "Flexao interrompida antes da contracao maxima do biceps.",
        "OMBRO_INSTAVEL": "Cotovelo projetou-se demasiado; mantenha o braco fixo ao tronco.",
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
            elif delta_cotovelo > 0:
                if cotovelo <= 120.0:
                    fase = 3
                elif cotovelo >= 140.0:
                    fase = 0
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
        if self.fases[1] in (1, 2, 3) and angulos.get("ombro", 0.0) > 40.0:
            erros_no_frame.append("OMBRO_INSTAVEL")

        for err in erros_no_frame:
            self.registrar_erro(err)

        return erros_no_frame[0] if erros_no_frame else None


class ElevacaoLateral(ExercicioBaseFSM):
    """
    Avalia a Elevação Lateral com Halteres (Lateral Raise).
    Articulações: ['ombro', 'cotovelo']
    """

    NOMES_FASES = {
        0: "Repouso (Bracos ao lado do corpo)",
        1: "Subindo (Abducao)",
        2: "Topo (Linha dos Ombros)",
        3: "Descendo (Aducao)",
    }

    MENSAGENS_ERRO = {
        "ELEVACAO_CURTA": "Subida incompleta: eleve os bracos ate a linha dos ombros (80 graus).",
        "ELEVACAO_EXCESSIVA": "Evite passar muito da linha dos ombros (> 110 graus) para nao sobrecarregar o trapezio.",
        "COTOVELO_MUITO_FLEXIONADO": "Mantenha os cotovelos semi-estendidos (>= 135 graus) durante a elevacao.",
    }

    PENALIDADES_ERRO = {
        "ELEVACAO_CURTA": 25.0,
        "ELEVACAO_EXCESSIVA": 15.0,
        "COTOVELO_MUITO_FLEXIONADO": 15.0,
    }

    def identificar_fase(self, angulos: dict, posicoes: dict, angulos_deltas: dict) -> int:
        ombro = angulos.get("ombro", 0.0)
        delta_ombro = angulos_deltas.get("ombro", 0.0)
        fase = self.fases[1]

        if fase == 0:
            if ombro > 50.0 and delta_ombro > 0:
                fase = 1
                self.erros_repeticao_atual = []
        elif fase == 1:
            if ombro >= 80.0:
                fase = 2
            elif delta_ombro < 0:
                if ombro >= 58.0:
                    fase = 3
                elif ombro <= 48.0:
                    fase = 0
        elif fase == 2:
            if ombro < 100.0 and delta_ombro < 0:
                fase = 3
        elif fase == 3:
            if ombro <= 45.0:
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
            erros_no_frame.append("ELEVACAO_CURTA")
        if self.fases[1] in (1, 2) and angulos.get("ombro", 0.0) > 125.0:
            erros_no_frame.append("ELEVACAO_EXCESSIVA")
        if self.fases[1] in (1, 2, 3) and angulos.get("cotovelo", 160.0) < 120.0:
            erros_no_frame.append("COTOVELO_MUITO_FLEXIONADO")

        for err in erros_no_frame:
            self.registrar_erro(err)

        return erros_no_frame[0] if erros_no_frame else None


class TricepsCorda(ExercicioBaseFSM):
    """
    Avalia o Tríceps na Polia com Corda (Triceps Pushdown).
    Articulações: ['cotovelo', 'ombro']
    """

    NOMES_FASES = {
        0: "Posicao Inicial (Cotovelos Flexionados)",
        1: "Estendendo (Concentrica)",
        2: "Fundo (Extensao Maxima)",
        3: "Retornando (Excentrica)",
    }

    MENSAGENS_ERRO = {
        "EXTENSAO_INCOMPLETA": "Estenda completamente os bracos no fundo (pelo menos 145 graus) antes de subir.",
        "COTOVELO_AVANCADO": "Mantenha os cotovelos fixos ao lado do tronco (ombro < 35 graus), sem projeta-los para frente.",
        "SUBIDA_EXCESSIVA": "Controle o retorno na subida; nao deixe o cabo puxar os bracos excessivamente (< 50 graus).",
        "HIPEREXTENSAO_COTOVELO": "Evite travar ou hiperextender os cotovelos no final da descida.",
    }

    PENALIDADES_ERRO = {
        "EXTENSAO_INCOMPLETA": 25.0,
        "COTOVELO_AVANCADO": 15.0,
        "SUBIDA_EXCESSIVA": 15.0,
        "HIPEREXTENSAO_COTOVELO": 15.0,
    }

    def identificar_fase(self, angulos: dict, posicoes: dict, angulos_deltas: dict) -> int:
        cotovelo = angulos.get("cotovelo", 0.0)
        delta_cotovelo = angulos_deltas.get("cotovelo", 0.0)
        fase = self.fases[1]

        if fase == 0:
            if cotovelo > 95.0 and delta_cotovelo > 0:
                fase = 1
                self.erros_repeticao_atual = []
        elif fase == 1:
            if cotovelo >= 145.0:
                fase = 2
            elif delta_cotovelo < 0:
                if cotovelo >= 120.0:
                    fase = 3
                elif cotovelo <= 98.0:
                    fase = 0
        elif fase == 2:
            if cotovelo < 140.0 or delta_cotovelo < 0:
                fase = 3
        elif fase == 3:
            if cotovelo <= 90.0:
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
            erros_no_frame.append("EXTENSAO_INCOMPLETA")
        if self.fases[1] in (1, 2, 3) and angulos.get("ombro", 0.0) > 35.0:
            erros_no_frame.append("COTOVELO_AVANCADO")
        if (self.fases[0] == 3 or self.fases[1] == 3) and angulos.get("cotovelo", 80.0) < 50.0:
            erros_no_frame.append("SUBIDA_EXCESSIVA")
        if self.fases[1] in (2, 3) and (angulos.get("cotovelo", 80.0) > 175.0 or angulos.get("cotovelo_orientado", 0.0) < -2.0):
            erros_no_frame.append("HIPEREXTENSAO_COTOVELO")

        for err in erros_no_frame:
            self.registrar_erro(err)

        return erros_no_frame[0] if erros_no_frame else None


class FlexaoDiamante(ExercicioBaseFSM):
    """
    Avalia a Flexão Diamante (Diamond Pushup).
    Articulações: ['cotovelo', 'ombro']
    """

    NOMES_FASES = {
        0: "Prancha Alta (Bracos Estendidos)",
        1: "Descendo (Excentrica)",
        2: "Fundo (Peito Proximo as Maos)",
        3: "Subindo (Concentrica)",
    }

    MENSAGENS_ERRO = {
        "FLEXAO_CURTA": "Desca ate aproximar o peito das maos (cotovelo <= 90 graus) antes de subir.",
        "ABERTURA_EXCESSIVA": "Mantenha os cotovelos mais fechados junto ao corpo (ombro < 75 graus) para preservar o estimulo de diamante.",
        "HIPEREXTENSAO_COTOVELO": "Mantenha os cotovelos levemente destravados no topo da prancha.",
    }

    PENALIDADES_ERRO = {
        "FLEXAO_CURTA": 25.0,
        "ABERTURA_EXCESSIVA": 15.0,
        "HIPEREXTENSAO_COTOVELO": 15.0,
    }

    def identificar_fase(self, angulos: dict, posicoes: dict, angulos_deltas: dict) -> int:
        cotovelo = angulos.get("cotovelo", 180.0)
        delta_cotovelo = angulos_deltas.get("cotovelo", 0.0)
        fase = self.fases[1]

        if fase == 0:
            if cotovelo < 130.0 and delta_cotovelo < 0:
                fase = 1
                self.erros_repeticao_atual = []
        elif fase == 1:
            if cotovelo <= 90.0:
                fase = 2
            elif delta_cotovelo > 0:
                if cotovelo <= 115.0:
                    fase = 3
                elif cotovelo >= 135.0:
                    fase = 0
        elif fase == 2:
            if cotovelo > 100.0 or delta_cotovelo > 0:
                fase = 3
        elif fase == 3:
            if cotovelo >= 135.0:
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
            erros_no_frame.append("FLEXAO_CURTA")
        if self.fases[1] in (1, 2, 3) and angulos.get("ombro", 0.0) > 75.0:
            erros_no_frame.append("ABERTURA_EXCESSIVA")
        if self.fases[1] in (0, 3) and (angulos.get("cotovelo", 160.0) > 175.0 or angulos.get("cotovelo_orientado", 0.0) < -2.0):
            erros_no_frame.append("HIPEREXTENSAO_COTOVELO")

        for err in erros_no_frame:
            self.registrar_erro(err)

        return erros_no_frame[0] if erros_no_frame else None


class RemadaBaixa(ExercicioBaseFSM):
    """
    Avalia a Remada Baixa Sentada / Polia (Seated Cable Row).
    Articulações: ['cotovelo', 'ombro', 'quadril']
    """

    NOMES_FASES = {
        0: "Bracos Estendidos (Inicio)",
        1: "Puxando (Concentrica)",
        2: "Contracao Maxima (Escapulas Retraidas)",
        3: "Retornando (Excentrica)",
    }

    MENSAGENS_ERRO = {
        "REMADA_CURTA": "Puxe a barra ate o abdomen (cotovelo <= 85 graus) antes de retornar.",
        "INCLINACAO_EXCESSIVA_TRONCO": "Mantenha o tronco firme (quadril <= 125 graus); evite jogar o corpo para tras.",
        "HIPEREXTENSAO_COTOVELO": "Controle o retorno dos bracos sem travar os cotovelos no final da remada.",
    }

    PENALIDADES_ERRO = {
        "REMADA_CURTA": 25.0,
        "INCLINACAO_EXCESSIVA_TRONCO": 15.0,
        "HIPEREXTENSAO_COTOVELO": 15.0,
    }

    def identificar_fase(self, angulos: dict, posicoes: dict, angulos_deltas: dict) -> int:
        cotovelo = angulos.get("cotovelo", 180.0)
        delta_cotovelo = angulos_deltas.get("cotovelo", 0.0)
        fase = self.fases[1]

        if fase == 0:
            if cotovelo < 140.0 and delta_cotovelo < 0:
                fase = 1
                self.erros_repeticao_atual = []
        elif fase == 1:
            if cotovelo <= 85.0:
                fase = 2
            elif delta_cotovelo > 0:
                if cotovelo >= 141.0:
                    fase = 0
                elif cotovelo >= 130.0:
                    fase = 3
        elif fase == 2:
            if cotovelo > 95.0 or delta_cotovelo > 0:
                fase = 3
        elif fase == 3:
            if cotovelo >= 145.0:
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
            erros_no_frame.append("REMADA_CURTA")
        if self.fases[1] in (1, 2, 3) and angulos.get("quadril", 90.0) > 125.0:
            erros_no_frame.append("INCLINACAO_EXCESSIVA_TRONCO")
        if self.fases[1] in (0, 3) and (angulos.get("cotovelo", 160.0) > 175.0 or angulos.get("cotovelo_orientado", 0.0) < -2.0):
            erros_no_frame.append("HIPEREXTENSAO_COTOVELO")

        for err in erros_no_frame:
            self.registrar_erro(err)

        return erros_no_frame[0] if erros_no_frame else None


class PuxadaAltaHalteres(ExercicioBaseFSM):
    """
    Avalia a Puxada Alta com Halteres / Remada Alta (Dumbbell High Pull).
    Articulações monitoradas: ['ombro', 'cotovelo']
    """

    NOMES_FASES = {
        0: "Repouso (Halteres a frente)",
        1: "Puxada / Subindo",
        2: "Pico de Elevacao",
        3: "Descendo / Retorno",
    }

    MENSAGENS_ERRO = {
        "PUXADA_CURTA": "Subida incompleta: eleve os cotovelos ate a linha dos ombros.",
        "ELEVACAO_EXCESSIVA": "Cotovelos elevados acima do limite seguro (> 120 graus). Risco de impacto subacromial.",
        "COTOVELO_CAIDO": "Mantenha os cotovelos elevados e acima da linha dos punhos na puxada.",
        "HIPEREXTENSAO_COTOVELO": "Evite travar ou hiperextender os cotovelos no final da descida.",
    }

    PENALIDADES_ERRO = {
        "PUXADA_CURTA": 25.0,
        "ELEVACAO_EXCESSIVA": 15.0,
        "COTOVELO_CAIDO": 15.0,
        "HIPEREXTENSAO_COTOVELO": 15.0,
    }

    def identificar_fase(self, angulos: dict, posicoes: dict, angulos_deltas: dict) -> int:
        ombro = angulos.get("ombro", 0.0)
        delta_ombro = angulos_deltas.get("ombro", 0.0)
        fase = self.fases[1]

        if fase == 0:
            if ombro > 35.0 and delta_ombro > 0:
                fase = 1
                self.erros_repeticao_atual = []
        elif fase == 1:
            if ombro >= 85.0:
                fase = 2
            elif delta_ombro < 0:
                if ombro >= 45.0:
                    fase = 3  # Desistência / Repetição curta
                elif ombro <= 28.0:
                    fase = 0  # Histerese suave na saída do repouso
        elif fase == 2:
            if ombro < 80.0 or delta_ombro < 0:
                fase = 3
        elif fase == 3:
            if ombro <= 25.0:
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
            erros_no_frame.append("PUXADA_CURTA")
        if self.fases[1] == 2 and angulos.get("ombro", 0.0) > 120.0:
            erros_no_frame.append("ELEVACAO_EXCESSIVA")
        if self.fases[1] == 2 and angulos.get("cotovelo", 0.0) > 120.0:
            erros_no_frame.append("COTOVELO_CAIDO")
        if self.fases[1] in (0, 3) and (angulos.get("cotovelo", 160.0) > 175.0 or angulos.get("cotovelo_orientado", 0.0) < -2.0):
            erros_no_frame.append("HIPEREXTENSAO_COTOVELO")

        for err in erros_no_frame:
            self.registrar_erro(err)

        return erros_no_frame[0] if erros_no_frame else None


class RoscaMartelo(ExercicioBaseFSM):
    """
    Avalia a Rosca Martelo com Halteres (Hammer Curl) - Visão Lateral/Perfil.
    Foco estrito na articulação do cotovelo: ['cotovelo']
    """

    NOMES_FASES = {
        0: "Repouso (Braco estendido ao lado)",
        1: "Subindo (Flexao Concentrica)",
        2: "Pico de Contracao",
        3: "Descendo (Extensao Excentrica)",
    }

    MENSAGENS_ERRO = {
        "SUBIDA_INCOMPLETA": "Flexao incompleta: suba o halter ate contrair o braco no topo (cotovelo <= 70 graus).",
        "HIPEREXTENSAO_COTOVELO": "Evite travar ou hiperextender o cotovelo no retorno ao repouso.",
    }

    PENALIDADES_ERRO = {
        "SUBIDA_INCOMPLETA": 25.0,
        "HIPEREXTENSAO_COTOVELO": 15.0,
    }

    def identificar_fase(self, angulos: dict, posicoes: dict, angulos_deltas: dict) -> int:
        cotovelo = angulos.get("cotovelo", 160.0)
        delta_cotovelo = angulos_deltas.get("cotovelo", 0.0)
        fase = self.fases[1]

        if fase == 0:
            if cotovelo < 140.0 and delta_cotovelo < 0:
                fase = 1
                self.erros_repeticao_atual = []
        elif fase == 1:
            if cotovelo <= 70.0:
                fase = 2
            elif delta_cotovelo > 0:
                if cotovelo <= 120.0:
                    fase = 3  # Desistência / Repetição incompleta
                elif cotovelo >= 148.0:
                    fase = 0  # Histerese suave
        elif fase == 2:
            if cotovelo > 80.0 or delta_cotovelo > 0:
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
        if self.fases[1] in (0, 3) and (angulos.get("cotovelo", 160.0) > 175.0 or angulos.get("cotovelo_orientado", 0.0) < -2.0):
            erros_no_frame.append("HIPEREXTENSAO_COTOVELO")

        for err in erros_no_frame:
            self.registrar_erro(err)

        return erros_no_frame[0] if erros_no_frame else None


class TricepsFrances(ExercicioBaseFSM):
    """
    Avalia o Tríceps Francês Sentado (Seated Overhead French Press) - Visão Lateral/Perfil.
    Articulações: ['cotovelo', 'ombro']
    """

    NOMES_FASES = {
        0: "Repouso (Bracos estendidos no topo)",
        1: "Descendo (Flexao atras da cabeca)",
        2: "Fundo (Maximo Alongamento)",
        3: "Subindo (Extensao Concentrica)",
    }

    MENSAGENS_ERRO = {
        "EXTENSAO_INCOMPLETA": "Descida ou extensao incompleta: flexione ate 75 graus e estenda no topo.",
        "BRACO_BAIXO": "Mantenha o braco elevado junto a cabeca apontando para o teto (ombro >= 125 graus).",
        "HIPEREXTENSAO_COTOVELO": "Evite travar ou hiperextender os cotovelos no topo da extensao.",
    }

    PENALIDADES_ERRO = {
        "EXTENSAO_INCOMPLETA": 25.0,
        "BRACO_BAIXO": 15.0,
        "HIPEREXTENSAO_COTOVELO": 15.0,
    }

    def identificar_fase(self, angulos: dict, posicoes: dict, angulos_deltas: dict) -> int:
        cotovelo = angulos.get("cotovelo", 155.0)
        delta_cotovelo = angulos_deltas.get("cotovelo", 0.0)
        fase = self.fases[1]

        if fase == 0:
            if cotovelo < 135.0 and delta_cotovelo < 0:
                fase = 1
                self.erros_repeticao_atual = []
        elif fase == 1:
            if cotovelo <= 75.0:
                fase = 2
            elif delta_cotovelo > 0:
                if cotovelo >= 140.0:
                    fase = 0  # Histerese suave perto do topo
                elif cotovelo >= 105.0:
                    fase = 3  # Desistência / Repetição incompleta
        elif fase == 2:
            if cotovelo > 85.0 or delta_cotovelo > 0:
                fase = 3
        elif fase == 3:
            if cotovelo >= 145.0:
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
            erros_no_frame.append("EXTENSAO_INCOMPLETA")
        if self.fases[1] in (1, 2, 3) and angulos.get("ombro", 150.0) < 125.0:
            erros_no_frame.append("BRACO_BAIXO")
        if self.fases[1] in (0, 3) and (angulos.get("cotovelo", 155.0) > 175.0 or angulos.get("cotovelo_orientado", 0.0) < -2.0):
            erros_no_frame.append("HIPEREXTENSAO_COTOVELO")

        for err in erros_no_frame:
            self.registrar_erro(err)

        return erros_no_frame[0] if erros_no_frame else None


class PuxadaAltaCostas(ExercicioBaseFSM):
    """
    Avalia a Puxada Alta na Polia / Lat Pulldown gravada de costas (visão posterior).
    Articulações: ['cotovelo', 'ombro']
    """

    NOMES_FASES = {
        0: "Bracos Estendidos no Alto (Repouso)",
        1: "Puxando (Flexao e Aducao)",
        2: "Pico de Contracao (Barra no Peito/Nuca)",
        3: "Retornando (Extensao Controlada)",
    }

    MENSAGENS_ERRO = {
        "PUXADA_CURTA": "Puxe a barra completamente ate embaixo (cotovelo <= 80 graus) antes de retornar.",
        "OMBRO_ELEVADO": "Deprima as escapulas e abaixe bem os ombros durante a puxada.",
        "HIPEREXTENSAO_COTOVELO": "Evite trancos ao estender os bracos no topo da puxada.",
    }

    PENALIDADES_ERRO = {
        "PUXADA_CURTA": 25.0,
        "OMBRO_ELEVADO": 15.0,
        "HIPEREXTENSAO_COTOVELO": 15.0,
    }

    def identificar_fase(self, angulos: dict, posicoes: dict, angulos_deltas: dict) -> int:
        cotovelo = angulos.get("cotovelo", 160.0)
        delta_cotovelo = angulos_deltas.get("cotovelo", 0.0)
        fase = self.fases[1]

        if fase == 0:
            if cotovelo < 140.0 and delta_cotovelo < 0:
                fase = 1
                self.erros_repeticao_atual = []
        elif fase == 1:
            if cotovelo <= 80.0:
                fase = 2
            elif delta_cotovelo > 0:
                if cotovelo >= 140.0:
                    fase = 0  # Histerese suave perto do topo
                elif cotovelo >= 105.0:
                    fase = 3  # Desistência / Repetição incompleta (PUXADA_CURTA)
        elif fase == 2:
            if cotovelo > 90.0 or delta_cotovelo > 0:
                fase = 3
        elif fase == 3:
            if cotovelo >= 145.0:
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
            erros_no_frame.append("PUXADA_CURTA")
        if self.fases[1] == 2 and angulos.get("ombro", 60.0) > 115.0:
            erros_no_frame.append("OMBRO_ELEVADO")
        if self.fases[1] in (0, 3) and (angulos.get("cotovelo", 160.0) > 175.0 or angulos.get("cotovelo_orientado", 0.0) < -2.0):
            erros_no_frame.append("HIPEREXTENSAO_COTOVELO")

        for err in erros_no_frame:
            self.registrar_erro(err)

        return erros_no_frame[0] if erros_no_frame else None


class PranchaAbdominal(ExercicioBaseFSM):
    """
    Avalia a Prancha Abdominal (Plank) em visão lateral.
    Articulações monitoradas: ['quadril', 'joelho', 'cotovelo']
    """

    ISOMETRICO: bool = True

    NOMES_FASES = {
        0: "Repouso (No solo ou em pe)",
        1: "Entrando na Prancha",
        2: "Sustentacao (Postura Alinhada)",
        3: "Saindo da Prancha",
    }

    MENSAGENS_ERRO = {
        "QUADRIL_CAIDO": "Cuidado com a lombar! Suba o quadril para manter o corpo alinhado.",
        "QUADRIL_ELEVADO": "Abaixe um pouco o quadril para ativar o abdomen.",
        "JOELHO_FLEXIONADO": "Mantenha as pernas estendidas e os joelhos firmes.",
    }

    PENALIDADES_ERRO = {
        "QUADRIL_CAIDO": 25.0,
        "QUADRIL_ELEVADO": 15.0,
        "JOELHO_FLEXIONADO": 15.0,
    }

    def identificar_fase(self, angulos: dict, posicoes: dict, angulos_deltas: dict) -> int:
        quadril = angulos.get("quadril", 90.0)
        joelho = angulos.get("joelho", 90.0)
        fase = self.fases[1]

        # Postura de prancha: corpo em linha reta (quadril e joelhos estendidos >= 155 graus)
        alinhado = (quadril >= 155.0) and (joelho >= 155.0)

        if fase == 0:
            if alinhado:
                fase = 1
                self.erros_repeticao_atual = []
        elif fase == 1:
            if alinhado:
                fase = 2
            else:
                fase = 0
        elif fase == 2:
            if not alinhado:
                fase = 3
        elif fase == 3:
            if not alinhado:
                fase = 0
                self.repeticoes += 1

        return fase

    def classificar(self, angulos: dict, posicoes: dict, angulos_deltas: dict) -> Optional[str]:
        fase_anterior = self.fases[1]
        fase_atual = self.identificar_fase(angulos, posicoes, angulos_deltas)

        self.fases[0] = fase_anterior
        self.fases[1] = fase_atual

        erros_no_frame = []
        quadril = angulos.get("quadril", 180.0)
        joelho = angulos.get("joelho", 180.0)

        if self.fases[1] == 2:
            if quadril < 155.0:
                erros_no_frame.append("QUADRIL_CAIDO")
            elif quadril > 195.0:
                erros_no_frame.append("QUADRIL_ELEVADO")

            if joelho < 155.0:
                erros_no_frame.append("JOELHO_FLEXIONADO")

        for err in erros_no_frame:
            self.registrar_erro(err)

        return erros_no_frame[0] if erros_no_frame else None


# Catálogo central que liga as teclas de atalho ou IDs aos componentes de cada exercício
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
    "4": {
        "id": "elevacao_lateral",
        "nome": "Elevacao Lateral",
        "classe_fsm": ElevacaoLateral,
        "articulacoes": ["ombro", "cotovelo"],
        "arquivo_gabarito": "gabarito_especialista_elevacao_lateral.json",
    },
    "5": {
        "id": "triceps_corda",
        "nome": "Triceps Corda",
        "classe_fsm": TricepsCorda,
        "articulacoes": ["cotovelo", "ombro"],
        "arquivo_gabarito": "gabarito_especialista_triceps_corda.json",
    },
    "6": {
        "id": "flexao_diamante",
        "nome": "Flexao Diamante",
        "classe_fsm": FlexaoDiamante,
        "articulacoes": ["cotovelo", "ombro"],
        "arquivo_gabarito": "gabarito_especialista_flexao_diamante.json",
    },
    "7": {
        "id": "remada_baixa",
        "nome": "Remada Baixa",
        "classe_fsm": RemadaBaixa,
        "articulacoes": ["cotovelo", "ombro", "quadril"],
        "arquivo_gabarito": "gabarito_especialista_remada_baixa.json",
    },
    "8": {
        "id": "puxada_alta_halteres",
        "nome": "Puxada Alta com Halteres",
        "classe_fsm": PuxadaAltaHalteres,
        "articulacoes": ["ombro", "cotovelo"],
        "arquivo_gabarito": "gabarito_especialista_puxada_alta.json",
    },
    "9": {
        "id": "rosca_martelo",
        "nome": "Rosca Martelo (Perfil)",
        "classe_fsm": RoscaMartelo,
        "articulacoes": ["cotovelo"],
        "arquivo_gabarito": "gabarito_especialista_rosca_martelo.json",
        "enquadramento": "lateral",
    },
    "0": {
        "id": "triceps_frances",
        "nome": "Triceps Frances Sentado (Perfil)",
        "classe_fsm": TricepsFrances,
        "articulacoes": ["cotovelo", "ombro"],
        "arquivo_gabarito": "gabarito_especialista_triceps_frances.json",
        "enquadramento": "lateral",
    },
    "c": {
        "id": "puxada_alta_costas",
        "nome": "Puxada Alta (Costas)",
        "classe_fsm": PuxadaAltaCostas,
        "articulacoes": ["cotovelo", "ombro"],
        "arquivo_gabarito": "gabarito_especialista_puxada_costas.json",
        "enquadramento": "costas",
    },
    "p": {
        "id": "prancha_abdominal",
        "nome": "Prancha Abdominal",
        "classe_fsm": PranchaAbdominal,
        "articulacoes": ["quadril", "joelho", "cotovelo"],
        "arquivo_gabarito": "gabarito_especialista_prancha_abdominal.json",
        "enquadramento": "lateral",
    },
}


def obter_config_exercicio(identificador: str) -> Dict[str, Any]:
    """
    Busca a configuração do exercício por chave do catálogo ('1'..'9', '0', 'c', 'p'),
    por IDs do catálogo do app mobile ('1', '2', '3', '8', '9', '10', '16', '17', '18', '20', '22', '24', '26', '29')
    ou por identificador de texto ('desenvolvimento_ombro', 'agachamento', 'prancha_abdominal', etc.).
    """
    chave = str(identificador).strip().lower()
    if chave in CATALOGO_EXERCICIOS:
        return CATALOGO_EXERCICIOS[chave]

    # Mapeamento unificado de aliases e IDs do catálogo do aplicativo Flutter
    aliases = {
        "16": "1",  # Desenvolvimento com Halteres (legado app)
        "ombro": "1",
        "desenvolvimento_ombro": "1",
        "11": "2",  # Agachamento Livre (legado app)
        "squat": "2",
        "agachamento": "2",
        "20": "3",  # Rosca Direta de Bíceps (legado app)
        "biceps": "3",
        "bíceps": "3",
        "rosca": "3",
        "rosca_biceps": "3",
        "17": "4",  # Elevação Lateral (legado app)
        "18": "4",  # Elevação Lateral (seed SQL)
        "elevacao": "4",
        "elevação": "4",
        "elevacao_lateral": "4",
        "23": "5",  # Tríceps Corda (legado app)
        "24": "5",  # Tríceps Corda (seed SQL)
        "triceps": "5",
        "tríceps": "5",
        "triceps_corda": "5",
        "flexao": "6",
        "flexão": "6",
        "flexao_diamante": "6",
        "flexao_braco": "6",
        "remada": "7",
        "remada_baixa": "7",
        "puxada_alta_halteres": "8",
        "puxada_alta": "8",
        "remada_alta": "8",
        "dumbbell_high_pulls": "8",
        "puxada": "8",
        "22": "9",  # Rosca Martelo (seed SQL)
        "rosca_martelo": "9",
        "martelo": "9",
        "hammer_curl": "9",
        "10": "0",
        "26": "0",  # Tríceps Testa / Francês (seed SQL)
        "triceps_frances": "0",
        "triceps_testa": "0",
        "frances": "0",
        "french_press": "0",
        "puxada_alta_costas": "c",
        "puxada_costas": "c",
        "puxada_frontal": "c",
        "costas": "c",
        "lat_pulldown": "c",
        "puxada_polia": "c",
        "12": "p",
        "29": "p",  # Prancha Abdominal (seed SQL)
        "prancha": "p",
        "prancha_abdominal": "p",
        "plank": "p",
    }
    if chave in aliases:
        return CATALOGO_EXERCICIOS[aliases[chave]]

    for item in CATALOGO_EXERCICIOS.values():
        if item["id"].lower() == chave:
            return item

    opcoes = list(CATALOGO_EXERCICIOS.keys()) + list(aliases.keys()) + [item["id"] for item in CATALOGO_EXERCICIOS.values()]
    raise ValueError(f"Exercício '{identificador}' não encontrado. Opções disponíveis: {opcoes}")

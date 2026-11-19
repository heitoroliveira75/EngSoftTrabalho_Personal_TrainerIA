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

    NOMES_FASES = {
        0: "Repouso",
        1: "Fase Inicial",
        2: "Pico do Movimento",
        3: "Retorno",
    }
    MENSAGENS_ERRO: Dict[str, str] = {}
    PENALIDADES_ERRO: Dict[str, float] = {}
    FRAMES_PERSISTENCIA_ERRO: int = 3
    LIMIAR_ASSIMETRIA_PADRAO: float = 20.0

    def __init__(self, frames_persistencia_erro: Optional[int] = None):
        self.fases = [0, 0]  # [fase_anterior, fase_atual]
        self.repeticoes = 0
        self.erros: List[str] = []
        self.erros_repeticao_atual: List[str] = []
        self.contadores_persistencia: Dict[str, int] = {}
        self.frames_persistencia_erro = (
            self.FRAMES_PERSISTENCIA_ERRO
            if frames_persistencia_erro is None
            else max(1, int(frames_persistencia_erro))
        )

    @property
    def nome_fase_atual(self) -> str:
        return self.NOMES_FASES.get(self.fases[1], "Em Analise")

    def traduzir_erro(self, codigo_erro: Optional[str]) -> str:
        if not codigo_erro:
            return "Movimento dentro dos parametros."
        if codigo_erro in self.MENSAGENS_ERRO:
            return self.MENSAGENS_ERRO[codigo_erro]
        if codigo_erro.startswith("ASSIMETRIA_"):
            art = codigo_erro.replace("ASSIMETRIA_", "").lower()
            return (
                f"Assimetria bilateral ({art}): mantenha os dois lados "
                "subindo e descendo de forma simetrica."
            )
        return codigo_erro

    def registrar_erro(self, codigo_erro: str) -> None:
        """Registra erro no histórico global e na repetição atual (sem duplicatas na repetição)."""
        self.erros.append(codigo_erro)
        if codigo_erro not in self.erros_repeticao_atual:
            self.erros_repeticao_atual.append(codigo_erro)

    def avaliar_erros_posturais_com_debounce(
        self,
        candidatos_no_frame: List[str],
        codigos_monitorados: Optional[List[str]] = None,
    ) -> List[str]:
        """
        Aplica filtro de persistência mínima (debounce) para erros posturais contínuos.
        Um erro postural só é confirmado após permanecer ativo por `frames_persistencia_erro`
        frames consecutivos, ignorando espasmos ou ruídos pontuais do detector de pose.
        """
        ativos_set = set(candidatos_no_frame)
        # Limpa apenas os contadores dos códigos que pertencem a este escopo de chamada,
        # evitando que chamadas independentes (ex.: FSM e simetria bilateral) zerem os contadores uma da outra.
        escopo = (set(codigos_monitorados) if codigos_monitorados is not None else set(self.contadores_persistencia.keys())) | ativos_set

        confirmados: List[str] = []
        for codigo in escopo:
            if codigo in ativos_set:
                self.contadores_persistencia[codigo] = self.contadores_persistencia.get(codigo, 0) + 1
                if self.contadores_persistencia[codigo] >= self.frames_persistencia_erro:
                    confirmados.append(codigo)
            else:
                self.contadores_persistencia[codigo] = 0

        # Preserva a ordem determinística de entrada dos candidatos no frame
        return [c for c in candidatos_no_frame if c in confirmados]

    def resetar_persistencia_erros(self) -> None:
        """Limpa os contadores de persistência ao fechar ou reiniciar o ciclo."""
        self.contadores_persistencia.clear()

    def verificar_simetria(
        self,
        angulos_dir: Optional[Dict[str, float]],
        angulos_esq: Optional[Dict[str, float]],
        articulacoes: List[str],
        limiar_assimetria: Optional[float] = None,
    ) -> Optional[str]:
        """
        Verifica a simetria bilateral comparando as articulações direita e esquerda
        durante as fases ativas do exercício (1, 2 e 3).
        """
        if not angulos_dir or not angulos_esq:
            return None
        if self.fases[1] not in (1, 2, 3):
            return None

        limiar = self.LIMIAR_ASSIMETRIA_PADRAO if limiar_assimetria is None else float(limiar_assimetria)
        for art in articulacoes:
            if art in angulos_dir and art in angulos_esq:
                if abs(float(angulos_dir[art]) - float(angulos_esq[art])) > limiar:
                    return f"ASSIMETRIA_{art.upper()}"
        return None

    def consumir_erros_repeticao(self) -> List[str]:
        """Retorna todos os erros ocorridos durante a repetição concluída e limpa o buffer da rep."""
        erros = list(self.erros_repeticao_atual)
        self.erros_repeticao_atual = []
        self.resetar_persistencia_erros()
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

        candidatos_posturais = []
        if self.fases[1] == 3 and angulos.get("cotovelo", 100.0) < 70.0:
            candidatos_posturais.append("DESCIDA_EXCESSIVA")
        if self.fases[1] in (1, 2, 3) and angulos.get("ombro", 90.0) < 60.0:
            candidatos_posturais.append("OMBRO_CAIDO")

        erros_no_frame.extend(
            self.avaliar_erros_posturais_com_debounce(
                candidatos_posturais,
                ["DESCIDA_EXCESSIVA", "OMBRO_CAIDO"],
            )
        )

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

        candidatos_posturais = []
        if self.fases[1] in (1, 2, 3) and angulos.get("quadril", 180.0) < 55.0:
            candidatos_posturais.append("TRONCO_MUITO_INCLINADO")
        if self.fases[1] in (0, 3) and (angulos.get("joelho", 170.0) > 178.0 or angulos.get("joelho_orientado", 0.0) < -2.0):
            candidatos_posturais.append("HIPEREXTENSAO_JOELHO")

        erros_no_frame.extend(
            self.avaliar_erros_posturais_com_debounce(
                candidatos_posturais,
                ["TRONCO_MUITO_INCLINADO", "HIPEREXTENSAO_JOELHO"],
            )
        )

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

        candidatos_posturais = []
        if self.fases[1] in (1, 2, 3) and angulos.get("ombro", 15.0) > 40.0:
            candidatos_posturais.append("OMBRO_INSTAVEL")

        erros_no_frame.extend(
            self.avaliar_erros_posturais_com_debounce(
                candidatos_posturais,
                ["OMBRO_INSTAVEL"],
            )
        )

        for err in erros_no_frame:
            self.registrar_erro(err)

        return erros_no_frame[0] if erros_no_frame else None


class ElevacaoLateral(ExercicioBaseFSM):
    """
    Avalia a Elevação Lateral de Ombros (Lateral Raise).
    Articulações: ['ombro', 'cotovelo']
    """

    NOMES_FASES = {
        0: "Bracos Abaixados (Repouso)",
        1: "Subindo (Abducao Lateral)",
        2: "Pico (Linha dos Ombros)",
        3: "Descendo (Retorno Controlado)",
    }

    MENSAGENS_ERRO = {
        "ELEVACAO_CURTA": "Eleve os bracos ate a linha dos ombros (pelo menos 80 graus) antes de descer.",
        "ELEVACAO_EXCESSIVA": "Evite elevar os bracos acima de 105 graus para proteger a articulacao dos ombros.",
        "COTOVELO_MUITO_FLEXIONADO": "Mantenha os cotovelos firmes (acima de 110 graus), sem dobrar excessivamente os bracos.",
    }

    PENALIDADES_ERRO = {
        "ELEVACAO_CURTA": 25.0,
        "ELEVACAO_EXCESSIVA": 15.0,
        "COTOVELO_MUITO_FLEXIONADO": 15.0,
    }

    def identificar_fase(self, angulos: dict, posicoes: dict, angulos_deltas: dict) -> int:
        ombro = angulos.get("ombro", 20.0)
        delta_ombro = angulos_deltas.get("ombro", 0.0)
        fase = self.fases[1]

        if fase == 0:
            if ombro > 45.0 and delta_ombro > 0:
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
            if ombro <= 50.0:
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

        candidatos_posturais = []
        if self.fases[1] == 2 and angulos.get("ombro", 20.0) > 115.0:
            candidatos_posturais.append("ELEVACAO_EXCESSIVA")
        if self.fases[1] in (1, 2, 3) and angulos.get("cotovelo", 160.0) < 110.0:
            candidatos_posturais.append("COTOVELO_MUITO_FLEXIONADO")

        erros_no_frame.extend(
            self.avaliar_erros_posturais_com_debounce(
                candidatos_posturais,
                ["ELEVACAO_EXCESSIVA", "COTOVELO_MUITO_FLEXIONADO"],
            )
        )

        for err in erros_no_frame:
            self.registrar_erro(err)

        return erros_no_frame[0] if erros_no_frame else None


class TricepsCorda(ExercicioBaseFSM):
    """
    Avalia o Tríceps Corda na Polia (Cable Triceps Pushdown).
    Articulações: ['cotovelo', 'ombro']
    """

    NOMES_FASES = {
        0: "Topo (Cotovelos Flexionados)",
        1: "Descendo (Extensao dos Bracos)",
        2: "Pico (Extensao Maxima no Fundo)",
        3: "Subindo (Retorno Controlado)",
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
        cotovelo = angulos.get("cotovelo", 80.0)
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
            if cotovelo <= 85.0:
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

        candidatos_posturais = []
        if self.fases[1] in (1, 2, 3) and angulos.get("ombro", 0.0) > 35.0:
            candidatos_posturais.append("COTOVELO_AVANCADO")
        if (self.fases[0] == 3 or self.fases[1] == 3) and angulos.get("cotovelo", 80.0) < 50.0:
            candidatos_posturais.append("SUBIDA_EXCESSIVA")
        if self.fases[1] in (2, 3) and (angulos.get("cotovelo", 80.0) > 175.0 or angulos.get("cotovelo_orientado", 0.0) < -2.0):
            candidatos_posturais.append("HIPEREXTENSAO_COTOVELO")

        erros_no_frame.extend(
            self.avaliar_erros_posturais_com_debounce(
                candidatos_posturais,
                ["COTOVELO_AVANCADO", "SUBIDA_EXCESSIVA", "HIPEREXTENSAO_COTOVELO"],
            )
        )

        for err in erros_no_frame:
            self.registrar_erro(err)

        return erros_no_frame[0] if erros_no_frame else None


class FlexaoDiamante(ExercicioBaseFSM):
    """
    Avalia a Flexão Diamante (Diamond Push-up) em visão frontal.
    Articulações: ['cotovelo', 'ombro']
    """

    NOMES_FASES = {
        0: "Prancha Alta (Bracos Estendidos)",
        1: "Descendo (Flexao dos Cotovelos)",
        2: "Fundo (Peito Proximo as Maos)",
        3: "Subindo (Extensao dos Bracos)",
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
        cotovelo = angulos.get("cotovelo", 160.0)
        delta_cotovelo = angulos_deltas.get("cotovelo", 0.0)
        fase = self.fases[1]

        if fase == 0:
            if cotovelo < 140.0 and delta_cotovelo < 0:
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
            erros_no_frame.append("FLEXAO_CURTA")

        candidatos_posturais = []
        if self.fases[1] in (1, 2, 3) and angulos.get("ombro", 0.0) > 75.0:
            candidatos_posturais.append("ABERTURA_EXCESSIVA")
        if self.fases[1] in (0, 3) and (angulos.get("cotovelo", 160.0) > 175.0 or angulos.get("cotovelo_orientado", 0.0) < -2.0):
            candidatos_posturais.append("HIPEREXTENSAO_COTOVELO")

        erros_no_frame.extend(
            self.avaliar_erros_posturais_com_debounce(
                candidatos_posturais,
                ["ABERTURA_EXCESSIVA", "HIPEREXTENSAO_COTOVELO"],
            )
        )

        for err in erros_no_frame:
            self.registrar_erro(err)

        return erros_no_frame[0] if erros_no_frame else None


class RemadaBaixa(ExercicioBaseFSM):
    """
    Avalia a Remada Baixa / Remada na Polia (Seated Cable Row) em visão lateral/diagonal.
    Articulações: ['cotovelo', 'ombro', 'quadril']
    """

    NOMES_FASES = {
        0: "Bracos Estendidos (Repouso)",
        1: "Puxando (Flexao dos Cotovelos)",
        2: "Pico de Contracao (Barra no Abdomen)",
        3: "Retornando (Extensao Controlada)",
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
        cotovelo = angulos.get("cotovelo", 160.0)
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

        candidatos_posturais = []
        if self.fases[1] in (1, 2, 3) and angulos.get("quadril", 90.0) > 125.0:
            candidatos_posturais.append("INCLINACAO_EXCESSIVA_TRONCO")
        if self.fases[1] in (0, 3) and (angulos.get("cotovelo", 160.0) > 175.0 or angulos.get("cotovelo_orientado", 0.0) < -2.0):
            candidatos_posturais.append("HIPEREXTENSAO_COTOVELO")

        erros_no_frame.extend(
            self.avaliar_erros_posturais_com_debounce(
                candidatos_posturais,
                ["INCLINACAO_EXCESSIVA_TRONCO", "HIPEREXTENSAO_COTOVELO"],
            )
        )

        for err in erros_no_frame:
            self.registrar_erro(err)

        return erros_no_frame[0] if erros_no_frame else None


class PuxadaAltaHalteres(ExercicioBaseFSM):
    """
    Avalia a Puxada Alta com Halteres / Remada Alta (Dumbbell High Pull).
    Articulações monitoradas: ['ombro', 'cotovelo']
    - Articulação motora primária: ombro (abdução/elevação vertical).
    - Articulação sinergista: cotovelo (flexão acompanhando a tração vertical).
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

        candidatos_posturais = []
        if self.fases[1] == 2 and angulos.get("ombro", 0.0) > 120.0:
            candidatos_posturais.append("ELEVACAO_EXCESSIVA")
        if self.fases[1] == 2 and angulos.get("cotovelo", 0.0) > 120.0:
            candidatos_posturais.append("COTOVELO_CAIDO")
        if self.fases[1] in (0, 3) and (angulos.get("cotovelo", 160.0) > 175.0 or angulos.get("cotovelo_orientado", 0.0) < -2.0):
            candidatos_posturais.append("HIPEREXTENSAO_COTOVELO")

        erros_no_frame.extend(
            self.avaliar_erros_posturais_com_debounce(
                candidatos_posturais,
                ["ELEVACAO_EXCESSIVA", "COTOVELO_CAIDO", "HIPEREXTENSAO_COTOVELO"],
            )
        )

        for err in erros_no_frame:
            self.registrar_erro(err)

        return erros_no_frame[0] if erros_no_frame else None


class RoscaMartelo(ExercicioBaseFSM):
    """
    Avalia a Rosca Martelo com Halteres (Hammer Curl) - Visão Lateral/Perfil.
    Foco estrito na articulação do cotovelo: ['cotovelo']
    - Pegada neutra com palmas voltadas uma para a outra.
    - Gravação recomendada: de perfil/lado para rastreamento nítido da flexão do braquiorradial.
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
            # Sai do repouso se cotovelo começar a flexionar (< 140°) com delta negativo
            if cotovelo < 140.0 and delta_cotovelo < 0:
                fase = 1
                self.erros_repeticao_atual = []
        elif fase == 1:
            # Pico de contração da rosca martelo: cotovelo bem flexionado (<= 70°)
            if cotovelo <= 70.0:
                fase = 2
            elif delta_cotovelo > 0:
                # Se começou a estender/descer antes do pico
                if cotovelo <= 120.0:
                    fase = 3  # Desistência / Repetição incompleta
                elif cotovelo >= 148.0:
                    fase = 0  # Histerese suave (pequena oscilação perto do repouso)
        elif fase == 2:
            # Começou a descer
            if cotovelo > 80.0 or delta_cotovelo > 0:
                fase = 3
        elif fase == 3:
            # Retorno completo ao repouso
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
    - Articulação motora primária: cotovelo (extensão e flexão vertical).
    - Articulação de postura/estabilidade: ombro (manter o braço apontado para cima).
    - Gravação recomendada: de perfil/lado para visualização completa da extensão vertical.
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
            # Sai do repouso se cotovelo começar a descer/flexionar (< 135°) com delta negativo
            if cotovelo < 135.0 and delta_cotovelo < 0:
                fase = 1
                self.erros_repeticao_atual = []
        elif fase == 1:
            # Fundo do movimento (alongamento atrás da nuca <= 75°)
            if cotovelo <= 75.0:
                fase = 2
            elif delta_cotovelo > 0:
                # Começou a estender antes de atingir o fundo
                if cotovelo >= 140.0:
                    fase = 0  # Histerese suave perto do topo
                elif cotovelo >= 105.0:
                    fase = 3  # Desistência / Repetição incompleta
        elif fase == 2:
            # Começou a subir/estender
            if cotovelo > 85.0 or delta_cotovelo > 0:
                fase = 3
        elif fase == 3:
            # Retorno completo à extensão no topo
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


# Catálogo central que liga as teclas de atalho ou IDs aos componentes de cada exercício
CATALOGO_EXERCICIOS: Dict[str, Dict[str, Any]] = {
    "1": {
        "id": "desenvolvimento_ombro",
        "nome": "Desenvolvimento de Ombro",
        "classe_fsm": DesenvolvimentoOmbro,
        "articulacoes": ["cotovelo", "ombro"],
        "arquivo_gabarito": "gabarito_especialista_ombro.json",
        "bilateral": True,
    },
    "2": {
        "id": "agachamento",
        "nome": "Agachamento Livre",
        "classe_fsm": Agachamento,
        "articulacoes": ["joelho", "quadril"],
        "arquivo_gabarito": "gabarito_especialista_agachamento.json",
        "bilateral": True,
    },
    "3": {
        "id": "rosca_biceps",
        "nome": "Rosca Direta de Biceps",
        "classe_fsm": RoscaBiceps,
        "articulacoes": ["cotovelo", "ombro"],
        "arquivo_gabarito": "gabarito_especialista_rosca.json",
        "bilateral": False,
    },
    "4": {
        "id": "elevacao_lateral",
        "nome": "Elevacao Lateral",
        "classe_fsm": ElevacaoLateral,
        "articulacoes": ["ombro", "cotovelo"],
        "arquivo_gabarito": "gabarito_especialista_elevacao_lateral.json",
        "bilateral": True,
    },
    "5": {
        "id": "triceps_corda",
        "nome": "Triceps Corda",
        "classe_fsm": TricepsCorda,
        "articulacoes": ["cotovelo", "ombro"],
        "arquivo_gabarito": "gabarito_especialista_triceps_corda.json",
        "bilateral": True,
    },
    "6": {
        "id": "flexao_diamante",
        "nome": "Flexao Diamante",
        "classe_fsm": FlexaoDiamante,
        "articulacoes": ["cotovelo", "ombro"],
        "arquivo_gabarito": "gabarito_especialista_flexao_diamante.json",
        "bilateral": True,
    },
    "7": {
        "id": "remada_baixa",
        "nome": "Remada Baixa",
        "classe_fsm": RemadaBaixa,
        "articulacoes": ["cotovelo", "ombro", "quadril"],
        "arquivo_gabarito": "gabarito_especialista_remada_baixa.json",
        "bilateral": False,
    },
    "8": {
        "id": "puxada_alta_halteres",
        "nome": "Puxada Alta com Halteres",
        "classe_fsm": PuxadaAltaHalteres,
        "articulacoes": ["ombro", "cotovelo"],
        "arquivo_gabarito": "gabarito_especialista_puxada_alta.json",
        "bilateral": True,
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
}


def obter_config_exercicio(identificador: str) -> Dict[str, Any]:
    """
    Busca a configuração do exercício por chave numérica ('1', '2', '3')
    ou por identificador de texto ('desenvolvimento_ombro', 'agachamento', 'rosca_biceps').
    """
    chave = str(identificador).strip().lower()
    if chave in CATALOGO_EXERCICIOS:
        return CATALOGO_EXERCICIOS[chave]

    if chave == "flexao":
        return CATALOGO_EXERCICIOS["6"]

    if chave in ("remada", "remada_baixa"):
        return CATALOGO_EXERCICIOS["7"]

    if chave in ("puxada_alta_halteres", "puxada_alta", "remada_alta", "dumbbell_high_pulls", "puxada"):
        return CATALOGO_EXERCICIOS["8"]

    if chave in ("rosca_martelo", "martelo", "hammer_curl", "9"):
        return CATALOGO_EXERCICIOS["9"]

    if chave in ("triceps_frances", "frances", "french_press", "0", "10"):
        return CATALOGO_EXERCICIOS["0"]

    for item in CATALOGO_EXERCICIOS.values():
        if item["id"].lower() == chave:
            return item

    opcoes = list(CATALOGO_EXERCICIOS.keys()) + [item["id"] for item in CATALOGO_EXERCICIOS.values()]
    raise ValueError(f"Exercício '{identificador}' não encontrado. Opções disponíveis: {opcoes}")

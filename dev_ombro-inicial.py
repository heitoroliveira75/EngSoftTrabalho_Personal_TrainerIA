class DesenvolvimentoOmbro:
    """
    angulos: dict
        dicionario de angulos articulares (ex: {"ombro": float, "cotovelo": float})
    posicoes: dict
        dicionario com coordenadas dos landmarks
    angulos_deltas: dict
        dicionario com variacao de angulos entre frames (positivo = subindo/expandindo, negativo = descendo)


    a ideia eh que o fluxo siga processamento de imagem -> extracao de features -> classificacao -> retorno de feedback ao usuario
    aqui o foco eh so a classificacao
    """

    def __init__(self):
        #fases do movimento:
        # 0: repouso inicial
        # 1: fase concentrica
        # 2: pico de contracao
        # 3: fase excentrica
        self.fases = [0, 0]  # [fase_anterior, fase_atual]
        self.repeticoes = 0
        self.erros = []

    def identificar_fase(self, angulos: dict, posicoes: dict, angulos_deltas: dict):
        """
        maquina de estados para identificar a etapa do exercicio.
        """
        cotovelo = angulos.get("cotovelo", 0)
        ombro = angulos.get("ombro", 0)
        delta_cotovelo = angulos_deltas.get("cotovelo", 0)

        #partida eh a fase atual salva no historico
        fase = self.fases[1]

        #fase de repouso
        if fase == 0:
            #inicio do movimento
            if cotovelo > 100 and delta_cotovelo > 0:
                fase = 1

        #fase concentrica
        elif fase == 1:
            #subida normal
            if cotovelo >= 150:
                fase = 2
            #transicao anomala
            elif delta_cotovelo < 0 and cotovelo < 130:
                fase = 3

        #pico de contracao
        elif fase == 2:
            #comeca a descer
            if cotovelo < 140 or delta_cotovelo < 0:
                fase = 3

        #fase excentrica
        elif fase == 3:
            #fim do ciclo
            if cotovelo <= 100:
                fase = 0
                self.repeticoes += 1

        return fase

    def classificar(self, angulos: dict, posicoes: dict, angulos_deltas: dict):
        """
        atualiza e estado e classifica entre erro de transicao e erro de biomecanica dentro de cada fase
        """
        fase_anterior = self.fases[1]
        fase_atual = self.identificar_fase(angulos, posicoes, angulos_deltas)

        #atualiza historico
        self.fases[0] = fase_anterior
        self.fases[1] = fase_atual

        erro_detectado = None

        #erro por transicao impropria de fase
        if self.fases[0] == 1 and self.fases[1] == 3:
            erro_detectado = "REPETICAO_INCOMPLETA"

        #erro biomecanico postural
        elif self.fases[1] == 3 and angulos.get("cotovelo", 100) < 70:
            erro_detectado = "DESCIDA_EXCESSIVA"

        if erro_detectado:
            self.erros.append(erro_detectado)

        return erro_detectado

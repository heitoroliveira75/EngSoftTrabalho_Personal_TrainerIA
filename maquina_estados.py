import argparse
import json
import os


# Angulos recebidos no JSON de medidas e analisados independentemente.
ANGULOS_ANALISADOS = (
    "Ombro esquerdo",
    "Ombro direito",
    "Cotovelo esquerdo",
    "Cotovelo direito",
)
LIMIAR_MOVIMENTO = 2.0
MARGEM_EXTREMO = 0.5
ANGULO_MINIMO_PADRAO = 45.0
ANGULO_MAXIMO_PADRAO = 120.0


def valor_ou_none(medidas, nome):
    # Busca o angulo solicitado; retorna None se ele nao estiver disponivel.
    return medidas.get("angulos", {}).get(nome)


def classificar_estado_angular(anterior, atual, posterior, angulo_minimo, angulo_maximo):
    # Sem uma medida atual nao e possivel determinar o estado do braco.
    if atual is None:
        return "SEM_DETECCAO"

    # Define faixas proximas aos limites para reconhecer braco baixo ou alto.
    margem = (angulo_maximo - angulo_minimo) * MARGEM_EXTREMO
    limiar_baixo = angulo_minimo + margem
    limiar_alto = angulo_maximo - margem

    # Nas bordas do video, classifica apenas pela posicao, sem dados vizinhos.
    if anterior is None or posterior is None:
        if atual <= limiar_baixo:
            return "ANGULO_MINIMO"
        if atual >= limiar_alto:
            return "ANGULO_MAXIMO"
        return "EM_ANALISE"

    # Compara a medida atual com os frames vizinhos para detectar a direcao.
    variacao_antes = atual - anterior
    variacao_depois = posterior - atual

    # Se quase nao houve variacao, o braco esta parado ou em um extremo.
    if abs(variacao_antes) < LIMIAR_MOVIMENTO and abs(variacao_depois) < LIMIAR_MOVIMENTO:
        if atual <= limiar_baixo:
            return "ANGULO_MINIMO"
        if atual >= limiar_alto:
            return "ANGULO_MAXIMO"
        return "PARADO"

    # Classifica o sentido do movimento e os pontos de inversao da direcao.
    if variacao_antes > LIMIAR_MOVIMENTO and variacao_depois >= 0:
        return "ANGULO_AUMENTANDO"

    if variacao_antes < -LIMIAR_MOVIMENTO and variacao_depois <= 0:
        return "ANGULO_DIMINUINDO"

    if variacao_antes > 0 and variacao_depois < 0:
        return "PICO_DO_MOVIMENTO"

    if variacao_antes < 0 and variacao_depois > 0:
        return "VALE_DO_MOVIMENTO"

    return "TRANSICAO"


def calcular_limites_angulares(resultados, nome_angulo):
    # Reune medidas validas e medidas observadas durante subida e descida.
    angulos_validos = []
    angulos_subindo = []
    angulos_descendo = []

    for indice, registro in enumerate(resultados):
        atual = valor_ou_none(registro, nome_angulo)
        if atual is None:
            continue

        angulos_validos.append(atual)
        if indice == 0:
            continue

        anterior = valor_ou_none(resultados[indice - 1], nome_angulo)
        if anterior is None:
            continue

        variacao = atual - anterior
        if variacao > LIMIAR_MOVIMENTO:
            angulos_subindo.append(atual)
        elif variacao < -LIMIAR_MOVIMENTO:
            angulos_descendo.append(atual)

    # Se nao houver dados, usa os limites padrao configurados no inicio.
    if not angulos_validos:
        return ANGULO_MINIMO_PADRAO, ANGULO_MAXIMO_PADRAO

    # Estima cada extremo priorizando medidas coletadas no sentido correspondente.
    angulo_minimo = min(angulos_descendo) if angulos_descendo else min(angulos_validos)
    angulo_maximo = max(angulos_subindo) if angulos_subindo else max(angulos_validos)

    # Se a estimativa for invalida, tenta os extremos gerais das medidas.
    if angulo_minimo >= angulo_maximo:
        angulo_minimo = min(angulos_validos)
        angulo_maximo = max(angulos_validos)

    # Se ainda nao houver intervalo valido, retorna os limites padrao.
    if angulo_minimo >= angulo_maximo:
        return ANGULO_MINIMO_PADRAO, ANGULO_MAXIMO_PADRAO

    return angulo_minimo, angulo_maximo


def analisar_resultados(resultados):
    # Classifica cada frame usando seus vizinhos e os limites estimados.
    analise = []
    limites_por_articulacao = {
        nome: calcular_limites_angulares(resultados, nome)
        for nome in ANGULOS_ANALISADOS
    }

    for indice, registro in enumerate(resultados):
        # Obtem os registros anterior e posterior, quando existem.
        registro_anterior = resultados[indice - 1] if indice > 0 else None
        registro_posterior = (
            resultados[indice + 1]
            if indice < len(resultados) - 1
            else None
        )

        # Extrai medidas e classifica cada angulo sem privilegiar uma articulacao.
        articulacoes = {}
        for nome in ANGULOS_ANALISADOS:
            anterior_articulacao = (
                valor_ou_none(registro_anterior, nome)
                if registro_anterior
                else None
            )
            atual_articulacao = valor_ou_none(registro, nome)
            posterior_articulacao = (
                valor_ou_none(registro_posterior, nome)
                if registro_posterior
                else None
            )
            articulacoes[nome] = {
                "anterior": anterior_articulacao,
                "atual": atual_articulacao,
                "posterior": posterior_articulacao,
                "estado": classificar_estado_angular(
                    anterior_articulacao,
                    atual_articulacao,
                    posterior_articulacao,
                    *limites_por_articulacao[nome],
                ),
            }

        # Exporta um estado por articulacao para comparacao por outros programas.
        analise.append({
            "frame": registro["frame"],
            "tempo": registro["tempo"],
            "estado": {
                nome: dados["estado"]
                for nome, dados in articulacoes.items()
            },
            "articulacoes": articulacoes,
            "distancias": registro.get("distancias", {}),
        })

    return analise


def executar(caminho_entrada, caminho_saida):
    # Carrega os resultados da deteccao de pose gerados em formato JSON.
    with open(caminho_entrada, "r", encoding="utf-8") as arquivo:
        resultados = json.load(arquivo)

    # Analisa os frames e estima os limites usados para classificar os estados.
    analise = analisar_resultados(resultados)
    limites_por_articulacao = {
        nome: calcular_limites_angulares(resultados, nome)
        for nome in ANGULOS_ANALISADOS
    }

    # Salva a classificacao em um novo arquivo JSON.
    with open(caminho_saida, "w", encoding="utf-8") as arquivo:
        json.dump(analise, arquivo, ensure_ascii=False, indent=2)

    # Exibe os limites calculados separadamente para cada angulo.
    for nome, (angulo_minimo, angulo_maximo) in limites_por_articulacao.items():
        print(
            f"Limites estimados para {nome}: "
            f"minimo = {angulo_minimo:.1f} graus; "
            f"maximo = {angulo_maximo:.1f} graus"
        )
    print(f"{len(analise)} estados salvos em: {caminho_saida}")


if __name__ == "__main__":
    # Configura os argumentos de linha de comando e inicia a analise.
    argumentos = argparse.ArgumentParser(
        description="Classifica os estados usando frames anterior, atual e posterior."
    )
    # Recebe o JSON de entrada e permite escolher o caminho do arquivo de saida.
    argumentos.add_argument("entrada", help="JSON produzido pelo processar_video.py")
    argumentos.add_argument("--saida", default="estados_video.json")
    opcoes = argumentos.parse_args()
    executar(opcoes.entrada, opcoes.saida)

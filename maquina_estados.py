import argparse
import json
import os


ANGULO_ALVO = "Ombro esquerdo"
LIMIAR_MOVIMENTO = 2.0
LIMIAR_BAIXO = 45.0
LIMIAR_ALTO = 120.0


def valor_ou_none(medidas, nome):
    return medidas.get("angulos", {}).get(nome)


def classificar_estado(anterior, atual, posterior):
    if atual is None:
        return "SEM_DETECCAO"

    if anterior is None or posterior is None:
        if atual < LIMIAR_BAIXO:
            return "BRACO_BAIXO"
        if atual > LIMIAR_ALTO:
            return "BRACO_ALTO"
        return "EM_ANALISE"

    variacao_antes = atual - anterior
    variacao_depois = posterior - atual

    if abs(variacao_antes) < LIMIAR_MOVIMENTO and abs(variacao_depois) < LIMIAR_MOVIMENTO:
        if atual < LIMIAR_BAIXO:
            return "BRACO_BAIXO"
        if atual > LIMIAR_ALTO:
            return "BRACO_ALTO"
        return "PARADO"

    if variacao_antes > LIMIAR_MOVIMENTO and variacao_depois >= 0:
        return "BRACO_SUBINDO"

    if variacao_antes < -LIMIAR_MOVIMENTO and variacao_depois <= 0:
        return "BRACO_DESCENDO"

    if variacao_antes > 0 and variacao_depois < 0:
        return "PICO_DO_MOVIMENTO"

    if variacao_antes < 0 and variacao_depois > 0:
        return "VALE_DO_MOVIMENTO"

    return "TRANSICAO"


def analisar_resultados(resultados):
    analise = []

    for indice, registro in enumerate(resultados):
        registro_anterior = resultados[indice - 1] if indice > 0 else None
        registro_posterior = (
            resultados[indice + 1]
            if indice < len(resultados) - 1
            else None
        )

        valor_anterior = (
            valor_ou_none(registro_anterior, ANGULO_ALVO)
            if registro_anterior
            else None
        )
        valor_atual = valor_ou_none(registro, ANGULO_ALVO)
        valor_posterior = (
            valor_ou_none(registro_posterior, ANGULO_ALVO)
            if registro_posterior
            else None
        )

        analise.append({
            "frame": registro["frame"],
            "tempo": registro["tempo"],
            "anterior": valor_anterior,
            "atual": valor_atual,
            "posterior": valor_posterior,
            "estado": classificar_estado(
                valor_anterior,
                valor_atual,
                valor_posterior,
            ),
            "distancias": registro.get("distancias", {}),
        })

    return analise


def executar(caminho_entrada, caminho_saida):
    with open(caminho_entrada, "r", encoding="utf-8") as arquivo:
        resultados = json.load(arquivo)

    analise = analisar_resultados(resultados)
    with open(caminho_saida, "w", encoding="utf-8") as arquivo:
        json.dump(analise, arquivo, ensure_ascii=False, indent=2)

    print(f"{len(analise)} estados salvos em: {caminho_saida}")


if __name__ == "__main__":
    argumentos = argparse.ArgumentParser(
        description="Classifica os estados usando frames anterior, atual e posterior."
    )
    argumentos.add_argument("entrada", help="JSON produzido pelo processar_video.py")
    argumentos.add_argument("--saida", default="estados_video.json")
    opcoes = argumentos.parse_args()
    executar(opcoes.entrada, opcoes.saida)

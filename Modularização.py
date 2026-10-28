import argparse
import json
import math
import os

import cv2
import mediapipe as mp
import pandas as pd
from mediapipe.tasks import python
from mediapipe.tasks.python import vision

import maquina_estados


DIR_ATUAL = os.path.dirname(os.path.abspath(__file__))
CAMINHO_MODELO_POSE = os.path.join(DIR_ATUAL, "pose_landmarker_full.task")
EXTENSOES_VIDEO = (".mp4", ".avi")


def calcular_angulo_3d(p1, p2, p3):
    vetor_1 = (p1.x - p2.x, p1.y - p2.y, p1.z - p2.z)
    vetor_2 = (p3.x - p2.x, p3.y - p2.y, p3.z - p2.z)

    produto_escalar = (
        vetor_1[0] * vetor_2[0]
        + vetor_1[1] * vetor_2[1]
        + vetor_1[2] * vetor_2[2]
    )
    tamanho_1 = math.sqrt(sum(componente**2 for componente in vetor_1))
    tamanho_2 = math.sqrt(sum(componente**2 for componente in vetor_2))

    if tamanho_1 == 0 or tamanho_2 == 0:
        return None

    cosseno = produto_escalar / (tamanho_1 * tamanho_2)
    cosseno = max(-1.0, min(1.0, cosseno))
    return math.degrees(math.acos(cosseno))


def extrair_angulos(pose_landmarks):
    ombro_esquerdo = pose_landmarks[11]
    cotovelo_esquerdo = pose_landmarks[13]
    pulso_esquerdo = pose_landmarks[15]
    quadril_esquerdo = pose_landmarks[23]
    ombro_direito = pose_landmarks[12]
    cotovelo_direito = pose_landmarks[14]
    pulso_direito = pose_landmarks[16]
    quadril_direito = pose_landmarks[24]

    return {
        "Ombro esquerdo": calcular_angulo_3d(
            quadril_esquerdo, ombro_esquerdo, cotovelo_esquerdo
        ),
        "Ombro direito": calcular_angulo_3d(
            quadril_direito, ombro_direito, cotovelo_direito
        ),
        "Cotovelo esquerdo": calcular_angulo_3d(
            ombro_esquerdo, cotovelo_esquerdo, pulso_esquerdo
        ),
        "Cotovelo direito": calcular_angulo_3d(
            ombro_direito, cotovelo_direito, pulso_direito
        ),
    }


def processar_video(caminho_video, detector):
    cap = cv2.VideoCapture(caminho_video)
    if not cap.isOpened():
        cap.release()
        raise OSError(f"Não foi possível abrir o vídeo: {caminho_video}")

    fps = cap.get(cv2.CAP_PROP_FPS)
    resultados = []
    contador_frame = 0
    cotovelo_min = 999.0
    cotovelo_max = 0.0
    ombro_min = 999.0
    ombro_max = 0.0

    try:
        while cap.isOpened():
            sucesso, frame = cap.read()
            if not sucesso:
                break

            contador_frame += 1
            if contador_frame % 10 != 0:
                continue

            rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            mp_image = mp.Image(
                image_format=mp.ImageFormat.SRGB,
                data=rgb_frame,
            )
            detection_result = detector.detect(mp_image)
            angulos = (
                extrair_angulos(detection_result.pose_landmarks[0])
                if detection_result.pose_landmarks
                else {
                    "Ombro esquerdo": None,
                    "Ombro direito": None,
                    "Cotovelo esquerdo": None,
                    "Cotovelo direito": None,
                }
            )

            cotovelo_direito = angulos["Cotovelo direito"]
            ombro_direito = angulos["Ombro direito"]
            if cotovelo_direito is not None:
                cotovelo_min = min(cotovelo_min, cotovelo_direito)
                cotovelo_max = max(cotovelo_max, cotovelo_direito)
            if ombro_direito is not None:
                ombro_min = min(ombro_min, ombro_direito)
                ombro_max = max(ombro_max, ombro_direito)

            tempo = (
                contador_frame / fps
                if fps > 0
                else cap.get(cv2.CAP_PROP_POS_MSEC) / 1000
            )
            resultados.append({
                "frame": contador_frame,
                "tempo": tempo,
                "angulos": angulos,
                "distancias": {},
            })
    finally:
        cap.release()

    resumo = None
    if cotovelo_min != 999.0:
        resumo = {
            "cotovelo_min": cotovelo_min,
            "cotovelo_max": cotovelo_max,
            "ombro_variacao": ombro_max - ombro_min,
        }

    return resultados, resumo


def localizar_videos(caminho_entrada):
    if os.path.isfile(caminho_entrada):
        candidatos = [caminho_entrada]
    elif os.path.isdir(caminho_entrada):
        candidatos = [
            os.path.join(raiz, nome)
            for raiz, _, arquivos in os.walk(caminho_entrada)
            for nome in arquivos
        ]
    else:
        raise FileNotFoundError(f"Caminho de entrada não encontrado: {caminho_entrada}")

    return sorted(
        caminho
        for caminho in candidatos
        if os.path.splitext(caminho)[1].lower() in EXTENSOES_VIDEO
    )


def salvar_estados(caminho_video, resultados):
    analise = maquina_estados.analisar_resultados(resultados)
    caminho_saida = os.path.splitext(caminho_video)[0] + "_estados.json"
    with open(caminho_saida, "w", encoding="utf-8") as arquivo:
        json.dump(analise, arquivo, ensure_ascii=False, indent=2)
    return caminho_saida, analise


def main():
    argumentos = argparse.ArgumentParser(
        description="Extrai ângulos dos vídeos e classifica os estados do movimento."
    )
    argumentos.add_argument(
        "entrada",
        nargs="?",
        default=r"D:\Testes",
        help="Vídeo individual ou pasta com vídeos (padrão: D:\\Testes)",
    )
    opcoes = argumentos.parse_args()

    modelo_ia = None
    try:
        import joblib
    except ModuleNotFoundError as erro:
        if erro.name != "joblib":
            raise
        print(
            "AVISO: joblib não está instalado; os estados serão processados "
            "sem veredito da IA."
        )
    else:
        caminho_modelo_ia = os.path.join(DIR_ATUAL, "meu_personal_trainer_ia.pkl")
        try:
            modelo_ia = joblib.load(caminho_modelo_ia)
        except FileNotFoundError:
            print(
                "AVISO: modelo 'meu_personal_trainer_ia.pkl' não encontrado; "
                "os estados serão processados sem veredito da IA."
            )

    videos = localizar_videos(opcoes.entrada)
    if not videos:
        print(f"Nenhum vídeo .mp4 ou .avi encontrado em: {opcoes.entrada}")
        return 0

    base_options = python.BaseOptions(model_asset_path=CAMINHO_MODELO_POSE)
    options = vision.PoseLandmarkerOptions(
        base_options=base_options,
        output_segmentation_masks=False,
    )
    detector = vision.PoseLandmarker.create_from_options(options)
    dados_avaliados = []

    try:
        for caminho_video in videos:
            nome_arquivo = os.path.basename(caminho_video)
            print(f"\nAnalisando vídeo: {nome_arquivo}...")
            resultados, resumo = processar_video(caminho_video, detector)
            caminho_estados, analise_estados = salvar_estados(
                caminho_video, resultados
            )
            print(
                f"{len(analise_estados)} estados processados e salvos em: "
                f"{caminho_estados}"
            )

            if resumo is None:
                print(f"AVISO: nenhum corpo detectado no vídeo {nome_arquivo}.")
                continue

            if modelo_ia is None:
                continue

            caracteristicas_movimento = [[
                resumo["cotovelo_min"],
                resumo["cotovelo_max"],
                resumo["ombro_variacao"],
            ]]
            resultado_final = modelo_ia.predict(caracteristicas_movimento)[0]
            status_texto = "CORRETO" if resultado_final == 1 else "INCORRETO"
            print(f"VEREDITO: Execução {status_texto}.")

            dados_avaliados.append({
                "Video": nome_arquivo,
                "Cotovelo_Min": round(resumo["cotovelo_min"], 1),
                "Cotovelo_Max": round(resumo["cotovelo_max"], 1),
                "Ombro_Variacao": round(resumo["ombro_variacao"], 1),
                "Veredito_IA": status_texto,
            })
    finally:
        detector.close()

    if dados_avaliados:
        relatorio = pd.DataFrame(dados_avaliados)
        caminho_relatorio = os.path.join(DIR_ATUAL, "relatorio_avaliacoes_ia.csv")
        relatorio.to_csv(caminho_relatorio, index=False)
        print(f"\nRelatório salvo em: {caminho_relatorio}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())

import argparse
import json
import math
import os

import cv2
import mediapipe as mp
from mediapipe.tasks import python
from mediapipe.tasks.python import vision


ANGULOS_CORPO = [
    (12, 11, 13, "Ombro esquerdo"),
    (11, 12, 14, "Ombro direito"),
    (11, 13, 15, "Cotovelo esquerdo"),
    (12, 14, 16, "Cotovelo direito"),
    (11, 13, 15, "Cotovelo esquerdo"),
    (12, 14, 16, "Cotovelo direito"),
    (23, 25, 27, "Joelho esquerdo"),
    (24, 26, 28, "Joelho direito"),
]

CONEXOES_CORPO = [
    (11, 12), (11, 23), (12, 24), (23, 24),
    (11, 13), (13, 15), (12, 14), (14, 16),
    (23, 25), (25, 27), (27, 29), (29, 31), (27, 31),
    (24, 26), (26, 28), (28, 30), (30, 32), (28, 32),
]


def calcular_angulo(p1, p2, p3):
    vetor_1 = (p1.x - p2.x, p1.y - p2.y)
    vetor_2 = (p3.x - p2.x, p3.y - p2.y)
    produto_escalar = vetor_1[0] * vetor_2[0] + vetor_1[1] * vetor_2[1]
    tamanho_1 = math.hypot(*vetor_1)
    tamanho_2 = math.hypot(*vetor_2)

    if tamanho_1 == 0 or tamanho_2 == 0:
        return None

    cosseno = produto_escalar / (tamanho_1 * tamanho_2)
    cosseno = max(-1.0, min(1.0, cosseno))
    return math.degrees(math.acos(cosseno))


def calcular_distancia(p1, p2, largura, altura):
    distancia_x = (p1.x - p2.x) * largura
    distancia_y = (p1.y - p2.y) * altura
    return math.hypot(distancia_x, distancia_y)


def analisar_landmarks(landmarks, largura, altura):
    angulos = {}
    distancias = {}

    for ponto_1, vertice, ponto_3, nome in ANGULOS_CORPO:
        pontos = (ponto_1, vertice, ponto_3)
        if all(landmarks[index].visibility > 0.5 for index in pontos):
            angulos[nome] = calcular_angulo(
                landmarks[ponto_1], landmarks[vertice], landmarks[ponto_3]
            )

    for ponto_1, ponto_2 in CONEXOES_CORPO:
        if landmarks[ponto_1].visibility > 0.5 and landmarks[ponto_2].visibility > 0.5:
            nome = f"{ponto_1}-{ponto_2}"
            distancias[nome] = calcular_distancia(
                landmarks[ponto_1], landmarks[ponto_2], largura, altura
            )

    return {"angulos": angulos, "distancias": distancias}


def processar_video(caminho_video, caminho_modelo, caminho_saida):
    detector = vision.PoseLandmarker.create_from_options(
        vision.PoseLandmarkerOptions(
            base_options=python.BaseOptions(model_asset_path=caminho_modelo),
            output_segmentation_masks=False,
        )
    )
    captura = cv2.VideoCapture(caminho_video)
    fps = captura.get(cv2.CAP_PROP_FPS) or 0
    resultados = []
    indice_frame = 0

    while True:
        sucesso, frame = captura.read()
        if not sucesso:
            break

        altura, largura, _ = frame.shape
        imagem_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        imagem_mp = mp.Image(image_format=mp.ImageFormat.SRGB, data=imagem_rgb)
        deteccao = detector.detect(imagem_mp)
        medidas = {"angulos": {}, "distancias": {}}

        if deteccao.pose_landmarks:
            medidas = analisar_landmarks(
                deteccao.pose_landmarks[0], largura, altura
            )

        resultados.append({
            "frame": indice_frame,
            "tempo": indice_frame / fps if fps > 0 else None,
            **medidas,
        })
        indice_frame += 1

    captura.release()
    with open(caminho_saida, "w", encoding="utf-8") as arquivo:
        json.dump(resultados, arquivo, ensure_ascii=False, indent=2)

    print(f"{len(resultados)} frames salvos em: {caminho_saida}")


if __name__ == "__main__":
    pasta_atual = os.path.dirname(os.path.abspath(__file__))
    argumentos = argparse.ArgumentParser(description="Extrai medidas de um video.")
    argumentos.add_argument("video", help="Caminho do video de entrada")
    argumentos.add_argument(
        "--modelo",
        default=os.path.join(pasta_atual, "pose_landmarker_full.task"),
    )
    argumentos.add_argument("--saida", default="medidas_video.json")
    opcoes = argumentos.parse_args()
    processar_video(opcoes.video, opcoes.modelo, opcoes.saida)

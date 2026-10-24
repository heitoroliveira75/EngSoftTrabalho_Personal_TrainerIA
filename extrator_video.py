"""
Módulo de Extração de Ângulos e Geração de Gabaritos a partir de Vídeo.
Permite processar vídeos gravados de especialistas para qualquer exercício do catálogo.
"""

import argparse
import os
import urllib.request
from typing import List, Dict, Any
import cv2
import mediapipe as mp
from mediapipe.tasks import python
from mediapipe.tasks.python import vision

from calculo_angulos import extrair_angulos_exercicio
from buffer_repeticao import BufferRepeticao, extrair_primeira_repeticao
from gabarito import GabaritoExercicio
from exercicios_fsm import CATALOGO_EXERCICIOS, obter_config_exercicio

MODELO_URL_PADRAO = (
    "https://storage.googleapis.com/mediapipe-models/pose_landmarker/"
    "pose_landmarker_lite/float16/latest/pose_landmarker_lite.task"
)
MODELO_ARQUIVO_PADRAO = "pose_landmarker_lite.task"


def garantir_modelo_pose(caminho_modelo: str = MODELO_ARQUIVO_PADRAO) -> str:
    """Garante que o ficheiro .task do MediaPipe existe localmente."""
    if not os.path.exists(caminho_modelo):
        print(f"A transferir modelo oficial do MediaPipe Tasks ({caminho_modelo})...")
        urllib.request.urlretrieve(MODELO_URL_PADRAO, caminho_modelo)
        print("Transferência concluída com sucesso!")
    return caminho_modelo


class ExtratorVideo:
    def __init__(
        self,
        articulacoes: List[str],
        lado: str = "direito",
        caminho_modelo: str = MODELO_ARQUIVO_PADRAO
    ):
        self.articulacoes = articulacoes
        self.lado = lado
        self.caminho_modelo = garantir_modelo_pose(caminho_modelo)

        base_options = python.BaseOptions(model_asset_path=self.caminho_modelo)
        options = vision.PoseLandmarkerOptions(
            base_options=base_options,
            running_mode=vision.RunningMode.IMAGE,
            num_poses=1,
            min_pose_detection_confidence=0.5,
            min_tracking_confidence=0.5,
        )
        self.detector = vision.PoseLandmarker.create_from_options(options)

    def extrair_serie_temporal(self, caminho_video: str) -> List[Dict[str, Any]]:
        cap = cv2.VideoCapture(caminho_video)
        if not cap.isOpened():
            raise FileNotFoundError(f"Não foi possível abrir o vídeo: {caminho_video}")

        frames_processados: List[Dict[str, Any]] = []
        frame_idx = 0

        while cap.isOpened():
            sucesso, frame = cap.read()
            if not sucesso:
                break

            frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=frame_rgb)
            resultado = self.detector.detect(mp_image)

            if resultado.pose_landmarks and len(resultado.pose_landmarks) > 0:
                landmarks = resultado.pose_landmarks[0]
                angulos, visivel = extrair_angulos_exercicio(
                    landmarks=landmarks,
                    articulacoes=self.articulacoes,
                    lado=self.lado,
                )

                frames_processados.append({
                    "frame": frame_idx,
                    "angulos": angulos,
                    "visivel": visivel,
                })

            frame_idx += 1

        cap.release()
        return frames_processados


def gerar_gabarito_de_video_especialista(
    identificador_exercicio: str,
    caminho_video: str,
    lado: str = "direito"
) -> str:
    """Extrai a primeira repetição completa de um vídeo de especialista e salva o JSON."""
    config = obter_config_exercicio(identificador_exercicio)
    extrator = ExtratorVideo(articulacoes=config["articulacoes"], lado=lado)
    frames = extrator.extrair_serie_temporal(caminho_video)

    serie_angulos = [f["angulos"] for f in frames if f["visivel"]]
    dados_rep = extrair_primeira_repeticao(
        fsm_ou_id=identificador_exercicio,
        articulacoes=config["articulacoes"],
        serie_angulos=serie_angulos,
        lancar_excecao=True,
    )

    gabarito = GabaritoExercicio(
        nome_exercicio=config["id"],
        articulacoes=config["articulacoes"],
        dados=dados_rep,
        descricao=f"Extraído do vídeo '{caminho_video}'",
    )
    gabarito.salvar_json(config["arquivo_gabarito"])
    print(f"Gabarito salvo em '{config['arquivo_gabarito']}' ({gabarito.total_frames} frames).")
    return config["arquivo_gabarito"]


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Extrai gabarito JSON de um vídeo de especialista.")
    parser.add_argument("video", help="Caminho do ficheiro de vídeo do especialista")
    parser.add_argument("--exercicio", default="1", help="ID ou tecla do exercício (ex: 1, desenvolvimento_ombro, agachamento, rosca_biceps)")
    parser.add_argument("--lado", default="direito", choices=["direito", "esquerdo"])
    args = parser.parse_args()
    gerar_gabarito_de_video_especialista(args.exercicio, args.video, args.lado)

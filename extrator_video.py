"""
Módulo de Extração de Ângulos a partir de Vídeo (MediaPipe Tasks API)

Compatível com as versões mais recentes do MediaPipe (que descontinuaram o 'mp.solutions').
Utiliza o detector moderno PoseLandmarker da biblioteca mediapipe.tasks.
"""

import os
import urllib.request
from typing import List, Dict, Any, Optional
import cv2
import mediapipe as mp
from mediapipe.tasks import python
from mediapipe.tasks.python import vision

from calculo_angulos import extrair_angulos_ombro_e_cotovelo


# URL oficial do modelo leve (.task) hospedado pelo Google
MODELO_URL_PADRAO = (
    "https://storage.googleapis.com/mediapipe-models/pose_landmarker/"
    "pose_landmarker_lite/float16/latest/pose_landmarker_lite.task"
)
MODELO_ARQUIVO_PADRAO = "pose_landmarker_lite.task"


def garantir_modelo_pose(caminho_modelo: str = MODELO_ARQUIVO_PADRAO) -> str:
    """
    Verifica se o arquivo de pesos do modelo do MediaPipe existe localmente.
    Se não existir, faz o download automático (~9 MB) do repositório oficial do Google.
    """
    if not os.path.exists(caminho_modelo):
        print(f"Baixando modelo oficial do MediaPipe Tasks ({caminho_modelo})...")
        urllib.request.urlretrieve(MODELO_URL_PADRAO, caminho_modelo)
        print("Download do modelo concluído com sucesso!")
    return caminho_modelo


class ExtratorVideo:
    """
    Processa arquivos de vídeo frame a frame e extrai os ângulos articulares
    utilizando a moderna API de Tarefas do MediaPipe (PoseLandmarker).
    """

    def __init__(self, lado: str = "direito", caminho_modelo: str = MODELO_ARQUIVO_PADRAO):
        """
        Args:
            lado: 'direito' ou 'esquerdo' (define qual braço monitorar).
            caminho_modelo: Caminho para o arquivo do modelo (.task).
        """
        self.lado = lado
        self.caminho_modelo = garantir_modelo_pose(caminho_modelo)

        # Configuração do detector PoseLandmarker da nova API
        base_options = python.BaseOptions(model_asset_path=self.caminho_modelo)
        options = vision.PoseLandmarkerOptions(
            base_options=base_options,
            running_mode=vision.RunningMode.IMAGE,
            num_poses=1,
            min_pose_detection_confidence=0.5,
            min_tracking_confidence=0.5
        )
        self.detector = vision.PoseLandmarker.create_from_options(options)

    def extrair_serie_temporal(self, caminho_video: str) -> List[Dict[str, Any]]:
        """
        Lê um arquivo de vídeo do início ao fim e extrai os ângulos de cada frame.

        Args:
            caminho_video: Caminho do arquivo de vídeo (.mp4, .avi, etc.).

        Returns:
            Lista de dicionários, onde cada item contém:
            - 'frame': número do frame
            - 'angulos': dict com {'cotovelo': float, 'ombro': float}
            - 'deltas': dict com a variação em relação ao frame anterior
        """
        cap = cv2.VideoCapture(caminho_video)

        if not cap.isOpened():
            raise FileNotFoundError(f"Não foi possível abrir o arquivo de vídeo: {caminho_video}")

        frames_processados: List[Dict[str, Any]] = []

        cotovelo_anterior = None
        ombro_anterior = None
        frame_idx = 0

        while cap.isOpened():
            sucesso, frame = cap.read()
            if not sucesso:
                break  # Fim do vídeo

            # O OpenCV lê em BGR; o MediaPipe necessita de RGB
            frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

            # Converte para a estrutura de imagem exigida pelo MediaPipe Tasks
            mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=frame_rgb)

            # Executa a inferência de pose no frame atual
            resultado = self.detector.detect(mp_image)

            # Se encontrou pelo menos uma pessoa no frame
            if resultado.pose_landmarks and len(resultado.pose_landmarks) > 0:
                landmarks = resultado.pose_landmarks[0]

                # 1. Calcula os ângulos das articulações no frame atual
                angulos = extrair_angulos_ombro_e_cotovelo(
                    landmarks=landmarks,
                    lado=self.lado
                )

                # 2. Calcula a variação (delta) entre frames consecutivos
                c_atual = angulos["cotovelo"]
                o_atual = angulos["ombro"]

                if cotovelo_anterior is None:
                    delta_c = 0.0
                    delta_o = 0.0
                else:
                    delta_c = round(c_atual - cotovelo_anterior, 2)
                    delta_o = round(o_atual - ombro_anterior, 2)

                cotovelo_anterior = c_atual
                ombro_anterior = o_atual

                frames_processados.append({
                    "frame": frame_idx,
                    "angulos": angulos,
                    "deltas": {"cotovelo": delta_c, "ombro": delta_o}
                })

            frame_idx += 1

        cap.release()
        return frames_processados


if __name__ == "__main__":
    # Teste rápido: instancia o detector e assegura que o modelo baixa corretamente
    print("=== Testando ExtratorVideo com a nova API MediaPipe Tasks ===")
    extrator = ExtratorVideo(lado="direito")
    print("Extrator inicializado com sucesso!")

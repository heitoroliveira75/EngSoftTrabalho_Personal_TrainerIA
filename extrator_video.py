"""
Módulo de Extração de Ângulos a partir de Vídeo

Responsável por abrir arquivos de vídeo (.mp4, .avi) ou fluxo de câmera,
detectar poses corporais com MediaPipe e gerar séries temporais de ângulos articulares.
"""

from typing import List, Dict, Any, Optional
import cv2
import mediapipe as mp

from calculo_angulos import extrair_angulos_ombro_e_cotovelo


class ExtratorVideo:
    """
    Processa arquivos de vídeo frame a frame e extrai os ângulos articulares
    necessários para a análise biomecânica.
    """

    def __init__(self, lado: str = "direito"):
        """
        Args:
            lado: 'direito' ou 'esquerdo' (define qual braço monitorar).
        """
        self.lado = lado
        self.mp_pose = mp.solutions.pose

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

        # Inicializa o estimador de pose do MediaPipe
        with self.mp_pose.Pose(
            static_image_mode=False,
            model_complexity=1,
            min_detection_confidence=0.5,
            min_tracking_confidence=0.5
        ) as pose:

            while cap.isOpened():
                sucesso, frame = cap.read()
                if not sucesso:
                    break  # Fim do vídeo

                # O OpenCV lê em BGR; o MediaPipe necessita de RGB
                frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                resultado = pose.process(frame_rgb)

                if resultado.pose_landmarks:
                    # 1. Calcula os ângulos das articulações no frame atual
                    angulos = extrair_angulos_ombro_e_cotovelo(
                        landmarks=resultado.pose_landmarks.landmark,
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
    # Exemplo didático de uso:
    print("=== Módulo ExtratorVideo ===")
    print("Para processar um vídeo real, instale as dependências com:")
    print("  pip install opencv-python mediapipe\n")
    print("Exemplo de código:")
    print("""
    from extrator_video import ExtratorVideo

    extrator = ExtratorVideo(lado='direito')
    dados = extrator.extrair_serie_temporal('meu_video.mp4')
    print(f'Total de frames analisados: {len(dados)}')
    print('Primeiro frame:', dados[0])
    """)

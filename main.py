import cv2
import os
import mediapipe as mp
from mediapipe.tasks import python
from mediapipe.tasks.python import vision

# 1. Definimos os pares de pontos que devem ser conectados por linhas (barras)
CONEXOES_CORPO = [
    # Tronco
    (11, 12), (11, 23), (12, 24), (23, 24),
    # Braço Esquerdo
    (11, 13), (13, 15),
    # Braço Direito
    (12, 14), (14, 16),
    # Perna Esquerda
    (23, 25), (25, 27), (27, 29), (29, 31), (27, 31),
    # Perna Direita
    (24, 26), (26, 28), (28, 30), (30, 32), (28, 32)
]

# Pontos individuais para desenhar os círculos
Pontos_corpo = [11, 12, 13, 14, 15, 16, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32]

DIR_ATUAL = os.path.dirname(os.path.abspath(__file__))
CAMINHO_MODELO = os.path.join(DIR_ATUAL, 'pose_landmarker_full.task')

base_options = python.BaseOptions(model_asset_path=CAMINHO_MODELO)
options = vision.PoseLandmarkerOptions(
    base_options=base_options,
    output_segmentation_masks=False
)
detector = vision.PoseLandmarker.create_from_options(options)

cap = cv2.VideoCapture(0)

while cap.isOpened():
    success, frame = cap.read()
    if not success:
        print("Não foi possível acessar a câmera.")
        break

    frame = cv2.flip(frame, 1)
    h, w, _ = frame.shape
    rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    
    mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb_frame)
    detection_result = detector.detect(mp_image)

    if detection_result.pose_landmarks:
        for pose_landmarks in detection_result.pose_landmarks:
            
            # 2. DESENHAR AS LINHAS (BARRAS) ENTRE OS PONTOS
            for p1, p2 in CONEXOES_CORPO:
                pt1 = pose_landmarks[p1]
                pt2 = pose_landmarks[p2]
                
                # Só desenha a linha se ambos os pontos forem visíveis
                if pt1.visibility > 0.5 and pt2.visibility > 0.5:
                    x1, y1 = int(pt1.x * w), int(pt1.y * h)
                    x2, y2 = int(pt2.x * w), int(pt2.y * h)
                    # cv2.line(imagem, ponto_inicial, ponto_final, cor_BGR, espessura)
                    cv2.line(frame, (x1, y1), (x2, y2), (0, 255, 0), 2)

            # 3. DESENHAR OS CÍRCULOS NAS ARTICULAÇÕES
            for index, landmark in enumerate(pose_landmarks):
                if index in Pontos_corpo and landmark.visibility > 0.5:
                    x = int(landmark.x * w)
                    y = int(landmark.y * h)
                    cv2.circle(frame, (x, y), 5, (255, 0, 0), -1)

    cv2.imshow('MediaPipe Pose - Esqueleto Filtrado', frame)

    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()
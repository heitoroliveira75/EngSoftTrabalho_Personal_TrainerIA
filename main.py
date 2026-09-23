import cv2
import os
import math
import mediapipe as mp
from mediapipe.tasks import python
from mediapipe.tasks.python import vision

def calcularangulo(p1, p2, p3):
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

def calcular_distancia(p1, p2):
    # Calcula a distância em linha reta entre os pontos p1 e p2 em pixels
    dist = math.hypot(p2[0] - p1[0], p2[1] - p1[1])
    return dist

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

ANGULOS_CORPO = [
    (12, 11, 13, "Ombro esquerdo"),
    (11, 12, 14, "Ombro direito"),
    (11, 13, 15, "Cotovelo esquerdo"),
    (12, 14, 16, "Cotovelo direito"),
    (23, 25, 27, "Joelho esquerdo"),
    (24, 26, 28, "Joelho direito"),
]

DIR_ATUAL = os.path.dirname(os.path.abspath(__file__))
CAMINHO_MODELO = os.path.join(DIR_ATUAL, 'pose_landmarker_full.task')

base_options = python.BaseOptions(model_asset_path=CAMINHO_MODELO)
options = vision.PoseLandmarkerOptions(
    base_options=base_options,
    output_segmentation_masks=False
)
detector = vision.PoseLandmarker.create_from_options(options)

# Variaveis Pra repetição
contadoreps = 0
fase_movimento = "baixo"
cap = cv2.VideoCapture(0)

LARGURA_OMBRO_REAL_CM = 40.0
FOCAL_LENGTH = 600.0
fator_cm_pixel = 0.0 # Inicializado para evitar erro de referência na primeira leitura

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

    # Verifica se encontrou alguém antes de tentar processar
    if detection_result.pose_landmarks:
        for pose_landmarks in detection_result.pose_landmarks:

            # =======================================================
            # Cálculo de Proporção (Ombros)
            # =======================================================
            ombro_esq = pose_landmarks[11] # 11 é o esquerdo
            ombro_dir = pose_landmarks[12] # 12 é o direito

            if ombro_esq.visibility > 0.5 and ombro_dir.visibility > 0.5:
                x_esq, y_esq = int(ombro_esq.x * w), int(ombro_esq.y * h)
                x_dir, y_dir = int(ombro_dir.x * w), int(ombro_dir.y * h)

                distancia_pixel = math.hypot(x_dir - x_esq, y_dir - y_esq)

                if distancia_pixel > 0:
                    distancia_camera_ = (LARGURA_OMBRO_REAL_CM * FOCAL_LENGTH) / distancia_pixel
                    fator_cm_pixel = LARGURA_OMBRO_REAL_CM / distancia_pixel

            # =======================================================
            # Análise do Braço e Axila Direita
            # =======================================================
            lm_ombro = pose_landmarks[12]
            lm_cotovelo_d = pose_landmarks[14]
            lm_pulso_d = pose_landmarks[16]
            lm_quadril_d = pose_landmarks[24]

            if (lm_cotovelo_d.visibility > 0.5 and lm_pulso_d.visibility > 0.5 and 
                lm_quadril_d.visibility > 0.5 and lm_ombro.visibility > 0.5):
                
                # Para funções do OpenCV (Círculos, Linhas, Distância Euclidiana)
                cotovelo_d = (int(lm_cotovelo_d.x * w), int(lm_cotovelo_d.y * h))
                pulso_d = (int(lm_pulso_d.x * w), int(lm_pulso_d.y * h))
                quadril_d = (int(lm_quadril_d.x * w), int(lm_quadril_d.y * h))
                ombro_d = (int(lm_ombro.x * w), int(lm_ombro.y * h))
                
                distexerpx = calcular_distancia(cotovelo_d, pulso_d) #pixel

                if fator_cm_pixel > 0:
                    distemcm = distexerpx * fator_cm_pixel #transforma em cm

                # ATENÇÃO: Passando as landmarks brutas para o calcularangulo (pois possuem .x e .y)
                # A ordem para o ângulo da axila é: Quadril, Ombro (Vértice), Cotovelo
                anguloaxila = calcularangulo(lm_quadril_d, lm_ombro, lm_cotovelo_d)

                forma_correta = False
                cor_ombro = (0, 0, 255)

                if anguloaxila is not None:
                    if 45 <= anguloaxila <= 60:
                        forma_correta = True
                        aviso_postura = "Angulo do ombro certo"
                        cor_ombro = (0, 255, 0)
                    elif anguloaxila < 45:
                        aviso_postura = "Abra mais o ombro" 
                    else:
                        aviso_postura = "Feche mais o ombro"

                    cv2.putText(frame, f"Axila: {int(anguloaxila)}", (ombro_d[0] + 15, ombro_d[1]), 
                                cv2.FONT_HERSHEY_SIMPLEX, 0.6, cor_ombro, 2)
           
            # =======================================================
            # DESENHAR AS LINHAS E CÍRCULOS (BARRAS) NO CORPO
            # =======================================================
            for p1, p2 in CONEXOES_CORPO:
                pt1 = pose_landmarks[p1]
                pt2 = pose_landmarks[p2]
                
                if pt1.visibility > 0.5 and pt2.visibility > 0.5:
                    x1, y1 = int(pt1.x * w), int(pt1.y * h)
                    x2, y2 = int(pt2.x * w), int(pt2.y * h)
                    cv2.line(frame, (x1, y1), (x2, y2), (0, 255, 0), 2)

            for index, landmark in enumerate(pose_landmarks):
                if index in Pontos_corpo and landmark.visibility > 0.5:
                    x = int(landmark.x * w)
                    y = int(landmark.y * h)
                    cv2.circle(frame, (x, y), 5, (255, 0, 0), -1)

            # =======================================================
            # MOSTRAR ÂNGULOS NA TELA
            # =======================================================
            for linha, (ponto_1, vertice, ponto_3, nome) in enumerate(ANGULOS_CORPO):
                indices = (ponto_1, vertice, ponto_3)
                if all(pose_landmarks[index].visibility > 0.5 for index in indices):
                    angulo = calcularangulo(
                        pose_landmarks[ponto_1],
                        pose_landmarks[vertice],
                        pose_landmarks[ponto_3],
                    )
                    
                    if angulo is not None:
                        cv2.putText(
                            frame,
                            f"{nome}: {angulo:.1f} graus",
                            (10, 60 + linha * 30),
                            cv2.FONT_HERSHEY_SIMPLEX,
                            0.6,
                            (0, 255, 0),
                            2,
                        )

    cv2.imshow('MediaPipe Pose - Esqueleto Filtrado', frame)

    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()
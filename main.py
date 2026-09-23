import cv2
import os
import math
import mediapipe as mp
from mediapipe.tasks import python
from mediapipe.tasks.python import vision

# =======================================================
# NOVA CLASSE: Para criar uma linha reta para baixo do ombro
# =======================================================
class PontoVirtual:
    def __init__(self, x, y):
        self.x = x
        self.y = y

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
    return math.hypot(p2[0] - p1[0], p2[1] - p1[1])

# Conexões do corpo
CONEXOES_CORPO = [
    (11, 12), (11, 23), (12, 24), (23, 24),
    (11, 13), (13, 15), (12, 14), (14, 16),
    (23, 25), (25, 27), (27, 29), (29, 31), (27, 31),
    (24, 26), (26, 28), (28, 30), (30, 32), (28, 32)
]

Pontos_corpo = [11, 12, 13, 14, 15, 16, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32]

DIR_ATUAL = os.path.dirname(os.path.abspath(__file__))
CAMINHO_MODELO = os.path.join(DIR_ATUAL, 'pose_landmarker_full.task')

base_options = python.BaseOptions(model_asset_path=CAMINHO_MODELO)
options = vision.PoseLandmarkerOptions(
    base_options=base_options,
    output_segmentation_masks=False
)
detector = vision.PoseLandmarker.create_from_options(options)

contadoreps = 0
fase_movimento = "baixo"
cap = cv2.VideoCapture(0)

while cap.isOpened():
    success, frame = cap.read()
    if not success:
        break

    frame = cv2.flip(frame, 1)
    h, w, _ = frame.shape
    rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    
    mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb_frame)
    detection_result = detector.detect(mp_image)

    if detection_result.pose_landmarks:
        for pose_landmarks in detection_result.pose_landmarks:

            lm_ombro_e = pose_landmarks[13]
            lm_ombro_d = pose_landmarks[12]
            lm_cotovelo_d = pose_landmarks[14]
            lm_pulso_d = pose_landmarks[16]

            # Só checamos a visibilidade do braço!
            if (lm_cotovelo_d.visibility > 0.5 and lm_pulso_d.visibility > 0.5 and lm_ombro_d.visibility > 0.5):
                
                ombro_d = (int(lm_ombro_d.x * w), int(lm_ombro_d.y * h))
                ombro_e = (int(lm_ombro_e.x * w), int(lm_ombro_e.y * h))
                # =======================================================
                # O TRUQUE: Ponto Virtual
                # Cria um ponto artificial perfeitamente abaixo do ombro (eixo Y maior)
                # =======================================================
                lm_vertical = PontoVirtual(lm_ombro_d.x, lm_ombro_d.y + 0.2)
                
                # O ângulo agora é calculado entre a linha reta invisível e o seu cotovelo
                angulo_ombro = calcularangulo(lm_ombro_e, lm_ombro_d, lm_cotovelo_d)
                angulocotovelo = calcularangulo(lm_ombro_d, lm_cotovelo_d, lm_pulso_d)

                forma_correta = False
                cor_ombro = (0, 0, 255) # Vermelho

                # 1. Checagem de Postura do Ombro (Elevado ou Colado no corpo)
                # Se o braço estiver reto pra baixo, o ângulo será perto de 0.
                if angulo_ombro is not None:
                    # Mude esses valores conforme o exercício. Ex: 45 a 60 para banco Scott.
                    if 115<= angulo_ombro <= 135:
                        forma_correta = True
                        aviso_postura = "Ombro na posicao correta!"
                        cor_ombro = (0, 255, 0)
                    elif angulo_ombro < 115:
                        aviso_postura = "Levante mais o cotovelo!" 
                    else:
                        aviso_postura = "Abaixe um pouco o cotovelo!"

                    cv2.putText(frame, f"Ang. Ombro: {int(angulo_ombro)}", (ombro_d[0] + 15, ombro_d[1]), 
                                cv2.FONT_HERSHEY_SIMPLEX, 0.6, cor_ombro, 2)

                # 2. Lógica de Contagem
                if angulocotovelo is not None and contadoreps < 10:
                    if angulocotovelo < 45 and forma_correta:
                        if fase_movimento == "baixo":
                            fase_movimento = "cima"

                    if angulocotovelo > 150:
                        if fase_movimento == "cima":
                            contadoreps += 1
                            fase_movimento = "baixo"

                # 3. Textos na tela
                cv2.putText(frame, f"Reps: {contadoreps}/10", (20, 50), cv2.FONT_HERSHEY_SIMPLEX, 1.2, (255, 0, 0), 3)
                cv2.putText(frame, aviso_postura, (20, 90), cv2.FONT_HERSHEY_SIMPLEX, 0.8, cor_ombro, 2)

                if contadoreps >= 10:
                    cv2.putText(frame, "SERIE CONCLUIDA!", (20, 150), cv2.FONT_HERSHEY_SIMPLEX, 1.2, (0, 255, 255), 3)
           
            # Desenha linhas
            for p1, p2 in CONEXOES_CORPO:
                pt1 = pose_landmarks[p1]
                pt2 = pose_landmarks[p2]
                if pt1.visibility > 0.5 and pt2.visibility > 0.5:
                    x1, y1 = int(pt1.x * w), int(pt1.y * h)
                    x2, y2 = int(pt2.x * w), int(pt2.y * h)
                    cv2.line(frame, (x1, y1), (x2, y2), (0, 255, 0), 2)

            # Desenha círculos
            for index, landmark in enumerate(pose_landmarks):
                if index in Pontos_corpo and landmark.visibility > 0.5:
                    x = int(landmark.x * w)
                    y = int(landmark.y * h)
                    cv2.circle(frame, (x, y), 5, (255, 0, 0), -1)

    cv2.imshow('MediaPipe Pose - Esqueleto', frame)

    tecla = cv2.waitKey(1) & 0xFF
    if tecla == ord('q'):
        break
    elif tecla == ord('r'):
        contadoreps = 0
        fase_movimento = "baixo"

cap.release()
cv2.destroyAllWindows()
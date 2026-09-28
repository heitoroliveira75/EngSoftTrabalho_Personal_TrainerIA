import pandas as pd  # <-- Correção 1 (pd)
import cv2
import os
import math
import mediapipe as mp
from mediapipe.tasks import python
from mediapipe.tasks.python import vision

# <-- Adicionado a classe PontoVirtual que você usava para o ombro
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

# ... (Mantenha as conexões e configurações do seu detector aqui) ...
DIR_ATUAL = os.path.dirname(os.path.abspath(__file__))
CAMINHO_MODELO = os.path.join(DIR_ATUAL, 'pose_landmarker_full.task')

base_options = python.BaseOptions(model_asset_path=CAMINHO_MODELO)
options = vision.PoseLandmarkerOptions(
    base_options=base_options,
    output_segmentation_masks=False
)
detector = vision.PoseLandmarker.create_from_options(options)

# A Prancheta
dados_extraidos = []
contador_frame = 0

cap = cv2.VideoCapture("Nome.mp4")

while cap.isOpened():
    sucess, frame = cap.read()
    if not sucess:
        break
    
    contador_frame += 1 # <-- Correção 3 (Soma 1 do jeito certo)

    # <-- Correção 2: Atribuindo os resultados às variáveis corretamente
    rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb_frame)
    detection_result = detector.detect(mp_image)

    # <-- Correção 4: O bloco que extrai o esqueleto estava faltando!
    if detection_result.pose_landmarks:
        for pose_landmarks in detection_result.pose_landmarks:
            
            lm_ombro = pose_landmarks[12]
            lm_cotovelo_d = pose_landmarks[14]
            lm_pulso_d = pose_landmarks[16]
            
            # Recriando o cálculo dos ângulos
            lm_vertical = PontoVirtual(lm_ombro.x, lm_ombro.y + 0.2)
            angulo_ombro = calcularangulo(lm_vertical, lm_ombro, lm_cotovelo_d)
            angulocotovelo = calcularangulo(lm_ombro, lm_cotovelo_d, lm_pulso_d)

            # <-- Correção 5: O dicionário deve ficar DENTRO do loop (identado)
            linha_atual = {
                "Frame": contador_frame,
                "Angulo_Ombro": angulo_ombro,
                "Angulo_Cotovelo": angulocotovelo
            }

            dados_extraidos.append(linha_atual)

cap.release() # É importante liberar o arquivo no final

# As duas últimas linhas ficam coladas na esquerda (fora do loop)
tabela = pd.DataFrame(dados_extraidos)
tabela.to_csv("meu_dataset_treino.csv", index=False)

print("A extração acabou! Verifique a pasta para ver o seu novo arquivo CSV.")
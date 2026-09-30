import pandas as pd
import cv2
import os
import math
import mediapipe as mp
from mediapipe.tasks import python
from mediapipe.tasks.python import vision

# 1. Nova função matemática para cálculo em 3 Dimensões (usando X, Y e Z)
def calcular_angulo_3d(p1, p2, p3):
    vetor_1 = (p1.x - p2.x, p1.y - p2.y, p1.z - p2.z)
    vetor_2 = (p3.x - p2.x, p3.y - p2.y, p3.z - p2.z)
    
    produto_escalar = vetor_1[0]*vetor_2[0] + vetor_1[1]*vetor_2[1] + vetor_1[2]*vetor_2[2]
    
    tamanho_1 = math.sqrt(vetor_1[0]**2 + vetor_1[1]**2 + vetor_1[2]**2)
    tamanho_2 = math.sqrt(vetor_2[0]**2 + vetor_2[1]**2 + vetor_2[2]**2)
    
    if tamanho_1 == 0 or tamanho_2 == 0:
        return None
        
    cosseno = produto_escalar / (tamanho_1 * tamanho_2)
    cosseno = max(-1.0, min(1.0, cosseno))
    return math.degrees(math.acos(cosseno))

# 2. Configuração do MediaPipe
DIR_ATUAL = os.path.dirname(os.path.abspath(__file__))
CAMINHO_MODELO = os.path.join(DIR_ATUAL, 'pose_landmarker_full.task')

base_options = python.BaseOptions(model_asset_path=CAMINHO_MODELO)
options = vision.PoseLandmarkerOptions(
    base_options=base_options,
    output_segmentation_masks=False
)
detector = vision.PoseLandmarker.create_from_options(options)

# 3. Preparação do Extrator
# ATENÇÃO: Altere esta pasta para o local onde você baixar o dataset (ex: Fit3D)
pasta_dataset = "C:/caminho/para/a/pasta/do/dataset" 

dados_extraidos = []

# 4. Navegador inteligente de pastas e subpastas (os.walk)
for raiz, pastas, arquivos in os.walk(pasta_dataset):
    
    for nome_arquivo in arquivos:
        # Aceita formatos comuns em datasets acadêmicos
        if nome_arquivo.endswith(".mp4") or nome_arquivo.endswith(".avi"):
            
            caminho_completo = os.path.join(raiz, nome_arquivo)
            print(f"Processando vídeo: {caminho_completo}...")
            
            contador_frame = 0
            cap = cv2.VideoCapture(caminho_completo)

            while cap.isOpened():
                sucess, frame = cap.read()
                if not sucess:
                    break 
                
                contador_frame += 1 

                # 5. Downsampling: Lê apenas 1 a cada 10 frames para otimizar
                if contador_frame % 10 == 0:
                    
                    rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                    mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb_frame)
                    detection_result = detector.detect(mp_image)

                    if detection_result.pose_landmarks:
                        for pose_landmarks in detection_result.pose_landmarks:
                            
                            # --- LADO DIREITO ---
                            lm_ombro_d = pose_landmarks[12]
                            lm_cotovelo_d = pose_landmarks[14]
                            lm_pulso_d = pose_landmarks[16]
                            lm_quadril_d = pose_landmarks[24] # Retorno da biomecânica real

                            angulo_ombro_dir = calcular_angulo_3d(lm_quadril_d, lm_ombro_d, lm_cotovelo_d)
                            angulo_cotovelo_dir = calcular_angulo_3d(lm_ombro_d, lm_cotovelo_d, lm_pulso_d)

                            # --- LADO ESQUERDO ---
                            lm_ombro_e = pose_landmarks[11]
                            lm_cotovelo_e = pose_landmarks[13]
                            lm_pulso_e = pose_landmarks[15]
                            lm_quadril_e = pose_landmarks[23]

                            angulo_ombro_esq = calcular_angulo_3d(lm_quadril_e, lm_ombro_e, lm_cotovelo_e)
                            angulo_cotovelo_esq = calcular_angulo_3d(lm_ombro_e, lm_cotovelo_e, lm_pulso_e)

                            # 6. Salva as informações consolidadas
                            linha_atual = {
                                "Video_Nome": nome_arquivo, 
                                "Frame": contador_frame,
                                "Cotovelo_Dir": round(angulo_cotovelo_dir, 2) if angulo_cotovelo_dir else None,
                                "Cotovelo_Esq": round(angulo_cotovelo_esq, 2) if angulo_cotovelo_esq else None,
                                "Ombro_Dir": round(angulo_ombro_dir, 2) if angulo_ombro_dir else None,
                                "Ombro_Esq": round(angulo_ombro_esq, 2) if angulo_ombro_esq else None
                            }

                            dados_extraidos.append(linha_atual)

            cap.release()

# 7. Geração do Dataset
tabela = pd.DataFrame(dados_extraidos)
tabela.to_csv("meu_dataset_treino.csv", index=False)

print("A extração acabou! O seu arquivo meu_dataset_treino.csv foi gerado com sucesso.")
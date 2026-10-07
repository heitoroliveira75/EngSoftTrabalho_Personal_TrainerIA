import pandas as pd
import cv2
import os
import math
import joblib  # <-- Biblioteca nova para carregar o modelo treinado
import mediapipe as mp
from mediapipe.tasks import python
from mediapipe.tasks.python import vision

# 1. Função matemática para cálculo em 3 Dimensões
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

# =================================================================
# 3. CARREGAMENTO DO CÉREBRO DA I.A.
# Carrega o modelo que treinou previamente no script de Machine Learning
# =================================================================
try:
    modelo_ia = joblib.load("meu_personal_trainer_ia.pkl")
    print("✅ Cérebro da I.A. carregado com sucesso!")
except FileNotFoundError:
    print("❌ ERRO: Ficheiro 'meu_personal_trainer_ia.pkl' não encontrado!")
    print("Por favor, rode o script de treinamento primeiro para gerar o modelo.")
    exit()

# 4. Pasta com os vídeos que quer testar
pasta_dataset = "D:\Testes" 
dados_avaliados = []

# 5. Navegador inteligente de pastas e subpastas (os.walk)
for raiz, pastas, arquivos in os.walk(pasta_dataset):
    
    for nome_arquivo in arquivos:
        if nome_arquivo.endswith(".mp4") or nome_arquivo.endswith(".avi"):
            
            caminho_completo = os.path.join(raiz, nome_arquivo)
            print(f"\n🎥 Analisando vídeo: {nome_arquivo}...")
            
            contador_frame = 0
            
            # --- VARIÁVEIS DE RESUMO DO MOVIMENTO ---
            cotovelo_min = 999.0
            cotovelo_max = 0.0
            ombro_min = 999.0
            ombro_max = 0.0

            cap = cv2.VideoCapture(caminho_completo)

            while cap.isOpened():
                sucess, frame = cap.read()
                if not sucess:
                    break 
                
                contador_frame += 1 

                # Lê apenas 1 a cada 10 frames para otimizar a velocidade
                if contador_frame % 10 == 0:
                    
                    rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                    mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb_frame)
                    detection_result = detector.detect(mp_image)

                    if detection_result.pose_landmarks:
                        for pose_landmarks in detection_result.pose_landmarks:
                            
                            # Rastreamento focado no lado direito para a validação
                            lm_ombro_d = pose_landmarks[12]
                            lm_cotovelo_d = pose_landmarks[14]
                            lm_pulso_d = pose_landmarks[16]
                            lm_quadril_d = pose_landmarks[24]

                            angulo_ombro_dir = calcular_angulo_3d(lm_quadril_d, lm_ombro_d, lm_cotovelo_d)
                            angulo_cotovelo_dir = calcular_angulo_3d(lm_ombro_d, lm_cotovelo_d, lm_pulso_d)

                            # --- ATUALIZAÇÃO DOS PICOS E VALES (LIMITES) ---
                            if angulo_cotovelo_dir is not None:
                                if angulo_cotovelo_dir < cotovelo_min:
                                    cotovelo_min = angulo_cotovelo_dir
                                if angulo_cotovelo_dir > cotovelo_max:
                                    cotovelo_max = angulo_cotovelo_dir

                            if angulo_ombro_dir is not None:
                                if angulo_ombro_dir < ombro_min:
                                    ombro_min = angulo_ombro_dir
                                if angulo_ombro_dir > ombro_max:
                                    ombro_max = angulo_ombro_dir

            cap.release()

            # =================================================================
            # 6. INFERÊNCIA: HORA DA AVALIAÇÃO DA I.A.
            # O vídeo acabou, a I.A. vai julgar o resumo do movimento
            # =================================================================
            
            # Só avalia se o MediaPipe conseguiu ler algum esqueleto (o valor 999.0 foi alterado)
            if cotovelo_min != 999.0:
                ombro_variacao = ombro_max - ombro_min
                
                # As características que o seu modelo estudou (certifique-se de que a ordem 
                # e quantidade de variáveis são iguais ao script de treinamento!)
                caracteristicas_movimento = [[cotovelo_min, cotovelo_max, ombro_variacao]]
                
                # A I.A. toma a decisão
                previsao = modelo_ia.predict(caracteristicas_movimento)
                resultado_final = previsao[0]
                
                if resultado_final == 1:
                    print(f"✅ VEREDITO: Execução CORRETA!")
                    status_texto = "CORRETO"
                else:
                    print(f"❌ VEREDITO: Execução INCORRETA (Possível roubo no movimento)!")
                    status_texto = "INCORRETO"
                
                # Opcional: Salvar num relatório
                dados_avaliados.append({
                    "Video": nome_arquivo,
                    "Cotovelo_Min": round(cotovelo_min, 1),
                    "Cotovelo_Max": round(cotovelo_max, 1),
                    "Ombro_Variacao": round(ombro_variacao, 1),
                    "Veredito_IA": status_texto
                })
            else:
                print(f"⚠️ AVISO: Nenhum corpo detectado no vídeo {nome_arquivo}.")

# 7. (Opcional) Gerar Relatório de Desempenho dos Alunos
if dados_avaliados:
    relatorio = pd.DataFrame(dados_avaliados)
    relatorio.to_csv("relatorio_avaliacoes_ia.csv", index=False)
    print("\n📄 Relatório salvo em 'relatorio_avaliacoes_ia.csv'.")
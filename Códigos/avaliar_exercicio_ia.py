"""
Módulo de Gravação e Avaliação de Exercícios com IA Treinada no Dataset.
Permite ao usuário gravar um vídeo pela webcam (ou enviar um arquivo de vídeo)
e compara cada repetição com o modelo (.pkl) e a curva consenso aprendidos pela IA.
"""

import argparse
import csv
import os
import time
from typing import Dict, Any, List
import cv2
import joblib
import mediapipe as mp
from mediapipe.tasks import python
from mediapipe.tasks.python import vision

from exercicios_fsm import CATALOGO_EXERCICIOS
from buffer_repeticao import BufferRepeticao
from dtw_inicial import DTW
from extrator_video import ExtratorVideo, garantir_modelo_pose
from treinar_dataset import extrair_features_biomecanicas, PASTA_MODELOS_PADRAO

CONEXOES_CORPO = [
    (11, 12), (11, 23), (12, 24), (23, 24),
    (11, 13), (13, 15), (12, 14), (14, 16),
    (23, 25), (25, 27), (27, 29), (29, 31), (27, 31),
    (24, 26), (26, 28), (28, 30), (30, 32), (28, 32),
]


def gravar_video_usuario(caminho_saida: str = "treino_usuario.mp4") -> str:
    """
    Abre a webcam, desenha o esqueleto de referência na tela para o usuário se
    posicionar e salva a gravação em arquivo .mp4 para ser analisada pela IA.
    """
    caminho_modelo = garantir_modelo_pose()
    base_options = python.BaseOptions(model_asset_path=caminho_modelo)
    options = vision.PoseLandmarkerOptions(
        base_options=base_options,
        running_mode=vision.RunningMode.VIDEO,
        num_poses=1,
    )
    detector = vision.PoseLandmarker.create_from_options(options)

    cap = cv2.VideoCapture(0)
    if not cap.isOpened():
        raise RuntimeError("Não foi possível acessar a webcam para gravação.")

    largura = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH)) or 640
    altura = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT)) or 480
    fps = cap.get(cv2.CAP_PROP_FPS)
    if not fps or fps <= 0:
        fps = 30.0

    fourcc = cv2.VideoWriter_fourcc(*"mp4v")
    gravador = cv2.VideoWriter(caminho_saida, fourcc, fps, (largura, altura))

    print("\n[GRAVAÇÃO INICIADA] Realize o exercício na câmera. Pressione 'q' para encerrar e analisar.")
    t_inicio = time.monotonic()

    try:
        while cap.isOpened():
            sucesso, frame = cap.read()
            if not sucesso:
                break

            frame = cv2.flip(frame, 1)
            # Salva o frame limpo no arquivo de vídeo para análise fiel
            gravador.write(frame)

            # Desenha o esqueleto na tela apenas para retorno visual durante a gravação
            rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            mp_img = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb)
            ts_ms = int((time.monotonic() - t_inicio) * 1000)
            res = detector.detect_for_video(mp_img, ts_ms)

            if res.pose_landmarks:
                pts = res.pose_landmarks[0]
                for p1, p2 in CONEXOES_CORPO:
                    if pts[p1].visibility > 0.5 and pts[p2].visibility > 0.5:
                        pt1 = (int(pts[p1].x * largura), int(pts[p1].y * altura))
                        pt2 = (int(pts[p2].x * largura), int(pts[p2].y * altura))
                        cv2.line(frame, pt1, pt2, (0, 255, 0), 2)

            cv2.putText(
                frame,
                "GRAVANDO EXERCICIO... Pressione 'Q' para finalizar e avaliar",
                (15, 35),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.65,
                (0, 0, 255),
                2,
            )
            cv2.imshow("Gravacao do Exercicio", frame)

            if cv2.waitKey(1) & 0xFF == ord("q"):
                break
    finally:
        cap.release()
        gravador.release()
        detector.close()
        cv2.destroyAllWindows()

    print(f"Vídeo salvo com sucesso em: '{caminho_saida}'")
    return caminho_saida


def avaliar_video_com_ia(
    caminho_video: str,
    tecla_exercicio: str = "1",
    lado: str = "direito",
    pasta_modelos: str = PASTA_MODELOS_PADRAO
) -> None:
    """
    Carrega o conhecimento aprendido pela IA (.pkl) para o exercício escolhido,
    extrai as repetições do vídeo do usuário e emite o veredito completo.
    """
    if tecla_exercicio not in CATALOGO_EXERCICIOS:
        raise ValueError(f"Exercício '{tecla_exercicio}' inválido.")

    config = CATALOGO_EXERCICIOS[tecla_exercicio]
    id_ex = config["id"]
    nome_ex = config["nome"]
    articulacoes = config["articulacoes"]

    caminho_pkl = os.path.join(pasta_modelos, f"modelo_ia_{id_ex}.pkl")
    if not os.path.exists(caminho_pkl):
        raise FileNotFoundError(
            f"Modelo '{caminho_pkl}' não encontrado! "
            f"Execute primeiro: python treinar_dataset.py --simular"
        )

    # 1. Carrega o pacote treinado pela IA (Classificador + Curva Consenso do Dataset)
    pacote_ia = joblib.load(caminho_pkl)
    modelo_clf = pacote_ia["modelo_classificador"]
    curva_consenso = pacote_ia["curva_consenso"]
    total_reps_dataset = pacote_ia["total_repeticoes_aprendidas"]

    print(f"\n============================================================")
    print(f"Avaliando '{caminho_video}' -> {nome_ex}")
    print(f"IA treinada com base em {total_reps_dataset} execuções corretas do dataset")
    print(f"============================================================")

    # 2. Extrai os ângulos do vídeo do usuário
    extrator = ExtratorVideo(articulacoes=articulacoes, lado=lado)
    frames = extrator.extrair_serie_temporal(caminho_video)

    if not frames:
        print("[ERRO] Nenhuma pose humana foi detectada no vídeo enviado.")
        return

    fsm = config["classe_fsm"]()
    buffer = BufferRepeticao(fsm=fsm, articulacoes=articulacoes)
    dtw_avaliador = DTW(tolerancia=15.0)

    relatorio_csv: List[Dict[str, Any]] = []

    # 3. Avalia cada repetição encontrada no vídeo
    for f in frames:
        dados_rep, erro_fsm = buffer.processar_frame(
            angulos=f["angulos"],
            angulos_deltas=f["deltas"]
        )

        if dados_rep is not None:
            num_rep = fsm.repeticoes
            vetor_feats, metricas = extrair_features_biomecanicas(
                matriz_rep=dados_rep,
                curva_consenso=curva_consenso,
                articulacoes=articulacoes,
                dtw_avaliador=dtw_avaliador,
            )

            # Predição do modelo de Machine Learning (.pkl)
            predicao_ia = int(modelo_clf.predict([vetor_feats])[0])
            confianca_correto = float(modelo_clf.predict_proba([vetor_feats])[0][1]) * 100.0

            # Veredito final combina a aprovação da IA com a ausência de erros críticos na FSM
            execucao_correta = (predicao_ia == 1) and (erro_fsm is None)
            veredito_str = "CORRETO" if execucao_correta else "INCORRETO"

            print(f"\n--- REPETIÇÃO #{num_rep} ---")
            print(f"  Veredito Final da IA:     {veredito_str}")
            print(f"  Probabilidade de Acerto:  {confianca_correto:.1f}%")
            print(f"  Similaridade Motor (DTW): {metricas['dtw_score']:.1f}% (Erro médio: {metricas['dtw_erro_norm']}°)")

            if erro_fsm:
                print(f"  [ALERTA BIOMECÂNICO]:     {fsm.traduzir_erro(erro_fsm)}")

            for art in articulacoes:
                desvio = metricas[f"{art}_desvio_dtw"]
                amp = metricas[f"{art}_variacao"]
                print(f"  - {art.capitalize()}: amplitude de {amp}° | desvio em relação ao dataset: {desvio}°")
                if desvio > 12.0:
                    print(f"    -> Correção: Seu {art.upper()} desviou do padrão aprendido pela IA.")

            registro = {
                "Video": os.path.basename(caminho_video),
                "Exercicio": nome_ex,
                "Repeticao": num_rep,
                "Veredito_IA": veredito_str,
                "Confianca_IA_Pct": round(confianca_correto, 1),
                "Score_DTW_Pct": metricas["dtw_score"],
                "Erro_FSM": erro_fsm or "NENHUM",
            }
            relatorio_csv.append(registro)

    if fsm.repeticoes == 0:
        print("\n[AVISO] Nenhuma repetição completa foi detectada no vídeo.")
        return

    # 4. Exporta o relatório consolidado em CSV (como no Modularização.py)
    caminho_relatorio = "relatorio_avaliacoes_ia.csv"
    escrever_cabecalho = not os.path.exists(caminho_relatorio)
    with open(caminho_relatorio, "a", newline="", encoding="utf-8") as arq:
        escritor = csv.DictWriter(arq, fieldnames=relatorio_csv[0].keys())
        if escrever_cabecalho:
            escritor.writeheader()
        escritor.writerows(relatorio_csv)

    print(f"\nRelatório atualizado em: '{caminho_relatorio}'")


def main():
    parser = argparse.ArgumentParser(
        description="Grava ou lê um vídeo do usuário e avalia com a IA treinada no dataset."
    )
    parser.add_argument(
        "--exercicio",
        default="1",
        choices=list(CATALOGO_EXERCICIOS.keys()),
        help="1=Desenvolvimento de Ombro, 2=Agachamento Livre, 3=Rosca Bíceps",
    )
    parser.add_argument(
        "--video",
        default=None,
        help="Caminho de um vídeo já gravado (se omitido junto com --gravar, abre a webcam)",
    )
    parser.add_argument(
        "--gravar",
        action="store_true",
        help="Abre a webcam para o usuário gravar o exercício na hora antes de avaliar",
    )
    parser.add_argument(
        "--lado",
        default="direito",
        choices=["direito", "esquerdo"],
        help="Lado do corpo que será analisado",
    )
    args = parser.parse_args()

    if args.gravar or not args.video:
        caminho_video = gravar_video_usuario("treino_gravado_usuario.mp4")
    else:
        caminho_video = args.video

    avaliar_video_com_ia(
        caminho_video=caminho_video,
        tecla_exercicio=args.exercicio,
        lado=args.lado,
    )


if __name__ == "__main__":
    main()
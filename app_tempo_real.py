"""
Aplicação Principal de Avaliação Biomecânica em Tempo Real (Webcam).
Integra captura OpenCV e MediaPipe Tasks (RunningMode.VIDEO) ao OrquestradorSessao.
"""

import time
from typing import Dict, Any, Optional, Tuple
import cv2
import mediapipe as mp
from mediapipe.tasks import python
from mediapipe.tasks.python import vision

from calculo_angulos import extrair_angulos_exercicio
from exercicios_fsm import CATALOGO_EXERCICIOS
from avaliador_pontuacao import (
    OrquestradorSessao,
    ResultadoPontuacaoRepeticao,
)
from gabarito import garantir_gabaritos_padrao
from extrator_video import garantir_modelo_pose

# Conexões e pontos anatómicos para desenho do esqueleto na tela
CONEXOES_CORPO = [
    (11, 12), (11, 23), (12, 24), (23, 24),
    (11, 13), (13, 15), (12, 14), (14, 16),
    (23, 25), (25, 27), (27, 29), (29, 31), (27, 31),
    (24, 26), (26, 28), (28, 30), (30, 32), (28, 32),
]
PONTOS_CORPO = [11, 12, 13, 14, 15, 16, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32]


def inicializar_sessao_exercicio(tecla: str) -> Tuple[Dict[str, Any], OrquestradorSessao]:
    """Cria o orquestrador oficial para o exercício selecionado."""
    config = CATALOGO_EXERCICIOS[tecla]
    return config, OrquestradorSessao(tecla)


def processar_frame_webcam(
    orquestrador: OrquestradorSessao,
    angulos: Dict[str, float],
    visivel: bool,
    alerta_atual: Optional[str],
) -> Tuple[Optional[str], Optional[ResultadoPontuacaoRepeticao]]:
    """Delega ao orquestrador o frame e mantém o alerta visível até voltar ao repouso."""
    alerta, resultado = orquestrador.processar_frame(angulos, visivel=visivel)
    if alerta:
        alerta_atual = orquestrador.fsm.traduzir_erro(alerta)
    elif orquestrador.fsm.fases[1] == 0:
        alerta_atual = None
    return alerta_atual, resultado


def desenhar_esqueleto(frame, pose_landmarks, w: int, h: int, cor_linha=(0, 255, 0)):
    """Desenha as barras e articulações visíveis sobre o utilizador."""
    for p1, p2 in CONEXOES_CORPO:
        pt1, pt2 = pose_landmarks[p1], pose_landmarks[p2]
        if pt1.visibility > 0.5 and pt2.visibility > 0.5:
            x1, y1 = int(pt1.x * w), int(pt1.y * h)
            x2, y2 = int(pt2.x * w), int(pt2.y * h)
            cv2.line(frame, (x1, y1), (x2, y2), cor_linha, 2)

    for index, landmark in enumerate(pose_landmarks):
        if index in PONTOS_CORPO and landmark.visibility > 0.5:
            x, y = int(landmark.x * w), int(landmark.y * h)
            cv2.circle(frame, (x, y), 5, (255, 0, 0), -1)


def desenhar_painel_hud(
    frame,
    nome_exercicio: str,
    lado: str,
    repeticoes: int,
    fase_texto: str,
    angulos: Dict[str, float],
    corpo_visivel: bool,
    alerta_imediato: Optional[str],
    ultimo_veredito: Optional[Dict[str, Any]],
    score_medio_sessao: float,
):
    """Renderiza o painel informativo superior e o resultado da última repetição."""
    h, w, _ = frame.shape

    # Fundo semitransparente no topo
    overlay = frame.copy()
    cv2.rectangle(overlay, (0, 0), (w, 190), (20, 20, 20), -1)
    cv2.addWeighted(overlay, 0.72, frame, 0.28, 0, frame)

    # Linha 1: Exercício ativo, lado e atalhos
    cv2.putText(
        frame,
        f"Exercicio: {nome_exercicio} ({lado.upper()}) | [1] Ombro [2] Agachamento [3] Rosca [L] Lado [Q] Sair",
        (12, 25),
        cv2.FONT_HERSHEY_SIMPLEX,
        0.52,
        (255, 255, 255),
        1,
    )

    # Linha 2: Contador de Repetições e Fase Atual
    cv2.putText(
        frame,
        f"Repeticoes: {repeticoes}  |  Fase: {fase_texto}",
        (12, 55),
        cv2.FONT_HERSHEY_SIMPLEX,
        0.68,
        (0, 255, 255),
        2,
    )

    # Linha 3: Ângulos em tempo real ou aviso de enquadramento
    if not corpo_visivel:
        cv2.putText(
            frame,
            "AVISO: Enquadre todas as articulacoes do exercicio na camara!",
            (12, 85),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.6,
            (0, 140, 255),
            2,
        )
    else:
        texto_angulos = "  |  ".join(f"{k.capitalize()}: {v:.1f} graus" for k, v in angulos.items())
        cv2.putText(
            frame,
            texto_angulos,
            (12, 85),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.58,
            (200, 255, 200),
            2,
        )

    # Linha 4: Alerta biomecânico imediato (FSM)
    if alerta_imediato:
        cv2.putText(
            frame,
            f"ALERTA POSTURAL: {alerta_imediato}",
            (12, 115),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.58,
            (0, 0, 255),
            2,
        )

    # Linha 5: Veredito consolidado da última repetição
    if ultimo_veredito:
        cor_veredito = (0, 255, 0) if ultimo_veredito["aprovado"] else (0, 60, 255)
        cv2.putText(
            frame,
            ultimo_veredito["resumo"],
            (12, 150),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.54,
            cor_veredito,
            2,
        )

    cv2.putText(
        frame,
        f"Media da sessao: {score_medio_sessao:.1f}%",
        (12, 180),
        cv2.FONT_HERSHEY_SIMPLEX,
        0.58,
        (255, 255, 255),
        1,
    )


def main():
    # 1. Garante que os ficheiros JSON de gabarito e o modelo do MediaPipe existem
    garantir_gabaritos_padrao()
    caminho_modelo = garantir_modelo_pose()

    # 2. Configura o MediaPipe PoseLandmarker em modo VIDEO para rastreio rápido ao vivo
    base_options = python.BaseOptions(model_asset_path=caminho_modelo)
    options = vision.PoseLandmarkerOptions(
        base_options=base_options,
        running_mode=vision.RunningMode.VIDEO,
        num_poses=1,
        min_pose_detection_confidence=0.5,
        min_tracking_confidence=0.5,
    )
    detector = vision.PoseLandmarker.create_from_options(options)

    # 3. Inicializa o estado com o exercício 1 (Desenvolvimento de Ombro)
    tecla_ativa = "1"
    lado_ativo = "direito"
    config, orquestrador = inicializar_sessao_exercicio(tecla_ativa)
    alerta_imediato_texto: Optional[str] = None
    ultimo_veredito: Optional[Dict[str, Any]] = None
    score_medio_sessao = 0.0

    cap = cv2.VideoCapture(0)
    if not cap.isOpened():
        print("Erro: Não foi possível aceder à webcam.")
        return

    timestamp_inicial = time.monotonic()

    try:
        while cap.isOpened():
            sucesso, frame = cap.read()
            if not sucesso:
                break

            frame = cv2.flip(frame, 1)
            h, w, _ = frame.shape
            rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

            mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb_frame)
            timestamp_ms = int((time.monotonic() - timestamp_inicial) * 1000)
            resultado = detector.detect_for_video(mp_image, timestamp_ms)

            angulos_atuais: Dict[str, float] = {}
            corpo_visivel = False

            if resultado.pose_landmarks and len(resultado.pose_landmarks) > 0:
                pose_landmarks = resultado.pose_landmarks[0]
                angulos_atuais, corpo_visivel = extrair_angulos_exercicio(
                    landmarks=pose_landmarks,
                    articulacoes=orquestrador.articulacoes,
                    lado=lado_ativo,
                )

                cor_esqueleto = (0, 0, 255) if alerta_imediato_texto else (0, 255, 0)
                desenhar_esqueleto(frame, pose_landmarks, w, h, cor_linha=cor_esqueleto)

            alerta_imediato_texto, resultado_repeticao = processar_frame_webcam(
                orquestrador=orquestrador,
                angulos=angulos_atuais,
                visivel=corpo_visivel,
                alerta_atual=alerta_imediato_texto,
            )
            if resultado_repeticao is not None:
                status = "CORRETA" if resultado_repeticao.aprovado else "INCORRETA"
                ultimo_veredito = {
                    "aprovado": resultado_repeticao.aprovado,
                    "resumo": (
                        f"Rep #{resultado_repeticao.numero_repeticao}: {status} "
                        f"(Score: {resultado_repeticao.score_final:.1f}%) - "
                        f"{resultado_repeticao.feedback_principal}"
                    ),
                }
                score_medio_sessao = orquestrador.gerar_resumo_sessao().score_medio
                print(ultimo_veredito["resumo"])

            # Desenha a interface gráfica (HUD)
            desenhar_painel_hud(
                frame=frame,
                nome_exercicio=config["nome"],
                lado=lado_ativo,
                repeticoes=orquestrador.fsm.repeticoes,
                fase_texto=orquestrador.fsm.nome_fase_atual,
                angulos=angulos_atuais,
                corpo_visivel=corpo_visivel,
                alerta_imediato=alerta_imediato_texto,
                ultimo_veredito=ultimo_veredito,
                score_medio_sessao=score_medio_sessao,
            )

            cv2.imshow("Personal Trainer IA - Avaliacao em Tempo Real", frame)

            # Leitura de comandos do teclado
            tecla = cv2.waitKey(1) & 0xFF
            if tecla == ord("q"):
                break
            elif chr(tecla) in CATALOGO_EXERCICIOS:
                tecla_ativa = chr(tecla)
                config, orquestrador = inicializar_sessao_exercicio(tecla_ativa)
                alerta_imediato_texto = None
                ultimo_veredito = None
                score_medio_sessao = 0.0
            elif tecla == ord("l"):
                lado_ativo = "esquerdo" if lado_ativo == "direito" else "direito"
                orquestrador.referencia_deltas.clear()
            elif tecla == ord("r"):
                orquestrador.reiniciar_serie()
                alerta_imediato_texto = None
                ultimo_veredito = None
                score_medio_sessao = 0.0
    finally:
        cap.release()
        detector.close()
        cv2.destroyAllWindows()


if __name__ == "__main__":
    main()
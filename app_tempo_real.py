"""
Aplicação Principal de Avaliação Biomecânica em Tempo Real (Webcam).
Integra captura OpenCV, MediaPipe Tasks (RunningMode.VIDEO), Máquinas de Estados (FSM),
Buffer de Repetição e Dynamic Time Warping (DTW) para múltiplos exercícios.
"""

import time
from typing import Dict, Any, Optional
import cv2
import mediapipe as mp
from mediapipe.tasks import python
from mediapipe.tasks.python import vision

from calculo_angulos import extrair_angulos_exercicio
from exercicios_fsm import CATALOGO_EXERCICIOS
from buffer_repeticao import BufferRepeticao
from dtw_inicial import DTW
from gabarito import GabaritoExercicio, garantir_gabaritos_padrao
from extrator_video import garantir_modelo_pose

# Conexões e pontos anatómicos para desenho do esqueleto na tela
CONEXOES_CORPO = [
    (11, 12), (11, 23), (12, 24), (23, 24),
    (11, 13), (13, 15), (12, 14), (14, 16),
    (23, 25), (25, 27), (27, 29), (29, 31), (27, 31),
    (24, 26), (26, 28), (28, 30), (30, 32), (28, 32),
]
PONTOS_CORPO = [11, 12, 13, 14, 15, 16, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32]

# Filtro de ruído para evitar falsas transições por tremidas da webcam (em graus)
LIMIAR_MOVIMENTO = 1.2
SCORE_MINIMO_APROVACAO = 70.0


def inicializar_sessao_exercicio(tecla: str):
    """Carrega o gabarito, a FSM e o BufferRepeticao para o exercício selecionado."""
    config = CATALOGO_EXERCICIOS[tecla]
    gabarito = GabaritoExercicio.carregar_json(config["arquivo_gabarito"])
    fsm = config["classe_fsm"]()
    buffer = BufferRepeticao(fsm=fsm, articulacoes=gabarito.articulacoes)
    return config, gabarito, fsm, buffer


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
    ultimo_veredito: Optional[Dict[str, Any]]
):
    """Renderiza o painel informativo superior e o resultado da última repetição."""
    h, w, _ = frame.shape

    # Fundo semitransparente no topo
    overlay = frame.copy()
    cv2.rectangle(overlay, (0, 0), (w, 165), (20, 20, 20), -1)
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

    # Linha 5: Veredito consolidado da última repetição (FSM + DTW)
    if ultimo_veredito:
        cor_veredito = (0, 255, 0) if ultimo_veredito["aprovado"] else (0, 60, 255)
        cv2.putText(
            frame,
            ultimo_veredito["resumo"],
            (12, 148),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.62,
            cor_veredito,
            2,
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
    config, gabarito, fsm, buffer = inicializar_sessao_exercicio(tecla_ativa)
    dtw = DTW(tolerancia=15.0)

    angulos_anteriores: Dict[str, float] = {}
    alerta_imediato_texto: Optional[str] = None
    ultimo_veredito: Optional[Dict[str, Any]] = None

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
                    articulacoes=gabarito.articulacoes,
                    lado=lado_ativo,
                )

                if corpo_visivel:
                    # Calcula os deltas com filtro de ruído (LIMIAR_MOVIMENTO)
                    deltas: Dict[str, float] = {}
                    for art, valor in angulos_atuais.items():
                        if art not in angulos_anteriores:
                            deltas[art] = 0.0
                        else:
                            diff = valor - angulos_anteriores[art]
                            deltas[art] = round(diff, 2) if abs(diff) >= LIMIAR_MOVIMENTO else 0.0
                        angulos_anteriores[art] = valor

                    # Processa o fotograma no Buffer e na Máquina de Estados
                    dados_rep, erro_fsm = buffer.processar_frame(
                        angulos=angulos_atuais,
                        angulos_deltas=deltas,
                    )

                    if erro_fsm:
                        alerta_imediato_texto = fsm.traduzir_erro(erro_fsm)
                    elif fsm.fases[1] == 0:
                        alerta_imediato_texto = None

                    # Se uma repetição acabou de ser concluída, avalia imediatamente com o DTW
                    if dados_rep is not None:
                        _, dist_norm, score, _, desvios = dtw.calcular(
                            serie_a=dados_rep,
                            serie_b=gabarito.dados,
                            nomes_articulacoes=gabarito.articulacoes,
                        )

                        pior_art = max(desvios, key=desvios.get)
                        maior_erro = desvios[pior_art]

                        # Critério de aprovação combinando FSM e DTW
                        aprovado = (erro_fsm is None) and (score >= SCORE_MINIMO_APROVACAO)
                        status_str = "CORRETA" if aprovado else "INCORRETA"

                        if erro_fsm:
                            motivo = fsm.traduzir_erro(erro_fsm)
                        elif maior_erro > 12.0:
                            motivo = f"Ajuste {pior_art.upper()} (desvio {maior_erro:.1f} graus)"
                        else:
                            motivo = "Boa execucao biomecanica!"

                        ultimo_veredito = {
                            "aprovado": aprovado,
                            "resumo": f"Rep #{fsm.repeticoes}: {status_str} (Score: {score:.1f}%) - {motivo}",
                        }
                        print(ultimo_veredito["resumo"])

                cor_esqueleto = (0, 0, 255) if alerta_imediato_texto else (0, 255, 0)
                desenhar_esqueleto(frame, pose_landmarks, w, h, cor_linha=cor_esqueleto)

            # Desenha a interface gráfica (HUD)
            desenhar_painel_hud(
                frame=frame,
                nome_exercicio=config["nome"],
                lado=lado_ativo,
                repeticoes=fsm.repeticoes,
                fase_texto=fsm.nome_fase_atual,
                angulos=angulos_atuais,
                corpo_visivel=corpo_visivel,
                alerta_imediato=alerta_imediato_texto,
                ultimo_veredito=ultimo_veredito,
            )

            cv2.imshow("Personal Trainer IA - Avaliacao em Tempo Real", frame)

            # Leitura de comandos do teclado
            tecla = cv2.waitKey(1) & 0xFF
            if tecla == ord("q"):
                break
            elif chr(tecla) in CATALOGO_EXERCICIOS:
                tecla_ativa = chr(tecla)
                config, gabarito, fsm, buffer = inicializar_sessao_exercicio(tecla_ativa)
                angulos_anteriores.clear()
                alerta_imediato_texto = None
                ultimo_veredito = None
            elif tecla == ord("l"):
                lado_ativo = "esquerdo" if lado_ativo == "direito" else "direito"
                angulos_anteriores.clear()
            elif tecla == ord("r"):
                config, gabarito, fsm, buffer = inicializar_sessao_exercicio(tecla_ativa)
                angulos_anteriores.clear()
                alerta_imediato_texto = None
                ultimo_veredito = None
    finally:
        cap.release()
        detector.close()
        cv2.destroyAllWindows()


if __name__ == "__main__":
    main()
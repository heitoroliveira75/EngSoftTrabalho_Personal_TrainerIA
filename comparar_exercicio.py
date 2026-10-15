"""
Módulo Principal de Comparação de Exercícios

Integra a extração de vídeo, a máquina de estados (FSM) e o DTW
para comparar a execução de um usuário com o gabarito gravado por um especialista.
"""

import sys
import os
import importlib
from typing import Optional, Dict, Any, List
import numpy as np

# Importação dos módulos construídos progressivamente ao longo do projeto
from dtw_inicial import DTW
from gabarito import GabaritoExercicio
from buffer_repeticao import BufferRepeticao
from extrator_video import ExtratorVideo

_dev_modulo = importlib.import_module("dev_ombro-inicial")
DesenvolvimentoOmbro = _dev_modulo.DesenvolvimentoOmbro


def formatar_relatorio(
    num_rep: int,
    score: float,
    erro_normalizado: float,
    desvios_articulacoes: Dict[str, float],
    erro_fsm: Optional[str],
    frames_usuario: int,
    frames_especialista: int
) -> str:
    """
    Gera um laudo textual legível e didático para o usuário pós-repetição.
    """
    linhas = []
    linhas.append("=" * 60)
    linhas.append(f"          RELATÓRIO DE AVALIAÇÃO - REPETIÇÃO #{num_rep}")
    linhas.append("=" * 60)

    # 1. Diagnóstico de Técnica Geral (Score DTW)
    if score >= 85.0:
        classificacao = "[EXCELENTE] Padrão motor muito próximo ao do especialista."
    elif score >= 70.0:
        classificacao = "[BOM] Execução biomecanicamente aceitável, com pequenas divergências."
    else:
        classificacao = "[ATENÇÃO] Movimento divergiu consideravelmente da referência ideal."

    linhas.append(f"\nPontuação Técnica (DTW): {score:.1f}%")
    linhas.append(f"Classificação: {classificacao}")
    linhas.append(f"Desvio Médio Global: {erro_normalizado:.2f}° por frame alinhado")

    # 2. Diagnóstico Imediato da Máquina de Estados (FSM)
    linhas.append("\nStatus Biomecânico Imediato (FSM):")
    if erro_fsm:
        if erro_fsm == "REPETICAO_INCOMPLETA":
            linhas.append("  - [ALERTA] Repetição incompleta: subida interrompida antes do topo.")
        elif erro_fsm == "DESCIDA_EXCESSIVA":
            linhas.append("  - [ALERTA] Descida excessiva: cotovelo desceu abaixo do ângulo seguro (<70°).")
        else:
            linhas.append(f"  - [ALERTA] Erro detectado: {erro_fsm}")
    else:
        linhas.append("  - Todas as transições de fase ocorreram corretamente.")

    # 3. Análise de Cadência e Ritmo
    linhas.append("\nCadência e Duração:")
    linhas.append(f"  - Duração do Aluno: {frames_usuario} frames")
    linhas.append(f"  - Duração do Especialista: {frames_especialista} frames")
    if frames_usuario > frames_especialista * 1.3:
        linhas.append("  - Observação: Sua execução foi mais lenta que o padrão de referência.")
    elif frames_usuario < frames_especialista * 0.7:
        linhas.append("  - Observação: Sua execução foi mais rápida/explosiva que o padrão.")
    else:
        linhas.append("  - Observação: Cadência compatível com o especialista.")

    # 4. Desvios Detalhados por Articulação
    linhas.append("\nAnálise Detalhada por Articulação:")
    pior_articulacao = None
    maior_erro = -1.0

    for art, erro in desvios_articulacoes.items():
        linhas.append(f"  - {art.capitalize()}: desvio médio de {erro:.1f}°")
        if erro > maior_erro:
            maior_erro = erro
            pior_articulacao = art

    if pior_articulacao and maior_erro > 10.0:
        linhas.append(f"\nRecomendação do Personal Trainer IA:")
        linhas.append(f"  -> Preste atenção no alinhamento do seu(sua) {pior_articulacao.upper()}.")
        linhas.append(f"     Foi o ponto com maior divergência ({maior_erro:.1f}°) em relação ao gabarito.")

    linhas.append("=" * 60)
    return "\n".join(linhas)


def extrair_gabarito_de_video(
    caminho_video_especialista: str,
    caminho_json_saida: str = "gabarito_especialista_gerado.json",
    lado: str = "direito"
) -> str:
    """
    Processa o vídeo do especialista com OpenCV + MediaPipe,
    isola a primeira repetição de referência e salva o arquivo JSON.
    """
    print(f"\n[1/2] Extraindo referência do vídeo do especialista: '{caminho_video_especialista}'...")
    extrator = ExtratorVideo(lado=lado)
    frames = extrator.extrair_serie_temporal(caminho_video_especialista)

    if not frames:
        raise ValueError("Não foi possível detectar poses no vídeo do especialista.")

    fsm = DesenvolvimentoOmbro()
    articulacoes = ["cotovelo", "ombro"]
    buffer = BufferRepeticao(fsm=fsm, articulacoes=articulacoes)

    dados_repeticao_especialista = None

    for f in frames:
        dados_rep, _ = buffer.processar_frame(
            angulos=f["angulos"],
            angulos_deltas=f["deltas"]
        )
        if dados_rep is not None:
            dados_repeticao_especialista = dados_rep
            break  # Captura a primeira repetição perfeita

    if dados_repeticao_especialista is None:
        raise ValueError(
            "Nenhuma repetição completa foi detectada no vídeo do especialista. "
            "Certifique-se de que o especialista iniciou em repouso, subiu até o topo e retornou."
        )

    gabarito = GabaritoExercicio(
        nome_exercicio="desenvolvimento_ombro",
        articulacoes=articulacoes,
        dados=dados_repeticao_especialista,
        descricao=f"Gabarito extraído automaticamente do vídeo '{caminho_video_especialista}'."
    )
    gabarito.salvar_json(caminho_json_saida)
    print(f"-> Gabarito do especialista gerado com sucesso ({gabarito.total_frames} frames) em '{caminho_json_saida}'.")
    return caminho_json_saida


def avaliar_video(
    caminho_video_usuario: str,
    caminho_referencia: str = "gabarito_especialista_ombro.json",
    lado: str = "direito"
):
    """
    Processa o vídeo do usuário e compara contra uma referência.
    O parâmetro `caminho_referencia` pode ser tanto um arquivo .json quanto outro vídeo .mp4.
    """
    extensoes_video = (".mp4", ".avi", ".mov", ".mkv")

    # Se a referência passada for outro vídeo, gera o JSON dele primeiro
    if caminho_referencia.lower().endswith(extensoes_video):
        json_gabarito = "gabarito_especialista_gerado.json"
        extrair_gabarito_de_video(caminho_referencia, json_gabarito, lado=lado)
    else:
        json_gabarito = caminho_referencia

    print(f"\n[2/2] Carregando gabarito de referência: '{json_gabarito}'...")
    gabarito = GabaritoExercicio.carregar_json(json_gabarito)

    print(f"Processando vídeo do aluno: '{caminho_video_usuario}'...")
    extrator = ExtratorVideo(lado=lado)
    frames_extraidos = extrator.extrair_serie_temporal(caminho_video_usuario)

    if not frames_extraidos:
        print("[ERRO] Nenhum frame ou pose válida foi detectada no vídeo do usuário.")
        return

    print(f"Total de frames extraídos da gravação do aluno: {len(frames_extraidos)}")

    # Instanciação dos componentes do pipeline
    fsm = DesenvolvimentoOmbro()
    dtw = DTW(tolerancia=15.0)
    buffer = BufferRepeticao(fsm=fsm, articulacoes=gabarito.articulacoes)

    # Itera sobre os frames do vídeo (simulando o tempo real)
    for frame_info in frames_extraidos:
        dados_rep, erro_fsm = buffer.processar_frame(
            angulos=frame_info["angulos"],
            angulos_deltas=frame_info["deltas"]
        )

        # Repetição concluída detectada pela máquina de estados
        if dados_rep is not None:
            _, dist_norm, score, caminho, desvios = dtw.calcular(
                serie_a=dados_rep,
                serie_b=gabarito.dados,
                nomes_articulacoes=gabarito.articulacoes
            )

            relatorio = formatar_relatorio(
                num_rep=fsm.repeticoes,
                score=score,
                erro_normalizado=dist_norm,
                desvios_articulacoes=desvios,
                erro_fsm=erro_fsm,
                frames_usuario=dados_rep.shape[0],
                frames_especialista=gabarito.total_frames
            )
            print("\n" + relatorio)

    if fsm.repeticoes == 0:
        print("\n[INFO] Nenhuma repetição completa foi detectada. Verifique se o exercício foi iniciado e concluído no vídeo.")


def demonstrar_fluxo_simulado():
    """
    Executa uma demonstração pedagógica imediata utilizando o gabarito JSON existente
    e dados simulados, mostrando a saída completa do sistema.
    """
    print("=== Demonstração do Pipeline de Comparação ===")
    gabarito = GabaritoExercicio.carregar_json("gabarito_especialista_ombro.json")

    fsm = DesenvolvimentoOmbro()
    dtw = DTW(tolerancia=15.0)
    buffer = BufferRepeticao(fsm=fsm, articulacoes=gabarito.articulacoes)

    # Simulação da execução de um aluno com ombro deficitário:
    frames_cotovelo = [90, 90, 110, 130, 150, 165, 165, 150, 130, 110, 95, 90]
    frames_ombro =    [80, 80,  90, 100, 115, 125, 125, 115, 100,  90, 85, 80]

    cotovelo_ant = 90.0

    for i in range(len(frames_cotovelo)):
        c = float(frames_cotovelo[i])
        o = float(frames_ombro[i])
        delta_c = c - cotovelo_ant

        dados_rep, erro_fsm = buffer.processar_frame(
            angulos={"cotovelo": c, "ombro": o},
            angulos_deltas={"cotovelo": delta_c, "ombro": 0.0}
        )
        cotovelo_ant = c

        if dados_rep is not None:
            _, dist_norm, score, _, desvios = dtw.calcular(
                serie_a=dados_rep,
                serie_b=gabarito.dados,
                nomes_articulacoes=gabarito.articulacoes
            )

            relatorio = formatar_relatorio(
                num_rep=fsm.repeticoes,
                score=score,
                erro_normalizado=dist_norm,
                desvios_articulacoes=desvios,
                erro_fsm=erro_fsm,
                frames_usuario=dados_rep.shape[0],
                frames_especialista=gabarito.total_frames
            )
            print("\n" + relatorio)


if __name__ == "__main__":
    if len(sys.argv) > 1:
        # Modo execução real:
        # Exemplo 1 (Dois vídeos):  python comparar_exercicio.py video_aluno.mp4 video_especialista.mp4
        # Exemplo 2 (Vídeo + JSON): python comparar_exercicio.py video_aluno.mp4 gabarito_especialista_ombro.json
        video_usuario = sys.argv[1]
        referencia = sys.argv[2] if len(sys.argv) > 2 else "gabarito_especialista_ombro.json"
        avaliar_video(video_usuario, referencia)
    else:
        # Modo demonstração integrado
        demonstrar_fluxo_simulado()

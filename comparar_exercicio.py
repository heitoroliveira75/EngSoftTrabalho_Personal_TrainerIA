"""
Módulo Principal de Comparação de Exercícios

Integra a extração de vídeo, a máquina de estados (FSM) e o DTW
para comparar a execução de um usuário com o gabarito gravado por um especialista.
"""

import argparse
from typing import Optional, Dict

from gabarito import GabaritoExercicio
from extrator_video import ExtratorVideo
from exercicios_fsm import obter_config_exercicio
from avaliador_pontuacao import OrquestradorSessao
from buffer_repeticao import extrair_primeira_repeticao


def formatar_relatorio(
    num_rep: int,
    score: float,
    erro_normalizado: float,
    desvios_articulacoes: Dict[str, float],
    erro_fsm: Optional[str],
    frames_usuario: int,
    frames_especialista: int,
    score_dtw: Optional[float] = None,
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

    linhas.append(f"\nPontuação Final: {score:.1f}%")
    if score_dtw is not None:
        linhas.append(f"Similaridade DTW: {score_dtw:.1f}%")
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
    lado: str = "direito",
    identificador_exercicio: str = "1",
) -> str:
    """
    Processa o vídeo do especialista com OpenCV + MediaPipe,
    isola a primeira repetição de referência e salva o arquivo JSON.
    """
    config = obter_config_exercicio(identificador_exercicio)
    print(f"\n[1/2] Extraindo referência do vídeo do especialista: '{caminho_video_especialista}'...")
    extrator = ExtratorVideo(articulacoes=config["articulacoes"], lado=lado)
    frames = extrator.extrair_serie_temporal(caminho_video_especialista)
    serie_angulos = [frame["angulos"] for frame in frames if frame["visivel"]]
    dados_repeticao_especialista = extrair_primeira_repeticao(
        fsm_ou_id=identificador_exercicio,
        articulacoes=config["articulacoes"],
        serie_angulos=serie_angulos,
        lancar_excecao=True,
    )
    gabarito = GabaritoExercicio(
        nome_exercicio=config["id"],
        articulacoes=config["articulacoes"],
        dados=dados_repeticao_especialista,
        descricao=f"Gabarito extraído automaticamente do vídeo '{caminho_video_especialista}'.",
    )
    gabarito.salvar_json(caminho_json_saida)
    print(f"-> Gabarito do especialista gerado com sucesso ({gabarito.total_frames} frames) em '{caminho_json_saida}'.")
    return caminho_json_saida


def avaliar_video(
    caminho_video_usuario: str,
    caminho_referencia: str = "gabarito_especialista_ombro.json",
    lado: str = "direito",
    identificador_exercicio: str = "1",
):
    """
    Processa o vídeo do usuário e compara contra uma referência.
    O parâmetro `caminho_referencia` pode ser tanto um arquivo .json quanto outro vídeo .mp4.
    """
    extensoes_video = (".mp4", ".avi", ".mov", ".mkv")

    # Se a referência passada for outro vídeo, gera o JSON dele primeiro
    if caminho_referencia.lower().endswith(extensoes_video):
        json_gabarito = "gabarito_especialista_gerado.json"
        extrair_gabarito_de_video(
            caminho_referencia,
            json_gabarito,
            lado=lado,
            identificador_exercicio=identificador_exercicio,
        )
    else:
        json_gabarito = caminho_referencia

    print(f"\n[2/2] Carregando gabarito de referência: '{json_gabarito}'...")
    gabarito = GabaritoExercicio.carregar_json(json_gabarito)

    print(f"Processando vídeo do aluno: '{caminho_video_usuario}'...")
    config = obter_config_exercicio(identificador_exercicio)
    extrator = ExtratorVideo(articulacoes=config["articulacoes"], lado=lado)
    frames_extraidos = extrator.extrair_serie_temporal(caminho_video_usuario)

    if not frames_extraidos:
        print("[ERRO] Nenhum frame ou pose válida foi detectada no vídeo do usuário.")
        return

    print(f"Total de frames extraídos da gravação do aluno: {len(frames_extraidos)}")

    orquestrador = OrquestradorSessao(
        identificador_exercicio=identificador_exercicio,
        gabarito_customizado=gabarito,
    )

    for frame_info in frames_extraidos:
        alerta, resultado = orquestrador.processar_frame(
            angulos=frame_info["angulos"],
            visivel=frame_info["visivel"],
        )
        if resultado is not None:
            dtw = resultado.resultado_dtw
            relatorio = formatar_relatorio(
                num_rep=resultado.numero_repeticao,
                score=resultado.score_final,
                erro_normalizado=dtw.distancia_normalizada if dtw else 0.0,
                desvios_articulacoes=resultado.desvios_por_articulacao,
                erro_fsm=resultado.erros_fsm[0] if resultado.erros_fsm else None,
                frames_usuario=round(resultado.razao_cadencia * gabarito.total_frames),
                frames_especialista=gabarito.total_frames,
                score_dtw=resultado.score_dtw,
            )
            print("\n" + relatorio)
        elif alerta:
            print(f"\r{alerta}", end="", flush=True)

    resumo = orquestrador.gerar_resumo_sessao()
    if resumo.total_repeticoes == 0:
        print("\n[INFO] Nenhuma repetição completa foi detectada. Verifique se o exercício foi iniciado e concluído no vídeo.")
    else:
        print(
            f"\nResumo da sessão: {resumo.total_repeticoes} repetição(ões), "
            f"{resumo.repeticoes_aprovadas} aprovada(s), "
            f"média {resumo.score_medio:.1f}%, recomendação: {resumo.recomendacao_prioritaria}"
        )


def demonstrar_fluxo_simulado():
    """
    Executa uma demonstração pedagógica imediata utilizando o gabarito JSON existente
    e dados simulados, mostrando a saída completa do sistema.
    """
    print("=== Demonstração do Pipeline de Comparação ===")
    config = obter_config_exercicio("1")
    gabarito = GabaritoExercicio.carregar_json(config["arquivo_gabarito"])
    orquestrador = OrquestradorSessao("1", gabarito_customizado=gabarito)

    # Simulação da execução de um aluno com ombro deficitário:
    frames_cotovelo = [90, 90, 110, 130, 150, 165, 165, 150, 130, 110, 95, 90]
    frames_ombro =    [80, 80,  90, 100, 115, 125, 125, 115, 100,  90, 85, 80]

    for i in range(len(frames_cotovelo)):
        c = float(frames_cotovelo[i])
        o = float(frames_ombro[i])
        _, resultado = orquestrador.processar_frame(
            angulos={"cotovelo": c, "ombro": o},
            visivel=True,
        )

        if resultado is not None:
            dtw = resultado.resultado_dtw
            relatorio = formatar_relatorio(
                num_rep=resultado.numero_repeticao,
                score=resultado.score_final,
                erro_normalizado=dtw.distancia_normalizada if dtw else 0.0,
                desvios_articulacoes=resultado.desvios_por_articulacao,
                erro_fsm=resultado.erros_fsm[0] if resultado.erros_fsm else None,
                frames_usuario=round(resultado.razao_cadencia * gabarito.total_frames),
                frames_especialista=gabarito.total_frames,
                score_dtw=resultado.score_dtw,
            )
            print("\n" + relatorio)

    resumo = orquestrador.gerar_resumo_sessao()
    print(f"\nResumo da sessão: {resumo.total_repeticoes} repetição(ões), média {resumo.score_medio:.1f}%.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Compara vídeo de exercício com o gabarito do especialista.")
    parser.add_argument("video_usuario", nargs="?", help="Caminho do vídeo do praticante")
    parser.add_argument("referencia", nargs="?", default=None, help="Arquivo JSON ou vídeo de referência")
    parser.add_argument("--exercicio", default="1", help="ID ou tecla do exercício no catálogo")
    parser.add_argument("--lado", default="direito", choices=["direito", "esquerdo"])
    args = parser.parse_args()

    if args.video_usuario:
        config = obter_config_exercicio(args.exercicio)
        referencia = args.referencia or config["arquivo_gabarito"]
        avaliar_video(
            args.video_usuario,
            referencia,
            lado=args.lado,
            identificador_exercicio=args.exercicio,
        )
    else:
        demonstrar_fluxo_simulado()

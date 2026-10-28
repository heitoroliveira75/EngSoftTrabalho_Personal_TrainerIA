"""
Módulo de Treinamento da IA a partir de um Dataset de Vídeos.
Lê diversos vídeos de pessoas executando os exercícios corretamente,
aprende a curva média ideal (Gabarito Consenso) e treina um modelo de
Machine Learning (.pkl via joblib) para classificar execuções futuras.
"""

import argparse
import os
from typing import List, Dict, Any, Tuple
import joblib
import numpy as np
from sklearn.ensemble import RandomForestClassifier

from exercicios_fsm import CATALOGO_EXERCICIOS
from buffer_repeticao import BufferRepeticao
from dtw_inicial import DTW
from gabarito import GabaritoExercicio
from extrator_video import ExtratorVideo

EXTENSOES_VIDEO = (".mp4", ".avi", ".mov", ".mkv")
PASTA_DATASET_PADRAO = "dataset"
PASTA_MODELOS_PADRAO = "modelos_treinados"
FRAMES_NORMALIZADOS = 40


def localizar_videos(caminho_pasta: str) -> List[str]:
    """Localiza recursivamente todos os vídeos dentro de uma pasta."""
    if not os.path.exists(caminho_pasta):
        return []
    candidatos = [
        os.path.join(raiz, nome)
        for raiz, _, arquivos in os.walk(caminho_pasta)
        for nome in arquivos
    ]
    return sorted(
        caminho
        for caminho in candidatos
        if os.path.splitext(caminho)[1].lower() in EXTENSOES_VIDEO
    )


def normalizar_serie_temporal(matriz_rep: np.ndarray, num_frames: int = FRAMES_NORMALIZADOS) -> np.ndarray:
    """
    Redimensiona uma repetição de tamanho (T x D) para um tamanho fixo (num_frames x D)
    via interpolação linear, permitindo calcular a média entre várias pessoas.
    """
    t_original, dims = matriz_rep.shape
    x_original = np.linspace(0.0, 1.0, t_original)
    x_novo = np.linspace(0.0, 1.0, num_frames)

    matriz_normalizada = np.zeros((num_frames, dims), dtype=float)
    for d in range(dims):
        matriz_normalizada[:, d] = np.interp(x_novo, x_original, matriz_rep[:, d])

    return matriz_normalizada


def extrair_features_biomecanicas(
    matriz_rep: np.ndarray,
    curva_consenso: np.ndarray,
    articulacoes: List[str],
    dtw_avaliador: DTW
) -> Tuple[List[float], Dict[str, Any]]:
    """
    Extrai o vetor numérico de características da repetição para alimentar a IA:
    - Para cada articulação: [angulo_min, angulo_max, amplitude_variacao, desvio_dtw]
    - Global: [erro_normalizado_dtw, score_dtw]
    """
    _, dist_norm, score, _, desvios = dtw_avaliador.calcular(
        serie_a=matriz_rep,
        serie_b=curva_consenso,
        nomes_articulacoes=articulacoes,
    )

    vetor_features: List[float] = []
    resumo_dict: Dict[str, Any] = {}

    for idx, nome_art in enumerate(articulacoes):
        coluna = matriz_rep[:, idx]
        ang_min = float(np.min(coluna))
        ang_max = float(np.max(coluna))
        variacao = float(ang_max - ang_min)
        desvio_art = float(desvios[nome_art])

        vetor_features.extend([ang_min, ang_max, variacao, desvio_art])
        resumo_dict[f"{nome_art}_min"] = round(ang_min, 1)
        resumo_dict[f"{nome_art}_max"] = round(ang_max, 1)
        resumo_dict[f"{nome_art}_variacao"] = round(variacao, 1)
        resumo_dict[f"{nome_art}_desvio_dtw"] = round(desvio_art, 1)

    vetor_features.extend([float(dist_norm), float(score)])
    resumo_dict["dtw_erro_norm"] = round(float(dist_norm), 2)
    resumo_dict["dtw_score"] = round(float(score), 1)

    return vetor_features, resumo_dict


def gerar_exemplos_incorretos_sinteticos(
    repeticoes_corretas: List[np.ndarray],
    rng: np.random.Generator
) -> List[np.ndarray]:
    """
    A partir das repetições corretas do dataset, gera variações biomecânicas
    incorretas (repetições curtas/incompletas, excesso de descida, articulação
    travada ou assimétrica) para ensinar à IA o limite entre CERTO (1) e ERRADO (0).
    """
    incorretas: List[np.ndarray] = []

    for rep in repeticoes_corretas:
        # Erro 1: Amplitude reduzida (movimento incompleto / "roubado" em 45% a 65%)
        media = np.mean(rep, axis=0)
        fator_curto = rng.uniform(0.40, 0.65)
        rep_curta = media + (rep - media) * fator_curto
        incorretas.append(rep_curta)

        # Erro 2: Desalinhamento severo numa das articulações (+25° a +45° de erro)
        rep_desalinhada = rep.copy()
        col_erro = rng.integers(0, rep.shape[1])
        deslocamento = rng.choice([-1.0, 1.0]) * rng.uniform(25.0, 45.0)
        rep_desalinhada[:, col_erro] = np.clip(rep_desalinhada[:, col_erro] + deslocamento, 10.0, 180.0)
        incorretas.append(rep_desalinhada)

        # Erro 3: Movimento trêmulo / perda de controle motor
        ruido_alto = rng.normal(0.0, 22.0, size=rep.shape)
        rep_instavel = np.clip(rep + ruido_alto, 10.0, 180.0)
        incorretas.append(rep_instavel)

    return incorretas


def simular_repeticoes_dataset(id_exercicio: str, qtd: int = 25) -> List[np.ndarray]:
    """Gera repetições corretas variadas caso o usuário queira testar sem vídeos na pasta."""
    rng = np.random.default_rng(42)
    repeticoes: List[np.ndarray] = []

    for _ in range(qtd):
        n_frames = int(rng.integers(30, 55))
        t = np.linspace(0, np.pi, n_frames)

        if id_exercicio == "desenvolvimento_ombro":
            base_c, amp_c = rng.normal(90.0, 3.0), rng.normal(75.0, 4.0)
            base_o, amp_o = rng.normal(80.0, 3.0), rng.normal(75.0, 4.0)
            c = base_c + amp_c * np.sin(t) + rng.normal(0, 1.5, n_frames)
            o = base_o + amp_o * np.sin(t) + rng.normal(0, 1.5, n_frames)
            repeticoes.append(np.column_stack((c, o)))

        elif id_exercicio == "agachamento":
            base_j, amp_j = rng.normal(170.0, 3.0), rng.normal(80.0, 4.0)
            base_q, amp_q = rng.normal(170.0, 3.0), rng.normal(85.0, 4.0)
            j = base_j - amp_j * np.sin(t) + rng.normal(0, 1.5, n_frames)
            q = base_q - amp_q * np.sin(t) + rng.normal(0, 1.5, n_frames)
            repeticoes.append(np.column_stack((j, q)))

        elif id_exercicio == "rosca_biceps":
            base_c, amp_c = rng.normal(165.0, 3.0), rng.normal(115.0, 4.0)
            base_o, amp_o = rng.normal(15.0, 2.0), rng.normal(5.0, 1.5)
            c = base_c - amp_c * np.sin(t) + rng.normal(0, 1.5, n_frames)
            o = base_o + amp_o * np.sin(t) + rng.normal(0, 1.0, n_frames)
            repeticoes.append(np.column_stack((c, o)))

    return repeticoes


def treinar_exercicio(
    config_exercicio: Dict[str, Any],
    pasta_dataset: str,
    pasta_modelos: str,
    lado: str = "direito",
    usar_simulacao: bool = False
) -> None:
    id_ex = config_exercicio["id"]
    nome_ex = config_exercicio["nome"]
    articulacoes = config_exercicio["articulacoes"]
    classe_fsm = config_exercicio["classe_fsm"]

    caminho_ex_dataset = os.path.join(pasta_dataset, id_ex)
    os.makedirs(caminho_ex_dataset, exist_ok=True)
    os.makedirs(pasta_modelos, exist_ok=True)

    videos = localizar_videos(caminho_ex_dataset)
    repeticoes_corretas: List[np.ndarray] = []

    print(f"\n============================================================")
    print(f"Treinando Exercício: {nome_ex} ({id_ex})")
    print(f"============================================================")

    if videos:
        print(f"Encontrados {len(videos)} vídeos em '{caminho_ex_dataset}'. Extraindo repetições...")
        extrator = ExtratorVideo(articulacoes=articulacoes, lado=lado)

        for caminho_video in videos:
            nome_arq = os.path.basename(caminho_video)
            frames = extrator.extrair_serie_temporal(caminho_video)
            fsm = classe_fsm()
            buffer = BufferRepeticao(fsm=fsm, articulacoes=articulacoes)

            reps_video = 0
            for f in frames:
                dados_rep, erro_fsm = buffer.processar_frame(
                    angulos=f["angulos"],
                    angulos_deltas=f["deltas"]
                )
                # Só adiciona ao aprendizado repetições completas e sem erro grosseiro
                if dados_rep is not None and erro_fsm is None:
                    repeticoes_corretas.append(dados_rep)
                    reps_video += 1

            print(f"  -> Vídeo '{nome_arq}': {reps_video} repetição(ões) válida(s) extraída(s).")

    if not repeticoes_corretas:
        if usar_simulacao:
            print(f"Nenhum vídeo em '{caminho_ex_dataset}'. Gerando dataset simulado de 25 execuções corretas...")
            repeticoes_corretas = simular_repeticoes_dataset(id_ex, qtd=25)
        else:
            print(
                f"[AVISO] Nenhuma repetição encontrada em '{caminho_ex_dataset}'. "
                f"Coloque vídeos .mp4/.avi nessa pasta ou execute com --simular."
            )
            return

    # 1. Calcula o Gabarito Consenso (Média de todas as execuções corretas do dataset)
    reps_normalizadas = np.array([normalizar_serie_temporal(r) for r in repeticoes_corretas])
    curva_consenso = np.mean(reps_normalizadas, axis=0)
    desvio_padrao_curva = np.std(reps_normalizadas, axis=0)

    caminho_gabarito = os.path.join(pasta_modelos, f"gabarito_aprendido_{id_ex}.json")
    gabarito = GabaritoExercicio(
        nome_exercicio=id_ex,
        articulacoes=articulacoes,
        dados=curva_consenso,
        descricao=f"Curva média aprendida pela IA a partir de {len(repeticoes_corretas)} repetições corretas.",
    )
    gabarito.salvar_json(caminho_gabarito)

    # 2. Prepara os dados de treino da IA (Positivos do Dataset vs Negativos Biomecânicos)
    dtw_avaliador = DTW(tolerancia=15.0)
    rng = np.random.default_rng(42)

    # Aumenta levemente as amostras corretas caso o dataset tenha poucos vídeos
    amostras_positivas = list(repeticoes_corretas)
    while len(amostras_positivas) < 20:
        base = repeticoes_corretas[rng.integers(0, len(repeticoes_corretas))]
        ruido_leve = rng.normal(0.0, 2.0, size=base.shape)
        amostras_positivas.append(base + ruido_leve)

    amostras_negativas = gerar_exemplos_incorretos_sinteticos(amostras_positivas, rng)

    X_treino: List[List[float]] = []
    y_treino: List[int] = []

    for rep_ok in amostras_positivas:
        feats, _ = extrair_features_biomecanicas(rep_ok, curva_consenso, articulacoes, dtw_avaliador)
        X_treino.append(feats)
        y_treino.append(1)  # 1 = CORRETO

    for rep_err in amostras_negativas:
        feats, _ = extrair_features_biomecanicas(rep_err, curva_consenso, articulacoes, dtw_avaliador)
        X_treino.append(feats)
        y_treino.append(0)  # 0 = INCORRETO

    # 3. Treina o classificador RandomForest e salva o pacote completo via joblib
    modelo_clf = RandomForestClassifier(n_estimators=150, max_depth=8, random_state=42)
    modelo_clf.fit(X_treino, y_treino)

    pacote_ia = {
        "id_exercicio": id_ex,
        "nome_exercicio": nome_ex,
        "articulacoes": articulacoes,
        "modelo_classificador": modelo_clf,
        "curva_consenso": curva_consenso,
        "desvio_padrao_curva": desvio_padrao_curva,
        "total_repeticoes_aprendidas": len(repeticoes_corretas),
    }

    caminho_pkl = os.path.join(pasta_modelos, f"modelo_ia_{id_ex}.pkl")
    joblib.dump(pacote_ia, caminho_pkl)

    print(f"[SUCESSO] Padrão aprendido com {len(repeticoes_corretas)} repetições reais!")
    print(f"  -> Gabarito Consenso salvo em: '{caminho_gabarito}'")
    print(f"  -> Modelo de IA salvo em:      '{caminho_pkl}'")


def main():
    parser = argparse.ArgumentParser(
        description="Lê o dataset de vídeos de exercícios corretos e treina os modelos de IA."
    )
    parser.add_argument(
        "--dataset",
        default=PASTA_DATASET_PADRAO,
        help="Pasta raiz contendo as subpastas de cada exercício (padrão: dataset)",
    )
    parser.add_argument(
        "--modelos",
        default=PASTA_MODELOS_PADRAO,
        help="Pasta onde os modelos .pkl e gabaritos .json aprendidos serão salvos",
    )
    parser.add_argument(
        "--lado",
        default="direito",
        choices=["direito", "esquerdo"],
        help="Lado do corpo predominante nos vídeos do dataset",
    )
    parser.add_argument(
        "--simular",
        action="store_true",
        help="Se ativado, gera dados simulados para exercícios que ainda não tenham vídeos na pasta dataset/",
    )
    args = parser.parse_args()

    for tecla, config in CATALOGO_EXERCICIOS.items():
        treinar_exercicio(
            config_exercicio=config,
            pasta_dataset=args.dataset,
            pasta_modelos=args.modelos,
            lado=args.lado,
            usar_simulacao=args.simular,
        )


if __name__ == "__main__":
    main()
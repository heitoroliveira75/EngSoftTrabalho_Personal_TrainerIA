"""
Suíte de Testes Automatizados — Pipeline de Avaliação Biomecânica e Pontuação.
Cobre cálculo geométrico, deltas angulares, FSMs, segmentação, DTW e orquestração.
"""

import pytest
import numpy as np
import sys
from pathlib import Path
_DIR_CODIGOS = Path(__file__).resolve().parent.parent / "Códigos"
if str(_DIR_CODIGOS) not in sys.path:
    sys.path.insert(0, str(_DIR_CODIGOS))
from typing import Optional, List, Dict, Any
from types import ModuleType, SimpleNamespace
from calculo_angulos import calcular_angulo, calcular_angulo_orientado, calcular_deltas_angulares
from exercicios_fsm import ExercicioBaseFSM
from buffer_repeticao import BufferRepeticao


class TestCalculoAngulos:
    def test_calcular_angulo_perpendicular(self):
        # Triângulo retângulo: A=(0, 1), B=(0, 0), C=(1, 0) -> 90 graus
        ang = calcular_angulo((0, 1), (0, 0), (1, 0))
        assert pytest.approx(ang, rel=1e-2) == 90.0

    def test_calcular_angulo_linha_reta(self):
        # Linha reta: A=(-1, 0), B=(0, 0), C=(1, 0) -> 180 graus
        ang = calcular_angulo((-1, 0), (0, 0), (1, 0))
        assert pytest.approx(ang, rel=1e-2) == 180.0

    def test_calcular_angulo_orientado_sinais(self):
        # Sentido anti-horário: BA=(1, 0) -> BC=(0, 1) produz ângulo positivo (+90 graus)
        ang_pos = calcular_angulo_orientado((1, 0), (0, 0), (0, 1))
        assert pytest.approx(ang_pos, rel=1e-2) == 90.0

        # Sentido horário: BA=(0, 1) -> BC=(1, 0) produz ângulo negativo (-90 graus)
        ang_neg = calcular_angulo_orientado((0, 1), (0, 0), (1, 0))
        assert pytest.approx(ang_neg, rel=1e-2) == -90.0

        # Retrocompatibilidade: calcular_angulo sem sinal retorna magnitude positiva
        assert pytest.approx(calcular_angulo((1, 0), (0, 0), (0, 1)), rel=1e-2) == 90.0
        assert pytest.approx(calcular_angulo((0, 1), (0, 0), (1, 0)), rel=1e-2) == 90.0

    def test_calcular_deltas_inicializacao(self):
        referencia = {}
        angulos = {"cotovelo": 90.0, "ombro": 80.0}
        deltas = calcular_deltas_angulares(angulos, referencia, limiar_graus=1.2)

        assert deltas == {"cotovelo": 0.0, "ombro": 0.0}
        assert referencia["cotovelo"] == 90.0
        assert referencia["ombro"] == 80.0

    def test_calcular_deltas_rejeicao_jitter(self):
        referencia = {"cotovelo": 90.0}
        # Variação menor que o limiar de 1.2 graus
        deltas = calcular_deltas_angulares({"cotovelo": 90.8}, referencia, limiar_graus=1.2)

        assert deltas["cotovelo"] == 0.0
        # A âncora de referência NÃO deve ser alterada com ruído
        assert referencia["cotovelo"] == 90.0

    def test_calcular_deltas_movimento_lento_acumulado(self):
        """
        Em movimentos lentos (ex.: subida gradual de 0.5 graus por fotograma),
        a âncora deve manter o valor anterior até que a soma alcance o limiar,
        evitando que a variação seja zerada e perdida permanentemente.
        """
        referencia = {"cotovelo": 100.0}

        # Fotograma 1: +0.5 graus (total 100.5, diff=0.5 < 1.2)
        d1 = calcular_deltas_angulares({"cotovelo": 100.5}, referencia, limiar_graus=1.2)
        assert d1["cotovelo"] == 0.0
        assert referencia["cotovelo"] == 100.0

        # Fotograma 2: +0.5 graus (total 101.0, diff=1.0 < 1.2)
        d2 = calcular_deltas_angulares({"cotovelo": 101.0}, referencia, limiar_graus=1.2)
        assert d2["cotovelo"] == 0.0
        assert referencia["cotovelo"] == 100.0

        # Fotograma 3: +0.5 graus (total 101.5, diff=1.5 >= 1.2) -> Detecta movimento!
        d3 = calcular_deltas_angulares({"cotovelo": 101.5}, referencia, limiar_graus=1.2)
        assert d3["cotovelo"] == 1.5
        assert referencia["cotovelo"] == 101.5


def test_extrair_serie_temporal_retorna_angulos_e_visibilidade_sem_deltas(monkeypatch, request, capsys):
    cv2_fake = ModuleType("cv2")
    cv2_fake.COLOR_BGR2RGB = 1

    mediapipe_fake = ModuleType("mediapipe")
    mediapipe_fake.__path__ = []
    mediapipe_fake.ImageFormat = SimpleNamespace(SRGB=1)
    mediapipe_fake.Image = lambda **_kwargs: object()

    tasks_fake = ModuleType("mediapipe.tasks")
    tasks_fake.__path__ = []
    python_fake = ModuleType("mediapipe.tasks.python")
    python_fake.BaseOptions = lambda **_kwargs: object()
    vision_fake = ModuleType("mediapipe.tasks.python.vision")
    tasks_fake.python = python_fake
    mediapipe_fake.tasks = tasks_fake
    python_fake.vision = vision_fake

    monkeypatch.setitem(sys.modules, "cv2", cv2_fake)
    monkeypatch.setitem(sys.modules, "mediapipe", mediapipe_fake)
    monkeypatch.setitem(sys.modules, "mediapipe.tasks", tasks_fake)
    monkeypatch.setitem(sys.modules, "mediapipe.tasks.python", python_fake)
    monkeypatch.setitem(sys.modules, "mediapipe.tasks.python.vision", vision_fake)

    import extrator_video
    request.addfinalizer(lambda: sys.modules.pop("extrator_video", None))

    class CapturaFake:
        def __init__(self):
            self.frames = [object(), object()]

        def isOpened(self):
            return bool(self.frames)

        def read(self):
            if not self.frames:
                return False, None
            return True, self.frames.pop(0)

        def release(self):
            pass

    class DetectorFake:
        def __init__(self):
            self.resultados = [
                SimpleNamespace(pose_landmarks=[[object()]]),
                SimpleNamespace(pose_landmarks=[]),
            ]

        def detect(self, _imagem):
            return self.resultados.pop(0)

    cv2_fake.VideoCapture = lambda _caminho: CapturaFake()
    cv2_fake.cvtColor = lambda frame, _codigo: frame
    monkeypatch.setattr(
        extrator_video,
        "extrair_angulos_exercicio",
        lambda **_kwargs: ({"cotovelo": 90.0}, False),
    )

    extrator = extrator_video.ExtratorVideo.__new__(extrator_video.ExtratorVideo)
    extrator.articulacoes = ["cotovelo"]
    extrator.lado = "direito"
    extrator.detector = DetectorFake()

    frames = extrator.extrair_serie_temporal("video-teste.mp4")

    assert frames == [{
        "frame": 0,
        "angulos": {"cotovelo": 90.0},
        "visivel": False,
    }]

    import comparar_exercicio

    comparar_exercicio.demonstrar_fluxo_simulado()
    assert "Resumo da sessão:" in capsys.readouterr().out



from exercicios_fsm import (
    DesenvolvimentoOmbro,
    Agachamento,
    RoscaBiceps,
    ElevacaoLateral,
    TricepsCorda,
    FlexaoDiamante,
    RemadaBaixa,
    obter_config_exercicio,
)


class TestExerciciosFSM:
    def test_histerese_rejeita_ruido_estatico_no_repouso(self):
        """[TASK-CORR.04] Garante que ruído estático no repouso não faz a FSM sair da fase 0."""
        fsm = DesenvolvimentoOmbro()
        pos = {}
        for val in [89.0, 91.0, 92.5, 91.0, 89.5, 90.5]:
            fsm.classificar({"cotovelo": val, "ombro": 80.0}, pos, {"cotovelo": 0.8})
            assert fsm.fases[1] == 0
            assert fsm.repeticoes == 0
            assert fsm.erros == []

    def test_histerese_recupera_para_repouso_sem_erro_se_movimento_mal_iniciou(self):
        """[TASK-CORR.04] Se o usuário subiu apenas 3 graus além do limiar e voltou, não acusa incompleto."""
        fsm = DesenvolvimentoOmbro()
        pos = {}
        fsm.classificar({"cotovelo": 105.0, "ombro": 80.0}, pos, {"cotovelo": 2.5})
        assert fsm.fases[1] == 1
        erro = fsm.classificar({"cotovelo": 100.0, "ombro": 80.0}, pos, {"cotovelo": -3.0})
        assert fsm.fases[1] == 0
        assert erro is None
        assert fsm.repeticoes == 0
        assert fsm.erros == []

    def test_histerese_todas_as_7_fsms_imunes_a_ruido_estatico(self):
        """[TASK-CORR.04] Valida que nenhuma das 7 FSMs acumula repetições falsas sob ruído estático."""
        casos = [
            (DesenvolvimentoOmbro, {"cotovelo": 90.0, "ombro": 80.0}, "cotovelo"),
            (Agachamento, {"joelho": 175.0, "quadril": 170.0}, "joelho"),
            (RoscaBiceps, {"cotovelo": 165.0, "ombro": 15.0}, "cotovelo"),
            (ElevacaoLateral, {"ombro": 25.0, "cotovelo": 160.0}, "ombro"),
            (TricepsCorda, {"cotovelo": 80.0, "ombro": 15.0}, "cotovelo"),
            (FlexaoDiamante, {"cotovelo": 160.0, "ombro": 50.0}, "cotovelo"),
            (RemadaBaixa, {"cotovelo": 160.0, "ombro": 30.0, "quadril": 90.0}, "cotovelo"),
        ]

        for classe_fsm, pose_base, art_principal in casos:
            fsm = classe_fsm()
            val_base = pose_base[art_principal]
            for i in range(25):
                ruido = float(np.sin(i * 1.5) * 2.0)
                pose_frame = dict(pose_base)
                pose_frame[art_principal] = val_base + ruido
                fsm.classificar(pose_frame, {}, {art_principal: float(ruido * 0.4)})
                assert fsm.repeticoes == 0, f"FSM {classe_fsm.__name__} contou repetição indevida com ruído!"

    def test_desenvolvimento_ombro_ciclo_ideal(self):
        fsm = DesenvolvimentoOmbro()
        pos = {}

        # Fase 0: Repouso
        assert fsm.fases[1] == 0

        # Transição 0 -> 1 (Subindo)
        fsm.classificar({"cotovelo": 110.0, "ombro": 85.0}, pos, {"cotovelo": 10.0})
        assert fsm.fases[1] == 1

        # Transição 1 -> 2 (Topo)
        fsm.classificar({"cotovelo": 160.0, "ombro": 140.0}, pos, {"cotovelo": 15.0})
        assert fsm.fases[1] == 2

        # Transição 2 -> 3 (Descendo)
        fsm.classificar({"cotovelo": 135.0, "ombro": 110.0}, pos, {"cotovelo": -10.0})
        assert fsm.fases[1] == 3

        # Transição 3 -> 0 (Retorno / Repeticao concluída)
        fsm.classificar({"cotovelo": 95.0, "ombro": 80.0}, pos, {"cotovelo": -10.0})
        assert fsm.fases[1] == 0
        assert fsm.repeticoes == 1
        assert fsm.consumir_erros_repeticao() == []

    def test_desenvolvimento_ombro_incompleto(self):
        fsm = DesenvolvimentoOmbro()
        pos = {}

        # Fase 0 -> 1
        fsm.classificar({"cotovelo": 110.0, "ombro": 85.0}, pos, {"cotovelo": 10.0})
        assert fsm.fases[1] == 1

        # Transição anômala 1 -> 3 (subida interrompida antes do topo)
        erro = fsm.classificar({"cotovelo": 120.0, "ombro": 85.0}, pos, {"cotovelo": -5.0})
        assert fsm.fases[1] == 3
        assert erro == "REPETICAO_INCOMPLETA"
        assert "REPETICAO_INCOMPLETA" in fsm.consumir_erros_repeticao()

    def test_desenvolvimento_ombro_retencao_erro_postural(self):
        fsm = DesenvolvimentoOmbro()
        pos = {}

        # 0 -> 1
        fsm.classificar({"cotovelo": 110.0, "ombro": 85.0}, pos, {"cotovelo": 10.0})
        # 1 -> 2 com ombro caído (< 60 graus)
        erro = fsm.classificar({"cotovelo": 160.0, "ombro": 50.0}, pos, {"cotovelo": 10.0})
        assert erro == "OMBRO_CAIDO"

        # 2 -> 3 corrigindo postura
        fsm.classificar({"cotovelo": 130.0, "ombro": 75.0}, pos, {"cotovelo": -10.0})

        # 3 -> 0 finalizando repetição
        fsm.classificar({"cotovelo": 90.0, "ombro": 75.0}, pos, {"cotovelo": -10.0})
        assert fsm.repeticoes == 1

        # O erro postural transiente NÃO pode ser esquecido ao fechar a repetição
        erros_rep = fsm.consumir_erros_repeticao()
        assert "OMBRO_CAIDO" in erros_rep
        # Após consumir, o acumulador da repetição deve estar vazio
        assert fsm.consumir_erros_repeticao() == []

    def test_obter_config_exercicio(self):
        conf_chave = obter_config_exercicio("1")
        assert conf_chave["id"] == "desenvolvimento_ombro"

        conf_id = obter_config_exercicio("agachamento")
        assert conf_id["nome"] == "Agachamento Livre"

        with pytest.raises(ValueError):
            obter_config_exercicio("inexistente")



from dtw_evaluator import DTWComparator, DTWResult, DTW
from buffer_repeticao import extrair_primeira_repeticao
from gabarito import GabaritoExercicio, garantir_gabaritos_padrao
from avaliador_pontuacao import (
    calcular_pontuacao,
    OrquestradorSessao,
    ResultadoPontuacaoRepeticao,
    ResumoPontuacaoSessao,
)
from exemplo_integracao import (
    criar_frames_movimento_completo,
    criar_frames_movimento_incompleto,
    executar_sessao,
)



class TestDTWEvaluator:
    def test_dtw_series_identicas(self):
        t = np.linspace(0, np.pi, 30)
        serie = np.column_stack((90.0 + 75.0 * np.sin(t), 80.0 + 75.0 * np.sin(t)))

        dtw = DTWComparator(tolerancia=15.0)
        res = dtw.compute(serie, serie, nomes_articulacoes=["cotovelo", "ombro"])

        assert isinstance(res, DTWResult)
        assert res.valido is True
        assert pytest.approx(res.distancia_total, abs=1e-3) == 0.0
        assert pytest.approx(res.distancia_normalizada, abs=1e-3) == 0.0
        assert res.score_similaridade == 100.0
        assert res.desvios_por_articulacao == {"cotovelo": 0.0, "ombro": 0.0}
        assert len(res.caminho) == 30

    def test_dtw_invariancia_temporal_cadencia(self):
        # Mesma curva motora percorrida em velocidades diferentes (25 frames vs 50 frames)
        t_rapido = np.linspace(0, np.pi, 25)
        t_lento = np.linspace(0, np.pi, 50)
        serie_rapida = 90.0 + 75.0 * np.sin(t_rapido)
        serie_lenta = 90.0 + 75.0 * np.sin(t_lento)

        dtw = DTWComparator(tolerancia=15.0)
        res = dtw.compute(serie_rapida, serie_lenta)

        assert res.valido is True
        # Conforme Critério AC2 do PLANO_SPRINT_US01: cadência lenta mantém score >= 85.0%
        assert res.score_similaridade >= 85.0
        assert res.distancia_normalizada < 2.0

    def test_dtw_multivariado_com_nomes(self):
        # Valida mapeamento nominal e cálculo exato de desvios médios por articulação
        aluno = np.column_stack((np.full(25, 90.0), np.full(25, 90.0)))
        gabarito = np.column_stack((np.full(25, 90.0), np.full(25, 80.0)))

        dtw = DTWComparator(tolerancia=15.0)
        res = dtw.compute(aluno, gabarito, nomes_articulacoes=["cotovelo", "ombro"])

        assert res.valido is True
        assert set(res.desvios_por_articulacao.keys()) == {"cotovelo", "ombro"}
        assert pytest.approx(res.desvios_por_articulacao["cotovelo"], abs=1e-2) == 0.0
        assert pytest.approx(res.desvios_por_articulacao["ombro"], abs=1e-2) == 10.0

    def test_dtw_desempacotamento_tupla_e_indexacao(self):
        dtw = DTWComparator(tolerancia=15.0)
        t = np.linspace(0, np.pi, 20)
        serie = 90.0 + 50.0 * np.sin(t)
        res = dtw.compute(serie, serie)

        # 1. Desempacotamento de 5 elementos compatível com legado
        d_tot, d_norm, score, caminho, desvios = res
        assert d_tot == res.distancia_total
        assert d_norm == res.distancia_normalizada
        assert score == res.score_similaridade
        assert caminho == res.caminho
        assert desvios == res.desvios_por_articulacao

        # 2. Indexação posicional (resultado[2] -> score)
        assert res[2] == res.score_similaridade

    def test_dtw_restricao_sakoe_chiba(self):
        t = np.linspace(0, np.pi, 30)
        serie_a = 90.0 + 60.0 * np.sin(t)
        serie_b = 90.0 + 55.0 * np.sin(t)

        # Teste com janela percentual relativa (0.20 = 20%)
        dtw_rel = DTWComparator(janela=0.20)
        res_rel = dtw_rel.compute(serie_a, serie_b)
        assert res_rel.valido is True
        assert res_rel.score_similaridade >= 85.0

        # Teste com janela absoluta em frames (janela = 5)
        dtw_abs = DTWComparator(janela=5)
        res_abs = dtw_abs.compute(serie_a, serie_b)
        assert res_abs.valido is True

    def test_dtw_degradacao_graciosa_vs_excecao(self):
        dtw = DTWComparator()
        serie_valida = [[10.0, 20.0], [15.0, 25.0], [20.0, 30.0], [25.0, 35.0]]
        serie_curta = [[10.0, 20.0]]  # Apenas 1 frame (< 3)
        serie_dim_incompativel = [[10.0, 20.0, 30.0], [15.0, 25.0, 35.0], [20.0, 30.0, 40.0]]

        # 1. Comprimento insuficiente - Degradação Graciosa (padrão)
        res_curta = dtw.compute(serie_valida, serie_curta)
        assert res_curta.valido is False
        assert res_curta.score_similaridade == 0.0
        assert "comprimento insuficiente" in res_curta.mensagem_erro.lower()

        # 2. Dimensões incompatíveis - Degradação Graciosa
        res_dim = dtw.compute(serie_valida, serie_dim_incompativel)
        assert res_dim.valido is False
        assert res_dim.score_similaridade == 0.0
        assert "dimensões incompatíveis" in res_dim.mensagem_erro.lower()

        # 3. Com lancar_excecao=True deve disparar ValueError
        with pytest.raises(ValueError, match="comprimento insuficiente"):
            dtw.compute(serie_valida, serie_curta, lancar_excecao=True)

        with pytest.raises(ValueError, match="Dimensões incompatíveis"):
            dtw.compute(serie_valida, serie_dim_incompativel, lancar_excecao=True)

    def test_dtw_alias_calcular(self):
        # Valida que o alias .calcular() e classe DTW funcionam de forma idêntica
        t = np.linspace(0, np.pi, 20)
        serie = 90.0 + 50.0 * np.sin(t)
        dtw = DTW()
        res = dtw.calcular(serie, serie)
        assert res.score_similaridade == 100.0

    def test_dtw_deadzone_fisiologica_e_normalizacao_articular(self):
        # Valida que pequenas variações anatômicas dentro da deadzone (ex.: 5 graus)
        # resultam em distância total zero e score 100%
        t = np.linspace(0, np.pi, 30)
        gabarito = np.column_stack((90.0 + 70.0 * np.sin(t), 80.0 + 70.0 * np.sin(t)))
        # Usuário desvia 5.0 graus no cotovelo e 4.0 graus no ombro (ambos <= 6.0 graus de deadzone)
        aluno_com_desvio_leve = np.column_stack((gabarito[:, 0] + 5.0, gabarito[:, 1] - 4.0))

        dtw = DTWComparator(tolerancia=30.0, deadzone_graus=6.0, normalizar_por_articulacao=True)
        res = dtw.compute(aluno_com_desvio_leve, gabarito, nomes_articulacoes=["cotovelo", "ombro"])

        assert res.valido is True
        assert pytest.approx(res.distancia_total, abs=1e-3) == 0.0
        assert pytest.approx(res.distancia_normalizada, abs=1e-3) == 0.0
        assert res.score_similaridade == 100.0
        # Os desvios médios exibidos no relatório ainda registram os valores brutos para diagnóstico
        assert pytest.approx(res.desvios_por_articulacao["cotovelo"], abs=1e-2) == 5.0
        assert pytest.approx(res.desvios_por_articulacao["ombro"], abs=1e-2) == 4.0

    def test_dtw_normalizacao_por_articulacao_invariancia_escala(self):
        # Com normalização por raiz(D), um desvio idêntico por articulação gera
        # o mesmo custo normalizado independente de serem 1 ou 2 articulações
        t = np.linspace(0, np.pi, 25)
        base = 90.0 + 50.0 * np.sin(t)
        desvio_constante = 10.0  # Acima da deadzone de 6.0 graus -> desvio efetivo = 4.0 graus

        # Caso 1D
        dtw_1d = DTWComparator(tolerancia=30.0, deadzone_graus=6.0, normalizar_por_articulacao=True)
        res_1d = dtw_1d.compute(base + desvio_constante, base)

        # Caso 2D (ambas as articulações com o mesmo desvio)
        base_2d = np.column_stack((base, base))
        aluno_2d = np.column_stack((base + desvio_constante, base + desvio_constante))
        res_2d = dtw_1d.compute(aluno_2d, base_2d)

        assert pytest.approx(res_1d.distancia_normalizada, abs=1e-2) == res_2d.distancia_normalizada
        assert pytest.approx(res_1d.score_similaridade, abs=1e-1) == res_2d.score_similaridade


class TestSegmentadorCanonicoEGabarito:
    def _gerar_curva_ombro_com_margens(self, frames_movimento=45, margem_inicio=8, margem_fim=8):
        t = np.linspace(0, np.pi, frames_movimento)
        serie: list = []
        for _ in range(margem_inicio):
            serie.append({"cotovelo": 90.0, "ombro": 80.0})
        for val in t:
            serie.append({
                "cotovelo": float(90.0 + 75.0 * np.sin(val)),
                "ombro": float(80.0 + 75.0 * np.sin(val)),
            })
        for _ in range(margem_fim):
            serie.append({"cotovelo": 90.0, "ombro": 80.0})
        return serie

    def test_extrair_primeira_repeticao_recorta_margens_corretamente(self):
        serie = self._gerar_curva_ombro_com_margens(frames_movimento=45, margem_inicio=10, margem_fim=10)
        rep = extrair_primeira_repeticao(
            fsm_ou_id="desenvolvimento_ombro",
            serie_angulos=serie,
            lancar_excecao=True,
        )

        assert rep is not None
        assert isinstance(rep, np.ndarray)
        assert rep.ndim == 2
        assert rep.shape[1] == 2  # [cotovelo, ombro]
        # O total de frames extraídos é menor que o total bruto (cortou os repousos inicial e final)
        assert rep.shape[0] < len(serie)
        # O primeiro frame capturado após a transição 0 -> 1 deve ter cotovelo > 100 graus
        assert rep[0, 0] > 100.0

    def test_extrair_primeira_repeticao_polimorfismo(self):
        serie = self._gerar_curva_ombro_com_margens(frames_movimento=45, margem_inicio=5, margem_fim=5)

        # 1. Por ID textual
        rep1 = extrair_primeira_repeticao("desenvolvimento_ombro", serie_angulos=serie)
        # 2. Por tecla rápida
        rep2 = extrair_primeira_repeticao("1", serie_angulos=serie)
        # 3. Por classe FSM com articulações explícitas
        rep3 = extrair_primeira_repeticao(DesenvolvimentoOmbro, articulacoes=["cotovelo", "ombro"], serie_angulos=serie)
        # 4. Por instância já criada
        fsm_inst = DesenvolvimentoOmbro()
        rep4 = extrair_primeira_repeticao(fsm_inst, articulacoes=["cotovelo", "ombro"], serie_angulos=serie)

        assert rep1 is not None and rep2 is not None and rep3 is not None and rep4 is not None
        assert np.array_equal(rep1, rep2)
        assert np.array_equal(rep1, rep3)
        assert np.array_equal(rep1, rep4)

    def test_extrair_primeira_repeticao_degradacao_graciosa_vs_excecao(self):
        # Série incompleta (apenas a fase de subida, interrompida no topo)
        t = np.linspace(0, np.pi / 2, 20)
        serie_incompleta = [{"cotovelo": float(90.0 + 75.0 * np.sin(val)), "ombro": 80.0} for val in t]

        # 1. Modo gracioso (padrão) -> retorna None
        rep_gracioso = extrair_primeira_repeticao(
            "desenvolvimento_ombro",
            serie_angulos=serie_incompleta,
            lancar_excecao=False,
        )
        assert rep_gracioso is None

        # 2. Modo com exceção -> levanta ValueError
        with pytest.raises(ValueError, match="Nenhuma repetição completa"):
            extrair_primeira_repeticao(
                "desenvolvimento_ombro",
                serie_angulos=serie_incompleta,
                lancar_excecao=True,
            )

        # 3. Série vazia
        assert extrair_primeira_repeticao("desenvolvimento_ombro", serie_angulos=[]) is None
        with pytest.raises(ValueError, match="está vazia"):
            extrair_primeira_repeticao("desenvolvimento_ombro", serie_angulos=[], lancar_excecao=True)

    def test_gabaritos_carregamento_e_score_100_autoconsistencia(self):
        """
        Critério de Pronto (DoD) da TASK-05 e Fundação do AC1:
        Os gabaritos padronizados carregados do disco comparados contra si mesmos
        ou contra uma execução ideal extraída com a FSM canônica devem atingir nota máxima (100.0%).
        """
        # Garante que os gabaritos existem e estão sincronizados
        garantir_gabaritos_padrao(sobrescrever=False)
        dtw = DTWComparator(tolerancia=15.0)

        exercicios = [
            ("gabarito_especialista_ombro.json", ["cotovelo", "ombro"]),
            ("gabarito_especialista_agachamento.json", ["joelho", "quadril"]),
            ("gabarito_especialista_rosca.json", ["cotovelo", "ombro"]),
        ]

        for arq, arts in exercicios:
            gab = GabaritoExercicio.carregar_json(arq)
            assert gab.articulacoes == arts
            assert gab.total_frames >= 20

            # DTW contra si mesmo
            res = dtw.compute(gab.dados, gab.dados, nomes_articulacoes=arts)
            assert res.valido is True
            assert pytest.approx(res.distancia_total, abs=1e-3) == 0.0
            assert pytest.approx(res.distancia_normalizada, abs=1e-3) == 0.0
            assert res.score_similaridade == 100.0
            for art in arts:
                assert pytest.approx(res.desvios_por_articulacao[art], abs=1e-3) == 0.0

    def test_execucao_ideal_do_aluno_atinge_100_contra_gabarito(self):
        """
        Valida que o problema diagnosticado no PLANO_SPRINT_US01 (Problema 5) foi sanado:
        Uma execução do aluno com repouso antes e depois do movimento, ao ser recortada
        pela FSM canônica, produz a mesma matriz do gabarito e atinge score 100%.
        """
        gab_ombro = GabaritoExercicio.carregar_json("gabarito_especialista_ombro.json")

        # Aluno faz a repetição com 15 frames de repouso antes e 15 depois
        serie_aluno = self._gerar_curva_ombro_com_margens(frames_movimento=45, margem_inicio=15, margem_fim=15)
        rep_aluno = extrair_primeira_repeticao("desenvolvimento_ombro", serie_angulos=serie_aluno, lancar_excecao=True)

        dtw = DTWComparator(tolerancia=15.0)
        res = dtw.compute(gab_ombro.dados, rep_aluno, nomes_articulacoes=["cotovelo", "ombro"])

        assert res.valido is True
        assert res.score_similaridade == 100.0
        assert pytest.approx(res.distancia_normalizada, abs=1e-3) == 0.0


class TestGuardasBiomecanicasBuffer:
    """[TASK-CORR.03] Valida a rejeição de falsos positivos pelo BufferRepeticao."""

    def test_duration_guard_rejeita_ciclo_ultracurto(self):
        class FSMFalsaCurta(ExercicioBaseFSM):
            def identificar_fase(self, a, p, d):
                return 0
            def classificar(self, a, p, d):
                self.fases = [3, 0]
                self.repeticoes += 1
                return None

        fsm = FSMFalsaCurta()
        buffer = BufferRepeticao(fsm=fsm, articulacoes=["cotovelo"], min_frames=6, min_rom=15.0)
        buffer.frames_atuais = [[90.0], [95.0], [90.0]]
        rep, erro = buffer.processar_frame({"cotovelo": 90.0})
        assert rep is None
        pass

    def test_rom_guard_rejeita_oscilacao_sem_amplitude_real(self):
        class FSMFalsaOscilacao(ExercicioBaseFSM):
            def identificar_fase(self, a, p, d):
                return 0
            def classificar(self, a, p, d):
                self.fases = [3, 0]
                self.repeticoes += 1
                return None

        fsm = FSMFalsaOscilacao()
        buffer = BufferRepeticao(fsm=fsm, articulacoes=["cotovelo"], min_frames=6, min_rom=15.0)
        buffer.frames_atuais = [[90.0 + (i % 2) * 2.0] for i in range(14)]
        rep, erro = buffer.processar_frame({"cotovelo": 90.0})
        assert rep is None
        pass

    def test_guardas_aceitam_repeticao_com_duracao_e_amplitude_validas(self):
        class FSMValida(ExercicioBaseFSM):
            def identificar_fase(self, a, p, d):
                return 0
            def classificar(self, a, p, d):
                self.fases = [3, 0]
                self.repeticoes += 1
                return None

        fsm = FSMValida()
        buffer = BufferRepeticao(fsm=fsm, articulacoes=["cotovelo"], min_frames=6, min_rom=15.0)
        t = np.linspace(0, np.pi, 20)
        buffer.frames_atuais = [[float(90.0 + 70.0 * np.sin(val))] for val in t]
        rep, erro = buffer.processar_frame({"cotovelo": 90.0})
        assert rep is not None
        assert isinstance(rep, np.ndarray)
        assert rep.shape[0] == 21


class TestOrquestradorEAvaliadorPontuacao:
    def _criar_frames_desenvolvimento(self, n_mov=45, margem=5, desvio_ombro=0.0):
        t = np.linspace(0, np.pi, n_mov)
        frames = []
        for _ in range(margem):
            frames.append({"cotovelo": 90.0, "ombro": 80.0 + desvio_ombro})
        for val in t:
            frames.append({
                "cotovelo": float(90.0 + 75.0 * np.sin(val)),
                "ombro": float(80.0 + 75.0 * np.sin(val) + desvio_ombro),
            })
        for _ in range(margem):
            frames.append({"cotovelo": 90.0, "ombro": 80.0 + desvio_ombro})
        return frames

    def test_calcular_pontuacao_execucao_perfeita(self):
        gab = GabaritoExercicio.carregar_json("gabarito_especialista_ombro.json")
        conf = {"classe_fsm": DesenvolvimentoOmbro}
        res = calcular_pontuacao(
            dados_usuario=gab.dados,
            gabarito=gab,
            erros_fsm=[],
            fsm_ou_config=conf,
            numero_repeticao=1,
        )

        assert isinstance(res, ResultadoPontuacaoRepeticao)
        assert res.numero_repeticao == 1
        assert res.score_dtw == 100.0
        assert res.penalidade_fsm == 0.0
        assert res.score_final == 100.0
        assert res.aprovado is True
        assert res.classificacao == "EXCELENTE"
        assert res.erros_fsm == []
        assert "Excelente" in res.feedback_principal

    def test_calcular_pontuacao_com_penalidade_fsm_e_deduplicacao(self):
        gab = GabaritoExercicio.carregar_json("gabarito_especialista_ombro.json")
        conf = {"classe_fsm": DesenvolvimentoOmbro}
        # Simula ocorrência múltipla do mesmo erro postural durante o ciclo
        erros = ["OMBRO_CAIDO", "OMBRO_CAIDO", "OMBRO_CAIDO"]
        res = calcular_pontuacao(
            dados_usuario=gab.dados,
            gabarito=gab,
            erros_fsm=erros,
            fsm_ou_config=conf,
            numero_repeticao=2,
        )

        # Penalidade de OMBRO_CAIDO = 15.0 pts (deduplicado uma única vez)
        assert res.penalidade_fsm == 15.0
        assert res.score_final == 85.0
        assert res.aprovado is True
        assert res.classificacao == "EXCELENTE"
        assert len(res.erros_fsm) == 1
        assert "ombros alinhados" in res.feedback_principal.lower()

    def test_calcular_pontuacao_reprova_incompletude_mesmo_com_nota_75(self):
        gab = GabaritoExercicio.carregar_json("gabarito_especialista_ombro.json")
        conf = {"classe_fsm": DesenvolvimentoOmbro}
        # Incompletude subtrai 25 pontos
        erros = ["REPETICAO_INCOMPLETA"]
        res = calcular_pontuacao(
            dados_usuario=gab.dados,
            gabarito=gab,
            erros_fsm=erros,
            fsm_ou_config=conf,
            numero_repeticao=3,
        )

        # A penalidade preserva a nota, mas incompletude é desqualificadora.
        assert res.penalidade_fsm == 25.0
        assert res.score_final == 75.0
        assert res.aprovado is False
        assert "subida interrompida" in res.feedback_principal.lower()

    def test_todos_os_erros_de_incompletude_sao_desqualificadores(self):
        gab = GabaritoExercicio.carregar_json("gabarito_especialista_ombro.json")
        codigos = (
            "REPETICAO_INCOMPLETA",
            "AGACHAMENTO_CURTO",
            "SUBIDA_INCOMPLETA",
        )
        config = SimpleNamespace(
            PENALIDADES_ERRO={codigo: 25.0 for codigo in codigos},
            MENSAGENS_ERRO={},
        )

        for codigo in codigos:
            resultado = calcular_pontuacao(
                dados_usuario=gab.dados,
                gabarito=gab,
                erros_fsm=[codigo],
                fsm_ou_config=config,
            )
            assert resultado.score_final == 75.0
            assert resultado.aprovado is False

    def test_orquestrador_processar_frame_fluxo_completo(self):
        orq = OrquestradorSessao("desenvolvimento_ombro")
        frames = self._criar_frames_desenvolvimento(n_mov=45, margem=5)

        res_rep_final = None
        for frame in frames:
            alerta, res_rep = orq.processar_frame(angulos=frame, visivel=True)
            if res_rep is not None:
                res_rep_final = res_rep

        assert res_rep_final is not None
        assert res_rep_final.score_final >= 95.0
        assert res_rep_final.aprovado is True
        assert len(orq.historico_repeticoes) == 1

    def test_orquestrador_resumo_sessao_e_gamificacao(self):
        orq = OrquestradorSessao("1")
        frames_ideal = self._criar_frames_desenvolvimento(n_mov=45, margem=4)

        # Executa 2 repetições ideais
        for _ in range(2):
            for frame in frames_ideal:
                orq.processar_frame(frame, visivel=True)

        resumo = orq.gerar_resumo_sessao()
        assert isinstance(resumo, ResumoPontuacaoSessao)
        assert resumo.id_exercicio == "desenvolvimento_ombro"
        assert resumo.total_repeticoes == 2
        assert resumo.repeticoes_aprovadas == 2
        assert resumo.repeticoes_reprovadas == 0
        assert resumo.taxa_aprovacao == 100.0
        assert resumo.score_medio >= 95.0
        # Pontos de gamificação: soma das notas / 10
        assert resumo.pontos_gamificacao >= 19.0
        assert "consistência técnica" in resumo.recomendacao_prioritaria.lower()

    def test_orquestrador_tolerancia_e_reset_perda_visao(self):
        orq = OrquestradorSessao("desenvolvimento_ombro", limite_frames_invisivel=10)

        # 1. Poucos frames de invisibilidade (tolerância transitória)
        alerta, res = orq.processar_frame({"cotovelo": 90.0, "ombro": 80.0}, visivel=False)
        assert alerta == "ATENÇÃO: Articulação fora de visão"
        assert res is None

        # 2. Invisibilidade prolongada excedendo o limite (> 10 frames)
        for _ in range(12):
            alerta, res = orq.processar_frame({"cotovelo": 90.0, "ombro": 80.0}, visivel=False)

        assert "Visão perdida por muito tempo" in alerta
        assert res is None
        assert orq.buffer.frames_atuais == []

    def test_presence_gate_sem_repeticao_fantasma_quando_invisivel_ou_vazio(self):
        """
        [TASK-CORR.02] Garante que frames sem visibilidade ou com marcos vazios
        não progridem a FSM, não criam deltas espúrios e não contam repetições fantasma.
        """
        orq = OrquestradorSessao("desenvolvimento_ombro", limite_frames_invisivel=15)

        # 1. Simula 50 frames sem detecção (câmera vazia)
        for _ in range(50):
            alerta, rep = orq.processar_frame(angulos={}, visivel=False)
            assert rep is None
        pass

        assert orq.total_repeticoes == 0
        assert orq.fsm.repeticoes == 0
        assert orq.buffer.frames_atuais == []
        assert len(orq.referencia_deltas) == 0

        # 2. Usuário entra no quadro em uma pose qualquer
        alerta, rep = orq.processar_frame({"cotovelo": 120.0, "ombro": 100.0}, visivel=True)
        assert rep is None
        pass
        # Na primeira leitura visível, a referência é ancorada com deltas zerados
        assert orq.referencia_deltas["cotovelo"] == 120.0
        assert orq.fsm.fases[1] == 0
        assert orq.total_repeticoes == 0

    def test_orquestrador_trocar_exercicio_e_reiniciar_serie(self):
        orq = OrquestradorSessao("desenvolvimento_ombro")
        assert orq.id_exercicio == "desenvolvimento_ombro"
        assert orq.articulacoes == ["cotovelo", "ombro"]

        # Troca para Agachamento
        orq.trocar_exercicio("2")
        assert orq.id_exercicio == "agachamento"
        assert orq.articulacoes == ["joelho", "quadril"]
        assert orq.gabarito.nome_exercicio == "agachamento"

        # Reiniciar série
        orq.reiniciar_serie()
        assert len(orq.historico_repeticoes) == 0
        assert orq.fsm.repeticoes == 0

    def test_calcular_pontuacao_com_alinhamento_baseline_offset_estatico(self):
        # Valida que uma repetição com offset constante (ex.: biotipo diferente ou câmera inclinada
        # que adiciona +10 graus em todas as articulações) obtém score alto quando alinhar_baseline=True
        gab = GabaritoExercicio.carregar_json("gabarito_especialista_ombro.json")
        conf = {"classe_fsm": DesenvolvimentoOmbro}
        
        # Simula aluno com deslocamento de +10.0 graus em cotovelo e +8.0 graus no ombro
        dados_aluno_com_offset = np.column_stack((
            gab.dados[:, 0] + 10.0,
            gab.dados[:, 1] + 8.0,
        ))

        # 1. Com alinhamento de baseline (novo padrão) -> avalia a forma/morfologia
        res_alinhado = calcular_pontuacao(
            dados_usuario=dados_aluno_com_offset,
            gabarito=gab,
            erros_fsm=[],
            fsm_ou_config=conf,
            alinhar_baseline=True,
        )
        assert res_alinhado.aprovado is True
        assert res_alinhado.score_final >= 95.0
        # O diagnóstico real deve continuar registrando os desvios médios brutos reais (10° e 8°)
        assert pytest.approx(res_alinhado.desvios_por_articulacao["cotovelo"], abs=1e-1) == 10.0
        assert pytest.approx(res_alinhado.desvios_por_articulacao["ombro"], abs=1e-1) == 8.0

        # 2. Sem alinhamento de baseline -> penaliza o deslocamento constante
        res_sem_alinhamento = calcular_pontuacao(
            dados_usuario=dados_aluno_com_offset,
            gabarito=gab,
            erros_fsm=[],
            fsm_ou_config=conf,
            alinhar_baseline=False,
        )
        # O score sem alinhamento é estritamente menor do que com alinhamento de baseline
        assert res_sem_alinhamento.score_final < res_alinhado.score_final

    def test_exemplo_integracao_cenarios_apresentam_vereditos_esperados(self):
        ideal, resumo_ideal = executar_sessao(criar_frames_movimento_completo(55))
        assert ideal.score_final >= 95.0
        assert ideal.aprovado is True
        assert ideal.erros_fsm == []
        assert resumo_ideal.repeticoes_aprovadas == 1

        for total_frames in (65, 150):
            lento, resumo_lento = executar_sessao(
                criar_frames_movimento_completo(total_frames)
            )
            assert lento.score_final >= 85.0
            assert lento.aprovado is True
            assert lento.erros_fsm == []
            assert resumo_lento.repeticoes_aprovadas == 1

        incompleto, resumo_incompleto = executar_sessao(
            criar_frames_movimento_incompleto()
        )
        assert incompleto.aprovado is False
        assert incompleto.penalidade_fsm == 25.0
        assert incompleto.erros_fsm == ["REPETICAO_INCOMPLETA"]
        assert resumo_incompleto.repeticoes_reprovadas == 1

    def test_webcam_usa_orquestrador_nos_tres_exercicios(self):
        from app_tempo_real import inicializar_sessao_exercicio, processar_frame_webcam

        for tecla, articulacoes in (
            ("1", ["cotovelo", "ombro"]),
            ("2", ["joelho", "quadril"]),
            ("3", ["cotovelo", "ombro"]),
        ):
            config, orquestrador = inicializar_sessao_exercicio(tecla)
            assert config["classe_fsm"] is type(orquestrador.fsm)
            assert orquestrador.articulacoes == articulacoes

        _, orquestrador = inicializar_sessao_exercicio("1")
        alerta_atual = None
        resultado_repeticao = None
        for angulos in criar_frames_movimento_completo(55):
            alerta_atual, resultado = processar_frame_webcam(
                orquestrador=orquestrador,
                angulos=angulos,
                visivel=True,
                alerta_atual=alerta_atual,
            )
            if resultado is not None:
                resultado_repeticao = resultado

        assert resultado_repeticao is not None
        assert resultado_repeticao.aprovado is True
        assert resultado_repeticao.score_final >= 95.0
        assert orquestrador.fsm.repeticoes == 1


class TestCriteriosAceiteUS01:
    """
    Suíte de Aceite Final (AC1 a AC7) da História de Usuário US-01:
    Garante que todos os critérios mensuráveis do PLANO_SPRINT_US01 são atendidos
    pelo OrquestradorSessao e motor híbrido FSM + DTW.
    """

    def _gerar_frames_agachamento(self, n_mov=45, margem=5):
        t = np.linspace(0, np.pi, n_mov)
        frames = []
        for _ in range(margem):
            frames.append({"joelho": 170.0, "quadril": 170.0})
        for val in t:
            frames.append({
                "joelho": float(170.0 - 80.0 * np.sin(val)),
                "quadril": float(170.0 - 85.0 * np.sin(val)),
            })
        for _ in range(margem):
            frames.append({"joelho": 170.0, "quadril": 170.0})
        return frames

    def _gerar_frames_rosca(self, n_mov=45, margem=5):
        t = np.linspace(0, np.pi, n_mov)
        frames = []
        for _ in range(margem):
            frames.append({"cotovelo": 165.0, "ombro": 15.0})
        for val in t:
            frames.append({
                "cotovelo": float(165.0 - 115.0 * np.sin(val)),
                "ombro": float(15.0 + 3.0 * np.sin(val)),
            })
        for _ in range(margem):
            frames.append({"cotovelo": 165.0, "ombro": 15.0})
        return frames

    def test_ac1_execucao_ideal_nos_tres_exercicios(self):
        """
        AC1: Repetição com padrão motor idêntico ao gabarito atinge
        score_final >= 95.0%, aprovado == True e erros_fsm == [] nos 3 exercícios.
        """
        # 1. Desenvolvimento de Ombro
        orq_ombro = OrquestradorSessao("1")
        frames_ombro = criar_frames_movimento_completo(55)
        res_ombro = None
        for f in frames_ombro:
            _, r = orq_ombro.processar_frame(f, visivel=True)
            if r is not None:
                res_ombro = r
        assert res_ombro is not None
        assert res_ombro.score_final >= 95.0
        assert res_ombro.aprovado is True
        assert res_ombro.erros_fsm == []

        # 2. Agachamento Livre
        orq_agach = OrquestradorSessao("2")
        frames_agach = self._gerar_frames_agachamento(n_mov=45, margem=5)
        res_agach = None
        for f in frames_agach:
            _, r = orq_agach.processar_frame(f, visivel=True)
            if r is not None:
                res_agach = r
        assert res_agach is not None
        assert res_agach.score_final >= 95.0
        assert res_agach.aprovado is True
        assert res_agach.erros_fsm == []

        # 3. Rosca Direta de Bíceps
        orq_rosca = OrquestradorSessao("3")
        frames_rosca = self._gerar_frames_rosca(n_mov=45, margem=5)
        res_rosca = None
        for f in frames_rosca:
            _, r = orq_rosca.processar_frame(f, visivel=True)
            if r is not None:
                res_rosca = r
        assert res_rosca is not None
        assert res_rosca.score_final >= 95.0
        assert res_rosca.aprovado is True
        assert res_rosca.erros_fsm == []

    def test_ac2_invariancia_temporal_cadencias_multiplas(self):
        """
        AC2: Execuções corretas com cadências de 40, 65 e 150 frames mantêm
        score_final >= 85.0% e aprovado == True.
        """
        for total_frames in (40, 65, 150):
            orq = OrquestradorSessao("1")
            frames = criar_frames_movimento_completo(total_frames)
            res = None
            for f in frames:
                _, r = orq.processar_frame(f, visivel=True)
                if r is not None:
                    res = r
            assert res is not None, f"Falha ao concluir repetição com {total_frames} frames"
            assert res.score_final >= 85.0
            assert res.aprovado is True
            assert res.erros_fsm == []

    def test_ac3_deteccao_e_punicao_incompletude(self):
        """
        AC3: Movimento interrompido antes do pico registra erro de transição,
        aplica penalidade de 25 pontos e resulta em aprovado == False.
        """
        orq = OrquestradorSessao("1")
        frames_incompletos = criar_frames_movimento_incompleto()
        res = None
        for f in frames_incompletos:
            _, r = orq.processar_frame(f, visivel=True)
            if r is not None:
                res = r

        assert res is not None
        assert res.aprovado is False
        assert res.penalidade_fsm == 25.0
        assert "REPETICAO_INCOMPLETA" in res.erros_fsm

    def test_ac4_preservacao_de_erro_postural_transiente(self):
        """
        AC4: Compensação postural ocorrida no meio da repetição (ex.: ombro caído < 60° na fase 2)
        é retida no fechamento do ciclo em repouso e aplica desconto de 15 pontos.
        """
        orq = OrquestradorSessao("1")
        # Gera repetição onde a postura do ombro é comprometida apenas no pico
        t = np.linspace(0, np.pi, 45)
        frames = [{"cotovelo": 90.0, "ombro": 80.0} for _ in range(5)]
        for idx, val in enumerate(t):
            cot = float(90.0 + 75.0 * np.sin(val))
            # No terço central (fases 1-2), ombro cai para 45° (< 60°)
            omb = 45.0 if 15 <= idx <= 30 else float(80.0 + 75.0 * np.sin(val))
            frames.append({"cotovelo": cot, "ombro": omb})
        frames.extend([{"cotovelo": 90.0, "ombro": 80.0} for _ in range(5)])

        res = None
        for f in frames:
            _, r = orq.processar_frame(f, visivel=True)
            if r is not None:
                res = r

        assert res is not None
        assert "OMBRO_CAIDO" in res.erros_fsm
        assert res.penalidade_fsm >= 15.0

    def test_ac5_consolidacao_serie_resumo_gamificacao(self):
        """
        AC5: Série com múltiplas repetições calcula acuradamente média das notas,
        percentual de aprovadas e pontos de gamificação proporcionais.
        """
        orq = OrquestradorSessao("1")
        frames_ideal = criar_frames_movimento_completo(50)
        frames_incompletos = criar_frames_movimento_incompleto()

        # 2 ideais + 1 incompleta
        for f in frames_ideal:
            orq.processar_frame(f, visivel=True)
        for f in frames_ideal:
            orq.processar_frame(f, visivel=True)
        for f in frames_incompletos:
            orq.processar_frame(f, visivel=True)

        resumo = orq.gerar_resumo_sessao()
        assert resumo.total_repeticoes == 3
        assert resumo.repeticoes_aprovadas == 2
        assert resumo.repeticoes_reprovadas == 1
        assert pytest.approx(resumo.taxa_aprovacao, abs=0.2) == 66.7
        assert pytest.approx(resumo.score_medio, abs=0.2) == 66.7
        # Apenas repetições aprovadas somam pontos de gamificação (100.0/10 + 100.0/10 = 20.0)
        assert pytest.approx(resumo.pontos_gamificacao, abs=0.2) == 20.0
        assert "Atenção recorrente" in resumo.recomendacao_prioritaria or "REPETICAO_INCOMPLETA" in resumo.recomendacao_prioritaria

    def test_ac6_verificacao_estatica_ausencia_duplicacao_consumidores(self):
        """
        AC6: Verificação estática garantindo que os scripts consumidores
        (app_tempo_real.py, comparar_exercicio.py, exemplo_integracao.py)
        não importam dtw_inicial nem duplicam cálculos manuais de DTW/pontuação.
        """
        import pathlib
        raiz = pathlib.Path(__file__).resolve().parent.parent
        pasta_codigos = raiz / "Códigos" if (raiz / "Códigos").exists() else raiz
        consumidores = [
            pasta_codigos / "app_tempo_real.py",
            pasta_codigos / "comparar_exercicio.py",
            pasta_codigos / "exemplo_integracao.py",
        ]

        for script in consumidores:
            assert script.exists(), f"Arquivo não encontrado: {script}"
            codigo = script.read_text(encoding="utf-8")
            assert "import dtw_inicial" not in codigo
            assert "from dtw_inicial" not in codigo
            assert "OrquestradorSessao" in codigo

    def test_ac7_extensibilidade_poo_novo_exercicio_sem_alterar_motor(self):
        """
        AC7: Criação de um novo exercício sintético no catálogo prova o princípio
        Aberto/Fechado (OCP): o orquestrador o instancia, processa frames e avalia
        sem nenhuma alteração no código central.
        """
        from exercicios_fsm import ExercicioBaseFSM, CATALOGO_EXERCICIOS

        class ExercicioDummyTeste(ExercicioBaseFSM):
            PENALIDADES_ERRO = {"ERRO_DUMMY": 20.0}
            MENSAGENS_ERRO = {"ERRO_DUMMY": "Erro dummy detectado"}

            def identificar_fase(self, angulos: dict, posicoes: dict, angulos_deltas: dict) -> int:
                a = angulos.get("articulacao_teste", 0.0)
                da = angulos_deltas.get("articulacao_teste", 0.0)
                fase = self.fases[1]
                if fase == 0 and a > 50.0 and da > 0:
                    fase = 1
                elif fase == 1 and a >= 100.0:
                    fase = 2
                elif fase == 2 and a < 90.0:
                    fase = 3
                elif fase == 3 and a <= 50.0:
                    fase = 0
                return fase

            def classificar(self, angulos: dict, posicoes: dict, angulos_deltas: dict) -> Optional[str]:
                fase = self.identificar_fase(angulos, posicoes, angulos_deltas)
                self.fases = [self.fases[1], fase]
                if self.fases[0] == 3 and self.fases[1] == 0:
                    self.repeticoes += 1
                return None

        # Dados sintéticos de gabarito para o exercício dummy
        t = np.linspace(0, np.pi, 30)
        dados_dummy = np.column_stack((50.0 + 55.0 * np.sin(t),))
        gabarito_dummy = GabaritoExercicio(
            nome_exercicio="exercicio_dummy",
            articulacoes=["articulacao_teste"],
            dados=dados_dummy,
            descricao="Gabarito de teste de extensibilidade OCP",
        )

        chave_teste = "99"
        CATALOGO_EXERCICIOS[chave_teste] = {
            "id": "exercicio_dummy",
            "nome": "Exercício Dummy Extensível",
            "classe_fsm": ExercicioDummyTeste,
            "articulacoes": ["articulacao_teste"],
            "arquivo_gabarito": "dummy_nao_usado.json",
        }

        try:
            # Instancia o orquestrador diretamente pelo novo ID do catálogo
            orq = OrquestradorSessao(
                identificador_exercicio=chave_teste,
                gabarito_customizado=gabarito_dummy,
            )
            assert orq.nome_exercicio == "Exercício Dummy Extensível"
            assert isinstance(orq.fsm, ExercicioDummyTeste)

            # Envia frames sintéticos do novo exercício
            res_rep = None
            frames = [{"articulacao_teste": 50.0} for _ in range(4)]
            for val in t:
                frames.append({"articulacao_teste": float(50.0 + 55.0 * np.sin(val))})
            frames.extend([{"articulacao_teste": 50.0} for _ in range(4)])

            for f in frames:
                _, r = orq.processar_frame(f, visivel=True)
                if r is not None:
                    res_rep = r

            assert res_rep is not None
            assert res_rep.score_final >= 95.0
            assert res_rep.aprovado is True
            assert orq.fsm.repeticoes == 1
            resumo = orq.gerar_resumo_sessao()
            assert resumo.total_repeticoes == 1
            assert resumo.repeticoes_aprovadas == 1
        finally:
            CATALOGO_EXERCICIOS.pop(chave_teste, None)


from exercicios_fsm import ElevacaoLateral

class TestElevacaoLateral:
    """Testes unitários específicos da FSM e regras de Elevação Lateral."""

    def test_ciclo_completo_execucao_ideal(self):
        fsm = ElevacaoLateral()
        pos = {}

        # Fase 0 (Repouso)
        assert fsm.fases[1] == 0
        fsm.classificar({"ombro": 20.0, "cotovelo": 160.0}, pos, {"ombro": 0.0})
        assert fsm.fases[1] == 0

        # Fase 0 -> 1 (Subida)
        fsm.classificar({"ombro": 48.0, "cotovelo": 160.0}, pos, {"ombro": 10.0})
        assert fsm.fases[1] == 1

        # Fase 1 -> 2 (Pico na linha dos ombros)
        fsm.classificar({"ombro": 88.0, "cotovelo": 160.0}, pos, {"ombro": 10.0})
        assert fsm.fases[1] == 2

        # Fase 2 -> 3 (Descida controlada)
        fsm.classificar({"ombro": 70.0, "cotovelo": 160.0}, pos, {"ombro": -10.0})
        assert fsm.fases[1] == 3

        # Fase 3 -> 0 (Retorno ao repouso)
        fsm.classificar({"ombro": 25.0, "cotovelo": 160.0}, pos, {"ombro": -10.0})
        assert fsm.fases[1] == 0
        assert fsm.repeticoes == 1
        assert fsm.consumir_erros_repeticao() == []

    def test_deteccao_erro_elevacao_curta(self):
        fsm = ElevacaoLateral()
        pos = {}

        # 0 -> 1
        fsm.classificar({"ombro": 48.0, "cotovelo": 160.0}, pos, {"ombro": 10.0})
        assert fsm.fases[1] == 1

        # 1 -> 3 precoce (desce antes de atingir 80°)
        erro = fsm.classificar({"ombro": 60.0, "cotovelo": 160.0}, pos, {"ombro": -8.0})
        assert fsm.fases[1] == 3
        assert erro == "ELEVACAO_CURTA"
        assert "ELEVACAO_CURTA" in fsm.consumir_erros_repeticao()

    def test_deteccao_erro_elevacao_excessiva(self):
        fsm = ElevacaoLateral()
        pos = {}

        # 0 -> 1
        fsm.classificar({"ombro": 48.0, "cotovelo": 160.0}, pos, {"ombro": 10.0})
        # 1 -> 2 com elevação exagerada (> 115°)
        erro = fsm.classificar({"ombro": 120.0, "cotovelo": 160.0}, pos, {"ombro": 10.0})
        assert fsm.fases[1] == 2
        assert erro == "ELEVACAO_EXCESSIVA"
        assert "ELEVACAO_EXCESSIVA" in fsm.consumir_erros_repeticao()

    def test_deteccao_erro_cotovelo_muito_flexionado(self):
        fsm = ElevacaoLateral()
        pos = {}

        # 0 -> 1 com cotovelo dobrado excessivamente (< 110°)
        erro = fsm.classificar({"ombro": 48.0, "cotovelo": 100.0}, pos, {"ombro": 10.0})
        assert erro == "COTOVELO_MUITO_FLEXIONADO"
        assert "COTOVELO_MUITO_FLEXIONADO" in fsm.consumir_erros_repeticao()

    def test_registro_catalogo_elevacao_lateral(self):
        conf_4 = obter_config_exercicio("4")
        assert conf_4["id"] == "elevacao_lateral"
        assert conf_4["classe_fsm"] is ElevacaoLateral
        assert conf_4["articulacoes"] == ["ombro", "cotovelo"]

        conf_id = obter_config_exercicio("elevacao_lateral")
        assert conf_id["nome"] == "Elevacao Lateral"

    def test_gabarito_especialista_elevacao_lateral_e_orquestrador(self):
        gab = GabaritoExercicio.carregar_json("gabarito_especialista_elevacao_lateral.json")
        assert gab.nome_exercicio == "elevacao_lateral"
        assert gab.articulacoes == ["ombro", "cotovelo"]
        assert gab.total_frames >= 30

        orq = OrquestradorSessao("4")
        resultado_rep = None

        for linha in gab.dados:
            frame_angulos = {"ombro": float(linha[0]), "cotovelo": float(linha[1])}
            _, rep = orq.processar_frame(frame_angulos, visivel=True)
            if rep is not None:
                resultado_rep = rep

        assert resultado_rep is not None
        assert resultado_rep.score_final >= 95.0
        assert resultado_rep.aprovado is True


from exercicios_fsm import TricepsCorda

class TestTricepsCorda:
    """Testes unitários específicos da FSM e regras de Tríceps Corda."""

    def test_ciclo_completo_execucao_ideal(self):
        fsm = TricepsCorda()
        pos = {}

        # Fase 0 (Topo / Repouso)
        assert fsm.fases[1] == 0
        fsm.classificar({"cotovelo": 80.0, "ombro": 15.0}, pos, {"cotovelo": 0.0})
        assert fsm.fases[1] == 0

        # Fase 0 -> 1 (Descida / Extensão)
        fsm.classificar({"cotovelo": 105.0, "ombro": 15.0}, pos, {"cotovelo": 15.0})
        assert fsm.fases[1] == 1

        # Fase 1 -> 2 (Pico de extensão no fundo)
        fsm.classificar({"cotovelo": 152.0, "ombro": 15.0}, pos, {"cotovelo": 20.0})
        assert fsm.fases[1] == 2

        # Fase 2 -> 3 (Retorno / Flexão controlada)
        fsm.classificar({"cotovelo": 130.0, "ombro": 15.0}, pos, {"cotovelo": -15.0})
        assert fsm.fases[1] == 3

        # Fase 3 -> 0 (Retorno ao topo)
        fsm.classificar({"cotovelo": 80.0, "ombro": 15.0}, pos, {"cotovelo": -15.0})
        assert fsm.fases[1] == 0
        assert fsm.repeticoes == 1
        assert fsm.consumir_erros_repeticao() == []

    def test_deteccao_erro_extensao_incompleta(self):
        fsm = TricepsCorda()
        pos = {}

        # 0 -> 1
        fsm.classificar({"cotovelo": 105.0, "ombro": 15.0}, pos, {"cotovelo": 15.0})
        assert fsm.fases[1] == 1

        # 1 -> 3 precoce (sobe antes de atingir 145°)
        erro = fsm.classificar({"cotovelo": 120.0, "ombro": 15.0}, pos, {"cotovelo": -10.0})
        assert fsm.fases[1] == 3
        assert erro == "EXTENSAO_INCOMPLETA"
        assert "EXTENSAO_INCOMPLETA" in fsm.consumir_erros_repeticao()

    def test_deteccao_erro_cotovelo_avancado(self):
        fsm = TricepsCorda()
        pos = {}

        # 0 -> 1 com ombro projetado para frente (> 35°)
        erro = fsm.classificar({"cotovelo": 105.0, "ombro": 45.0}, pos, {"cotovelo": 15.0})
        assert erro == "COTOVELO_AVANCADO"
        assert "COTOVELO_AVANCADO" in fsm.consumir_erros_repeticao()

    def test_deteccao_erro_subida_excessiva(self):
        fsm = TricepsCorda()
        pos = {}

        # 0 -> 1 -> 2 -> 3
        fsm.classificar({"cotovelo": 105.0, "ombro": 15.0}, pos, {"cotovelo": 15.0})
        fsm.classificar({"cotovelo": 150.0, "ombro": 15.0}, pos, {"cotovelo": 20.0})
        fsm.classificar({"cotovelo": 130.0, "ombro": 15.0}, pos, {"cotovelo": -10.0})
        # Na fase 3, sobe demais (< 50°)
        erro = fsm.classificar({"cotovelo": 45.0, "ombro": 15.0}, pos, {"cotovelo": -10.0})
        assert erro == "SUBIDA_EXCESSIVA"
        assert "SUBIDA_EXCESSIVA" in fsm.consumir_erros_repeticao()

    def test_registro_catalogo_triceps_corda(self):
        conf_5 = obter_config_exercicio("5")
        assert conf_5["id"] == "triceps_corda"
        assert conf_5["classe_fsm"] is TricepsCorda
        assert conf_5["articulacoes"] == ["cotovelo", "ombro"]

        conf_id = obter_config_exercicio("triceps_corda")
        assert conf_id["nome"] == "Triceps Corda"

    def test_gabarito_especialista_triceps_corda_e_orquestrador(self):
        gab = GabaritoExercicio.carregar_json("gabarito_especialista_triceps_corda.json")
        assert gab.nome_exercicio == "triceps_corda"
        assert gab.articulacoes == ["cotovelo", "ombro"]
        assert gab.total_frames >= 30

        orq = OrquestradorSessao("5")
        resultado_rep = None

        for linha in gab.dados:
            frame_angulos = {"cotovelo": float(linha[0]), "ombro": float(linha[1])}
            _, rep = orq.processar_frame(frame_angulos, visivel=True)
            if rep is not None:
                resultado_rep = rep

        assert resultado_rep is not None
        assert resultado_rep.score_final >= 90.0
        assert resultado_rep.aprovado is True


from exercicios_fsm import FlexaoDiamante

class TestFlexaoDiamante:
    """Testes unitários específicos da FSM e regras de Flexão Diamante."""

    def test_ciclo_completo_execucao_ideal(self):
        fsm = FlexaoDiamante()
        pos = {}

        # Fase 0 (Prancha Alta / Braços Estendidos)
        assert fsm.fases[1] == 0
        fsm.classificar({"cotovelo": 155.0, "ombro": 20.0}, pos, {"cotovelo": 0.0})
        assert fsm.fases[1] == 0

        # Fase 0 -> 1 (Descida / Flexão dos Cotovelos)
        fsm.classificar({"cotovelo": 130.0, "ombro": 25.0}, pos, {"cotovelo": -15.0})
        assert fsm.fases[1] == 1

        # Fase 1 -> 2 (Fundo / Cotovelo <= 90°)
        fsm.classificar({"cotovelo": 85.0, "ombro": 30.0}, pos, {"cotovelo": -15.0})
        assert fsm.fases[1] == 2

        # Fase 2 -> 3 (Subida / Extensão dos Braços)
        fsm.classificar({"cotovelo": 110.0, "ombro": 25.0}, pos, {"cotovelo": 15.0})
        assert fsm.fases[1] == 3

        # Fase 3 -> 0 (Retorno à Prancha Alta >= 145°)
        fsm.classificar({"cotovelo": 150.0, "ombro": 20.0}, pos, {"cotovelo": 15.0})
        assert fsm.fases[1] == 0
        assert fsm.repeticoes == 1
        assert fsm.consumir_erros_repeticao() == []

    def test_deteccao_erro_flexao_curta(self):
        fsm = FlexaoDiamante()
        pos = {}

        # 0 -> 1
        fsm.classificar({"cotovelo": 130.0, "ombro": 25.0}, pos, {"cotovelo": -15.0})
        assert fsm.fases[1] == 1

        # 1 -> 3 precoce (sobe antes de atingir 90°: delta > 0 e cotovelo > 105°)
        erro = fsm.classificar({"cotovelo": 115.0, "ombro": 25.0}, pos, {"cotovelo": 15.0})
        assert fsm.fases[1] == 3
        assert erro == "FLEXAO_CURTA"
        assert "FLEXAO_CURTA" in fsm.consumir_erros_repeticao()

    def test_deteccao_erro_abertura_excessiva(self):
        fsm = FlexaoDiamante()
        pos = {}

        # 0 -> 1 com ombro muito aberto (> 75°)
        erro = fsm.classificar({"cotovelo": 130.0, "ombro": 80.0}, pos, {"cotovelo": -15.0})
        assert erro == "ABERTURA_EXCESSIVA"
        assert "ABERTURA_EXCESSIVA" in fsm.consumir_erros_repeticao()

    def test_registro_catalogo_flexao_diamante(self):
        conf_6 = obter_config_exercicio("6")
        assert conf_6["id"] == "flexao_diamante"
        assert conf_6["classe_fsm"] is FlexaoDiamante
        assert conf_6["articulacoes"] == ["cotovelo", "ombro"]

        conf_id = obter_config_exercicio("flexao_diamante")
        assert conf_id["nome"] == "Flexao Diamante"

        conf_alias = obter_config_exercicio("flexao")
        assert conf_alias["id"] == "flexao_diamante"

    def test_gabarito_especialista_flexao_diamante_e_orquestrador(self):
        gab = GabaritoExercicio.carregar_json("gabarito_especialista_flexao_diamante.json")
        assert gab.nome_exercicio == "flexao_diamante"
        assert gab.articulacoes == ["cotovelo", "ombro"]
        assert gab.total_frames >= 10

        orq = OrquestradorSessao("6")
        resultado_rep = None

        for linha in gab.dados:
            frame_angulos = {"cotovelo": float(linha[0]), "ombro": float(linha[1])}
            _, rep = orq.processar_frame(frame_angulos, visivel=True)
            if rep is not None:
                resultado_rep = rep

        assert resultado_rep is not None
        assert resultado_rep.score_final >= 90.0
        assert resultado_rep.aprovado is True


from exercicios_fsm import RemadaBaixa

class TestRemadaBaixa:
    """Testes unitários específicos da FSM e regras da Remada Baixa."""

    def test_ciclo_completo_execucao_ideal(self):
        fsm = RemadaBaixa()
        pos = {}

        # Fase 0 (Repouso: braços estendidos à frente, cotovelo >= 140°)
        assert fsm.fases[1] == 0
        fsm.classificar({"cotovelo": 160.0, "ombro": 60.0, "quadril": 100.0}, pos, {"cotovelo": 0.0})
        assert fsm.fases[1] == 0

        # Fase 0 -> 1 (Puxando: cotovelo < 140°, delta < 0)
        fsm.classificar({"cotovelo": 125.0, "ombro": 45.0, "quadril": 105.0}, pos, {"cotovelo": -15.0})
        assert fsm.fases[1] == 1

        # Fase 1 -> 2 (Pico de contração: cotovelo <= 85°)
        fsm.classificar({"cotovelo": 75.0, "ombro": 45.0, "quadril": 110.0}, pos, {"cotovelo": -20.0})
        assert fsm.fases[1] == 2

        # Fase 2 -> 3 (Retorno excêntrico: cotovelo > 95° ou delta > 0)
        fsm.classificar({"cotovelo": 110.0, "ombro": 40.0, "quadril": 105.0}, pos, {"cotovelo": 20.0})
        assert fsm.fases[1] == 3

        # Fase 3 -> 0 (Retorno ao repouso: cotovelo >= 145°)
        fsm.classificar({"cotovelo": 155.0, "ombro": 60.0, "quadril": 100.0}, pos, {"cotovelo": 20.0})
        assert fsm.fases[1] == 0
        assert fsm.repeticoes == 1
        assert fsm.consumir_erros_repeticao() == []

    def test_deteccao_erro_remada_curta(self):
        fsm = RemadaBaixa()
        pos = {}

        # 0 -> 1
        fsm.classificar({"cotovelo": 125.0, "ombro": 45.0, "quadril": 105.0}, pos, {"cotovelo": -15.0})
        assert fsm.fases[1] == 1

        # 1 -> 3 precoce (retorna antes de puxar até 85°: delta > 0 e cotovelo >= 130°)
        erro = fsm.classificar({"cotovelo": 132.0, "ombro": 50.0, "quadril": 105.0}, pos, {"cotovelo": 10.0})
        assert fsm.fases[1] == 3
        assert erro == "REMADA_CURTA"
        assert "REMADA_CURTA" in fsm.consumir_erros_repeticao()

    def test_deteccao_erro_inclinacao_excessiva_tronco(self):
        fsm = RemadaBaixa()
        pos = {}

        # 0 -> 1 puxando, mas jogando o tronco para trás (quadril > 125°)
        erro = fsm.classificar({"cotovelo": 120.0, "ombro": 45.0, "quadril": 132.0}, pos, {"cotovelo": -15.0})
        assert erro == "INCLINACAO_EXCESSIVA_TRONCO"
        assert "INCLINACAO_EXCESSIVA_TRONCO" in fsm.consumir_erros_repeticao()

    def test_registro_catalogo_remada_baixa(self):
        conf_7 = obter_config_exercicio("7")
        assert conf_7["id"] == "remada_baixa"
        assert conf_7["classe_fsm"] is RemadaBaixa
        assert conf_7["articulacoes"] == ["cotovelo", "ombro", "quadril"]

        conf_id = obter_config_exercicio("remada_baixa")
        assert conf_id["nome"] == "Remada Baixa"

        conf_alias = obter_config_exercicio("remada")
        assert conf_alias["id"] == "remada_baixa"

    def test_gabarito_especialista_remada_baixa_e_orquestrador(self):
        gab = GabaritoExercicio.carregar_json("gabarito_especialista_remada_baixa.json")
        assert gab.nome_exercicio == "remada_baixa"
        assert gab.articulacoes == ["cotovelo", "ombro", "quadril"]
        assert gab.total_frames >= 30

        orq = OrquestradorSessao("7")
        resultado_rep = None

        for linha in gab.dados:
            frame_angulos = {
                "cotovelo": float(linha[0]),
                "ombro": float(linha[1]),
                "quadril": float(linha[2])
            }
            _, rep = orq.processar_frame(frame_angulos, visivel=True)
            if rep is not None:
                resultado_rep = rep

        assert resultado_rep is not None
        assert resultado_rep.score_final >= 95.0
        assert resultado_rep.aprovado is True


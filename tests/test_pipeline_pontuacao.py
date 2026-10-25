"""
Suíte de Testes Automatizados — Pipeline de Avaliação Biomecânica e Pontuação.
Cobre cálculo geométrico, deltas angulares, FSMs, segmentação, DTW e orquestração.
"""

import pytest
import numpy as np
import sys
from types import ModuleType, SimpleNamespace
from calculo_angulos import calcular_angulo, calcular_deltas_angulares


class TestCalculoAngulos:
    def test_calcular_angulo_perpendicular(self):
        # Triângulo retângulo: A=(0, 1), B=(0, 0), C=(1, 0) -> 90 graus
        ang = calcular_angulo((0, 1), (0, 0), (1, 0))
        assert pytest.approx(ang, rel=1e-2) == 90.0

    def test_calcular_angulo_linha_reta(self):
        # Linha reta: A=(-1, 0), B=(0, 0), C=(1, 0) -> 180 graus
        ang = calcular_angulo((-1, 0), (0, 0), (1, 0))
        assert pytest.approx(ang, rel=1e-2) == 180.0

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
    obter_config_exercicio,
)


class TestExerciciosFSM:
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

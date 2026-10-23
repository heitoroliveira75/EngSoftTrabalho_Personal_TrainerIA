"""
Suíte de Testes Automatizados — Pipeline de Avaliação Biomecânica e Pontuação.
Cobre cálculo geométrico, deltas angulares, FSMs, segmentação, DTW e orquestração.
"""

import pytest
import numpy as np
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

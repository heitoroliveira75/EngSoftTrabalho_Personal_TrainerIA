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

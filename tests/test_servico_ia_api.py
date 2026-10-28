"""
Testes unitários e de integração do ServicoIA (Back-end em memória).
Valida o ciclo de vida de sessões multi-usuário, decodificação em memória,
simulação canônica e geração de laudos com gamificação.
"""

import pytest
import numpy as np
import cv2

from servico_ia_api import ServicoIA, serializar_resultado_repeticao, serializar_resumo_sessao


@pytest.fixture
def servico():
    # Cria uma nova instância de serviço limpa para cada teste
    instancia = ServicoIA()
    instancia.sessoes.clear()
    return instancia


def test_gerenciamento_sessoes_isoladas_por_usuario(servico):
    """Garante que usuários distintos possuem sessões e orquestradores desacoplados."""
    sessao_user1 = servico.obter_ou_criar_sessao("user_1", "1")
    sessao_user2 = servico.obter_ou_criar_sessao("user_2", "2")

    assert sessao_user1.id_exercicio == "desenvolvimento_ombro"
    assert sessao_user2.id_exercicio == "agachamento"
    assert "user_1" in servico.sessoes
    assert "user_2" in servico.sessoes
    assert servico.sessoes["user_1"] is not servico.sessoes["user_2"]


def test_reiniciar_sessao(servico):
    """Garante que o reset da série zera repetições e histórico."""
    servico.obter_ou_criar_sessao("user_teste", "1")
    resultado_sim = servico.simular_repeticao("user_teste", "1", "ideal")
    assert resultado_sim["repeticoes"] >= 1

    res_reset = servico.reiniciar_sessao("user_teste", "1")
    assert res_reset["sucesso"] is True
    assert res_reset["repeticoes"] == 0

    sessao = servico.sessoes["user_teste"]
    assert len(sessao.historico_repeticoes) == 0


def test_processar_frame_angulos_passo_a_passo(servico):
    """Testa alimentação direta por dicionário de ângulos sem MediaPipe."""
    res = servico.processar_frame_angulos(
        angulos={"cotovelo": 90.0, "ombro": 85.0},
        usuario_id="user_step",
        exercicio_id="1",
        visivel=True,
    )
    assert res["sucesso"] is True
    assert res["corpo_visivel"] is True
    assert "fase_numero" in res
    assert "fase_nome" in res
    assert res["repeticoes"] == 0


def test_simular_repeticao_ideal_ombro(servico):
    """Executa simulação de repetição ideal e valida score elevado."""
    res = servico.simular_repeticao(
        usuario_id="user_atleta",
        exercicio_id="1",
        tipo_cenario="ideal",
    )
    assert res["sucesso"] is True
    assert res["repeticoes"] >= 1
    ultima_rep = res["ultima_repeticao"]
    assert ultima_rep is not None
    assert ultima_rep["score_final"] >= 85.0
    assert ultima_rep["aprovado"] is True


def test_simular_repeticao_postural(servico):
    """Executa simulação com desvio postural proposital."""
    res = servico.simular_repeticao(
        usuario_id="user_postural",
        exercicio_id="1",
        tipo_cenario="postural",
    )
    assert res["sucesso"] is True
    assert res["repeticoes"] >= 1


def test_resumo_sessao_com_gamificacao(servico):
    """Garante que o resumo compila repetições, pontuação de gamificação e recomendação."""
    servico.simular_repeticao("user_game", "1", "ideal")
    resumo_resp = servico.obter_resumo_sessao("user_game")

    assert resumo_resp["sucesso"] is True
    dados = resumo_resp["dados"]
    assert dados["total_repeticoes"] >= 1
    assert dados["pontos_gamificacao"] > 0.0
    assert dados["taxa_aprovacao"] == 100.0
    assert len(dados["recomendacao_prioritaria"]) > 0


def test_decodificacao_frame_bytes_corrompidos(servico):
    """Testa tratamento gracioso contra buffers de imagem inválidos ou corrompidos."""
    bytes_invalidos = b"isso_nao_e_uma_imagem_valida"
    res = servico.processar_frame_imagem(
        conteudo_bytes=bytes_invalidos,
        usuario_id="user_erro",
        exercicio_id="1",
    )
    assert res["sucesso"] is False
    assert "inválido" in res["mensagem"].lower()

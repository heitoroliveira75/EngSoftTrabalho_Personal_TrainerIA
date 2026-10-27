"""
Testes de Integração End-to-End da API REST de IA (FastAPI).
Valida o ciclo completo de rotas /ia/*:
reiniciar-sessao -> processar-frame/angulos -> simular-repeticao -> resumo-sessao -> finalizar-serie-e-pontuar.
"""

import io
import pytest
import numpy as np
import cv2
from fastapi.testclient import TestClient
from unittest.mock import patch

from BD.api import app
from servico_ia_api import ServicoIA


@pytest.fixture
def client():
    # Limpa as sessões ativas antes de cada teste
    ServicoIA.obter_instancia().sessoes.clear()
    return TestClient(app)


def test_rota_ia_reiniciar_sessao(client):
    """Testa inicialização e reset da sessão de treino pela API."""
    resposta = client.post(
        "/ia/reiniciar-sessao",
        json={"usuario_id": "user_api_1", "exercicio_id": "1"},
    )
    assert resposta.status_code == 200
    dados = resposta.json()
    assert dados["sucesso"] is True
    assert dados["exercicio_id"] == "desenvolvimento_ombro"
    assert dados["repeticoes"] == 0


def test_rota_ia_simular_repeticao_ideal(client):
    """Testa injeção de repetição canônica demonstrativa."""
    client.post(
        "/ia/reiniciar-sessao",
        json={"usuario_id": "user_demo", "exercicio_id": "1"},
    )

    resposta = client.post(
        "/ia/simular-repeticao",
        json={"usuario_id": "user_demo", "exercicio_id": "1", "tipo_cenario": "ideal"},
    )
    assert resposta.status_code == 200
    dados = resposta.json()
    assert dados["sucesso"] is True
    assert dados["repeticoes"] >= 1
    assert dados["ultima_repeticao"]["score_final"] >= 85.0
    assert dados["ultima_repeticao"]["aprovado"] is True


def test_rota_ia_processar_angulos(client):
    """Testa processamento de fotograma via payload JSON de ângulos."""
    resposta = client.post(
        "/ia/processar-angulos",
        json={
            "usuario_id": "user_angulos",
            "exercicio_id": "1",
            "angulos": {"cotovelo": 95.0, "ombro": 80.0},
            "visivel": True,
        },
    )
    assert resposta.status_code == 200
    dados = resposta.json()
    assert dados["sucesso"] is True
    assert "fase_numero" in dados
    assert "fase_nome" in dados


def test_rota_ia_processar_frame_multipart(client):
    """Testa envio de imagem JPG via multipart/form-data."""
    # Cria uma imagem sintética preta de 300x300 e codifica em JPG na memória
    img = np.zeros((300, 300, 3), dtype=np.uint8)
    _, buffer_jpg = cv2.imencode(".jpg", img)
    bytes_io = io.BytesIO(buffer_jpg.tobytes())

    resposta = client.post(
        "/ia/processar-frame",
        files={"frame": ("frame.jpg", bytes_io, "image/jpeg")},
        data={"usuario_id": "user_cam", "exercicio": "1", "lado": "direito"},
    )
    assert resposta.status_code == 200
    dados = resposta.json()
    assert dados["sucesso"] is True
    assert "corpo_visivel" in dados
    assert "repeticoes" in dados


def test_rota_ia_resumo_sessao_e_gamificacao(client):
    """Testa recuperação do laudo consolidado e cálculo de pontos."""
    # Executa uma repetição ideal para pontuar
    client.post(
        "/ia/simular-repeticao",
        json={"usuario_id": "user_laudo", "exercicio_id": "1", "tipo_cenario": "ideal"},
    )

    resposta = client.get("/ia/resumo-sessao?usuario_id=user_laudo")
    assert resposta.status_code == 200
    resumo = resposta.json()
    assert resumo["sucesso"] is True
    dados = resumo["dados"]
    assert dados["total_repeticoes"] >= 1
    assert dados["pontos_gamificacao"] > 0.0
    assert dados["taxa_aprovacao"] == 100.0


def test_rota_ia_finalizar_serie_e_pontuar(client):
    """Testa encerramento da série e envio automático de pontos para a gamificação."""
    client.post(
        "/ia/simular-repeticao",
        json={"usuario_id": "user_final", "exercicio_id": "1", "tipo_cenario": "ideal"},
    )

    with patch("BD.api.bd.adicionar_pontuacao_diaria") as mock_pontuacao:
        mock_pontuacao.return_value = {
            "sucesso": True,
            "mensagem": "Pontuação diária atualizada com sucesso!",
            "pontos_adicionados": 10,
        }

        resposta = client.post(
            "/ia/finalizar-serie-e-pontuar",
            json={"usuario_id": "user_final", "incrementar_sequencia": True},
        )
        assert resposta.status_code == 200
        dados = resposta.json()
        assert dados["sucesso"] is True
        assert dados["pontos_atribuidos"] > 0
        assert dados["atualizacao_banco"]["sucesso"] is True
        mock_pontuacao.assert_called_once()

"""
Suíte de Testes Automatizados — Feature: Treinos em Dupla (US-DUPLA).
Valida o ciclo de vida completo da sessão cooperativa:
convite -> aceite/recusa -> lobby e seleção de treino -> alternância de turnos -> encerramento com bônus de 20% (1.2x).
"""

import pytest
from fastapi.testclient import TestClient
from unittest.mock import patch

from BD.api import app
import BD.main as bd


@pytest.fixture
def client():
    # Limpa sessões em memória antes dos testes
    bd._sessoes_dupla_memoria.clear()
    return TestClient(app)


def test_dupla_criar_convite(client):
    """Host convida amigo para treinar em dupla e gera sessão com status pendente."""
    payload = {
        "host_id": "user_host_100",
        "convidado_id": "user_guest_200",
        "total_series": 3,
        "dados_treino": {"nome": "Treino Superior"}
    }
    resp = client.post("/dupla/convidar", json=payload)
    assert resp.status_code == 200
    dados = resp.json()
    assert dados["sucesso"] is True
    assert "sessao_id" in dados
    assert dados["status"] == "pendente"


def test_dupla_validacao_mesmo_usuario(client):
    """Rejeita tentativa de criar sessão de treino em dupla consigo mesmo."""
    payload = {
        "host_id": "user_mesmo_id",
        "convidado_id": "user_mesmo_id",
    }
    resp = client.post("/dupla/convidar", json=payload)
    assert resp.status_code == 400
    assert "consigo mesmo" in resp.json()["detail"]


def test_dupla_listar_convites_pendentes(client):
    """Convidado lista solicitações recebidas pendentes com metadados do host."""
    client.post("/dupla/convidar", json={
        "host_id": "host_teste",
        "convidado_id": "convidado_teste",
        "dados_treino": {"nome": "Treino Peito"}
    })

    resp = client.get("/dupla/convites/pendentes", params={"usuario_id": "convidado_teste"})
    assert resp.status_code == 200
    dados = resp.json()
    assert dados["sucesso"] is True
    assert len(dados["convites"]) >= 1
    convite = dados["convites"][0]
    assert convite["status"] == "pendente"
    assert convite["host_id"] == "host_teste"


def test_dupla_responder_convite_recusado(client):
    """Convidado recusa convite, alterando o status da sessão para recusado."""
    c_resp = client.post("/dupla/convidar", json={
        "host_id": "host_recusa",
        "convidado_id": "guest_recusa"
    })
    sessao_id = c_resp.json()["sessao_id"]

    resp = client.post("/dupla/responder-convite", json={
        "sessao_id": sessao_id,
        "usuario_id": "guest_recusa",
        "resposta": "recusado"
    })
    assert resp.status_code == 200
    assert resp.json()["status"] == "recusado"

    # Verifica persistência do estado
    estado = client.get(f"/dupla/estado/{sessao_id}").json()
    assert estado["sessao"]["status"] == "recusado"


def test_dupla_aceitar_selecionar_e_iniciar_treino(client):
    """Convidado aceita, Host seleciona exercícios no Lobby e inicia o treino."""
    c_resp = client.post("/dupla/convidar", json={
        "host_id": "host_treino",
        "convidado_id": "guest_treino"
    })
    sessao_id = c_resp.json()["sessao_id"]

    # 1. Convidado aceita
    client.patch("/dupla/responder-convite", json={
        "sessao_id": sessao_id,
        "usuario_id": "guest_treino",
        "resposta": "aceito"
    })

    # 2. Host seleciona os exercícios do treino
    treino_dados = {
        "nome": "Treino Braço e Ombro",
        "exercicios": [
            {"id": "16", "nome": "Desenvolvimento com Halteres", "series": 3, "repeticoes": 10},
            {"id": "20", "nome": "Rosca Direta", "series": 3, "repeticoes": 12}
        ]
    }
    sel_resp = client.post("/dupla/selecionar-treino", json={
        "sessao_id": sessao_id,
        "host_id": "host_treino",
        "dados_treino": treino_dados,
        "total_series": 3
    })
    assert sel_resp.status_code == 200
    assert sel_resp.json()["sucesso"] is True

    # 3. Host inicia o treino
    ini_resp = client.post("/dupla/iniciar-treino", json={
        "sessao_id": sessao_id,
        "host_id": "host_treino"
    })
    assert ini_resp.status_code == 200
    assert ini_resp.json()["status"] == "em_andamento"
    assert ini_resp.json()["sessao"]["turno_usuario_id"] == "host_treino"


def test_dupla_revezamento_turnos_e_pontuacao(client):
    """Testa alternância estrita de turnos por série e acúmulo de pontos parciais."""
    c_resp = client.post("/dupla/convidar", json={
        "host_id": "atleta_a",
        "convidado_id": "atleta_b",
        "total_series": 3
    })
    sessao_id = c_resp.json()["sessao_id"]
    client.post("/dupla/responder-convite", json={"sessao_id": sessao_id, "usuario_id": "atleta_b", "resposta": "aceito"})
    client.post("/dupla/iniciar-treino", json={"sessao_id": sessao_id, "host_id": "atleta_a"})

    # Turno 1: Atleta A (Host) executa Série 1 e faz 50 pontos
    r1 = client.post("/dupla/concluir-serie", json={
        "sessao_id": sessao_id,
        "usuario_id": "atleta_a",
        "pontos_serie": 50,
        "nova_serie": 1
    })
    assert r1.status_code == 200
    assert r1.json()["proximo_turno"] == "atleta_b"
    assert r1.json()["pontos_host"] == 50
    assert r1.json()["pontos_convidado"] == 0

    # Turno 2: Atleta B (Convidado) executa Série 1 e faz 45 pontos
    r2 = client.post("/dupla/concluir-serie", json={
        "sessao_id": sessao_id,
        "usuario_id": "atleta_b",
        "pontos_serie": 45,
        "nova_serie": 2
    })
    assert r2.status_code == 200
    assert r2.json()["proximo_turno"] == "atleta_a"
    assert r2.json()["pontos_host"] == 50
    assert r2.json()["pontos_convidado"] == 45


def test_dupla_calculo_matematico_bonus_cooperativo(client):
    """
    Testa a fórmula matemática rigorosa da pontuação cooperativa:
    Pontos Final = round(((Pontos_Host + Pontos_Guest) / 2) * 1.20)
    Exemplo: Host = 90, Guest = 70.
    Média = 80.
    Bônus (+20%) = 80 * 1.20 = 96 pontos para cada.
    """
    c_resp = client.post("/dupla/convidar", json={
        "host_id": "user_host_gamificacao",
        "convidado_id": "user_guest_gamificacao",
    })
    sessao_id = c_resp.json()["sessao_id"]

    # Simula pontos acumulados
    client.post("/dupla/concluir-serie", json={
        "sessao_id": sessao_id,
        "usuario_id": "user_host_gamificacao",
        "pontos_serie": 90
    })
    client.post("/dupla/concluir-serie", json={
        "sessao_id": sessao_id,
        "usuario_id": "user_guest_gamificacao",
        "pontos_serie": 70
    })

    # Encerra sessão e valida cálculo
    with patch("main.adicionar_pontuacao_diaria") as mock_pontos:
        mock_pontos.return_value = {"sucesso": True, "pontos_adicionados": 96}

        resp = client.post("/dupla/encerrar-sessao", json={
            "sessao_id": sessao_id,
            "solicitante_id": "user_host_gamificacao"
        })
        assert resp.status_code == 200
        dados = resp.json()
        assert dados["sucesso"] is True
        assert dados["pontos_host"] == 90
        assert dados["pontos_convidado"] == 70
        assert dados["media_dupla"] == 80.0
        assert dados["multiplicador"] == 1.20
        assert dados["pontos_finais_cada"] == 96  # round(80 * 1.2) = 96

        # Garante que adicionar_pontuacao_diaria foi chamado para ambos os participantes
        assert mock_pontos.call_count == 2


def test_dupla_estado_inexistente_404(client):
    """Retorna HTTP 404 para consulta de ID de sessão inexistente."""
    resp = client.get("/dupla/estado/sessao_nao_existente_999")
    assert resp.status_code == 404

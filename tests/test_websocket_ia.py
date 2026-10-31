"""
Testes automatizados da rota WebSocket /ia/ws/{usuario_id}.
Testa a conexão persistente, recepção de ângulos, resposta com FSM/DTW,
ping/pong para keep-alive e troca dinâmica de exercício in-place.
"""

from fastapi.testclient import TestClient
from BD.api import app


def test_websocket_ia_conexao_e_envio_angulos():
    client = TestClient(app)
    with client.websocket_connect("/ia/ws/usuario_teste_ws?exercicio=16&lado=direito") as ws:
        # 1. Envia frame com cotovelo e ombro em repouso
        payload = {
            "angulos": {"cotovelo": 90.0, "ombro": 75.0},
            "visivel": True,
        }
        ws.send_json(payload)
        resp = ws.receive_json()

        assert resp.get("sucesso") is True
        assert resp.get("usuario_id") == "usuario_teste_ws"
        assert resp.get("corpo_visivel") is True
        assert "fase_nome" in resp
        assert "repeticoes" in resp
        assert resp.get("angulos", {}).get("cotovelo") == 90.0


def test_websocket_ia_fluxo_movimento():
    client = TestClient(app)
    with client.websocket_connect("/ia/ws/usuario_fluxo_ws?exercicio=16&lado=direito") as ws:
        # Simula sequência de fotogramas
        curva_cotovelo = [90.0, 110.0, 130.0, 155.0, 130.0, 95.0]
        for ang in curva_cotovelo:
            ws.send_json({
                "angulos": {"cotovelo": float(ang), "ombro": 75.0},
                "visivel": True,
            })
            resp = ws.receive_json()
            assert resp.get("sucesso") is True
            assert "fase_numero" in resp


def test_websocket_ia_ping_pong_e_comandos():
    client = TestClient(app)
    with client.websocket_connect("/ia/ws/usuario_cmd_ws?exercicio=16&lado=direito") as ws:
        # Ping / Pong (heartbeat para evitar timeout do Render)
        ws.send_json({"tipo": "ping"})
        resp_ping = ws.receive_json()
        assert resp_ping == {"tipo": "pong"}

        # Reiniciar sessão
        ws.send_json({"tipo": "reiniciar"})
        resp_reiniciar = ws.receive_json()
        assert resp_reiniciar.get("tipo") == "sessao_reiniciada"

        # Trocar exercício in-place
        ws.send_json({"tipo": "trocar_exercicio", "exercicio_id": "20", "lado": "direito"})
        resp_troca = ws.receive_json()
        assert resp_troca.get("tipo") == "exercicio_trocado"

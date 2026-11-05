"""
Suíte de Testes Automatizados — Isolamento de Sessão Multi-Usuário (Stateless Auth).
Reproduz e valida a correção do cenário crítico onde 4 usuários fazem login simultaneamente
(sendo 'Ramon' o último a logar) e garante que nenhum usuário herde ou receba a sessão,
o ID ou os dados de outro usuário.
"""

import sys
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch, MagicMock

RAIZ_REPO = Path(__file__).resolve().parent.parent
if str(RAIZ_REPO) not in sys.path:
    sys.path.insert(0, str(RAIZ_REPO))

# Salvaguarda para ambientes leves onde pacotes nativos de imagem não estejam instalados
for _mod in ("numpy", "cv2", "multipart", "python_multipart", "multipart.multipart"):
    if _mod not in sys.modules:
        try:
            __import__(_mod)
        except ImportError:
            _m = MagicMock()
            _m.__version__ = "0.0.20"
            sys.modules[_mod] = _m

try:
    import pytest
except ImportError:
    pytest = None

from fastapi.testclient import TestClient
from BD.api import app, bd


if pytest is not None:
    @pytest.fixture
    def client():
        return TestClient(app)


def _criar_mock_clientes_isolados(usuarios_db: dict, tokens_db: dict):
    """
    Fábrica de mocks para criar_cliente_auth() simulando autenticação stateless
    para múltiplos usuários (Ana, Bruno, Carlos e Ramon).
    """
    def _factory():
        mock_client = MagicMock()

        def _sign_in(credenciais: dict):
            email = credenciais.get("email")
            for uid, dados in usuarios_db.items():
                if dados["email"] == email:
                    user_ns = SimpleNamespace(
                        id=uid,
                        email=dados["email"],
                        user_metadata={"nome": dados["nome"]},
                    )
                    session_ns = SimpleNamespace(
                        access_token=dados["token"],
                        refresh_token=f"refresh_{uid}",
                    )
                    return SimpleNamespace(user=user_ns, session=session_ns)
            return SimpleNamespace(user=None, session=None)

        def _get_user(jwt_token: str = None):
            # Se alguém chamasse get_user() sem token, em um cliente compartilhado retornaria Ramon.
            # No novo design, get_user exige o jwt_token explícito do usuário.
            if not jwt_token or jwt_token not in tokens_db:
                return SimpleNamespace(user=None)
            uid = tokens_db[jwt_token]
            dados = usuarios_db[uid]
            user_ns = SimpleNamespace(
                id=uid,
                email=dados["email"],
                user_metadata={"nome": dados["nome"]},
            )
            return SimpleNamespace(user=user_ns)

        mock_client.auth.sign_in_with_password.side_effect = _sign_in
        mock_client.auth.get_user.side_effect = _get_user
        return mock_client

    return _factory


def test_quatro_usuarios_logando_simultaneamente_nao_viram_ramon(client):
    """
    Dado que 4 usuários (Ana, Bruno, Carlos e Ramon) fazem login em sequência no servidor,
    Quando cada um consulta /auth/usuario-atual com seu próprio token JWT,
    Então cada usuário recebe estritamente seus próprios dados e jamais vira o usuário Ramon.
    """
    usuarios_db = {
        "uid-1-ana": {"nome": "Ana Silva", "email": "ana@teste.com", "token": "jwt-token-ana"},
        "uid-2-bruno": {"nome": "Bruno Costa", "email": "bruno@teste.com", "token": "jwt-token-bruno"},
        "uid-3-carlos": {"nome": "Carlos Souza", "email": "carlos@teste.com", "token": "jwt-token-carlos"},
        "uid-4-ramon": {"nome": "Ramon Oliveira", "email": "ramon@teste.com", "token": "jwt-token-ramon"},
    }
    tokens_db = {v["token"]: k for k, v in usuarios_db.items()}

    with patch.object(bd, "criar_cliente_auth", side_effect=_criar_mock_clientes_isolados(usuarios_db, tokens_db)), \
         patch.object(bd, "_buscar_nome_usuario_tabela", side_effect=lambda uid, meta=None: usuarios_db[uid]["nome"]):

        # 1. Os 4 usuários fazem login (Ramon é o último a logar)
        sessoes_clientes = {}
        for uid, info in usuarios_db.items():
            resp_login = client.post(
                "/auth/login",
                json={"email": info["email"], "senha": "123456"},
            )
            assert resp_login.status_code == 200
            body = resp_login.json()
            assert body["sucesso"] is True
            assert body["usuario"]["id"] == uid
            assert body["usuario"]["nome"] == info["nome"]
            sessoes_clientes[uid] = body["sessao"]["access_token"]

        # 2. Todos os 4 usuários consultam /auth/usuario-atual após o login do Ramon
        for uid, info in usuarios_db.items():
            token_do_aparelho = sessoes_clientes[uid]
            resp_me = client.get(
                "/auth/usuario-atual",
                headers={"Authorization": f"Bearer {token_do_aparelho}"},
            )
            assert resp_me.status_code == 200
            dados_me = resp_me.json()
            assert dados_me["sucesso"] is True
            assert dados_me["usuario"]["id"] == uid, f"Usuário {info['nome']} virou {dados_me['usuario']}"
            assert dados_me["usuario"]["nome"] == info["nome"]
            assert dados_me["usuario"]["email"] == info["email"]


def test_usuario_atual_sem_token_nao_vaza_sessao_do_ramon(client):
    """
    Garante que uma chamada a /auth/usuario-atual sem token e sem usuario_id
    jamais retorne o último usuário que fez login no servidor.
    """
    resp = client.get("/auth/usuario-atual")
    assert resp.status_code == 200
    dados = resp.json()
    assert dados["sucesso"] is False
    assert dados["usuario"] is None


def test_logout_de_um_usuario_nao_desloga_demais_usuarios(client):
    """
    Garante que quando um usuário aciona /auth/logout, os demais usuários
    continuam autenticados normalmente.
    """
    usuarios_db = {
        "uid-ana": {"nome": "Ana", "email": "ana@teste.com", "token": "jwt-ana"},
        "uid-ramon": {"nome": "Ramon", "email": "ramon@teste.com", "token": "jwt-ramon"},
    }
    tokens_db = {v["token"]: k for k, v in usuarios_db.items()}

    with patch.object(bd, "criar_cliente_auth", side_effect=_criar_mock_clientes_isolados(usuarios_db, tokens_db)), \
         patch.object(bd, "_buscar_nome_usuario_tabela", side_effect=lambda uid, meta=None: usuarios_db[uid]["nome"]):

        # Ramon desloga
        resp_logout = client.post(
            "/auth/logout",
            headers={"Authorization": "Bearer jwt-ramon"},
        )
        assert resp_logout.status_code == 200
        assert resp_logout.json()["sucesso"] is True

        # Ana continua logada e obtém seus próprios dados
        resp_ana = client.get(
            "/auth/usuario-atual",
            headers={"Authorization": "Bearer jwt-ana"},
        )
        assert resp_ana.status_code == 200
        assert resp_ana.json()["sucesso"] is True
        assert resp_ana.json()["usuario"]["id"] == "uid-ana"
        assert resp_ana.json()["usuario"]["nome"] == "Ana"


if __name__ == "__main__":
    c = TestClient(app)
    test_quatro_usuarios_logando_simultaneamente_nao_viram_ramon(c)
    test_usuario_atual_sem_token_nao_vaza_sessao_do_ramon(c)
    test_logout_de_um_usuario_nao_desloga_demais_usuarios(c)
    print("TODOS OS TESTES DE ISOLAMENTO DE SESSAO MULTI-USUARIO PASSARAM COM SUCESSO!")

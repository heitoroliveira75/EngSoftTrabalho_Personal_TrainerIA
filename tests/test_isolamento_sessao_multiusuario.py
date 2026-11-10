"""
Suíte de Testes Automatizados — Isolamento de Sessão Multi-Usuário e Controle de Dispositivo Único.
Valida:
1. 4 usuários logando simultaneamente (com 'Ramon' por último) sem vazamento ou mistura de dados;
2. Bloqueio de login quando a mesma conta já está conectada em outro dispositivo (ja_conectado=True);
3. Opção 'forcar_login=True' que desconecta o aparelho antigo (sessao_encerrada=True) e autentica o novo;
4. Liberação imediata de novo login após logout explícito.
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
        bd._sessoes_ativas_usuarios.clear()
        return TestClient(app)


def _criar_mock_clientes_isolados(usuarios_db: dict, tokens_db: dict):
    """
    Fábrica de mocks para criar_cliente_auth() simulando autenticação stateless
    para múltiplos usuários (Ana, Bruno, Carlos e Ramon).
    """
    contador_tokens = {"n": 0}

    def _factory():
        mock_client = MagicMock()

        def _sign_in(credenciais: dict):
            email = credenciais.get("email")
            for uid, dados in usuarios_db.items():
                if dados["email"] == email:
                    contador_tokens["n"] += 1
                    token_gerado = f"{dados['token']}_v{contador_tokens['n']}"
                    tokens_db[token_gerado] = uid
                    user_ns = SimpleNamespace(
                        id=uid,
                        email=dados["email"],
                        user_metadata={"nome": dados["nome"]},
                    )
                    session_ns = SimpleNamespace(
                        access_token=token_gerado,
                        refresh_token=f"refresh_{uid}_{contador_tokens['n']}",
                    )
                    return SimpleNamespace(user=user_ns, session=session_ns)
            return SimpleNamespace(user=None, session=None)

        def _get_user(jwt_token: str = None):
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
    bd._sessoes_ativas_usuarios.clear()
    usuarios_db = {
        "uid-1-ana": {"nome": "Ana Silva", "email": "ana@teste.com", "token": "jwt-token-ana"},
        "uid-2-bruno": {"nome": "Bruno Costa", "email": "bruno@teste.com", "token": "jwt-token-bruno"},
        "uid-3-carlos": {"nome": "Carlos Souza", "email": "carlos@teste.com", "token": "jwt-token-carlos"},
        "uid-4-ramon": {"nome": "Ramon Oliveira", "email": "ramon@teste.com", "token": "jwt-token-ramon"},
    }
    tokens_db = {}

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


def test_bloqueio_segundo_dispositivo_e_forcar_login(client):
    """
    Valida que:
    1. Se o Celular 1 já está conectado na conta da Ana, o Celular 2 é impedido de logar (ja_conectado=True).
    2. Se o Celular 2 enviar forcar_login=True, o login é aceito e o Celular 1 tem sua sessão encerrada (sessao_encerrada=True).
    """
    bd._sessoes_ativas_usuarios.clear()
    usuarios_db = {
        "uid-ana": {"nome": "Ana", "email": "ana@teste.com", "token": "jwt-ana"},
    }
    tokens_db = {}

    with patch.object(bd, "criar_cliente_auth", side_effect=_criar_mock_clientes_isolados(usuarios_db, tokens_db)), \
         patch.object(bd, "_buscar_nome_usuario_tabela", side_effect=lambda uid, meta=None: usuarios_db[uid]["nome"]):

        # 1. Celular 1 faz login normalmente
        r1 = client.post("/auth/login", json={"email": "ana@teste.com", "senha": "123"}).json()
        assert r1["sucesso"] is True
        token_celular_1 = r1["sessao"]["access_token"]

        # 2. Celular 2 tenta fazer login na mesma conta sem forcar_login -> Bloqueado!
        r2 = client.post("/auth/login", json={"email": "ana@teste.com", "senha": "123", "forcar_login": False}).json()
        assert r2["sucesso"] is False
        assert r2["ja_conectado"] is True

        # Celular 1 continua ativo normalmente
        me1 = client.get("/auth/usuario-atual", headers={"Authorization": f"Bearer {token_celular_1}"}).json()
        assert me1["sucesso"] is True
        assert me1["usuario"]["id"] == "uid-ana"

        # 3. Celular 2 confirma "Desconectar outro e entrar" (forcar_login=True)
        r3 = client.post("/auth/login", json={"email": "ana@teste.com", "senha": "123", "forcar_login": True}).json()
        assert r3["sucesso"] is True
        token_celular_2 = r3["sessao"]["access_token"]
        assert token_celular_2 != token_celular_1

        # 4. Celular 1 agora recebe sessao_encerrada=True!
        me1_depois = client.get("/auth/usuario-atual", headers={"Authorization": f"Bearer {token_celular_1}"}).json()
        assert me1_depois["sucesso"] is False
        assert me1_depois.get("sessao_encerrada") is True

        # 5. Celular 2 opera normalmente
        me2 = client.get("/auth/usuario-atual", headers={"Authorization": f"Bearer {token_celular_2}"}).json()
        assert me2["sucesso"] is True
        assert me2["usuario"]["id"] == "uid-ana"


def test_logout_libera_novo_login_sem_bloqueio(client):
    """
    Garante que quando o usuário faz logout no Celular 1, o Celular 2 pode fazer login
    imediatamente sem aviso de conta já conectada.
    """
    bd._sessoes_ativas_usuarios.clear()
    usuarios_db = {
        "uid-ana": {"nome": "Ana", "email": "ana@teste.com", "token": "jwt-ana"},
    }
    tokens_db = {}

    with patch.object(bd, "criar_cliente_auth", side_effect=_criar_mock_clientes_isolados(usuarios_db, tokens_db)), \
         patch.object(bd, "_buscar_nome_usuario_tabela", side_effect=lambda uid, meta=None: usuarios_db[uid]["nome"]):

        r1 = client.post("/auth/login", json={"email": "ana@teste.com", "senha": "123"}).json()
        assert r1["sucesso"] is True
        token_c1 = r1["sessao"]["access_token"]

        # Celular 1 faz logout
        resp_logout = client.post(
            "/auth/logout?usuario_id=uid-ana",
            headers={"Authorization": f"Bearer {token_c1}"},
        )
        assert resp_logout.status_code == 200
        assert resp_logout.json()["sucesso"] is True

        # Celular 2 faz login sem precisar de forcar_login
        r2 = client.post("/auth/login", json={"email": "ana@teste.com", "senha": "123"}).json()
        assert r2["sucesso"] is True
        assert r2.get("ja_conectado") is False


def test_pontuacao_e_streak_nao_zeram_com_rls_stateless(client):
    """
    Regressão pós-Entrada #025:
    Quando o cliente global 'supabase' opera sem JWT (papel anon bloqueado por RLS, retornando data=[]),
    ver_pontuacao e ver_perfil devem usar criar_cliente_db(token) autenticado com o JWT do usuário
    para retornar pontuacao_diaria, pontuacao_semanal, pontuacao_total, sequencia e maior_sequencia reais.
    """
    bd._sessoes_ativas_usuarios.clear()
    usuarios_db = {
        "uid-atleta-1": {
            "id": "uid-atleta-1",
            "nome": "Davi Atleta",
            "email": "davi@teste.com",
            "token": "jwt-davi",
            "pontuacao_diaria": 120,
            "pontuacao_semanal": 540,
            "pontuacao_total": 1850,
            "sequencia": 7,
            "maior_sequencia": 14,
            "checagem": True,
        }
    }
    tokens_db = {}

    def _mock_criar_cliente_db(token_jwt: str = None):
        mock_db = MagicMock()
        uid_authed = tokens_db.get(token_jwt)
        linha = [usuarios_db[uid_authed]] if uid_authed in usuarios_db else []
        mock_table = MagicMock()
        mock_table.select.return_value.eq.return_value.execute.return_value = SimpleNamespace(data=linha)
        mock_table.select.return_value.eq.return_value.limit.return_value.execute.return_value = SimpleNamespace(data=linha)
        mock_db.table.return_value = mock_table
        return mock_db

    # Simula RLS bloqueando o cliente global 'supabase' (sempre retorna data=[])
    mock_anon_supabase = MagicMock()
    mock_anon_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value = SimpleNamespace(data=[])
    mock_anon_supabase.table.return_value.select.return_value.eq.return_value.limit.return_value.execute.return_value = SimpleNamespace(data=[])

    with patch.object(bd, "criar_cliente_auth", side_effect=_criar_mock_clientes_isolados(usuarios_db, tokens_db)), \
         patch.object(bd, "criar_cliente_db", side_effect=_mock_criar_cliente_db), \
         patch.object(bd, "supabase", mock_anon_supabase):

        # 1. Faz login e verifica se métricas já vêm preenchidas no login
        r_login = client.post("/auth/login", json={"email": "davi@teste.com", "senha": "123"}).json()
        assert r_login["sucesso"] is True
        jwt_token = r_login["sessao"]["access_token"]
        assert r_login["usuario"]["pontuacao_total"] == 1850
        assert r_login["usuario"]["sequencia"] == 7
        assert r_login["usuario"]["maior_sequencia"] == 14

        # 2. Consulta /pontuacao/{usuario_id} com o JWT e garante que não vem zerado
        r_pts = client.get(
            "/pontuacao/uid-atleta-1",
            headers={"Authorization": f"Bearer {jwt_token}"},
        ).json()
        assert r_pts["sucesso"] is True
        assert r_pts["pontuacao_diaria"] == 120
        assert r_pts["pontuacao_semanal"] == 540
        assert r_pts["pontuacao_total"] == 1850
        assert r_pts["sequencia"] == 7
        assert r_pts["maior_sequencia"] == 14

        # 3. Consulta /perfil/{usuario_id} com o JWT e garante que não vem zerado
        r_perfil = client.get(
            "/perfil/uid-atleta-1",
            headers={"Authorization": f"Bearer {jwt_token}"},
        ).json()
        assert r_perfil["sucesso"] is True
        assert r_perfil["perfil"]["pontuacao_total"] == 1850
        assert r_perfil["perfil"]["sequencia"] == 7


if __name__ == "__main__":
    c = TestClient(app)
    test_quatro_usuarios_logando_simultaneamente_nao_viram_ramon(c)
    test_usuario_atual_sem_token_nao_vaza_sessao_do_ramon(c)
    test_bloqueio_segundo_dispositivo_e_forcar_login(c)
    test_logout_libera_novo_login_sem_bloqueio(c)
    test_pontuacao_e_streak_nao_zeram_com_rls_stateless(c)
    print("TODOS OS 5 TESTES DE ISOLAMENTO, RLS E CONTROLE DE DISPOSITIVO UNICO PASSARAM COM SUCESSO!")

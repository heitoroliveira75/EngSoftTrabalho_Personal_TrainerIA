import os
from pathlib import Path

from dotenv import load_dotenv
from supabase import create_client, Client, ClientOptions


# Localiza o diretório onde este arquivo está
BASE_DIR = Path(__file__).resolve().parent

# Carrega o arquivo .env
load_dotenv(BASE_DIR / ".env")


# Lê as variáveis de ambiente
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY") or os.getenv("SUPABASE_PUBLISHABLE_KEY")


# Verifica se as configurações existem com fallback seguro para testes e desenvolvimento local
if not SUPABASE_URL or not SUPABASE_KEY:
    SUPABASE_URL = SUPABASE_URL or "https://placeholder-project.supabase.co"
    SUPABASE_KEY = SUPABASE_KEY or "placeholder-anon-key"
    print("Aviso: SUPABASE_URL ou chave não encontrada no .env. Operando em modo de desenvolvimento/teste local.")


def _opcoes_stateless() -> ClientOptions:
    """Retorna opções stateless para impedir persistência de sessão compartilhada em memória no servidor."""
    return ClientOptions(auto_refresh_token=False, persist_session=False)


def criar_cliente_auth() -> Client:
    """
    Cria uma instância isolada e descartável do cliente Supabase para operações de autenticação
    (login, cadastro, validação de JWT e alteração de senha).
    Garante que múltiplos usuários logando simultaneamente jamais compartilhem ou sobrescrevam
    a sessão uns dos outros ou os headers do cliente global de banco de dados.
    """
    return create_client(SUPABASE_URL, SUPABASE_KEY, options=_opcoes_stateless())


# Cria o cliente Supabase global exclusivamente para consultas de banco (PostgREST / RPC)
supabase: Client = create_client(
    SUPABASE_URL,
    SUPABASE_KEY,
    options=_opcoes_stateless(),
)

print("Supabase configurado")

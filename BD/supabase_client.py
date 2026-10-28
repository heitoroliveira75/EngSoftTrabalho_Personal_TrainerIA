import os
from pathlib import Path

from dotenv import load_dotenv
from supabase import create_client, Client


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


# Cria o cliente Supabase
supabase: Client = create_client(
    SUPABASE_URL,
    SUPABASE_KEY
)

print("Supabase configurado")

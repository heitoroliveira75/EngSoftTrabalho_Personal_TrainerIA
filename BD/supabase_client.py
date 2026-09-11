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
SUPABASE_PUBLISHABLE_KEY = os.getenv("SUPABASE_PUBLISHABLE_KEY")


# Verifica se as configurações existem
if not SUPABASE_URL:
    raise RuntimeError("SUPABASE_URL não foi encontrada no .env")

if not SUPABASE_PUBLISHABLE_KEY:
    raise RuntimeError(
        "SUPABASE_PUBLISHABLE_KEY não foi encontrada no .env"
    )


# Cria o cliente Supabase
supabase: Client = create_client(
    SUPABASE_URL,
    SUPABASE_PUBLISHABLE_KEY
)

print("Supabase conectado")
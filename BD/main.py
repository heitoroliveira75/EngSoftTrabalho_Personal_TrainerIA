import os

from dotenv import load_dotenv
from supabase import create_client, Client


from supabase_client import supabase

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_PUBLISHABLE_KEY = os.getenv("SUPABASE_PUBLISHABLE_KEY")

if not SUPABASE_URL or not SUPABASE_PUBLISHABLE_KEY:
    raise RuntimeError(
        "Os dados precisam estar definidos no .env"
    )

supabase: Cliente = create_client(
    SUPABASE_URL,
    SUPABASE_PUBLISHABLE_KEY
)

print("Supabase conectado")


def criar_usuario(email: str, senha: str, nome: str):
    resposta = supabase.auth.sign_up({
        "email": email,
        "password": senha,
        "options":{
            "data":{
                "nome": nome
            }
        }
    })

    return resposta

def login_usuario(email: str, senha: str):
    resposta = supabase.auth.sign_in_with_password({
        "email": email,
        "password": senha
    })

    return resposta



if __name__ == "__main__":
    resposta = login_usuario(
        email="teste5@teste.com",
        senha="teste123"
    )

    if resposta.user:
        print("Login realizado com sucesso!")
        print("ID:", resposta.user.id)

        resultado = (
            supabase
            .table("usuarios")
            .select("*")
            .execute()
        )



        print("Dados do perfil:")
        print(resultado.data)
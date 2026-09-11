from supabase_client import supabase


def login_usuario(email: str, senha: str):
    """
    Realiza login utilizando e-mail e senha.
    """
    resposta = supabase.auth.sign_in_with_password({
        "email": email,
        "password": senha
    })

    return resposta


def mostrar_perfil():
    """
    Consulta os perfis permitidos pela RLS.

    Como nossa policy utiliza auth.uid(),
    o usuário autenticado deve conseguir enxergar
    somente o próprio perfil.
    """
    resultado = (
        supabase
        .table("usuarios")
        .select("*")
        .execute()
    )

    return resultado.data


def atualizar_proprio_perfil(nome: str, cpf: str):
    """
    Atualiza o perfil do usuário atualmente autenticado.

    O ID é obtido através do usuário autenticado,
    e não fornecido pelo usuário.
    """
    usuario_atual = supabase.auth.get_user()

    if usuario_atual.user is None:
        raise RuntimeError("Nenhum usuário autenticado.")

    usuario_id = usuario_atual.user.id

    resultado = (
        supabase
        .table("usuarios")
        .update({
            "nome": nome,
            "cpf": cpf
        })
        .eq("id", usuario_id)
        .execute()
    )

    return resultado.data


def tentar_editar_outro_usuario(outro_usuario_id: str):
    """
    Tenta alterar o perfil de outro usuário.

    Neste teste, João estará autenticado e tentará
    alterar o perfil da Maria.

    A RLS deve impedir essa operação.
    """
    resultado = (
        supabase
        .table("usuarios")
        .update({
            "nome": "HACKED"
        })
        .eq("id", outro_usuario_id)
        .execute()
    )

    return resultado.data


if __name__ == "__main__":

    # =================================================
    # UUID DA MARIA
    # =================================================
    #
    # Cole aqui o UUID que apareceu na primeira execução.
    #

    MARIA_ID = "ac05b2e9-b74c-4c4d-8f32-a210011fa099"


    # =================================================
    # 1. LIMPA QUALQUER SESSÃO ANTERIOR
    # =================================================

    try:
        supabase.auth.sign_out()
        print("Sessão anterior encerrada.")
    except Exception:
        pass


    # =================================================
    # 2. LOGIN DO JOÃO
    # =================================================

    resposta = login_usuario(
        email="teste5@teste.com",
        senha="teste123"
    )

    if resposta.user is None:
        print("Login falhou.")
        raise SystemExit(1)


    print("\n====================")
    print("LOGIN")
    print("====================")

    print("ID:", resposta.user.id)
    print("Email:", resposta.user.email)


    # =================================================
    # 3. VERIFICA A SESSÃO
    # =================================================

    if resposta.session is None:
        print("Nenhuma sessão foi criada.")
        raise SystemExit(1)


    print("\n====================")
    print("SESSION")
    print("====================")

    print("ID do usuário:", resposta.session.user.id)


    # =================================================
    # 4. VERIFICA O USUÁRIO ATUAL
    # =================================================

    usuario_atual = supabase.auth.get_user()

    if usuario_atual.user is None:
        print("Não foi possível obter o usuário atual.")
        raise SystemExit(1)


    print("\n====================")
    print("GET_USER")
    print("====================")

    print("ID:", usuario_atual.user.id)
    print("Email:", usuario_atual.user.email)


    # =================================================
    # 5. LÊ O PERFIL DO JOÃO
    # =================================================

    perfil = mostrar_perfil()


    print("\n====================")
    print("PERFIL ATUAL")
    print("====================")

    print(perfil)


    # =================================================
    # 6. ATUALIZA O PRÓPRIO PERFIL
    # =================================================

    perfil_atualizado = atualizar_proprio_perfil(
        nome="João Pedro de Almeida",
        cpf="11111111111"
    )


    print("\n====================")
    print("ATUALIZANDO PRÓPRIO PERFIL")
    print("====================")

    print(perfil_atualizado)


    # =================================================
    # 7. CONSULTA NOVAMENTE
    # =================================================

    perfil = mostrar_perfil()


    print("\n====================")
    print("PERFIL DEPOIS DA ATUALIZAÇÃO")
    print("====================")

    print(perfil)


    # =================================================
    # 8. TESTE DE SEGURANÇA
    # =================================================

    print("\n====================")
    print("TESTE DE SEGURANÇA")
    print("====================")

    print("Usuário autenticado:", usuario_atual.user.email)
    print("Tentando alterar o perfil da Maria...")
    print("ID da Maria:", MARIA_ID)


    try:

        resultado_hack = tentar_editar_outro_usuario(
            MARIA_ID
        )

        print("\nResultado da tentativa:")
        print(resultado_hack)


    except Exception as erro:

        print("\nA operação foi rejeitada:")
        print(erro)


    # =================================================
    # 9. FINALIZA
    # =================================================

    print("\n====================")
    print("TESTE FINALIZADO")
    print("====================")
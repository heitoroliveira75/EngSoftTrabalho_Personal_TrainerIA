from supabase_client import supabase


# ============================================================
# FUNÇÕES DE AUTENTICAÇÃO
# ============================================================

def criar_conta():
    print("\n" + "=" * 45)
    print("             CRIAR CONTA")
    print("=" * 45)

    nome = input("Nome: ").strip()
    email = input("Email: ").strip()
    senha = input("Senha: ").strip()

    if not nome or not email or not senha:
        print("\n[ERRO] Todos os campos são obrigatórios.")
        return

    try:
        resposta = supabase.auth.sign_up({
            "email": email,
            "password": senha,
            "options": {
                "data": {
                    "nome": nome
                }
            }
        })

        if resposta.user is None:
            print("\n[ERRO] Não foi possível criar a conta.")
            print(resposta)
            return

        print("\n[OK] Conta criada com sucesso!")
        print("ID:", resposta.user.id)
        print("Email:", resposta.user.email)

        print("\nAgora você pode fazer login.")

    except Exception as erro:
        print("\n[ERRO] Não foi possível criar a conta.")
        print(erro)


def fazer_login():
    print("\n" + "=" * 45)
    print("                LOGIN")
    print("=" * 45)

    email = input("Email: ").strip()
    senha = input("Senha: ").strip()

    if not email or not senha:
        print("\n[ERRO] Email e senha são obrigatórios.")
        return None

    try:
        resposta = supabase.auth.sign_in_with_password({
            "email": email,
            "password": senha
        })

        if resposta.user is None:
            print("\n[ERRO] Login não realizado.")
            return None

        print("\n[OK] Login realizado com sucesso!")

        return resposta.user

    except Exception as erro:
        print("\n[ERRO] Não foi possível realizar o login.")
        print(erro)
        return None


def fazer_logout():
    try:
        supabase.auth.sign_out()
        print("\n[OK] Logout realizado com sucesso.")

    except Exception as erro:
        print("\n[ERRO] Não foi possível realizar o logout.")
        print(erro)


# ============================================================
# FUNÇÕES DE PERFIL
# ============================================================

def obter_usuario_atual():
    resposta = supabase.auth.get_user()

    if resposta.user is None:
        return None

    return resposta.user


def visualizar_perfil():
    usuario = obter_usuario_atual()

    if usuario is None:
        print("\n[ERRO] Nenhum usuário autenticado.")
        return

    try:
        resultado = (
            supabase
            .table("usuarios")
            .select("*")
            .eq("id", usuario.id)
            .execute()
        )

        if not resultado.data:
            print("\n[ERRO] Perfil não encontrado.")
            return

        perfil = resultado.data[0]

        print("\n" + "=" * 45)
        print("              MEU PERFIL")
        print("=" * 45)

        print(f"Nome:       {perfil['nome']}")
        print(f"Email:      {usuario.email}")
        print(f"CPF:        {perfil['cpf']}")
        print(f"Criado em:  {perfil['created_at']}")

        print("=" * 45)

    except Exception as erro:
        print("\n[ERRO] Não foi possível carregar o perfil.")
        print(erro)


def editar_perfil():
    usuario = obter_usuario_atual()

    if usuario is None:
        print("\n[ERRO] Nenhum usuário autenticado.")
        return

    try:
        # Primeiro buscamos os dados atuais
        resultado = (
            supabase
            .table("usuarios")
            .select("*")
            .eq("id", usuario.id)
            .execute()
        )

        if not resultado.data:
            print("\n[ERRO] Perfil não encontrado.")
            return

        perfil = resultado.data[0]

        print("\n" + "=" * 45)
        print("             EDITAR PERFIL")
        print("=" * 45)

        print("Deixe vazio para manter o valor atual.\n")

        nome_atual = perfil["nome"]
        cpf_atual = perfil["cpf"]

        print(f"Nome atual: {nome_atual}")
        novo_nome = input("Novo nome: ").strip()

        print(f"\nCPF atual: {cpf_atual}")
        novo_cpf = input("Novo CPF: ").strip()

        # Se o usuário não digitou nada,
        # mantemos o valor atual
        if not novo_nome:
            novo_nome = nome_atual

        if not novo_cpf:
            novo_cpf = cpf_atual

        resultado = (
            supabase
            .table("usuarios")
            .update({
                "nome": novo_nome,
                "cpf": novo_cpf
            })
            .eq("id", usuario.id)
            .execute()
        )

        print("\n[OK] Perfil atualizado com sucesso!")

        print("\nDados atualizados:")
        print("Nome:", novo_nome)
        print("CPF:", novo_cpf)

    except Exception as erro:
        print("\n[ERRO] Não foi possível atualizar o perfil.")
        print(erro)


# ============================================================
# MENU DO USUÁRIO
# ============================================================

def menu_usuario(usuario):
    while True:

        print("\n" + "=" * 45)
        print("             MENU PRINCIPAL")
        print("=" * 45)

        print(f"Olá, {usuario.user_metadata.get('nome', 'Usuário')}!")
        print(f"Email: {usuario.email}")

        print("\n1 - Ver meu perfil")
        print("2 - Editar meu perfil")
        print("3 - Treinos")
        print("4 - Logout")
        print("0 - Sair")

        print("=" * 45)

        opcao = input("Escolha uma opção: ").strip()

        if opcao == "1":

            visualizar_perfil()

        elif opcao == "2":

            editar_perfil()

        elif opcao == "3":

            print("\n" + "=" * 45)
            print("                TREINOS")
            print("=" * 45)

            print("\nAinda vamos implementar essa parte.")
            print("Por enquanto, o CRUD de usuários está sendo desenvolvido.")

        elif opcao == "4":

            fazer_logout()
            return "logout"

        elif opcao == "0":

            return "sair"

        else:

            print("\n[ERRO] Opção inválida.")

        input("\nPressione ENTER para continuar...")


# ============================================================
# TELA INICIAL
# ============================================================

def tela_inicial():

    while True:

        print("\n" + "=" * 45)
        print("         SISTEMA DE TREINOS")
        print("=" * 45)

        print("\n1 - Criar conta")
        print("2 - Fazer login")
        print("0 - Sair")

        print("=" * 45)

        opcao = input("Escolha uma opção: ").strip()

        if opcao == "1":

            criar_conta()

            input("\nPressione ENTER para continuar...")

        elif opcao == "2":

            usuario = fazer_login()

            if usuario is not None:

                resultado = menu_usuario(usuario)

                if resultado == "sair":
                    break

        elif opcao == "0":

            print("\nEncerrando o sistema...")
            break

        else:

            print("\n[ERRO] Opção inválida.")


# ============================================================
# PROGRAMA PRINCIPAL
# ============================================================

if __name__ == "__main__":

    # Garante que não começamos com uma sessão antiga
    try:
        supabase.auth.sign_out()
    except Exception:
        pass

    print("\nSupabase conectado.")

    tela_inicial()

    print("\nPrograma encerrado.")
from typing import Optional, List, Dict, Any, Union
from supabase_client import supabase


# ============================================================
# 1. AUTENTICAÇÃO E SESSÃO
# ============================================================

def criar_conta(nome: str, email: str, senha: str) -> Dict[str, Any]:
    """
    Cria uma nova conta no Supabase Auth.
    A trigger do banco insere automaticamente o usuário na tabela 'usuarios'.
    """
    if not nome or not email or not senha:
        return {"sucesso": False, "mensagem": "Nome, e-mail e senha são obrigatórios."}

    try:
        resposta = supabase.auth.sign_up({
            "email": email.strip(),
            "password": senha.strip(),
            "options": {
                "data": {
                    "nome": nome.strip()
                }
            }
        })

        if not resposta.user:
            return {"sucesso": False, "mensagem": "Não foi possível criar a conta."}

        return {
            "sucesso": True,
            "mensagem": "Conta criada com sucesso!",
            "usuario": {
                "id": resposta.user.id,
                "email": resposta.user.email,
                "nome": nome.strip()
            }
        }
    except Exception as erro:
        return {"sucesso": False, "mensagem": str(erro)}


def fazer_login(email: str, senha: str) -> Dict[str, Any]:
    """
    Autentica o usuário com e-mail e senha, retornando os dados do usuário e tokens de sessão.
    """
    if not email or not senha:
        return {"sucesso": False, "mensagem": "E-mail e senha são obrigatórios."}

    try:
        resposta = supabase.auth.sign_in_with_password({
            "email": email.strip(),
            "password": senha.strip()
        })

        if not resposta.user:
            return {"sucesso": False, "mensagem": "Credenciais inválidas ou usuário não encontrado."}

        return {
            "sucesso": True,
            "mensagem": "Login realizado com sucesso!",
            "usuario": {
                "id": resposta.user.id,
                "email": resposta.user.email,
                "user_metadata": resposta.user.user_metadata
            },
            "sessao": {
                "access_token": resposta.session.access_token if resposta.session else None,
                "refresh_token": resposta.session.refresh_token if resposta.session else None
            }
        }
    except Exception as erro:
        return {"sucesso": False, "mensagem": str(erro)}


def deslogar_perfil() -> Dict[str, Any]:
    """
    Encerra a sessão ativa do usuário no Supabase.
    """
    try:
        supabase.auth.sign_out()
        return {"sucesso": True, "mensagem": "Logout realizado com sucesso."}
    except Exception as erro:
        return {"sucesso": False, "mensagem": str(erro)}


def obter_usuario_atual() -> Optional[Dict[str, Any]]:
    """
    Retorna os dados do usuário autenticado no momento no cliente Supabase.
    """
    try:
        resposta = supabase.auth.get_user()
        if resposta and resposta.user:
            return {
                "id": resposta.user.id,
                "email": resposta.user.email,
                "user_metadata": resposta.user.user_metadata
            }
        return None
    except Exception:
        return None


# ============================================================
# 2. PERFIL DE USUÁRIO
# ============================================================

def ver_perfil(usuario_id: str) -> Dict[str, Any]:
    """
    Consulta e retorna os dados cadastrais da tabela 'usuarios' referentes ao ID informado.
    """
    if not usuario_id:
        return {"sucesso": False, "mensagem": "ID do usuário é obrigatório."}

    try:
        resultado = (
            supabase
            .table("usuarios")
            .select("*")
            .eq("id", usuario_id)
            .execute()
        )

        if not resultado.data:
            return {"sucesso": False, "mensagem": "Perfil não encontrado."}

        return {
            "sucesso": True,
            "perfil": resultado.data[0]
        }
    except Exception as erro:
        return {"sucesso": False, "mensagem": str(erro)}


def editar_perfil(usuario_id: str, nome: Optional[str] = None, cpf: Optional[str] = None) -> Dict[str, Any]:
    """
    Atualiza os dados de nome e/ou CPF do usuário na tabela 'usuarios'.
    """
    if not usuario_id:
        return {"sucesso": False, "mensagem": "ID do usuário é obrigatório."}

    dados_atualizacao = {}
    if nome is not None and nome.strip() != "":
        dados_atualizacao["nome"] = nome.strip()
    if cpf is not None and cpf.strip() != "":
        dados_atualizacao["cpf"] = cpf.strip()

    if not dados_atualizacao:
        return {"sucesso": False, "mensagem": "Nenhum dado informado para atualização."}

    try:
        resultado = (
            supabase
            .table("usuarios")
            .update(dados_atualizacao)
            .eq("id", usuario_id)
            .execute()
        )

        if not resultado.data:
            return {"sucesso": False, "mensagem": "Não foi possível atualizar o perfil."}

        return {
            "sucesso": True,
            "mensagem": "Perfil atualizado com sucesso!",
            "perfil": resultado.data[0]
        }
    except Exception as erro:
        return {"sucesso": False, "mensagem": str(erro)}


# ============================================================
# 3. EXERCÍCIOS
# ============================================================

def listar_exercicios(grupo_muscular: Optional[str] = None) -> Dict[str, Any]:
    """
    Retorna a lista de exercícios cadastrados. Permite filtrar opcionalmente por grupo muscular.
    """
    try:
        consulta = supabase.table("exercicios").select("*")

        if grupo_muscular and grupo_muscular.strip() != "":
            consulta = consulta.ilike("grupo_muscular", f"%{grupo_muscular.strip()}%")

        resultado = consulta.execute()
        return {
            "sucesso": True,
            "exercicios": resultado.data or []
        }
    except Exception as erro:
        return {"sucesso": False, "mensagem": str(erro), "exercicios": []}


# ============================================================
# 4. TREINOS
# ============================================================

def ver_treinos_premont() -> Dict[str, Any]:
    """
    Lista todos os treinos pré-montados do sistema junto com seus exercícios associados.
    """
    try:
        resultado = (
            supabase
            .table("treinos")
            .select("*, treino_exercicios(*, exercicios(*))")
            .eq("pre_montado", True)
            .execute()
        )

        return {
            "sucesso": True,
            "treinos": resultado.data or []
        }
    except Exception as erro:
        return {"sucesso": False, "mensagem": str(erro), "treinos": []}


def listar_treinos(usuario_id: str) -> Dict[str, Any]:
    """
    Lista todos os treinos criados por um usuário específico com os respectivos exercícios vinculados.
    """
    if not usuario_id:
        return {"sucesso": False, "mensagem": "ID do usuário é obrigatório.", "treinos": []}

    try:
        resultado = (
            supabase
            .table("treinos")
            .select("*, treino_exercicios(*, exercicios(*))")
            .eq("usuario_id", usuario_id)
            .execute()
        )

        return {
            "sucesso": True,
            "treinos": resultado.data or []
        }
    except Exception as erro:
        return {"sucesso": False, "mensagem": str(erro), "treinos": []}


def criar_treino(
    usuario_id: Optional[str] = None,
    nome: str = "",
    descricao: str = "",
    pre_montado: bool = False,
    exercicios: Optional[List[Dict[str, Any]]] = None
) -> Dict[str, Any]:
    """
    Cria um novo treino na tabela 'treinos' e insere os exercícios associados na tabela 'treino_exercicios'.
    """
    if not nome:
        return {"sucesso": False, "mensagem": "Nome do treino é obrigatório."}

    if not pre_montado and not usuario_id:
        return {"sucesso": False, "mensagem": "ID do usuário é obrigatório para treinos personalizados."}

    try:
        dados_treino = {
            "nome": nome.strip(),
            "descricao": descricao.strip() if descricao else "",
            "pre_montado": pre_montado
        }
        if usuario_id:
            dados_treino["usuario_id"] = usuario_id

        res_treino = supabase.table("treinos").insert(dados_treino).execute()

        if not res_treino.data:
            return {"sucesso": False, "mensagem": "Não foi possível criar o treino."}

        treino_criado = res_treino.data[0]
        treino_id = treino_criado["id"]

        exercicios_adicionados = []
        if exercicios:
            registros_exercicios = [
                {
                    "treino_id": treino_id,
                    "exercicio_id": item["exercicio_id"],
                    "ordem": item.get("ordem", 1),
                    "series": item.get("series", 3),
                    "repeticoes": item.get("repeticoes", 10)
                }
                for item in exercicios
            ]

            res_ex = supabase.table("treino_exercicios").insert(registros_exercicios).execute()
            exercicios_adicionados = res_ex.data or []

        return {
            "sucesso": True,
            "mensagem": "Treino criado com sucesso!",
            "treino": treino_criado,
            "exercicios": exercicios_adicionados
        }
    except Exception as erro:
        return {"sucesso": False, "mensagem": str(erro)}


def editar_treino(
    treino_id: Union[int, str],
    nome: Optional[str] = None,
    descricao: Optional[str] = None,
    exercicios: Optional[List[Dict[str, Any]]] = None
) -> Dict[str, Any]:
    """
    Atualiza os dados do treino (nome/descrição) e/ou substitui a lista de exercícios vinculados.
    """
    if not treino_id:
        return {"sucesso": False, "mensagem": "ID do treino é obrigatório."}

    try:
        dados_atualizacao = {}
        if nome is not None and nome.strip() != "":
            dados_atualizacao["nome"] = nome.strip()
        if descricao is not None:
            dados_atualizacao["descricao"] = descricao.strip()

        if dados_atualizacao:
            res_treino = (
                supabase
                .table("treinos")
                .update(dados_atualizacao)
                .eq("id", treino_id)
                .execute()
            )
            if not res_treino.data:
                return {"sucesso": False, "mensagem": "Treino não encontrado para atualização."}

        if exercicios is not None:
            supabase.table("treino_exercicios").delete().eq("treino_id", treino_id).execute()

            if exercicios:
                registros_exercicios = [
                    {
                        "treino_id": treino_id,
                        "exercicio_id": item["exercicio_id"],
                        "ordem": item.get("ordem", 1),
                        "series": item.get("series", 3),
                        "repeticoes": item.get("repeticoes", 10)
                    }
                    for item in exercicios
                ]
                supabase.table("treino_exercicios").insert(registros_exercicios).execute()

        return {"sucesso": True, "mensagem": "Treino atualizado com sucesso!"}
    except Exception as erro:
        return {"sucesso": False, "mensagem": str(erro)}


def excluir_treino(treino_id: Union[int, str]) -> Dict[str, Any]:
    """
    Remove o treino da tabela 'treinos' e desvincula suas associações na tabela 'treino_exercicios'.
    """
    if not treino_id:
        return {"sucesso": False, "mensagem": "ID do treino é obrigatório."}

    try:
        supabase.table("treino_exercicios").delete().eq("treino_id", treino_id).execute()
        resultado = supabase.table("treinos").delete().eq("id", treino_id).execute()

        if not resultado.data:
            return {"sucesso": False, "mensagem": "Treino não encontrado para exclusão."}

        return {"sucesso": True, "mensagem": "Treino excluído com sucesso!"}
    except Exception as erro:
        return {"sucesso": False, "mensagem": str(erro)}
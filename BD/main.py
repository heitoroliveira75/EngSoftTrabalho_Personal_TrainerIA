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


def solicitar_redefinicao_senha(email: str, redirect_to: Optional[str] = None) -> Dict[str, Any]:
    """
    Envia um e-mail de recuperação de senha pelo Supabase Auth contendo um link ou código.
    """
    if not email:
        return {"sucesso": False, "mensagem": "E-mail é obrigatório."}

    try:
        opcoes = {}
        if redirect_to:
            opcoes["redirect_to"] = redirect_to

        supabase.auth.reset_password_for_email(
            email.strip(),
            options=opcoes if opcoes else None
        )

        return {
            "sucesso": True,
            "mensagem": "E-mail de recuperação enviado com sucesso! Verifique sua caixa de entrada."
        }
    except Exception as erro:
        return {"sucesso": False, "mensagem": str(erro)}


def redefinir_senha_com_codigo(email: str, token: str, nova_senha: str) -> Dict[str, Any]:
    """
    Valida o token/código OTP recebido por e-mail e define a nova senha do usuário.
    Ideal para aplicações desktop, mobile ou terminais CLI.
    """
    if not email or not token or not nova_senha:
        return {"sucesso": False, "mensagem": "E-mail, token e nova senha são obrigatórios."}

    try:
        # 1. Valida o código/token de recuperação e estabelece uma sessão temporária
        res_otp = supabase.auth.verify_otp({
            "email": email.strip(),
            "token": token.strip(),
            "type": "recovery"
        })

        if not res_otp.user:
            return {"sucesso": False, "mensagem": "Código de recuperação inválido ou expirado."}

        # 2. Com a sessão recuperada, atualiza a senha do usuário
        res_update = supabase.auth.update_user({
            "password": nova_senha.strip()
        })

        if not res_update.user:
            return {"sucesso": False, "mensagem": "Não foi possível atualizar a senha."}

        return {"sucesso": True, "mensagem": "Senha redefinida com sucesso!"}
    except Exception as erro:
        return {"sucesso": False, "mensagem": str(erro)}


def alterar_senha(nova_senha: str, senha_atual: Optional[str] = None, email: Optional[str] = None) -> Dict[str, Any]:
    """
    Atualiza a senha do usuário atualmente autenticado ou valida com senha atual se informada.
    """
    if not nova_senha:
        return {"sucesso": False, "mensagem": "A nova senha é obrigatória."}

    try:
        # Se email e senha_atual forem fornecidos, valida a senha atual antes de alterar
        if email and senha_atual:
            try:
                auth_res = supabase.auth.sign_in_with_password({
                    "email": email.strip(),
                    "password": senha_atual.strip()
                })
                if not auth_res.user:
                    return {"sucesso": False, "mensagem": "Senha atual incorreta."}
            except Exception as auth_err:
                return {"sucesso": False, "mensagem": f"Senha atual incorreta: {auth_err}"}

        res = supabase.auth.update_user({
            "password": nova_senha.strip()
        })

        if not res.user:
            return {"sucesso": False, "mensagem": "Não foi possível atualizar a senha."}

        return {"sucesso": True, "mensagem": "Senha alterada com sucesso!"}
    except Exception as erro:
        return {"sucesso": False, "mensagem": str(erro)}


def atualizar_senha(nova_senha: str) -> Dict[str, Any]:
    """
    Atualiza a senha do usuário atualmente autenticado (com sessão ativa).
    Útil caso o usuário já esteja logado ou tenha acessado via link de recuperação em app Web.
    """
    return alterar_senha(nova_senha=nova_senha)


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
            # Fallback para os metadados do auth se a linha da tabela usuarios ainda não estiver criada
            usuario_auth = obter_usuario_atual()
            if usuario_auth and usuario_auth.get("id") == usuario_id:
                nome = usuario_auth.get("user_metadata", {}).get("nome", "")
                return {
                    "sucesso": True,
                    "perfil": {
                        "id": usuario_id,
                        "email": usuario_auth.get("email", ""),
                        "nome": nome,
                        "pontuacao_diaria": 0,
                        "pontuacao_semanal": 0,
                        "pontuacao_total": 0,
                    }
                }
            return {"sucesso": False, "mensagem": "Perfil não encontrado."}

        perfil = resultado.data[0]
        perfil["pontuacao_diaria"] = perfil.get("pontuacao_diaria") or 0
        perfil["pontuacao_semanal"] = perfil.get("pontuacao_semanal") or 0
        perfil["pontuacao_total"] = perfil.get("pontuacao_total") or 0

        return {
            "sucesso": True,
            "perfil": perfil
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
        # Atualiza metadata do auth se houver nome
        if nome is not None and nome.strip() != "":
            try:
                supabase.auth.update_user({
                    "data": {"nome": nome.strip()}
                })
            except Exception:
                pass

        resultado = (
            supabase
            .table("usuarios")
            .update(dados_atualizacao)
            .eq("id", usuario_id)
            .execute()
        )

        if not resultado.data:
            # Se ainda não existe registro na tabela usuarios, faz upsert
            dados_atualizacao["id"] = usuario_id
            upsert_res = supabase.table("usuarios").upsert(dados_atualizacao).execute()
            if upsert_res.data:
                return {
                    "sucesso": True,
                    "mensagem": "Perfil atualizado com sucesso!",
                    "perfil": upsert_res.data[0]
                }
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


# ============================================================
# 5. PONTUAÇÕES / GAMIFICAÇÃO
# ============================================================

def ver_pontuacao(usuario_id: str) -> Dict[str, Any]:
    """
    Consulta e retorna a pontuação diária, semanal e total do usuário na tabela 'usuarios'.
    """
    if not usuario_id:
        return {
            "sucesso": False,
            "mensagem": "ID do usuário é obrigatório.",
            "pontuacao_diaria": 0,
            "pontuacao_semanal": 0,
            "pontuacao_total": 0,
        }

    try:
        resultado = (
            supabase
            .table("usuarios")
            .select("id, nome, pontuacao_diaria, pontuacao_semanal, pontuacao_total")
            .eq("id", usuario_id)
            .execute()
        )

        if not resultado.data:
            return {
                "sucesso": False,
                "mensagem": "Usuário não encontrado na base de dados.",
                "usuario_id": usuario_id,
                "pontuacao_diaria": 0,
                "pontuacao_semanal": 0,
                "pontuacao_total": 0,
                "pontuacoes": {
                    "pontuacao_diaria": 0,
                    "pontuacao_semanal": 0,
                    "pontuacao_total": 0,
                }
            }

        dados = resultado.data[0]
        diaria = dados.get("pontuacao_diaria") or 0
        semanal = dados.get("pontuacao_semanal") or 0
        total = dados.get("pontuacao_total") or 0

        return {
            "sucesso": True,
            "usuario_id": usuario_id,
            "nome": dados.get("nome"),
            "pontuacao_diaria": diaria,
            "pontuacao_semanal": semanal,
            "pontuacao_total": total,
            "pontuacoes": {
                "pontuacao_diaria": diaria,
                "pontuacao_semanal": semanal,
                "pontuacao_total": total,
            }
        }
    except Exception as erro:
        return {
            "sucesso": False,
            "mensagem": str(erro),
            "pontuacao_diaria": 0,
            "pontuacao_semanal": 0,
            "pontuacao_total": 0,
        }


def adicionar_pontuacao_diaria(usuario_id: str, pontos: int = 50) -> Dict[str, Any]:
    """
    Adiciona pontos diários ao usuário, incrementando também as pontuações semanal e total.
    """
    if not usuario_id:
        return {"sucesso": False, "mensagem": "ID do usuário é obrigatório."}

    if pontos is None or pontos <= 0:
        return {"sucesso": False, "mensagem": "A quantidade de pontos deve ser maior que zero."}

    try:
        # Busca a pontuação atual do usuário
        resultado = (
            supabase
            .table("usuarios")
            .select("id, pontuacao_diaria, pontuacao_semanal, pontuacao_total")
            .eq("id", usuario_id)
            .execute()
        )

        if not resultado.data:
            # Caso o usuário ainda não exista na tabela, tenta fazer upsert inicial
            dados_novos = {
                "id": usuario_id,
                "pontuacao_diaria": pontos,
                "pontuacao_semanal": pontos,
                "pontuacao_total": pontos
            }
            res_upsert = supabase.table("usuarios").upsert(dados_novos).execute()
            if res_upsert.data:
                return {
                    "sucesso": True,
                    "mensagem": f"{pontos} pontos adicionados com sucesso!",
                    "pontos_adicionados": pontos,
                    "pontuacao_diaria": pontos,
                    "pontuacao_semanal": pontos,
                    "pontuacao_total": pontos,
                    "pontuacoes": {
                        "pontuacao_diaria": pontos,
                        "pontuacao_semanal": pontos,
                        "pontuacao_total": pontos
                    }
                }
            return {"sucesso": False, "mensagem": "Usuário não encontrado para pontuar."}

        atual = resultado.data[0]
        atual_diaria = atual.get("pontuacao_diaria") or 0
        atual_semanal = atual.get("pontuacao_semanal") or 0
        atual_total = atual.get("pontuacao_total") or 0

        nova_diaria = atual_diaria + pontos
        nova_semanal = atual_semanal + pontos
        nova_total = atual_total + pontos

        res_update = (
            supabase
            .table("usuarios")
            .update({
                "pontuacao_diaria": nova_diaria,
                "pontuacao_semanal": nova_semanal,
                "pontuacao_total": nova_total
            })
            .eq("id", usuario_id)
            .execute()
        )

        if not res_update.data:
            return {"sucesso": False, "mensagem": "Não foi possível atualizar a pontuação."}

        return {
            "sucesso": True,
            "mensagem": f"{pontos} pontos adicionados com sucesso!",
            "pontos_adicionados": pontos,
            "pontuacao_diaria": nova_diaria,
            "pontuacao_semanal": nova_semanal,
            "pontuacao_total": nova_total,
            "pontuacoes": {
                "pontuacao_diaria": nova_diaria,
                "pontuacao_semanal": nova_semanal,
                "pontuacao_total": nova_total
            }
        }
    except Exception as erro:
        return {"sucesso": False, "mensagem": str(erro)}
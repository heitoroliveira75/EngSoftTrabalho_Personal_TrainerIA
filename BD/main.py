import json
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
                        "sequencia": 0,
                        "maior_sequencia": 0,
                        "checagem": False,
                    }
                }
            return {"sucesso": False, "mensagem": "Perfil não encontrado."}

        perfil = resultado.data[0]
        perfil["pontuacao_diaria"] = perfil.get("pontuacao_diaria") or 0
        perfil["pontuacao_semanal"] = perfil.get("pontuacao_semanal") or 0
        perfil["pontuacao_total"] = perfil.get("pontuacao_total") or 0
        perfil["sequencia"] = perfil.get("sequencia") if perfil.get("sequencia") is not None else 0
        perfil["maior_sequencia"] = perfil.get("maior_sequencia") if perfil.get("maior_sequencia") is not None else 0
        perfil["checagem"] = bool(perfil.get("checagem")) if perfil.get("checagem") is not None else False

        return {
            "sucesso": True,
            "perfil": perfil
        }
    except Exception as erro:
        return {"sucesso": False, "mensagem": str(erro)}


def editar_perfil(
    usuario_id: str,
    nome: Optional[str] = None,
    cpf: Optional[str] = None,
    sequencia: Optional[int] = None,
    maior_sequencia: Optional[int] = None,
    checagem: Optional[bool] = None
) -> Dict[str, Any]:
    """
    Atualiza os dados de nome, CPF, sequência, maior sequência e/ou checagem do usuário na tabela 'usuarios'.
    """
    if not usuario_id:
        return {"sucesso": False, "mensagem": "ID do usuário é obrigatório."}

    dados_atualizacao = {}
    if nome is not None and nome.strip() != "":
        dados_atualizacao["nome"] = nome.strip()
    if cpf is not None and cpf.strip() != "":
        dados_atualizacao["cpf"] = cpf.strip()
    if sequencia is not None:
        dados_atualizacao["sequencia"] = int(sequencia)
    if maior_sequencia is not None:
        dados_atualizacao["maior_sequencia"] = int(maior_sequencia)
    if checagem is not None:
        dados_atualizacao["checagem"] = bool(checagem)

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

TREINOS_PADRAO_CATALOGO = {
    "iniciante": [
        {
            "id": "1",
            "titulo": "Corpo completo A",
            "dificuldade": "Iniciante",
            "exerciciosCount": 8,
            "duracaoMinutos": 40,
            "pontosTotais": 200,
            "corTema": "#00E676",
            "exercicios": [
                {"nome": "Polichinelo", "series": 3, "repeticoes": 12, "pontos": 20},
                {"nome": "Agachamento Livre", "series": 3, "repeticoes": 12, "pontos": 20},
                {"nome": "Flexão com Joelhos", "series": 3, "repeticoes": 10, "pontos": 20},
                {"nome": "Abdominal Supra", "series": 3, "repeticoes": 15, "pontos": 20},
                {"nome": "Prancha Abdominal", "series": 3, "repeticoes": 30, "pontos": 20},
                {"nome": "Elevação Pélvica", "series": 3, "repeticoes": 12, "pontos": 20},
                {"nome": "Passada Parada", "series": 3, "repeticoes": 10, "pontos": 20},
                {"nome": "Polichinelo Inverso", "series": 3, "repeticoes": 12, "pontos": 20},
            ],
        },
        {
            "id": "2",
            "titulo": "Membros Inferiores & Core",
            "dificuldade": "Iniciante",
            "exerciciosCount": 5,
            "duracaoMinutos": 25,
            "pontosTotais": 140,
            "corTema": "#00E676",
            "exercicios": [
                {"nome": "Agachamento Isométrico", "series": 3, "repeticoes": 30, "pontos": 25},
                {"nome": "Afundo Alternado", "series": 3, "repeticoes": 10, "pontos": 25},
                {"nome": "Abdominal Infra", "series": 3, "repeticoes": 12, "pontos": 30},
                {"nome": "Ponte Glúteos", "series": 3, "repeticoes": 15, "pontos": 30},
                {"nome": "Elevação de Panturrilha", "series": 3, "repeticoes": 20, "pontos": 30},
            ],
        },
        {
            "id": "3",
            "titulo": "Mobilidade e Alongamento",
            "dificuldade": "Iniciante",
            "exerciciosCount": 6,
            "duracaoMinutos": 20,
            "pontosTotais": 100,
            "corTema": "#00E676",
            "exercicios": [
                {"nome": "Rotação de Tronco", "series": 2, "repeticoes": 15, "pontos": 15},
                {"nome": "Gato-Camelo", "series": 3, "repeticoes": 10, "pontos": 15},
                {"nome": "Alongamento de Posteriores", "series": 2, "repeticoes": 30, "pontos": 20},
                {"nome": "Alongamento de Quadríceps", "series": 2, "repeticoes": 30, "pontos": 20},
                {"nome": "Rotação de Ombros", "series": 2, "repeticoes": 12, "pontos": 15},
                {"nome": "Postura da Criança", "series": 2, "repeticoes": 45, "pontos": 15},
            ],
        },
    ],
    "intermediario": [
        {
            "id": "4",
            "titulo": "Superiores & HIIT",
            "dificuldade": "Intermediário",
            "exerciciosCount": 7,
            "duracaoMinutos": 45,
            "pontosTotais": 280,
            "corTema": "#29B6F6",
            "exercicios": [
                {"nome": "Flexão Tradicional", "series": 4, "repeticoes": 12, "pontos": 35},
                {"nome": "Tríceps no Banco", "series": 4, "repeticoes": 12, "pontos": 35},
                {"nome": "Mountain Climber", "series": 4, "repeticoes": 20, "pontos": 40},
                {"nome": "Desenvolvimento Halteres", "series": 4, "repeticoes": 10, "pontos": 40},
                {"nome": "Remada Curvada", "series": 4, "repeticoes": 12, "pontos": 40},
                {"nome": "Abdominal Remador", "series": 4, "repeticoes": 15, "pontos": 45},
                {"nome": "Prancha Dinâmica", "series": 3, "repeticoes": 40, "pontos": 45},
            ],
        },
        {
            "id": "5",
            "titulo": "Pernas & Glúteos Intenso",
            "dificuldade": "Intermediário",
            "exerciciosCount": 6,
            "duracaoMinutos": 35,
            "pontosTotais": 250,
            "corTema": "#29B6F6",
            "exercicios": [
                {"nome": "Agachamento Búlgaro", "series": 3, "repeticoes": 10, "pontos": 40},
                {"nome": "Agachamento Sumô", "series": 4, "repeticoes": 12, "pontos": 40},
                {"nome": "Stiff com Halteres", "series": 4, "repeticoes": 12, "pontos": 40},
                {"nome": "Saltos Vertical na Caixa", "series": 3, "repeticoes": 10, "pontos": 40},
                {"nome": "Elevação Pélvica Unilateral", "series": 3, "repeticoes": 12, "pontos": 45},
                {"nome": "Cadeira Flexora", "series": 3, "repeticoes": 15, "pontos": 45},
            ],
        },
        {
            "id": "6",
            "titulo": "Desafio Core & Cardio",
            "dificuldade": "Intermediário",
            "exerciciosCount": 5,
            "duracaoMinutos": 30,
            "pontosTotais": 220,
            "corTema": "#29B6F6",
            "exercicios": [
                {"nome": "Russian Twist", "series": 4, "repeticoes": 20, "pontos": 40},
                {"nome": "Prancha Lateral com Elevação", "series": 3, "repeticoes": 10, "pontos": 45},
                {"nome": "Polichinelo com Carga", "series": 4, "repeticoes": 20, "pontos": 45},
                {"nome": "Bicicleta Abdominal", "series": 4, "repeticoes": 20, "pontos": 45},
                {"nome": "Corrida Estacionária", "series": 4, "repeticoes": 45, "pontos": 45},
            ],
        },
    ],
    "avancado": [
        {
            "id": "7",
            "titulo": "Full Body Extreme",
            "dificuldade": "Avançado",
            "exerciciosCount": 8,
            "duracaoMinutos": 55,
            "pontosTotais": 480,
            "corTema": "#9E7AFF",
            "exercicios": [
                {"nome": "Burpee Completo com Flexão", "series": 4, "repeticoes": 15, "pontos": 60},
                {"nome": "Agachamento com Salto", "series": 4, "repeticoes": 20, "pontos": 60},
                {"nome": "Flexão Declinada", "series": 4, "repeticoes": 15, "pontos": 60},
                {"nome": "Pistol Squat (Cada Perna)", "series": 3, "repeticoes": 8, "pontos": 60},
                {"nome": "Barra Fixa Pronada", "series": 4, "repeticoes": 10, "pontos": 60},
                {"nome": "Abdominal Canivete", "series": 4, "repeticoes": 15, "pontos": 60},
                {"nome": "Prancha com Carga", "series": 4, "repeticoes": 60, "pontos": 60},
                {"nome": "Sprawl Cardio", "series": 4, "repeticoes": 15, "pontos": 60},
            ],
        },
        {
            "id": "8",
            "titulo": "Calistenia de Alta Performance",
            "dificuldade": "Avançado",
            "exerciciosCount": 6,
            "duracaoMinutos": 50,
            "pontosTotais": 400,
            "corTema": "#9E7AFF",
            "exercicios": [
                {"nome": "Flexão Diamante", "series": 4, "repeticoes": 15, "pontos": 65},
                {"nome": "Muscle Up / Flexão na Barra", "series": 4, "repeticoes": 6, "pontos": 70},
                {"nome": "Flexão Pseudo-Planoche", "series": 4, "repeticoes": 10, "pontos": 65},
                {"nome": "Agachamento Búlgaro Salto", "series": 4, "repeticoes": 12, "pontos": 65},
                {"nome": "L-Sit na Paralela", "series": 4, "repeticoes": 20, "pontos": 70},
                {"nome": "Dragon Flag Flexion", "series": 3, "repeticoes": 8, "pontos": 65},
            ],
        },
    ]
}


def ver_treinos_por_dificuldade(dificuldade: str) -> Dict[str, Any]:
    """
    Retorna os treinos padrão correspondentes à dificuldade especificada
    ('iniciante', 'intermediario', 'avancado').
    """
    dif_key = (dificuldade or "").lower().strip()
    if "inic" in dif_key:
        dif_key = "iniciante"
    elif "inter" in dif_key:
        dif_key = "intermediario"
    elif "avan" in dif_key:
        dif_key = "avancado"

    treinos = TREINOS_PADRAO_CATALOGO.get(dif_key, [])
    return {
        "sucesso": True,
        "dificuldade": dif_key,
        "treinos": treinos,
        "total": len(treinos)
    }


def _desempacotar_treino(treino: Dict[str, Any]) -> Dict[str, Any]:
    """
    Garante que treinos retornem sua lista de exercícios e metadados,
    extraindo do JSON da coluna 'descricao' caso a relação 'treino_exercicios' esteja vazia
    ou complementando metadados de dificuldade, duração e pontos.
    """
    desc = treino.get("descricao")
    exercicios_extraidos = []
    if desc and isinstance(desc, str) and desc.strip().startswith("{") and desc.strip().endswith("}"):
        try:
            dados_desc = json.loads(desc)
            if isinstance(dados_desc, dict):
                exercicios_extraidos = dados_desc.get("exercicios") or []
                if "dificuldade" in dados_desc and "dificuldade" not in treino:
                    treino["dificuldade"] = dados_desc["dificuldade"]
                if "duracao_minutos" in dados_desc and "duracao_minutos" not in treino:
                    treino["duracao_minutos"] = dados_desc["duracao_minutos"]
                    treino["duracaoMinutos"] = dados_desc["duracao_minutos"]
                if "pontos_totais" in dados_desc and "pontos_totais" not in treino:
                    treino["pontos_totais"] = dados_desc["pontos_totais"]
                    treino["pontosTotais"] = dados_desc["pontos_totais"]
                if "texto" in dados_desc:
                    treino["descricao_texto"] = dados_desc["texto"]
        except Exception:
            pass

    # Verifica se treino_exercicios veio preenchido do Supabase
    treino_ex = treino.get("treino_exercicios") or []
    if treino_ex:
        exercicios_da_relacao = []
        for te in treino_ex:
            ex_info = te.get("exercicios") or {}
            nome = ex_info.get("nome") or "Exercício"
            series = te.get("series") or 3
            reps = te.get("repeticoes") or 10
            pontos = series * 15
            exercicios_da_relacao.append({
                "exercicio_id": te.get("exercicio_id"),
                "nome": nome,
                "series": series,
                "repeticoes": reps,
                "pontos": pontos,
                "pontos_totais": pontos
            })
        treino["exercicios"] = exercicios_da_relacao
    elif exercicios_extraidos:
        treino["exercicios"] = exercicios_extraidos
        treino["treino_exercicios"] = [
            {
                "treino_id": treino.get("id"),
                "exercicio_id": ex.get("exercicio_id") or ex.get("id") or 1,
                "series": ex.get("series", 3),
                "repeticoes": ex.get("repeticoes", 10),
                "exercicios": {
                    "nome": ex.get("nome", "Exercício")
                }
            }
            for ex in exercicios_extraidos
        ]
    else:
        treino["exercicios"] = []

    if "exerciciosCount" not in treino:
        treino["exerciciosCount"] = len(treino.get("exercicios") or [])

    return treino


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

        treinos = [_desempacotar_treino(t) for t in (resultado.data or [])]
        return {
            "sucesso": True,
            "treinos": treinos
        }
    except Exception as erro:
        return {"sucesso": False, "mensagem": str(erro), "treinos": []}


def listar_treinos(usuario_id: str) -> Dict[str, Any]:
    """
    Lista todos os treinos criados por um usuário específico com os respectivos exercícios vinculados.
    """
    if not usuario_id:
        usuario_auth = obter_usuario_atual()
        if usuario_auth and usuario_auth.get("id"):
            usuario_id = str(usuario_auth["id"])
        else:
            return {"sucesso": False, "mensagem": "ID do usuário é obrigatório.", "treinos": []}

    try:
        resultado = (
            supabase
            .table("treinos")
            .select("*, treino_exercicios(*, exercicios(*))")
            .eq("usuario_id", usuario_id)
            .order("id", desc=True)
            .execute()
        )

        treinos = [_desempacotar_treino(t) for t in (resultado.data or [])]
        return {
            "sucesso": True,
            "treinos": treinos
        }
    except Exception as erro:
        try:
            res_simples = (
                supabase
                .table("treinos")
                .select("*")
                .eq("usuario_id", usuario_id)
                .order("id", desc=True)
                .execute()
            )
            treinos = [_desempacotar_treino(t) for t in (res_simples.data or [])]
            return {
                "sucesso": True,
                "treinos": treinos
            }
        except Exception:
            return {"sucesso": False, "mensagem": str(erro), "treinos": []}


def criar_treino(
    usuario_id: Optional[str] = None,
    nome: str = "",
    descricao: str = "",
    pre_montado: bool = False,
    exercicios: Optional[List[Dict[str, Any]]] = None,
    dificuldade: Optional[str] = None,
    duracao_minutos: Optional[int] = None,
    pontos_totais: Optional[int] = None
) -> Dict[str, Any]:
    """
    Cria um novo treino na tabela 'treinos' e insere os exercícios associados na tabela 'treino_exercicios'.
    Também serializa a lista de exercícios e metadados no campo 'descricao' em formato JSON para garantir
    que nenhum dado seja perdido mesmo que a inserção na tabela relacional falhe por RLS ou restrições de FK.
    """
    if not nome:
        return {"sucesso": False, "mensagem": "Nome do treino é obrigatório."}

    if not pre_montado and not usuario_id:
        usuario_auth = obter_usuario_atual()
        if usuario_auth and usuario_auth.get("id"):
            usuario_id = str(usuario_auth["id"])
        else:
            try:
                res_u = supabase.table("usuarios").select("id").limit(1).execute()
                if res_u.data:
                    usuario_id = str(res_u.data[0]["id"])
            except Exception:
                pass

        if not usuario_id:
            return {"sucesso": False, "mensagem": "ID do usuário é obrigatório para treinos personalizados."}

    try:
        # Serializa os exercícios e metadados em JSON para persistência garantida na coluna 'descricao'
        payload_descricao = {
            "texto": (descricao or "").strip(),
            "dificuldade": dificuldade or "Personalizado",
            "duracao_minutos": duracao_minutos or ((len(exercicios) * 5) if exercicios else 30),
            "pontos_totais": pontos_totais or 150,
            "exercicios": exercicios or []
        }
        descricao_para_salvar = json.dumps(payload_descricao, ensure_ascii=False)

        dados_treino = {
            "nome": nome.strip(),
            "descricao": descricao_para_salvar,
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
            try:
                registros_exercicios = []
                for idx, item in enumerate(exercicios, start=1):
                    ex_id = item.get("exercicio_id") or item.get("id")
                    if ex_id is not None and str(ex_id).isdigit():
                        ex_id = int(ex_id)
                    else:
                        ex_id = 1
                    registros_exercicios.append({
                        "treino_id": treino_id,
                        "exercicio_id": ex_id,
                        "ordem": item.get("ordem", idx),
                        "series": item.get("series", 3),
                        "repeticoes": item.get("repeticoes", 10)
                    })

                res_ex = supabase.table("treino_exercicios").insert(registros_exercicios).execute()
                exercicios_adicionados = res_ex.data or []
            except Exception as e_ex:
                # Caso a tabela treino_exercicios falhe por constraint de FK ou RLS,
                # os dados continuam 100% seguros na coluna 'descricao'
                print(f"Aviso ao inserir treino_exercicios: {e_ex}")

        treino_desempacotado = _desempacotar_treino(treino_criado)
        return {
            "sucesso": True,
            "mensagem": "Treino criado com sucesso!",
            "treino": treino_desempacotado,
            "exercicios": treino_desempacotado.get("exercicios") or exercicios_adicionados
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
    Consulta e retorna a pontuação diária, semanal e total, além da sequência, maior sequência e checagem do usuário na tabela 'usuarios'.
    """
    if not usuario_id:
        return {
            "sucesso": False,
            "mensagem": "ID do usuário é obrigatório.",
            "pontuacao_diaria": 0,
            "pontuacao_semanal": 0,
            "pontuacao_total": 0,
            "sequencia": 0,
            "maior_sequencia": 0,
            "checagem": False,
        }

    try:
        resultado = (
            supabase
            .table("usuarios")
            .select("id, nome, pontuacao_diaria, pontuacao_semanal, pontuacao_total, sequencia, maior_sequencia, checagem")
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
                "sequencia": 0,
                "maior_sequencia": 0,
                "checagem": False,
                "pontuacoes": {
                    "pontuacao_diaria": 0,
                    "pontuacao_semanal": 0,
                    "pontuacao_total": 0,
                    "sequencia": 0,
                    "maior_sequencia": 0,
                    "checagem": False,
                }
            }

        dados = resultado.data[0]
        diaria = dados.get("pontuacao_diaria") or 0
        semanal = dados.get("pontuacao_semanal") or 0
        total = dados.get("pontuacao_total") or 0
        sequencia = dados.get("sequencia") if dados.get("sequencia") is not None else 0
        maior_sequencia = dados.get("maior_sequencia") if dados.get("maior_sequencia") is not None else 0
        checagem = bool(dados.get("checagem")) if dados.get("checagem") is not None else False

        return {
            "sucesso": True,
            "usuario_id": usuario_id,
            "nome": dados.get("nome"),
            "pontuacao_diaria": diaria,
            "pontuacao_semanal": semanal,
            "pontuacao_total": total,
            "sequencia": sequencia,
            "maior_sequencia": maior_sequencia,
            "checagem": checagem,
            "pontuacoes": {
                "pontuacao_diaria": diaria,
                "pontuacao_semanal": semanal,
                "pontuacao_total": total,
                "sequencia": sequencia,
                "maior_sequencia": maior_sequencia,
                "checagem": checagem,
            }
        }
    except Exception as erro:
        return {
            "sucesso": False,
            "mensagem": str(erro),
            "pontuacao_diaria": 0,
            "pontuacao_semanal": 0,
            "pontuacao_total": 0,
            "sequencia": 0,
            "maior_sequencia": 0,
            "checagem": False,
        }


def adicionar_pontuacao_diaria(
    usuario_id: str,
    pontos: int = 50,
    incrementar_sequencia: Optional[bool] = None
) -> Dict[str, Any]:
    """
    Adiciona pontos diários ao usuário, incrementa as pontuações semanal e total,
    atualiza a flag de 'checagem' para True, atualiza a 'sequencia' e calcula a 'maior_sequencia'.
    """
    if not usuario_id:
        return {"sucesso": False, "mensagem": "ID do usuário é obrigatório."}

    if pontos is None or pontos <= 0:
        return {"sucesso": False, "mensagem": "A quantidade de pontos deve ser maior que zero."}

    try:
        # Busca a pontuação e status atuais do usuário
        resultado = (
            supabase
            .table("usuarios")
            .select("id, pontuacao_diaria, pontuacao_semanal, pontuacao_total, sequencia, maior_sequencia, checagem")
            .eq("id", usuario_id)
            .execute()
        )

        if not resultado.data:
            # Caso o usuário ainda não exista na tabela, tenta fazer upsert inicial
            nova_seq = 1
            dados_novos = {
                "id": usuario_id,
                "pontuacao_diaria": pontos,
                "pontuacao_semanal": pontos,
                "pontuacao_total": pontos,
                "sequencia": nova_seq,
                "maior_sequencia": nova_seq,
                "checagem": True
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
                    "sequencia": nova_seq,
                    "maior_sequencia": nova_seq,
                    "checagem": True,
                    "pontuacoes": {
                        "pontuacao_diaria": pontos,
                        "pontuacao_semanal": pontos,
                        "pontuacao_total": pontos,
                        "sequencia": nova_seq,
                        "maior_sequencia": nova_seq,
                        "checagem": True
                    }
                }
            return {"sucesso": False, "mensagem": "Usuário não encontrado para pontuar."}

        atual = resultado.data[0]
        atual_diaria = atual.get("pontuacao_diaria") or 0
        atual_semanal = atual.get("pontuacao_semanal") or 0
        atual_total = atual.get("pontuacao_total") or 0
        atual_sequencia = atual.get("sequencia") if atual.get("sequencia") is not None else 0
        atual_maior_sequencia = atual.get("maior_sequencia") if atual.get("maior_sequencia") is not None else 0
        atual_checagem = bool(atual.get("checagem")) if atual.get("checagem") is not None else False

        nova_diaria = atual_diaria + pontos
        nova_semanal = atual_semanal + pontos
        nova_total = atual_total + pontos

        # Define nova sequência: se checagem ainda não estava ativa (ou forçado), incrementa sequência
        if incrementar_sequencia is True:
            nova_sequencia = atual_sequencia + 1
        elif incrementar_sequencia is False:
            nova_sequencia = atual_sequencia
        else:
            # Se for a primeira pontuação do ciclo (checagem == False), incrementa
            nova_sequencia = atual_sequencia + 1 if not atual_checagem else atual_sequencia

        # Garantir ao menos 1 se for a primeira pontuação e a sequência estava zerada
        if nova_sequencia == 0:
            nova_sequencia = 1

        novo_maior_sequencia = max(atual_maior_sequencia, nova_sequencia)

        res_update = (
            supabase
            .table("usuarios")
            .update({
                "pontuacao_diaria": nova_diaria,
                "pontuacao_semanal": nova_semanal,
                "pontuacao_total": nova_total,
                "sequencia": nova_sequencia,
                "maior_sequencia": novo_maior_sequencia,
                "checagem": True
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
            "sequencia": nova_sequencia,
            "maior_sequencia": novo_maior_sequencia,
            "checagem": True,
            "pontuacoes": {
                "pontuacao_diaria": nova_diaria,
                "pontuacao_semanal": nova_semanal,
                "pontuacao_total": nova_total,
                "sequencia": nova_sequencia,
                "maior_sequencia": novo_maior_sequencia,
                "checagem": True
            }
        }
    except Exception as erro:
        return {"sucesso": False, "mensagem": str(erro)}


def atualizar_sequencia(usuario_id: str, sequencia: int) -> Dict[str, Any]:
    """
    Atualiza diretamente o número de dias de sequência do usuário na tabela 'usuarios',
    ajustando automaticamente a maior sequência se a nova sequência for superior.
    """
    if not usuario_id:
        return {"sucesso": False, "mensagem": "ID do usuário é obrigatório."}

    if sequencia is None or sequencia < 0:
        return {"sucesso": False, "mensagem": "A sequência deve ser um valor maior ou igual a zero."}

    try:
        # Busca maior_sequencia atual
        res_atual = supabase.table("usuarios").select("maior_sequencia").eq("id", usuario_id).execute()
        maior_atual = 0
        if res_atual.data:
            maior_atual = res_atual.data[0].get("maior_sequencia") or 0

        novo_maior = max(maior_atual, int(sequencia))

        resultado = (
            supabase
            .table("usuarios")
            .update({
                "sequencia": int(sequencia),
                "maior_sequencia": novo_maior
            })
            .eq("id", usuario_id)
            .execute()
        )

        if not resultado.data:
            return {"sucesso": False, "mensagem": "Usuário não encontrado para atualizar a sequência."}

        return {
            "sucesso": True,
            "mensagem": "Sequência atualizada com sucesso!",
            "usuario_id": usuario_id,
            "sequencia": int(sequencia),
            "maior_sequencia": novo_maior
        }
    except Exception as erro:
        return {"sucesso": False, "mensagem": str(erro)}


def atualizar_maior_sequencia(usuario_id: str, maior_sequencia: int) -> Dict[str, Any]:
    """
    Atualiza diretamente o recorde de maior sequência em dias do usuário na tabela 'usuarios'.
    """
    if not usuario_id:
        return {"sucesso": False, "mensagem": "ID do usuário é obrigatório."}

    if maior_sequencia is None or maior_sequencia < 0:
        return {"sucesso": False, "mensagem": "A maior sequência deve ser um valor maior ou igual a zero."}

    try:
        resultado = (
            supabase
            .table("usuarios")
            .update({"maior_sequencia": int(maior_sequencia)})
            .eq("id", usuario_id)
            .execute()
        )

        if not resultado.data:
            return {"sucesso": False, "mensagem": "Usuário não encontrado para atualizar maior sequência."}

        return {
            "sucesso": True,
            "mensagem": "Maior sequência atualizada com sucesso!",
            "usuario_id": usuario_id,
            "maior_sequencia": int(maior_sequencia)
        }
    except Exception as erro:
        return {"sucesso": False, "mensagem": str(erro)}


def atualizar_checagem(usuario_id: str, checagem: bool) -> Dict[str, Any]:
    """
    Atualiza o estado da checagem booleana do usuário na tabela 'usuarios'.
    """
    if not usuario_id:
        return {"sucesso": False, "mensagem": "ID do usuário é obrigatório."}

    try:
        resultado = (
            supabase
            .table("usuarios")
            .update({"checagem": bool(checagem)})
            .eq("id", usuario_id)
            .execute()
        )

        if not resultado.data:
            return {"sucesso": False, "mensagem": "Usuário não encontrado para atualizar checagem."}

        return {
            "sucesso": True,
            "mensagem": "Checagem atualizada com sucesso!",
            "usuario_id": usuario_id,
            "checagem": bool(checagem)
        }
    except Exception as erro:
        return {"sucesso": False, "mensagem": str(erro)}


def resetar_checagem_diaria(usuario_id: str) -> Dict[str, Any]:
    """
    Reseta o campo checagem do usuário para False (para novo ciclo diário).
    """
    return atualizar_checagem(usuario_id, checagem=False)
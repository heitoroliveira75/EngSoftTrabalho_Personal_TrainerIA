from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any, Union
import uvicorn
import sys
from pathlib import Path

# Garantir que o diretório BD esteja no sys.path
sys.path.append(str(Path(__file__).resolve().parent))

import main as bd
from supabase_client import supabase

app = FastAPI(
    title="Personal Trainer IA - API",
    description="API REST para conectar o aplicativo Flutter às funções do Banco de Dados / Supabase",
    version="1.0.0"
)

# Configuração de CORS para permitir requisições do Flutter (Web, Mobile, Emuladores, Desktop)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ============================================================
# SCHEMAS PYDANTIC (MODELOS DE ENTRADA)
# ============================================================

class CriarContaRequest(BaseModel):
    nome: str
    email: str
    senha: str

class LoginRequest(BaseModel):
    email: str
    senha: str

class EditarPerfilRequest(BaseModel):
    nome: Optional[str] = None
    cpf: Optional[str] = None

class ExercicioTreinoItem(BaseModel):
    exercicio_id: int
    ordem: Optional[int] = 1
    series: Optional[int] = 3
    repeticoes: Optional[int] = 10

class CriarTreinoRequest(BaseModel):
    usuario_id: Optional[str] = None
    nome: str
    descricao: Optional[str] = ""
    pre_montado: Optional[bool] = False
    exercicios: Optional[List[ExercicioTreinoItem]] = None

class EditarTreinoRequest(BaseModel):
    nome: Optional[str] = None
    descricao: Optional[str] = None
    exercicios: Optional[List[ExercicioTreinoItem]] = None

class RecuperarSenhaRequest(BaseModel):
    email: str

class RedefinirSenhaRequest(BaseModel):
    email: Optional[str] = None
    codigo: Optional[str] = None
    nova_senha: str

# ============================================================
# ROTAS - STATUS DA API
# ============================================================

@app.get("/")
def raiz():
    return {
        "status": "online",
        "app": "Personal Trainer IA API",
        "docs": "/docs"
    }

# ============================================================
# ROTAS - 1. AUTENTICAÇÃO E SESSÃO
# ============================================================

@app.post("/auth/criar-conta")
def api_criar_conta(req: CriarContaRequest):
    resposta = bd.criar_conta(req.nome, req.email, req.senha)
    return resposta

@app.post("/auth/login")
def api_fazer_login(req: LoginRequest):
    resposta = bd.fazer_login(req.email, req.senha)
    return resposta

@app.post("/auth/logout")
def api_deslogar():
    resposta = bd.deslogar_perfil()
    return resposta

@app.get("/auth/usuario-atual")
def api_obter_usuario_atual():
    usuario = bd.obter_usuario_atual()
    if not usuario:
        return {"sucesso": False, "mensagem": "Nenhum usuário logado no momento.", "usuario": None}
    return {"sucesso": True, "usuario": usuario}

@app.post("/auth/esqueceu-senha")
def api_esqueceu_senha(req: RecuperarSenhaRequest):
    """
    Envia email de recuperação de senha pelo Supabase Auth.
    """
    try:
        supabase.auth.reset_password_for_email(req.email.strip())
        return {
            "sucesso": True,
            "mensagem": f"Email de recuperação enviado para {req.email.strip()}."
        }
    except Exception as erro:
        return {"sucesso": False, "mensagem": str(erro)}

@app.post("/auth/redefinir-senha")
def api_redefinir_senha(req: RedefinirSenhaRequest):
    """
    Atualiza a senha do usuário.
    """
    try:
        if req.codigo and req.email:
            supabase.auth.verify_otp({
                "email": req.email.strip(),
                "token": req.codigo.strip(),
                "type": "recovery"
            })
        supabase.auth.update_user({
            "password": req.nova_senha.strip()
        })
        return {
            "sucesso": True,
            "mensagem": "Senha redefinida com sucesso!"
        }
    except Exception as erro:
        return {"sucesso": False, "mensagem": str(erro)}

# ============================================================
# ROTAS - 2. PERFIL DE USUÁRIO
# ============================================================

@app.get("/perfil/{usuario_id}")
def api_ver_perfil(usuario_id: str):
    resposta = bd.ver_perfil(usuario_id)
    return resposta

@app.put("/perfil/{usuario_id}")
def api_editar_perfil(usuario_id: str, req: EditarPerfilRequest):
    resposta = bd.editar_perfil(usuario_id, nome=req.nome, cpf=req.cpf)
    return resposta

# ============================================================
# ROTAS - 3. EXERCÍCIOS
# ============================================================

@app.get("/exercicios")
def api_listar_exercicios(grupo_muscular: Optional[str] = Query(None)):
    resposta = bd.listar_exercicios(grupo_muscular=grupo_muscular)
    return resposta

# ============================================================
# ROTAS - 4. TREINOS
# ============================================================

@app.get("/treinos/pre-montados")
def api_ver_treinos_premont():
    resposta = bd.ver_treinos_premont()
    return resposta

@app.get("/treinos/usuario/{usuario_id}")
def api_listar_treinos_usuario(usuario_id: str):
    resposta = bd.listar_treinos(usuario_id)
    return resposta

@app.post("/treinos")
def api_criar_treino(req: CriarTreinoRequest):
    exercicios_dict = None
    if req.exercicios:
        exercicios_dict = [item.model_dump() for item in req.exercicios]
    
    resposta = bd.criar_treino(
        usuario_id=req.usuario_id,
        nome=req.nome,
        descricao=req.descricao or "",
        pre_montado=req.pre_montado or False,
        exercicios=exercicios_dict
    )
    return resposta

@app.put("/treinos/{treino_id}")
def api_editar_treino(treino_id: str, req: EditarTreinoRequest):
    exercicios_dict = None
    if req.exercicios is not None:
        exercicios_dict = [item.model_dump() for item in req.exercicios]
    
    resposta = bd.editar_treino(
        treino_id=treino_id,
        nome=req.nome,
        descricao=req.descricao,
        exercicios=exercicios_dict
    )
    return resposta

@app.delete("/treinos/{treino_id}")
def api_excluir_treino(treino_id: str):
    resposta = bd.excluir_treino(treino_id)
    return resposta

# ============================================================
# EXECUÇÃO DIRETA
# ============================================================
if __name__ == "__main__":
    print("Iniciando servidor FastAPI em http://0.0.0.0:8000 ...")
    uvicorn.run("api:app", host="0.0.0.0", port=8000, reload=True)

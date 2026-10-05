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
    sequencia: Optional[int] = None
    maior_sequencia: Optional[int] = None
    checagem: Optional[bool] = None

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

class AlterarSenhaRequest(BaseModel):
    senha_atual: Optional[str] = None
    nova_senha: str
    email: Optional[str] = None

class AdicionarPontuacaoRequest(BaseModel):
    usuario_id: str
    pontos: int = Field(default=50, gt=0, description="Quantidade de pontos diários a adicionar")
    incrementar_sequencia: Optional[bool] = Field(default=None, description="Forçar incremento da sequência (opcional)")

class AtualizarSequenciaRequest(BaseModel):
    usuario_id: str
    sequencia: int = Field(ge=0, description="Novo valor de sequência em dias")

class AtualizarMaiorSequenciaRequest(BaseModel):
    usuario_id: str
    maior_sequencia: int = Field(ge=0, description="Novo recorde de maior sequência em dias")

class AtualizarChecagemRequest(BaseModel):
    usuario_id: str
    checagem: bool = Field(description="Status booleano da checagem")

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
    resposta = bd.solicitar_redefinicao_senha(req.email.strip())
    return resposta

@app.post("/auth/redefinir-senha")
def api_redefinir_senha(req: RedefinirSenhaRequest):
    """
    Redefine a senha do usuário com código OTP ou atualiza com sessão ativa.
    """
    if req.codigo and req.email:
        resposta = bd.redefinir_senha_com_codigo(req.email.strip(), req.codigo.strip(), req.nova_senha.strip())
    else:
        resposta = bd.atualizar_senha(req.nova_senha.strip())
    return resposta

@app.post("/auth/alterar-senha")
def api_alterar_senha(req: AlterarSenhaRequest):
    """
    Altera a senha do usuário autenticado, validando a senha atual.
    """
    resposta = bd.alterar_senha(
        nova_senha=req.nova_senha,
        senha_atual=req.senha_atual,
        email=req.email
    )
    return resposta

# ============================================================
# ROTAS - 2. PERFIL DE USUÁRIO
# ============================================================

@app.get("/perfil/{usuario_id}")
def api_ver_perfil(usuario_id: str):
    resposta = bd.ver_perfil(usuario_id)
    return resposta

@app.put("/perfil/{usuario_id}")
def api_editar_perfil(usuario_id: str, req: EditarPerfilRequest):
    resposta = bd.editar_perfil(
        usuario_id=usuario_id,
        nome=req.nome,
        cpf=req.cpf,
        sequencia=req.sequencia,
        maior_sequencia=req.maior_sequencia,
        checagem=req.checagem
    )
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
# ROTAS - 5. PONTUAÇÕES / GAMIFICAÇÃO
# ============================================================

@app.get("/pontuacao/{usuario_id}")
def api_ver_pontuacao(usuario_id: str):
    """
    Retorna as pontuações (diária, semanal e total), além da sequência e checagem do usuário.
    """
    resposta = bd.ver_pontuacao(usuario_id)
    return resposta

@app.post("/pontuacao/diaria")
def api_adicionar_pontuacao_diaria(req: AdicionarPontuacaoRequest):
    """
    Adiciona pontuação diária ao usuário, atualizando também a semanal, a total, checagem e sequência.
    """
    resposta = bd.adicionar_pontuacao_diaria(
        usuario_id=req.usuario_id,
        pontos=req.pontos,
        incrementar_sequencia=req.incrementar_sequencia
    )
    return resposta

@app.post("/pontuacao/{usuario_id}/adicionar-diaria")
def api_adicionar_pontuacao_diaria_path(
    usuario_id: str,
    pontos: int = Query(50, gt=0),
    incrementar_sequencia: Optional[bool] = Query(None)
):
    """
    Endpoint alternativo com usuario_id na URL para adicionar pontos diários.
    """
    resposta = bd.adicionar_pontuacao_diaria(
        usuario_id=usuario_id,
        pontos=pontos,
        incrementar_sequencia=incrementar_sequencia
    )
    return resposta

@app.put("/pontuacao/{usuario_id}/sequencia")
def api_atualizar_sequencia_path(usuario_id: str, sequencia: int = Query(..., ge=0)):
    """
    Atualiza diretamente o valor da sequência de dias de um usuário.
    """
    resposta = bd.atualizar_sequencia(usuario_id=usuario_id, sequencia=sequencia)
    return resposta

@app.post("/pontuacao/sequencia")
def api_atualizar_sequencia(req: AtualizarSequenciaRequest):
    """
    Atualiza diretamente a sequência de dias através de JSON payload.
    """
    resposta = bd.atualizar_sequencia(usuario_id=req.usuario_id, sequencia=req.sequencia)
    return resposta

@app.put("/pontuacao/{usuario_id}/maior-sequencia")
def api_atualizar_maior_sequencia_path(usuario_id: str, maior_sequencia: int = Query(..., ge=0)):
    """
    Atualiza diretamente o recorde de maior sequência de dias de um usuário.
    """
    resposta = bd.atualizar_maior_sequencia(usuario_id=usuario_id, maior_sequencia=maior_sequencia)
    return resposta

@app.post("/pontuacao/maior-sequencia")
def api_atualizar_maior_sequencia(req: AtualizarMaiorSequenciaRequest):
    """
    Atualiza diretamente a maior sequência de dias através de JSON payload.
    """
    resposta = bd.atualizar_maior_sequencia(usuario_id=req.usuario_id, maior_sequencia=req.maior_sequencia)
    return resposta

@app.put("/pontuacao/{usuario_id}/checagem")
def api_atualizar_checagem_path(usuario_id: str, checagem: bool = Query(...)):
    """
    Atualiza o status de checagem do usuário.
    """
    resposta = bd.atualizar_checagem(usuario_id=usuario_id, checagem=checagem)
    return resposta

@app.post("/pontuacao/checagem")
def api_atualizar_checagem(req: AtualizarChecagemRequest):
    """
    Atualiza o status de checagem através de JSON payload.
    """
    resposta = bd.atualizar_checagem(usuario_id=req.usuario_id, checagem=req.checagem)
    return resposta

@app.post("/pontuacao/{usuario_id}/resetar-checagem")
def api_resetar_checagem(usuario_id: str):
    """
    Reseta a checagem diária do usuário para False.
    """
    resposta = bd.resetar_checagem_diaria(usuario_id=usuario_id)
    return resposta

# ============================================================
# EXECUÇÃO DIRETA
# ============================================================
if __name__ == "__main__":
    print("Iniciando servidor FastAPI em http://0.0.0.0:8000 ...")
    uvicorn.run("api:app", host="0.0.0.0", port=8000, reload=True)

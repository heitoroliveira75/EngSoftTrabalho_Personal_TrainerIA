from fastapi import FastAPI, HTTPException, Query, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any, Union
import uvicorn
import sys
from pathlib import Path

# Garantir que a raiz do repositório e o diretório BD estejam no sys.path
DIRETORIO_BD = Path(__file__).resolve().parent
RAIZ_REPOSITORIO = DIRETORIO_BD.parent
if str(RAIZ_REPOSITORIO) not in sys.path:
    sys.path.insert(0, str(RAIZ_REPOSITORIO))
if str(DIRETORIO_BD) not in sys.path:
    sys.path.insert(0, str(DIRETORIO_BD))

import main as bd
from supabase_client import supabase
from servico_ia_api import ServicoIA

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
    exercicio_id: Union[int, str]
    ordem: Optional[int] = 1
    series: Optional[int] = 3
    repeticoes: Optional[int] = 10
    nome: Optional[str] = None
    grupo_muscular: Optional[str] = None
    pontos_series: Optional[int] = None
    pontos_repeticoes: Optional[int] = None
    pontos_totais: Optional[int] = None
    total_repeticoes: Optional[int] = None

    model_config = {"extra": "allow"}

class CriarTreinoRequest(BaseModel):
    usuario_id: Optional[str] = None
    nome: str
    descricao: Optional[str] = ""
    pre_montado: Optional[bool] = False
    dificuldade: Optional[str] = None
    duracao_minutos: Optional[int] = None
    pontos_totais: Optional[int] = None
    exercicios: Optional[List[ExercicioTreinoItem]] = None

    model_config = {"extra": "allow"}

class EditarTreinoRequest(BaseModel):
    nome: Optional[str] = None
    descricao: Optional[str] = None
    exercicios: Optional[List[ExercicioTreinoItem]] = None

    model_config = {"extra": "allow"}

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

class SolicitarAmizadeRequest(BaseModel):
    usuario_id: str
    amigo_id: str

class ResponderSolicitacaoRequest(BaseModel):
    status: str = Field(..., pattern="^(aceito|recusado)$")

class ReiniciarSessaoIARequest(BaseModel):
    usuario_id: str
    exercicio_id: str = Field(default="1", description="'1' Ombro, '2' Agachamento, '3' Rosca")

class SimularRepeticaoIARequest(BaseModel):
    usuario_id: str
    exercicio_id: str = Field(default="1", description="'1' Ombro, '2' Agachamento, '3' Rosca")
    tipo_cenario: str = Field(default="ideal", description="'ideal', 'postural'")

class ProcessarAngulosIARequest(BaseModel):
    usuario_id: str
    exercicio_id: str = Field(default="1")
    angulos: Dict[str, float]
    visivel: bool = True

class FinalizarSerieIARequest(BaseModel):
    usuario_id: str
    incrementar_sequencia: Optional[bool] = None


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

@app.get("/treinos/dificuldade/{dificuldade}")
def api_ver_treinos_por_dificuldade(dificuldade: str):
    """
    Retorna os treinos padrão de acordo com o nível de dificuldade selecionado:
    'iniciante', 'intermediario', 'avancado'.
    """
    resposta = bd.ver_treinos_por_dificuldade(dificuldade)
    return resposta

@app.get("/treinos/usuario/{usuario_id}")
def api_listar_treinos_usuario(usuario_id: str):
    resposta = bd.listar_treinos(usuario_id)
    return resposta

@app.post("/treinos")
def api_criar_treino(req: CriarTreinoRequest):
    usuario_id = req.usuario_id
    if not usuario_id and not req.pre_montado:
        usuario_atual = bd.obter_usuario_atual()
        if usuario_atual and usuario_atual.get("id"):
            usuario_id = str(usuario_atual["id"])

    exercicios_dict = None
    if req.exercicios:
        exercicios_dict = [item.model_dump() for item in req.exercicios]
    
    resposta = bd.criar_treino(
        usuario_id=usuario_id,
        nome=req.nome,
        descricao=req.descricao or "",
        pre_montado=req.pre_montado or False,
        exercicios=exercicios_dict,
        dificuldade=req.dificuldade,
        duracao_minutos=req.duracao_minutos,
        pontos_totais=req.pontos_totais
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
# ============================================================
# SISTEMA DE AMIZADES
# ============================================================

@app.get("/amigos/buscar")
def api_buscar_usuarios(nome: str = Query(...), usuario_id: Optional[str] = Query(None)):
    """
    Busca usuários cadastrados por aproximação de nome.
    """
    return bd.buscar_usuarios(nome=nome, usuario_atual_id=usuario_id)

@app.post("/amigos/solicitar")
def api_enviar_solicitacao(req: SolicitarAmizadeRequest):
    """
    Envia uma nova solicitação de amizade.
    """
    return bd.enviar_solicitacao_amizade(usuario_id=req.usuario_id, amigo_id=req.amigo_id)

@app.get("/amigos/solicitacoes/pendentes")
def api_listar_solicitacoes_pendentes(usuario_id: str = Query(...)):
    """
    Lista solicitações de amizade pendentes recebidas pelo usuário.
    """
    return bd.listar_solicitacoes_pendentes(usuario_id=usuario_id)

@app.patch("/amigos/solicitacoes/{solicitacao_id}")
def api_responder_solicitacao(solicitacao_id: str, req: ResponderSolicitacaoRequest):
    """
    Aceita ou recusa uma solicitação de amizade pendente.
    """
    return bd.responder_solicitacao(solicitacao_id=solicitacao_id, novo_status=req.status)

@app.get("/amigos/")
def api_listar_amigos(usuario_id: str = Query(...)):
    """
    Retorna a lista de amigos confirmados do usuário.
    """
    return bd.listar_amigos(usuario_id=usuario_id)

@app.delete("/amigos/{amigo_id}")
def api_remover_amigo(amigo_id: str, usuario_id: str = Query(...)):
    """
    Remove o vínculo de amizade entre o usuário logado e o amigo indicado.
    """
    return bd.remover_amigo(usuario_id=usuario_id, amigo_id=amigo_id)

# ============================================================
# SISTEMA DE LEADERBOARD
# ============================================================

@app.get("/leaderboard/global")
def api_obter_leaderboard_global(limite: int = Query(50, ge=1, le=200)):
    """
    Retorna o ranking global dos usuários ordenados por pontuação semanal e streak.
    """
    return bd.obter_leaderboard_global(limite=limite)

@app.get("/leaderboard/amigos")
def api_obter_leaderboard_amigos(usuario_id: str = Query(...)):
    """
    Retorna o ranking restrito ao usuário e seu círculo de amigos aceitos.
    """
    return bd.obter_leaderboard_amigos(usuario_id=usuario_id)

@app.get("/leaderboard/minha-posicao")
def api_obter_minha_posicao_global(usuario_id: str = Query(...)):
    """
    Retorna a posição ordinal exata do usuário no ranking global.
    """
    return bd.obter_minha_posicao_global(usuario_id=usuario_id)

# ============================================================
# EXECUÇÃO DIRETA
# ============================================================

# ============================================================
# ROTAS - IA E AVALIAÇÃO BIOMECÂNICA
# ============================================================

@app.post("/ia/reiniciar-sessao", tags=["IA & Biomecânica"])
def api_ia_reiniciar_sessao(req: ReiniciarSessaoIARequest):
    """
    Inicializa ou reseta a sessão do atleta para o exercício selecionado.
    """
    return ServicoIA.obter_instancia().reiniciar_sessao(
        usuario_id=req.usuario_id,
        exercicio_id=req.exercicio_id,
    )

@app.post("/ia/processar-frame", tags=["IA & Biomecânica"])
async def api_ia_processar_frame(
    frame: UploadFile = File(...),
    usuario_id: str = Form("anonimo"),
    exercicio: str = Form("1"),
    lado: str = Form("direito"),
):
    """
    Recebe um fotograma (Multipart JPG/PNG), decodifica em memória RAM,
    avalia o movimento na FSM e DTW, e devolve as métricas em tempo real para o HUD.
    """
    conteudo = await frame.read()
    return ServicoIA.obter_instancia().processar_frame_imagem(
        conteudo_bytes=conteudo,
        usuario_id=usuario_id,
        exercicio_id=exercicio,
        lado=lado,
    )

@app.post("/ia/processar-angulos", tags=["IA & Biomecânica"])
def api_ia_processar_angulos(req: ProcessarAngulosIARequest):
    """
    Permite processar diretamente um dicionário de ângulos (útil para testes sintéticos e clientes leves).
    """
    return ServicoIA.obter_instancia().processar_frame_angulos(
        angulos=req.angulos,
        usuario_id=req.usuario_id,
        exercicio_id=req.exercicio_id,
        visivel=req.visivel,
    )

@app.post("/ia/simular-repeticao", tags=["IA & Biomecânica"])
def api_ia_simular_repeticao(req: SimularRepeticaoIARequest):
    """
    Injeta uma repetição canônica completa no orquestrador do usuário para
    demonstrações instantâneas da banca avaliadora sem depender de webcam física.
    """
    return ServicoIA.obter_instancia().simular_repeticao(
        usuario_id=req.usuario_id,
        exercicio_id=req.exercicio_id,
        tipo_cenario=req.tipo_cenario,
    )

@app.get("/ia/resumo-sessao", tags=["IA & Biomecânica"])
def api_ia_obter_resumo_sessao(usuario_id: str = Query(...)):
    """
    Retorna o laudo da série realizada com o total de repetições,
    taxa de aprovação, recomendação biomecânica e pontos de gamificação.
    """
    return ServicoIA.obter_instancia().obter_resumo_sessao(usuario_id=usuario_id)

@app.post("/ia/finalizar-serie-e-pontuar", tags=["IA & Biomecânica"])
def api_ia_finalizar_serie_e_pontuar(req: FinalizarSerieIARequest):
    """
    Consolida a série do atleta com o motor de IA e envia os pontos conquistados
    diretamente para a tabela 'usuarios', atualizando a sequência diária (streak) e o Leaderboard.
    """
    resumo_resp = ServicoIA.obter_instancia().obter_resumo_sessao(usuario_id=req.usuario_id)
    if not resumo_resp.get("sucesso") or not resumo_resp.get("dados"):
        return {
            "sucesso": False,
            "mensagem": "Nenhuma sessão ativa com repetições para pontuar.",
            "resumo": None,
            "banco": None,
        }

    dados = resumo_resp["dados"]
    pts = int(round(dados.get("pontos_gamificacao", 0.0)))

    # Se fez repetições aprovadas mas a pontuação arredondada deu zero, garante ao menos 10 pts
    if pts == 0 and dados.get("repeticoes_aprovadas", 0) > 0:
        pts = 10

    resp_banco = None
    if pts > 0:
        try:
            resp_banco = bd.adicionar_pontuacao_diaria(
                usuario_id=req.usuario_id,
                pontos=pts,
                incrementar_sequencia=req.incrementar_sequencia,
            )
        except Exception as e:
            resp_banco = {"sucesso": False, "mensagem": f"Erro ao sincronizar pontos: {e}"}

    return {
        "sucesso": True,
        "pontos_atribuidos": pts,
        "resumo_ia": dados,
        "atualizacao_banco": resp_banco,
    }

if __name__ == "__main__":
    print("Iniciando servidor FastAPI em http://0.0.0.0:8000 ...")
    uvicorn.run("api:app", host="0.0.0.0", port=8000, reload=True)

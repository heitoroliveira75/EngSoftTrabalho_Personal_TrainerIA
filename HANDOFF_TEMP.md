# 🔄 AGY HANDOFF CONTEXT

## 🎯 Next Session Objective
**Mapeamento Geral da Arquitetura e Contexto do Projeto**
O objetivo prioritário da próxima sessão é fornecer uma compreensão profunda da arquitetura do projeto **Personal Trainer IA**, detalhando os principais arquivos, responsabilidades de cada camada (Frontend Flutter, Backend FastAPI e Banco de Dados Supabase) e fluxos de dados, para que qualquer IA agêntica compreenda o contexto completo e possa retomar o desenvolvimento, testes, refatoração ou evolução de novas funcionalidades imediatamente.

---

## 📊 Current State & Artifacts

### 1. Arquivos Criados ou Modificados Nesta Sessão
* `HANDOFF_TEMP.md`: Documento de transição universal com o mapeamento arquitetural e catálogo de arquivos.
* `AGY_HANDOFF_TEMP.md`: Versão prévia do documento de transição.
* `.agents/skills/handoff/SKILL.md`: Definição local da skill de handoff no projeto.

---

### 2. Visão Geral da Arquitetura do Sistema
O projeto implementa uma arquitetura de 3 camadas desacopladas:

```
┌─────────────────────────────────────────────────────────────┐
│                 Frontend (Flutter / Dart)                   │
│   Telas UI ──> ApiService (Singleton) ──> ApiConfig (Host)   │
└──────────────────────────────┬──────────────────────────────┘
                               │ HTTP / REST (JSON)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                  Backend (Python / FastAPI)                 │
│         api.py (Rotas REST, Pydantic Models, CORS)          │
│                              │                              │
│         main.py (Regras de Negócio & Gamificação)           │
└──────────────────────────────┬──────────────────────────────┘
                               │ Supabase SDK / PostgreSQL
                               ▼
┌─────────────────────────────────────────────────────────────┐
│             Banco de Dados & Auth (Supabase)                │
│    Tabelas: usuarios, exercicios, treinos, exercicios_treino│
│    Auth: Supabase GoTrue (JWT / Sessões)                    │
│    Triggers & Funções SQL: Sequência, Pontuação, RLS        │
└─────────────────────────────────────────────────────────────┘
```

---

### 3. Catálogo dos Principais Arquivos do Projeto (Caminhos Relativos)

#### A. Frontend Mobile / Web (`lib/`)
* **Inicialização e Navegação:**
  * `lib/main.dart`: Ponto de entrada do Flutter. Configura o tema global escuro (`0xFF0D1117`) com detalhes em verde neon (`0xFF00E676`) e registra as 14 rotas nomeadas da aplicação.
* **Configuração de Conectividade:**
  * `lib/config/api_config.dart`: Fornece a URL base dinâmica (`baseUrl`), roteando para `http://10.0.2.2:8000` no Emulador Android e `http://127.0.0.1:8000` em ambientes Desktop (Windows), Web ou iOS Simulator.
* **Camada de Serviço e Estado de Sessão:**
  * `lib/services/api_service.dart`: Classe Singleton que centraliza todas as comunicações com a API REST backend e gerencia o estado do usuário logado na memória:
    1. *Autenticação e Sessão:* `criarConta`, `fazerLogin`, `deslogar`, `obterUsuarioAtual`, `esqueceuSenha`, `redefinirSenha`, `alterarSenha`.
    2. *Perfil de Usuário:* `verPerfil`, `editarPerfil`.
    3. *Exercícios:* `listarExercicios` (com filtro por grupo muscular).
    4. *Treinos:* `verTreinosPremontados`, `verTreinosPorDificuldade`, `listarTreinos` do usuário, `criarTreino`, `editarTreino`, `excluirTreino`.
    5. *Pontuações e Gamificação:* `verPontuacao`, `adicionarPontuacaoDiaria`, `atualizarSequencia`, `atualizarMaiorSequencia`, `atualizarChecagem`, `resetarChecagem`.
* **Modelos de Domínio:**
  * `lib/models/exercicio_treino.dart`: Modelo estruturado de um exercício inserido em um treino (séries, repetições, cálculo de pontos por repetição/série e serialização `toJson`/`fromJson`).
* **Interface do Usuário (`lib/screens/`):**
  * `lib/screens/login_screen.dart`: Tela de login com validação de campos e integração com `ApiService.fazerLogin`.
  * `lib/screens/cadastro_screen.dart`: Tela de cadastro de novos usuários.
  * `lib/screens/esqueceu_senha_screen.dart` & `lib/screens/redefinir_senha_screen.dart`: Telas para recuperação e alteração de senha esquecida via token.
  * `lib/screens/home_screen.dart`: Painel principal com exibição de sequência diária (streak), pontuação acumulada, atalhos de treino e menu lateral/inferior.
  * `lib/screens/training_menu_screen.dart`: Hub principal de opções de treinamento e seleção de categorias.
  * `lib/screens/dificuldade_treino_screen.dart`: Seleção de nível de dificuldade (`iniciante`, `intermediario`, `avancado`).
  * `lib/screens/opcao_treinos_screen.dart`: Listagem e escolha dos treinos (pré-montados por dificuldade ou criados pelo usuário em `meus_treinos`).
  * `lib/screens/treinos_screen.dart`: Lista e visão geral dos treinos do usuário.
  * `lib/screens/treino_selecionado_screen.dart`: Tela de execução e acompanhamento do treino ativo (marcação de séries concluídas, cálculo de pontos e atualização de sequência).
  * `lib/screens/criar_exercicio_screen.dart`: Criação personalizada de novos treinos e configuração de exercícios.
  * `lib/screens/profile_screen.dart`: Exibição do perfil do usuário, ranking, estatísticas e opções de logout.
  * `lib/screens/change_name_screen.dart` & `lib/screens/change_password_screen.dart`: Telas para atualização cadastral do perfil.

#### B. Backend e Banco de Dados (`BD/`)
* **Servidor REST FastAPI:**
  * `BD/api.py`: Aplicação FastAPI com middlewares de CORS, validação de requisições com modelos Pydantic (`CriarContaRequest`, `LoginRequest`, `CriarTreinoRequest`, `AdicionarPontuacaoRequest`, etc.) e roteamento para funções de negócio.
* **Lógica de Acesso a Dados e Supabase:**
  * `BD/main.py`: Camada de regras de negócio e consultas ao Supabase:
    * Métodos de autenticação Supabase GoTrue (`criar_conta`, `fazer_login`, `obter_usuario_atual`, etc.).
    * Métodos cadastrais (`ver_perfil`, `editar_perfil`).
    * Gerenciamento de exercícios e treinos (`listar_exercicios`, `criar_treino`, `editar_treino`, `excluir_treino`, `ver_treinos_por_dificuldade`, `_desempacotar_treino`).
    * Gamificação (`adicionar_pontuacao_diaria`, `atualizar_sequencia`, `atualizar_maior_sequencia`, `atualizar_checagem`, `resetar_checagem_diaria`).
* **Cliente Supabase:**
  * `BD/supabase_client.py`: Leitura do arquivo `.env` e inicialização do singleton `supabase: Client`.
* **Especificações e Guias de Referência:**
  * `guia_api.md`: Documentação completa de mais de 600 linhas com todos os endpoints, payloads de requisição/resposta, exemplos em Python (`requests`) e Dart (`ApiService`).
  * `BD/Definições do banco`: Descrição do esquema de tabelas e tipos de dados do PostgreSQL.
  * `BD/guia funcoes back-end`: Relação detalhada de assinaturas e responsabilidades das funções em `main.py`.
  * `BD/guia flutter-python`: Padrões e contratos de integração entre o aplicativo Flutter e a API FastAPI.
  * `BD/Guia RLS`: Instruções sobre políticas de Row Level Security no Supabase.
  * `BD/Esquema banco.png`: Diagrama visual do banco de dados.

---

### 4. Estado Atual do Repositório Git
* **Branch Ativa:** `Banco-de-Dados` (sincronizada com `origin/Banco-de-Dados`).
* **Últimos Commits Relevantes:**
  * `82c32ff`: "adicionadas as telas novas e conexoes feitas"
  * `a3b5f6c`: "Adicionado esquema do banco corrigido e sistema de contabilizar sequencia"
  * `96fb035`: "Adicionado sistema de pontuação com triggers, eventos e integração ao back e frontend"
  * `cc65c90`: "Adicionadas novas telas e conexao com a API e banco"
  * `3b089e4`: "Adicionadas telas na branch banco e conexão entre python-flutter por FastAPI"

---

## 🧠 Decisions & Constraints
1. **Comunicação Indireta Obrigatória:** O app Flutter nunca se conecta diretamente ao banco de dados Supabase; todas as operações devem passar pela API FastAPI (`BD/api.py`), assegurando centralização de regras e validações.
2. **Gerenciamento de Estado do Usuário:** O `ApiService` em `lib/services/api_service.dart` mantém os dados da sessão em memória durante a execução do aplicativo.
3. **Integridade da Gamificação:** Pontos (diários, semanais, totais) e dias consecutivos de sequência (`sequencia`, `maior_sequencia`, flag `checagem`) são calculados e persistidos no backend via `BD/main.py`.
4. **Endereçamento Multiplataforma:** As chamadas de rede no Flutter devem sempre usar `ApiConfig.baseUrl` para garantir funcionamento tanto em emuladores Android quanto em desktop ou web.

---

## 🛠️ Suggested Skills
O próximo agente deve chamar as seguintes skills dependendo da tarefa a ser executada:
* **`handoff`** (`.agents/skills/handoff/SKILL.md`): Chamar ao final da próxima sessão para registrar novos avanços e orientar a sessão subsequente.
* **`antigravity-guide`**: Para guias sobre melhores práticas do ambiente e arquitetura de agentes.
* **`agy-customizations`**: Para gerenciar ou criar novos workflows, regras e plugins no ambiente de desenvolvimento.

---

## ❌ Redacted Information
* **[CRÍTICO] Segredos e Credenciais Omitidos:**
  * As chaves de acesso ao Supabase (`SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_PUBLISHABLE_KEY`) presentes em `BD/.env` foram totalmente omitidas deste documento e devem permanecer restritas ao arquivo local de variáveis de ambiente.

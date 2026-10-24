# 🗺️ Guia de Contexto do Projeto: Personal Trainer IA

> **Última Atualização:** 2026-10-24  
> **Status do Projeto:** Estável / Módulo Social & Gamificação Integrado  
> **Versão:** 1.1.0  

---

## 📖 Visão Geral

O **Personal Trainer IA** é uma solução completa desenvolvida para auxiliar praticantes de atividades físicas na gestão, acompanhamento e personalização de seus treinos, além de estimular o engajamento contínuo através de gamificação e interação social entre atletas. O ecossistema é composto por um aplicativo mobile moderno construído em **Flutter**, integrado a um back-end intermediário em **FastAPI (Python)** e armazenamento persistente com autenticação segura provido pelo **Supabase (PostgreSQL)**.

### Objetivos Principais
1. **Autenticação & Gestão de Usuários:** Cadastro, login com recuperação de senha e gestão de perfil.
2. **Rotinas e Planos de Treino:** Seleção de treinos por grupamento muscular, níveis de intensidade (Iniciante, Intermediário, Avançado) e rotinas personalizadas.
3. **Criação e Gestão de Exercícios:** Interface flexível para criar, listar e vincular exercícios aos treinos.
4. **Módulo Social & Amizades:** Busca de usuários cadastrados por aproximação de nome, envio e gerenciamento de solicitações de amizade (aceitar/recusar/remover conexões).
5. **Classificação & Gamificação (Leaderboard):** Ranking Global e Ranking entre Amigos com métricas duplas (**Pontuação Semanal** e **Streak de Treinos consecutivos**), seletor dinâmico de critério de ordenação e pódio interativo.
6. **Arquitetura Assistida por Agentes de IA:** Governança técnica orientada por agentes locais e regras de engenharia de software.

---

## 🏗️ Arquitetura & Fluxo de Dados

A arquitetura segue o modelo em camadas, desacoplando a interface visual móvel da regra de acesso a banco e serviços terceiros através de uma API REST:

```mermaid
flowchart TD
    subgraph Frontend["Frontend (Flutter / Dart)"]
        UI["Screens (lib/screens/)\n- Auth, Workouts, Profile\n- LeaderboardScreen, AmigosScreen"]
        Models["Models (lib/models/)"]
        Service["ApiService (lib/services/api_service.dart)"]
        Config["ApiConfig (lib/config/api_config.dart)"]
        
        UI --> Service
        UI --> Models
        Service --> Config
    end

    subgraph Backend["Backend (FastAPI / Python)"]
        API["API REST (BD/api.py)\n- /auth, /treinos, /perfil\n- /amigos, /leaderboard"]
        Core["Core Logic (BD/main.py)\n- Regras de negócio\n- Resolução RLS & RPCs"]
        ClientDB["Supabase Client (BD/supabase_client.py)"]

        API --> Core
        Core --> ClientDB
    end

    subgraph Database["BaaS & Storage (Supabase)"]
        Auth["Supabase Auth"]
        Tables["PostgreSQL (usuarios, treinos, exercicios, amizades)"]
        RPC["Funções RPC SECURITY DEFINER\n(obter_leaderboard_global, etc.)"]
    end

    Service -->|HTTP / JSON| API
    ClientDB -->|SDK / REST| Auth
    ClientDB -->|SDK / SQL| Tables
    ClientDB -->|RPC / SQL| RPC
```

---

## 🎮 Módulo Social & Gamificação

### 1. Leaderboard / Classificação Geral e Entre Amigos
* **Abas de Visualização:**
  * **Global:** Classificação pública de todos os atletas cadastrados na comunidade.
  * **Amigos:** Classificação restrita entre o usuário logado e seus amigos confirmados.
* **Métricas Duplas em Destaque:**
  * **Pontuação Semanal:** Pontos acumulados exclusivamente no ciclo semanal atual através da conclusão de treinos.
  * **Streak de Treinos:** Sequência contínua de dias em que o usuário treinou e validou seu ciclo diário (`checagem = true`).
* **Seletor de Critério de Ordenação:**
  * **⭐ Pontuação Semanal (Padrão):** Ordena os atletas com mais pontos na semana (desempate por streak).
  * **🔥 Streak de Treinos:** Ordena os atletas com a maior sequência ativa de dias (desempate por pontos).
* **Componentes da Tela:**
  * **Pódio dos 3 Primeiros:** Destaque visual ouro/prata/bronze exibindo nome, pontuação semanal e streak.
  * **Card de Posição Individual:** Exibe a colocação do usuário logado, seus pontos e streak em tempo real.
  * **Tabela Completa:** Lista ordenada com posição, avatar, nome (badge "VOCÊ" para o usuário atual) e métricas lado a lado.

### 2. Gestão de Amigos e Conexões
* **Aba "Meus Amigos":** Lista amigos confirmados, exibindo seus nomes reais, dias de streak e pontuação semanal, com botão para desfazer a amizade.
* **Aba "Solicitações":** Lista convites recebidos pendentes, exibindo o nome de quem enviou o pedido com opções imediatas de "Aceitar" ou "Recusar".
* **Aba "Buscar":** Campo de busca por nome conectado em tempo real à API. Permite encontrar atletas cadastrados e clicar em "Conectar" para enviar solicitação de amizade.
* **Resolução Segura de Nomes (RLS):** O back-end utiliza procedimentos com `SECURITY DEFINER` e mapeamento analítico para resolver e exibir os nomes reais dos atletas mesmo com o Row-Level Security ativado nas tabelas.

---

## 💻 Stack Tecnológica

| Componente | Tecnologia | Versão | Descrição |
| :--- | :--- | :--- | :--- |
| **Mobile Frontend** | Flutter / Dart | Dart 3.13+ / Flutter SDK | Interface móvel nativa multi-plataforma (Android, iOS, Web) |
| **Backend REST API** | FastAPI / Uvicorn | FastAPI >= 0.110 | Camada de rotas assíncronas e serialização com Pydantic |
| **Banco de Dados & Auth** | Supabase / PostgreSQL | Supabase Python >= 2.3 | Autenticação gerenciada, triggers, RLS e funções RPC |
| **Orquestração IA** | Google Antigravity | Custom Agents & Skills | Subagentes (`context-navigator`, `code-architect`) |

---

## 📁 Estrutura de Pastas e Módulos

```text
EngSoftTrabalho_Personal_TrainerIA/
├── .agents/                 # Governança de agentes, subagentes e skills locais
│   ├── agents/              # Definições dos agentes (context-navigator, code-architect)
│   ├── skills/              # Habilidades reutilizáveis (ai-context, human-context)
│   └── config.json          # Registro dos agentes e skills do workspace
├── .ai_context.md           # Contexto denso e ultraconciso consumido pela IA
├── PROJECT_CONTEXT.md       # Este guia de contexto voltado a humanos
├── guia_api.md              # Guia prático com exemplos de consumo da API em Python e Dart
├── BD/                      # Servidor backend Python e scripts de banco
│   ├── .ai_context.md       # Contexto denso do banco/API consumido pela IA
│   ├── DATABASE_CONTEXT.md  # Guia completo consolidado de Banco e APIs para humanos
│   ├── api.py               # Servidor FastAPI com rotas REST e documentação Swagger
│   ├── main.py              # Funções de interação direta com o Supabase e regras de negócio
│   ├── supabase_client.py   # Inicialização da conexão com Supabase
│   ├── script_amizades_leaderboard.sql # DDL de amizades, índices e funções RPC SECURITY DEFINER
│   ├── requirements.txt     # Dependências Python
│   └── .env                 # Variáveis de ambiente (chaves de API e URLs)
├── lib/                     # Código-fonte principal da aplicação Flutter
│   ├── config/              # Configurações de conexão (api_config.dart)
│   ├── models/              # Estruturas e classes de modelo (exercicio_treino.dart)
│   ├── screens/             # Telas de UI (login, cadastro, perfil, treinos, leaderboard, amigos)
│   │   ├── .ai_context.md   # Contexto denso das telas para consumo rápido de IAs
│   │   ├── SCREENS_CONTEXT.md # Guia completo das telas e navegação para humanos
│   │   ├── home_screen.dart # Dashboard principal com atalhos para Leaderboard e Amigos
│   │   ├── leaderboard_screen.dart # Ranking Global e Amigos (Pontos Semanais e Streak)
│   │   ├── amigos_screen.dart # Gestão de amigos, convites e busca de atletas
│   │   └── ...              # Demais telas Dart (login, cadastro, perfil, treinos, etc.)
│   ├── services/            # Serviços HTTP e sessão de usuário (api_service.dart)
│   └── main.dart            # Ponto de entrada do aplicativo Flutter
└── pubspec.yaml             # Dependências e metadados do projeto Flutter
```

---

## 🚀 Como Executar o Projeto

### 1. Inicializar o Back-end (FastAPI)
Certifique-se de ter o Python 3.10+ instalado:

```bash
# 1. Acessar a pasta do backend
cd BD

# 2. Instalar as dependências
pip install -r requirements.txt

# 3. Iniciar o servidor de desenvolvimento
uvicorn api:app --reload --host 0.0.0.0 --port 8000
```
> Documentação interativa da API estará disponível em: `http://localhost:8000/docs`

### 2. Inicializar o Front-end (Flutter)
Em outro terminal:

```bash
# 1. Instalar as dependências
flutter pub get

# 2. Executar no emulador ou dispositivo conectado
flutter run
```

> [!NOTE]
> Se estiver utilizando o emulador Android, a conexão com a API local é feita automaticamente pelo alias `10.0.2.2:8000`, conforme configurado em `lib/config/api_config.dart`.

---

## 🛡️ Regras e Padrões de Projeto

1. **Camada de Serviço Centralizada:** Nenhuma tela em `lib/screens/` deve realizar chamadas `http` diretas; utilize sempre métodos dentro de `lib/services/api_service.dart`.
2. **Governança de IA (`code-architect`):** Nenhum arquivo de código funcional deve ser alterado sem alinhamento prévio e aprovação expressa do usuário.
3. **Segurança de Credenciais:** Arquivos `.env` e chaves sensíveis do Supabase jamais devem ser incluídos em commits ou expostos abertamente.
4. **Resolução de RLS e Nomes:** Sempre que dados de outros usuários precisarem ser consultados no front-end, utilizar as funções RPC dedicadas com `SECURITY DEFINER` para contornar o bloqueio de linhas do PostgreSQL.

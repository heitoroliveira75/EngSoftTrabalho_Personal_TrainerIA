# PersonAI

---

##  Sobre o Projeto

Manter a disciplina nos treinos é um dos maiores desafios do dia a dia. A vontade de mudar de vida existe, mas a falta de acompanhamento, o desânimo e a rotina corrida muitas vezes falam mais alto. 

O **PersonAI** nasceu para ser mais do que apenas uma lista digital de exercícios: ele é um **aliado na sua jornada fitness**. Combinando praticidade, acompanhamento visual e mecânicas de gamificação, o aplicativo incentiva o usuário a criar hábitos consistentes, transformando cada treino concluído em uma conquista real comemorada na tela.

---

##  O Que Torna o PersonAI Especial?

*  **Constância que Motiva (Streaks & Gamificação):** Mantenha sua sequência de dias ativos, desafie-se a bater sua maior sequência e acumule pontos a cada exercício finalizado.
*  **Treinos Sob Medida:** Escolha treinos pré-montados pensados para o seu nível (**Iniciante**, **Intermediário** ou **Avançado**) ou crie suas próprias rotinas personalizadas com séries, repetições e grupos musculares específicos.
*  **Execução Fluida em Tempo Real:** Marque suas séries enquanto treina, acompanhe o progresso imediato e sinta o impacto de cada repetição sem distrações.
*  **Comunidade e Amigos:** Busque e adicione amigos, acompanhe a sequência de cada um e dispute posições no ranking global e entre amigos.
*  **Segurança e Perfil Individual:** Acesso pessoal protegido com login, recuperação de senha e um painel completo para acompanhar sua pontuação total, semanal e recordes.
*  **Visual Moderno e Focado:** Design intuitivo com tema escuro (*Dark Mode*) e detalhes em verde neon, pensado para não cansar a vista e manter a energia alta na academia ou em casa.

---

##  Arquitetura do Sistema

O projeto foi construído sobre uma arquitetura moderna, desacoplada e segura em três camadas:

![alt text](<Arquitetura do sistema 08_10.png>)

### Como tudo se conecta:
1. **Frontend (Flutter):** Aplicação multiplataforma (Android, iOS, Desktop e Web) com interface responsiva, gerenciando a interação do usuário através de um serviço centralizado ([ApiService](lib/services/api_service.dart)).
2. **Backend (Python & FastAPI):** Atua como o cérebro das regras de negócio ([BD/api.py](BD/api.py) e [BD/main.py](BD/main.py)), processando validações, lógica de pontuação, amizades, leaderboard e isolando o acesso direto ao banco.
3. **Motor de IA & Visão Computacional:** Pipeline biomecânico em tempo real com MediaPipe Pose, FSM ([exercicios_fsm.py](exercicios_fsm.py)), comparador DTW ([dtw_evaluator.py](dtw_evaluator.py)) e orquestrador de sessão ([servico_ia_api.py](servico_ia_api.py)). Documentações detalhadas em [GUIA_INTEGRACAO_FRONT_IA.md](GUIA_INTEGRACAO_FRONT_IA.md) e [EXPLICACAO_IA.md](EXPLICACAO_IA.md).
4. **Banco de Dados & Autenticação (Supabase / PostgreSQL):** Gerencia identidades e sessões com GoTrue (JWT), além de tabelas relacionais com triggers automáticos para apuração de pontuação e proteção de dados via Row Level Security (RLS) e RPCs seguras.

---

##  Como Começar

### Pré-requisitos
* [Flutter SDK](https://flutter.dev/docs/get-started/install) (versão ^3.13)
* Dispositivo físico, emulador configurado ou Google Chrome para execução Web
* *(Opcional para desenvolvimento local do backend)*: [Python 3.10+](https://www.python.org/downloads/)

---

### 1. Executando o Aplicativo (Flutter) — Modo Nuvem (Recomendado)

O backend do projeto **já está hospedado e operando online no Render** (`https://personai-t6mf.onrender.com`).  
Por padrão, o aplicativo já vem configurado em [`lib/config/api_config.dart`](lib/config/api_config.dart) para consumir a API em nuvem, não sendo necessário rodar nenhum arquivo Python na sua máquina para usar o app!

1. Na raiz do projeto, instale as dependências:
   ```bash
   flutter pub get
   ```

2. Execute o aplicativo:
   ```bash
   flutter run
   ```

> [!NOTE]
> **Hibernação no Plano Gratuito do Render:**  
> Se a API ficar sem receber requisições por mais de 15 minutos, o servidor entra em modo de repouso (*cold start*). A primeira requisição feita após esse período pode levar cerca de **30 a 50 segundos** para acordar a instância. Após acordar, o tempo de resposta volta a ser imediato.

---

### 2. Execução Local do Backend (Opcional / Desenvolvimento)

Caso queira fazer alterações no backend ou testar novos endpoints antes de publicar no Render:

1. Navegue até o diretório do backend:
   ```bash
   cd BD
   ```

2. Crie e ative um ambiente virtual:
   ```bash
   python -m venv venv
   # No Windows:
   .\venv\Scripts\activate
   # No Linux/macOS:
   source venv/bin/activate
   ```

3. Instale as dependências:
   ```bash
   pip install -r requirements.txt
   ```

4. Crie o seu arquivo `.env` baseado no modelo [`BD/.env.example`](BD/.env.example):
   ```env
   SUPABASE_URL=sua_url_supabase
   SUPABASE_PUBLISHABLE_KEY=sua_chave_publica_ou_anon
   SUPABASE_SERVICE_ROLE_KEY=sua_chave_service_role
   ```

5. Inicie o servidor FastAPI local:
   ```bash
   uvicorn api:app --host 0.0.0.0 --port 8000 --reload
   ```

6. No arquivo [`lib/config/api_config.dart`](lib/config/api_config.dart), altere a variável `remoteUrl` para `null`:
   ```dart
   static const String? remoteUrl = null;
   ```
   O Flutter voltará a usar automaticamente o `localhost` (ou `10.0.2.2` no emulador Android).

---

### 3. Deploy no Render

O repositório inclui um arquivo de automação [`render.yaml`](render.yaml) (Blueprint). Para criar sua própria instância no Render:
1. Acesse o [Dashboard do Render](https://dashboard.render.com/) e crie um **Blueprint** ou **Web Service** apontando para o repositório.
2. Defina as variáveis de ambiente `SUPABASE_URL` e `SUPABASE_PUBLISHABLE_KEY` nas configurações do serviço.
3. A inicialização e instalação de dependências ocorrem automaticamente conforme definido no [`render.yaml`](render.yaml).

---

##  Tecnologias Utilizadas

* **Mobile / Frontend:** [Flutter](https://flutter.dev/) & [Dart](https://dart.dev/)
* **Backend:** [Python](https://www.python.org/) & [FastAPI](https://fastapi.tiangolo.com/)
* **Servidor ASGI:** [Uvicorn](https://www.uvicorn.org/)
* **Banco de Dados & Auth:** [Supabase](https://supabase.com/) (PostgreSQL & GoTrue)
* **Validação de Dados:** [Pydantic](https://docs.pydantic.dev/)
* **Hospedagem & Cloud Backend:** [Render](https://render.com/)

---

## Contexto do Projeto

Este projeto está sendo desenvolvido no âmbito da disciplina de **Engenharia de Software**, com foco na aplicação prática de padrões arquiteturais modernos, desenvolvimento ágil, separação de responsabilidades e entrega contínua de valor centrado no usuário.

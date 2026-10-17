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
*  **Segurança e Perfil Individual:** Acesso pessoal protegido com login, recuperação de senha e um painel completo para acompanhar sua pontuação total, semanal e recordes.
*  **Visual Moderno e Focado:** Design intuitivo com tema escuro (*Dark Mode*) e detalhes em verde neon, pensado para não cansar a vista e manter a energia alta na academia ou em casa.

---

##  Arquitetura do Sistema

O projeto foi construído sobre uma arquitetura moderna, desacoplada e segura em três camadas:

![alt text](<Arquitetura do sistema 08_10.png>)

### Como tudo se conecta:
1. **Frontend (Flutter):** Aplicação multiplataforma (Android, iOS, Desktop e Web) com interface responsiva, gerenciando a interação do usuário de forma ágil através de um serviço centralizado ([`ApiService`](lib/services/api_service.dart)).
2. **Backend (Python & FastAPI):** Atua como o cérebro das regras de negócio ([`BD/api.py`](BD/api.py) e [`BD/main.py`](BD/main.py)), processando validações, lógica de pontuação, sequências e garantindo que o app nunca precise acessar o banco diretamente.
3. **Banco de Dados & Autenticação (Supabase / PostgreSQL):** Gerencia identidades e sessões com GoTrue (JWT), além de tabelas relacionais com triggers automáticos para apuração de pontuação diária e proteção de dados via Row Level Security (RLS).

---

##  Como Começar

### Pré-requisitos
* [Flutter SDK](https://flutter.dev/docs/get-started/install) (versão ^3.13)
* [Python 3.10+](https://www.python.org/downloads/)
* Uma conta ou instância configurada no [Supabase](https://supabase.com/)

---

### 1. Inicializando o Backend (FastAPI)

1. Navegue até o diretório do backend:
   ```bash
   cd BD
   ```

2. Crie e ative um ambiente virtual (opcional, mas recomendado):
   ```bash
   python -m venv venv
   # No Windows:
   .\venv\Scripts\activate
   # No Linux/macOS:
   source venv/bin/activate
   ```

3. Instale as dependências necessárias:
   ```bash
   pip install fastapi uvicorn pydantic supabase python-dotenv requests
   ```

4. Configure o arquivo `.env` dentro da pasta `BD` com as credenciais do seu Supabase:
   ```env
   SUPABASE_URL=sua_url_supabase
   SUPABASE_KEY=sua_service_role_ou_anon_key
   ```

5. Inicie o servidor da API:
   ```bash
   uvicorn api:app --host 0.0.0.0 --port 8000 --reload
   ```
---

### 2. Executando o Aplicativo (Flutter)

1. Na raiz do projeto, instale os pacotes do Flutter:
   ```bash
   flutter pub get
   ```

2. Execute o aplicativo no seu dispositivo ou emulador:
   ```bash
   flutter run
   ```
   >  O aplicativo detecta automaticamente o ambiente (Desktop, Emulador Android em `10.0.2.2` ou Web) via [`lib/config/api_config.dart`](lib/config/api_config.dart).

---

##  Tecnologias Utilizadas

* **Mobile / Frontend:** [Flutter](https://flutter.dev/) & [Dart](https://dart.dev/)
* **Backend:** [Python](https://www.python.org/) & [FastAPI](https://fastapi.tiangolo.com/)
* **Servidor ASGI:** [Uvicorn](https://www.uvicorn.org/)
* **Banco de Dados & Auth:** [Supabase](https://supabase.com/) (PostgreSQL & GoTrue)
* **Validação de Dados:** [Pydantic](https://docs.pydantic.dev/)

---

## Contexto do Projeto

Este projeto está sendo desenvolvido no âmbito da disciplina de **Engenharia de Software**, com foco na aplicação prática de padrões arquiteturais modernos, desenvolvimento ágil, separação de responsabilidades e entrega contínua de valor centrado no usuário.

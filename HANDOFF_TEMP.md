# 🔄 AGY HANDOFF CONTEXT

## 🎯 Next Session Objective
**Revisão de Código, Testes de Campo e Integração da IA de Postura na Câmera de Treino**
O objetivo prioritário da próxima sessão é realizar a **revisão e homologação do código da tela de câmera**, testar a execução em hardware real (webcam no Windows e celular Android), e evoluir o backend (`BD/api.py`) para integrar o processamento de visão computacional (ex: MediaPipe / Pose Estimation) nos frames recebidos.

---

## ⚠️ Status de Revisão do Código
> [!WARNING]
> **ATENÇÃO: O código recém-implementado nesta sessão AINDA NÃO FOI REVISADO POR UM HUMANO.**
> Embora a compilação e o linter estejam sem erros (`flutter analyze` limpo e rotas FastAPI validadas via testes automatizados), o fluxo completo de câmera e streaming de rede necessita de validação manual criteriosa, testes de regressão e auditoria de código antes de qualquer merge na branch principal ou implantação em produção.

---

## 📊 Current State & Artifacts

### 1. Arquivos Criados ou Modificados Nesta Sessão
* `lib/screens/camera_treino_screen.dart` & `lib/screens/camera_treino.dart`: Nova tela de monitoramento com câmera. Captura e envia periodicamente (a cada 2s) frames via Multipart HTTP, com preview adaptado para desktop (16:9) e mobile, contador de frames, controle de pausa/retomada e exclusão de temporários locais.
* `pubspec.yaml` & `pubspec.lock`: Inclusão das dependências oficiais `camera: ^0.12.1` e `camera_windows: ^0.3.0`.
* `lib/main.dart`: Registro da rota nomeada `/camera-treino`.
* `BD/api.py`: 
  * Instalação e uso da dependência `python-multipart`.
  * Rota `POST /ia/processar-frame`: Recebe imagens, salva fisicamente com timestamp em `BD/frames_salvos/` e retorna status 200 JSON.
  * Rota `GET /ia/frames`: Lista os frames salvos mais recentes e dados de uso de disco.
  * Rota `DELETE /ia/frames`: Limpa os frames gravados para poupar armazenamento.
* `.gitignore`: Adicionado padrão para ignorar a pasta `BD/frames_salvos/`.
* `leia.txt`: Documento de especificação/código de referência fornecido pelo usuário.
* `HANDOFF_TEMP.md`: Documento de transição universal mantido atualizado.

---

### 2. Visão Geral da Arquitetura do Sistema
O projeto implementa uma arquitetura de 3 camadas desacopladas:

```
┌─────────────────────────────────────────────────────────────┐
│                 Frontend (Flutter / Dart)                   │
│   Telas UI ──> ApiService (Singleton) ──> ApiConfig (Host)   │
│   CameraTreinoScreen ──> Multipart Frame Upload (a cada 2s) │
└──────────────────────────────┬──────────────────────────────┘
                               │ HTTP / REST (JSON & Multipart)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                  Backend (Python / FastAPI)                 │
│         api.py (Rotas REST, UploadFile, CORS, Pydantic)     │
│         Rotas /ia/* (Processamento e Salvamento de Frames)  │
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
└──────────────────────────────┬──────────────────────────────┘
```

---

### 3. Catálogo dos Principais Arquivos do Projeto

#### A. Frontend Mobile / Web (`lib/`)
* **Inicialização e Navegação:**
  * `lib/main.dart`: Ponto de entrada do Flutter. Configura tema escuro (`0xFF0D1117`), verde neon (`0xFF00E676`) e 15 rotas nomeadas (incluindo `/camera-treino`).
* **Configuração de Conectividade:**
  * `lib/config/api_config.dart`: Roteamento dinâmico de `baseUrl` (`10.0.2.2:8000` para Android Emulator e `127.0.0.1:8000` para Desktop/Web).
* **Camada de Serviço e Estado de Sessão:**
  * `lib/services/api_service.dart`: Singleton de comunicação REST e gestão de sessão em memória.
* **Telas do Aplicativo (`lib/screens/`):**
  * `lib/screens/login_screen.dart`, `cadastro_screen.dart`, `esqueceu_senha_screen.dart`, `redefinir_senha_screen.dart`: Autenticação completa.
  * `lib/screens/home_screen.dart`: Dashboard principal com sequências e pontuações.
  * `lib/screens/training_menu_screen.dart`, `dificuldade_treino_screen.dart`, `opcao_treinos_screen.dart`, `treinos_screen.dart`: Fluxos de seleção e catálogo de treinos.
  * `lib/screens/treino_selecionado_screen.dart`: Execução ativa do treino com marcação de repetições e séries.
  * `lib/screens/criar_exercicio_screen.dart`: Criação de treinos customizados.
  * `lib/screens/profile_screen.dart`, `change_name_screen.dart`, `change_password_screen.dart`: Gerenciamento do perfil.
  * `lib/screens/camera_treino_screen.dart` (`lib/screens/camera_treino.dart`): Câmera em tempo real com captura periódica e envio de frames.

#### B. Backend e Banco de Dados (`BD/`)
* **Servidor REST FastAPI:**
  * `BD/api.py`: Endpoints REST de auth, treinos, pontuações, sequências e os novos endpoints `/ia/*`.
  * `BD/frames_salvos/`: Diretório local para inspeção dos frames gravados pela câmera.
* **Lógica de Acesso a Dados e Supabase:**
  * `BD/main.py`: Métodos de banco, regras de gamificação e Supabase GoTrue.
* **Cliente Supabase:**
  * `BD/supabase_client.py`: Leitura do `.env` e conexão ao Supabase.

---

### 4. Estado Atual do Repositório Git
* **Branch Ativa:** `Banco-de-Dados`.
* **Alterações Pendentes (Working Tree):**
  * `M lib/main.dart`
  * `M pubspec.yaml` & `pubspec.lock`
  * `M .gitignore`
  * `M BD/api.py`
  * `?? lib/screens/camera_treino_screen.dart`
  * `?? lib/screens/camera_treino.dart`
  * `?? leia.txt`

---

## 🧠 Decisions & Constraints
1. **Suporte Nativo ao Windows Desktop:** O plugin `camera_windows` é mandatário para o funcionamento em desktop Windows. Qualquer nova build no Windows requer `flutter clean` e `flutter run -d windows` para gerar os binários C++/CMake.
2. **Adaptação de Aspect Ratio do Preview:** Detecção via `Platform.isWindows` para não inverter proporções 16:9 de webcams desktop.
3. **Gerenciamento de Armazenamento:**
   * No app Flutter: limpeza imediata do arquivo gerado por `takePicture()` logo após o envio.
   * No backend: persistência opcional para testes em `BD/frames_salvos/`, com endpoint de limpeza dedicado (`DELETE /ia/frames`).
4. **Comunicação Indireta:** Todas as chamadas de rede no Flutter devem respeitar `ApiConfig.baseUrl`.

---

## 🔮 Sugestões de Próximos Passos

1. **Revisão Manual do Código:**
   * Inspecionar tratamento de exceções de rede e permissões negadas de câmera.
   * Verificar consumo de memória do Flutter durante longos períodos com o timer ativo.
2. **Validação Prática em Dispositivos:**
   * Executar no Windows (`flutter run -d windows`) e validar a abertura do feed da webcam.
   * Executar em dispositivo físico Android para validar a câmera traseira e frontal.
3. **Integração na Navegação do Aplicativo:**
   * Adicionar um botão de atalho "Treinar com IA (Câmera)" dentro de `treino_selecionado_screen.dart` ou no card da `home_screen.dart`.
4. **Implementação do Motor de IA no Backend:**
   * Conectar um modelo de Pose Estimation (ex: MediaPipe Pose, YOLO-Pose ou OpenCV) dentro de `BD/api.py` para processar o frame recebido, extrair os landmarks corporais e validar a postura (ex: ângulo do agachamento, flexão de braço).
5. **Feedback Visual em Tempo Real no App:**
   * Exibir mensagens/overlays na `CameraTreinoScreen` com as correções sugeridas pela resposta JSON da API (ex: "Coluna curvada", "Desça mais", "Repetição correta!").

---

## 🛠️ Suggested Skills
* **`handoff`** (`.agents/skills/handoff/SKILL.md`): Utilizar ao término de cada sessão de trabalho para garantir continuidade.
* **`antigravity-guide`**: Para guias sobre melhores práticas do ambiente e arquitetura.
* **`agy-customizations`**: Para fluxos avançados ou automações locais.

---

## ❌ Redacted Information
* **Segredos e Credenciais Omitidos:**
  * As chaves de acesso ao Supabase (`SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_PUBLISHABLE_KEY`) presentes em `BD/.env` permanecem estritamente restritas ao arquivo local de variáveis de ambiente.

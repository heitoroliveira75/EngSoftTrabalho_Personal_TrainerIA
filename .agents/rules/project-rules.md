# Regras Globais do Projeto (`.agents/rules/project-rules.md`)

1. **Fonte Única de Contexto para IA (`AI Only`):**
   - Antes de planejar ou codificar, leia **exclusivamente** `/.ai_context.md` e, quando a tarefa envolver um submódulo mapeado (`BD/`, `lib/screens/`), leia apenas o respectivo `<pasta>/.ai_context.md` antes de abrir código-fonte.
   - **Proibição de Leitura Completa de Documentação Humana:** É proibido ler documentos extensos voltados a humanos (`PROJECT_CONTEXT.md`, `DATABASE_CONTEXT.md`, `SCREENS_CONTEXT.md`, `CONTEXTO_IA.md`, `EXPLICACAO_IA.md`, `DIRETRIZES_DESENVOLVIMENTO.md`, `PLANO_*.md`, `guia_api.md`), salvo solicitação explícita do usuário.
   - Para atualizar o `DEVLOG.md`, leia **apenas as primeiras 35 linhas** (`StartLine: 1, EndLine: 35`) para identificar o número da última entrada e inserir a nova no topo, sem carregar o restante do arquivo.

2. **Alinhamento Prévio Obrigatório (`code-architect`):**
   - Nenhuma alteração em código funcional deve ser feita sem antes apresentar uma proposta concisa (Objetivo, Arquivos Afetados, Estratégia e Impactos) e obter aprovação explícita do usuário.

3. **Portabilidade e Convenções de Código:**
   - Utilize **exclusivamente caminhos relativos à raiz** do repositório (ex.: `lib/main.dart`, `BD/api.py`, `calculo_angulos.py`). É proibido usar caminhos absolutos locais (`C:\...`, `/home/...`, `file:///...`).
   - Novos módulos Python devem usar nomes `snake_case` em ASCII puro, *type hints*, docstrings com unidades explícitas (graus, frames, ms) e `encoding="utf-8"`.
   - Mantenha o domínio biomecânico (`calculo_angulos.py`, `exercicios_fsm.py`, `buffer_repeticao.py`, `dtw_evaluator.py`, `gabarito.py`, `avaliador_pontuacao.py`) desacoplado de OpenCV/MediaPipe.
   - Preserve os arquivos legados (`exercícios_fsm.py`, `dev_ombro-inicial.py`, `dtw_inicial.py`, `Modularização.py`, `*.csv`) intactos.

4. **Testes via CI e Sincronização Automática Obrigatória:**
   - **Não execute suítes de testes localmente** (`pytest`, `flutter test`, `flutter analyze`) a cada modificação; a validação ocorre via GitHub Actions (`.github/workflows/ci.yml`). Só rode testes locais se o usuário pedir explicitamente.
   - **Arquivos sempre atualizados ao concluir qualquer entrega:**
     1. `<pasta>/.ai_context.md` do módulo afetado (`BD/.ai_context.md`, `lib/screens/.ai_context.md`).
     2. `/.ai_context.md` da raiz.
     3. `DEVLOG.md` (inserindo nova `[Entrada #NNN]` no topo de `## Histórico de Entradas`, lendo apenas as linhas 1–35).

---
name: ai-context
description: Gera e atualiza o contexto denso do projeto (.ai_context.md na raiz e em subpastas) e registra entregas no topo do DEVLOG.md com mínimo gasto de tokens.
---

# Skill: AI Context Manager

## Objetivo
Manter a malha de arquivos `.ai_context.md` (raiz e subpastas modulares) ultraconcisa (40–70 linhas por arquivo) e registrar o histórico enxuto no topo do `DEVLOG.md`, garantindo mínimo consumo de tokens.

## 1. Arquitetura Hierárquica
1. **Raiz (`/.ai_context.md`):** Índice geral e roteador (`ENTRYPOINTS`, `MODULE_MAP`, `IA_BIOMECHANICS_CONTRACTS`, `ACTIVE_STATE`, `ARCH_RULES`), apontando para contextos locais (`BD/.ai_context.md`, `lib/screens/.ai_context.md`).
2. **Subpastas (`<pasta>/.ai_context.md`):** Mapas de domínio especializados (tabelas, RPCs, rotas REST/WS, telas Flutter e regras locais), lidos apenas sob demanda quando a tarefa tocar aquele módulo.

## 2. Regras de Escrita e Leitura
- **Isolamento AI Only:** Nunca ler arquivos de documentação narrativa humana (`PROJECT_CONTEXT.md`, `DATABASE_CONTEXT.md`, `SCREENS_CONTEXT.md`, `CONTEXTO_IA.md`, `EXPLICACAO_IA.md`, `DIRETRIZES_DESENVOLVIMENTO.md`, `PLANO_*.md`) nem listá-los em `ENTRYPOINTS` ou `key_files`.
- **Leitura Econômica do `DEVLOG.md`:** Nunca leia o `DEVLOG.md` inteiro. Para atualizá-lo, leia exclusivamente as linhas `1` a `35` para verificar a última `[Entrada #NNN]` e insira a nova entrada no topo de `## Histórico de Entradas`.
- **Caminhos Relativos:** Todos os caminhos registrados devem ser relativos à raiz do repositório (ex: `BD/api.py`, `lib/screens/login_screen.dart`). Proibido usar caminhos absolutos (`C:\...`, `/home/...`).

## 3. Ações Operacionais

### `check_and_read` (Leitura sob Demanda)
1. Leia `/.ai_context.md` na raiz.
2. Identifique os módulos afetados pela tarefa em `MODULE_MAP` / `ENTRYPOINTS`.
3. Se o módulo possuir `<pasta>/.ai_context.md` local, leia-o antes de inspecionar arquivos de código-fonte.

### `update` (Sincronização Automática em Cascata)
Sempre ao concluir alterações funcionais, novas rotas, schemas ou criação/remoção de arquivos, atualize obrigatoriamente:
1. **Local:** `<pasta>/.ai_context.md` do módulo modificado.
2. **Raiz:** `/.ai_context.md` (`LAST_UPDATE`, `ACTIVE_STATE` e, se aplicável, `ENTRYPOINTS` / `MODULE_MAP` / `IA_BIOMECHANICS_CONTRACTS`).
3. **Devlog:** `DEVLOG.md` (leia apenas linhas 1–35 e adicione a nova `[Entrada #NNN]` no topo da seção `## Histórico de Entradas`).

## 4. Template para Contextos Locais (`<pasta>/.ai_context.md`)
```markdown
# AI_[MODULO]_CONTEXT
LAST_UPDATE: YYYY-MM-DDTHH:mm:ss
STACK: [tecnologia|biblioteca|padrao]

## ENTRYPOINTS
- entry1: caminho/relativo/arquivo.ext

## [DOMAIN]_MAP
- item1: [papel] -> key_details: (...)

## ARCH_RULES_[MODULO]
- regra_1: restricao_objetiva
```

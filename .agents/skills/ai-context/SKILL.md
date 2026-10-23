---
name: ai-context
description: Gera e atualiza o contexto denso do projeto (.ai_context.md) otimizado para consumo e navegação rápida de IAs com mínimo gasto de tokens.
---

# Skill: AI Context Manager

## Objetivo
Manter o arquivo `.ai_context.md` na raiz do projeto com estrutura ultra-concisa (máximo 60-80 linhas), focada na navegação rápida e baixo consumo de tokens.

## Estrutura Padrão do `.ai_context.md`

```markdown
# AI_CONTEXT
LAST_UPDATE: YYYY-MM-DDTHH:mm:ss
STACK: [linguagem|framework|banco]

## ENTRYPOINTS
- main: caminho/para/entrada.ext
- config: caminho/para/config.ext

## MODULE_MAP
- caminho/dir1/: [papel_curto] -> key_files: (arq1.ext, arq2.ext)
- caminho/dir2/: [papel_curto] -> key_files: (arq3.ext)

## ACTIVE_STATE
- [status] descricao_curta_da_tarefa_ou_feature

## ARCH_RULES
- regra1: restricao_concisa
- regra2: restricao_concisa
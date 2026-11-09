---
name: human-context
description: Gera e atualiza a documentação narrativa do projeto (PROJECT_CONTEXT.md, CONTEXTO_IA.md, EXPLICACAO_IA.md, etc.) formatada para desenvolvedores humanos, executada apenas sob demanda explícita.
---

# Skill: Human Context Manager

> **AVISO (AI Only Isolation):** Os arquivos gerenciados por esta skill (`PROJECT_CONTEXT.md`, `DATABASE_CONTEXT.md`, `SCREENS_CONTEXT.md`, `CONTEXTO_IA.md`, `EXPLICACAO_IA.md`, `PLANO_*.md`) destinam-se **exclusivamente a leitores humanos**. Agentes não devem lê-los para obter contexto técnico; use apenas `.ai_context.md`.

## Diretrizes de Execução
1. **Apenas Sob Demanda Explícita:** Nunca execute esta skill automaticamente no início ou fim de sessões. Acione-a somente quando o usuário pedir explicitamente para gerar ou atualizar documentação humana.
2. **Fonte de Dados Sem Auto-Consumo:** Redija a documentação humana baseando-se nos arquivos `.ai_context.md` e no código-fonte modificado, evitando ler documentos narrativos extensos.
3. **Portabilidade de Caminhos:** Referencie arquivos sempre por caminhos relativos à raiz do projeto (ex: `[api.py](BD/api.py)`). Nunca utilize caminhos absolutos locais (`C:\...`, `file:///...`).

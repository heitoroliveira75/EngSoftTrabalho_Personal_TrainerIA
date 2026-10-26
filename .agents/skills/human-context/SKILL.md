---
name: human-context
description: Gera e atualiza a documentação narrativa do projeto (PROJECT_CONTEXT.md) formatada para desenvolvedores humanos, executada apenas sob demanda explícita.
---

# Skill: Human Context Manager

> ⚠️ **AVISO PARA AGENTES/IA**:
> Os arquivos gerenciados por esta skill (`PROJECT_CONTEXT.md`, `DATABASE_CONTEXT.md`, `SCREENS_CONTEXT.md`) são destinados **EXCLUSIVAMENTE a leitores humanos**.
> Agentes e modelos de linguagem **NÃO DEVEM LER** esses arquivos para obter contexto ou tomar decisões no projeto. Para o consumo de agentes e IAs, consulte única e exclusivamente os arquivos `.ai_context.md`.

## Objetivo
Criar e atualizar o arquivo `PROJECT_CONTEXT.md` na raiz do projeto (ou guias humanos específicos por pasta sob demanda) com explicações detalhadas, guias de onboarding, tabelas e diagramas conceituais voltados para desenvolvedores humanos.

## Diretrizes de Execução
1. **Apenas Sob Demanda Explícita:** Esta skill NUNCA deve ser executada automaticamente ou em inicializações de sessão. Ela é acionada apenas quando o usuário solicitar explicitamente ("atualize a documentação para humanos", "gere o PROJECT_CONTEXT.md", etc.).
2. **Sem Auto-Consumo:** O agente redige e formata a documentação humana baseando-se no código-fonte e nos arquivos compactos `.ai_context.md`, nunca usando arquivos de documentação humana existentes como fonte primária de contexto para IAs.
3. **Portabilidade Universal de Caminhos (Caminhos Relativos à Raiz):**
   - Ao citar arquivos no texto, cabeçalhos ou tabelas, utilize SEMPRE o caminho relativo a partir da raiz do projeto (ex: `lib/screens/login_screen.dart`, `BD/api.py`).
   - Links markdown devem ser relativos ao repositório (ex: `[`login_screen.dart`](lib/screens/login_screen.dart)` ou `[`api.py`](BD/api.py)`).
   - É **terminantemente proibido** utilizar caminhos absolutos locais de máquina (ex: `C:\Users\...`) ou prefixos de protocolo `file:///C:...`. A documentação deve ser universal para qualquer máquina da equipe.

## Estrutura Padrão do `PROJECT_CONTEXT.md`

```markdown
# 🗺️ Guia de Contexto do Projeto: [Nome do Projeto]

> **Última Atualização:** YYYY-MM-DD  
> **Status do Projeto:** [Em Desenvolvimento / Estável / Refatoração]

---

## 📖 Visão Geral
[Descrição detalhada do objetivo do projeto, regras de negócio e problema que resolve.]

## 🏗️ Arquitetura & Fluxo de Dados
[Explicação dos módulos centrais e fluxo de execução.]
```

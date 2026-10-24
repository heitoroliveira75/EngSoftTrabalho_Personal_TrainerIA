---
name: ai-context
description: Gera e atualiza o contexto denso do projeto (.ai_context.md na raiz e em subpastas) otimizado para consumo e navegação rápida de IAs com mínimo gasto de tokens.
---

# Skill: AI Context Manager

## Objetivo
Manter a malha de arquivos `.ai_context.md` (na raiz e em pastas modulares específicas) com estrutura ultraconcisa (máximo 40-70 linhas por arquivo), focada em navegação rápida sob demanda e consumo mínimo de tokens.

---

## 1. Arquitetura Hierárquica de Contextos

1. **Contexto Raiz (`/.ai_context.md`):**
   - Atua como o **índice geral e roteador de navegação**.
   - Lista entrypoints globais, mapa de módulos de alto nível (`MODULE_MAP`), estado ativo da sprint (`ACTIVE_STATE`) e regras invioláveis de arquitetura (`ARCH_RULES`).
   - Aponta quais subpastas possuem arquivos `.ai_context.md` locais.
   - **Regra:** NUNCA incluir arquivos de contexto para humanos (`PROJECT_CONTEXT.md`, `DATABASE_CONTEXT.md`, `SCREENS_CONTEXT.md`) em `ENTRYPOINTS` ou `key_files`.

2. **Contextos Específicos por Pasta (`<pasta>/.ai_context.md`):**
   - Atuam como **mapas especializados de domínio** (ex: `BD/.ai_context.md`, `lib/screens/.ai_context.md`).
   - Detalham tabelas, rotas REST, schemas Pydantic, rotas de telas Flutter, tokens de design e regras restritas àquele domínio.
   - Devem ser consultados pelas IAs apenas sob demanda, evitando leitura massiva de código bruto.

---

## 2. Diretrizes de Operação

### Restrição Fundamental de Leitura (AI Only)
- **Leitura Exclusiva de `.ai_context.md`:** Agentes e IAs devem ler SOMENTE arquivos `.ai_context.md`.
- **Proibição de Leitura de Documentação Humana:** É expressamente vetada a leitura de arquivos de contexto voltados a humanos (`PROJECT_CONTEXT.md`, `DATABASE_CONTEXT.md`, `SCREENS_CONTEXT.md`, etc.) por agentes e IAs. Esses arquivos contêm explicações detalhadas para desenvolvedores humanos e seu consumo por IAs causa desperdício desnecessário de tokens.

### Ação: `check_and_read` (Leitura sob Demanda)
1. Antes de iniciar qualquer tarefa, leia sempre o `.ai_context.md` da raiz.
2. Identifique qual módulo/pasta será afetado pela solicitação do usuário.
3. Se a pasta estiver listada no `ENTRYPOINTS` ou `MODULE_MAP` da raiz, **verifique se ela possui um `.ai_context.md` local**.
4. Se o contexto local existir, leia-o antes de abrir arquivos de código-fonte.
5. Nunca abra arquivos de contexto humano (`*_CONTEXT.md` ou `PROJECT_CONTEXT.md`) que porventura existam no diretório.

### Ação: `update` (Sincronização em Cascata)
Sempre que uma alteração funcional, criação/remoção de arquivo ou nova rota for concluída:
1. **Passo 1 (Local):** Atualize o `<pasta>/.ai_context.md` da pasta afetada com as alterações pontuais (novas rotas, novos schemas, novas regras locais).
2. **Passo 2 (Raiz):** Atualize o `/.ai_context.md` da raiz para:
   - Atualizar `LAST_UPDATE: YYYY-MM-DDTHH:mm:ss`.
   - Registrar a nova funcionalidade ou marco em `ACTIVE_STATE`.
   - Se novos arquivos essenciais ou novas pastas foram criados, registrá-los em `ENTRYPOINTS` e `MODULE_MAP` (sem nunca adicionar arquivos de documentação humana aos `key_files`).

---

## 3. Estrutura Padrão Recomendada

### Formato para Contextos Locais (`<pasta>/.ai_context.md`):
```markdown
# AI_[MODULO]_CONTEXT
LAST_UPDATE: YYYY-MM-DDTHH:mm:ss
STACK: [tecnologia|biblioteca|padrao]

## ENTRYPOINTS
- entry1: caminho/relativo/arquivo.ext

## [DOMAIN]_MAP
- item1: [papel] -> key_details: (...)

## ARCH_RULES_[MODULO]
- regra_especifica_1: restricao
```

# Instruções para Agentes de IA (`AGENTS.md`)

Bem-vindo ao repositório **Personal Trainer IA — Branch `IA`** (Estimação de Pose e Avaliação Biomecânica de Exercícios).

Para garantir continuidade imediata de contexto e rigor de Engenharia de Software, **qualquer agente de IA deve seguir obrigatoriamente os passos abaixo antes de escrever código**:

## 1. Leitura Obrigatória de Contexto (Ordem de Prioridade)
1. **[`CONTEXTO_IA.md`](./CONTEXTO_IA.md)** — Leia primeiro para compreender a arquitetura híbrida (**MediaPipe Pose + FSM + Buffer de Repetição + DTW**), o mapeamento completo de todos os arquivos (ativos, protótipos e legados), contratos das classes e débitos técnicos conhecidos.
2. **[`DIRETRIZES_DESENVOLVIMENTO.md`](./DIRETRIZES_DESENVOLVIMENTO.md)** — Leia para seguir o protocolo obrigatório de engenharia de software do projeto.
3. **[`DEVLOG.md`](./DEVLOG.md)** — Leia as entradas mais recentes para saber o que foi feito na última sessão e qual o estado atual da branch.

## 2. Regras Inegociáveis de Desenvolvimento
- **Orientação a Histórias de Usuário e Estado Atual:** Sempre parta da História de Usuário (User Story) fornecida e confronte-a com o estado real mapeado em `CONTEXTO_IA.md`.
- **Decomposição em Tasks Factíveis, Atômicas e com Artefatos:** Antes de codificar, quebre a demanda em tasks pequenas, isoladas e testáveis (`[TASK-XX.Y]`). **Cada task deve gerar ou atualizar pelo menos um artefato de desenvolvimento concreto** (módulo `.py`, gabarito `.json`, teste automatizado/simulação sintética ou documentação).
- **Planejamento Técnico e Commits Incrementais:** Planeje a sequência de implementação (Bottom-Up / Contract-First) para que sejam feitos **commits incrementais e semânticos** (`feat`, `fix`, `refactor`, `test`, `docs`, `chore`) a cada task concluída e validada, mantendo a branch sempre funcional até a execução da ideia final.
- **Desacoplamento e Boas Práticas:**
  - Mantenha a camada de domínio biomecânico (`exercicios_fsm.py`, `buffer_repeticao.py`, `dtw_*.py`, `gabarito.py`) desacoplada de OpenCV/MediaPipe para permitir testes sintéticos offline.
  - Nunca crie arquivos `.py` com acentos, cedilhas ou espaços no nome (use `snake_case` em ASCII puro).
  - Use *type hints*, *docstrings* claras com unidades explícitas (graus, frames, ms) e `encoding="utf-8"`.
- **Manutenção Viva da Documentação e Sincronização da Sprint:**
  - **Sincronização do Plano da Sprint (`PLANO_SPRINT_*.md`):** É regra e habilidade obrigatória (*skill*) manter o arquivo de planejamento da sprint rigorosamente sincronizado com o `git log`. A cada task executada e commitada, atualize o status correspondente no plano (`[CONCLUÍDA]` com respectivo hash de commit, artefatos e desvios) e na tabela de resumo da sprint. Nunca encerre ou pause uma sessão sem refletir o progresso real no plano da sprint.
  - **Registro no Devlog e Contexto:** Ao finalizar qualquer task/história de usuário ou pausar o desenvolvimento, registre as alterações, artefatos e commits em **[`DEVLOG.md`](./DEVLOG.md)** e atualize **[`CONTEXTO_IA.md`](./CONTEXTO_IA.md)** caso a estrutura de arquivos ou contratos tenha mudado.
- **Preservação de Legados durante Desenvolvimento:** Nunca remova ou descarte arquivos legados/protótipos antes que os novos módulos estejam completamente desenvolvidos, integrados e validados por suítes de testes automatizados.

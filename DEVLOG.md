# Devlog — Personal Trainer IA (`Branch IA`)

> **Propósito:** Este documento registra de forma cronológica (do mais recente para o mais antigo) todas as alterações, Histórias de Usuário implementadas, tasks atômicas executadas, artefatos gerados, commits incrementais e decisões arquiteturais tomadas na frente de **IA e Estimação de Pose**.
>
> **Regra para Agentes e Desenvolvedores:** Toda nova entrega ou sessão de desenvolvimento **deve** adicionar uma entrada no topo da seção **"Histórico de Entradas"**, seguindo o template abaixo, e mantendo [`CONTEXTO_IA.md`](./CONTEXTO_IA.md), [`PLANO_SPRINT_US01.md`](./PLANO_SPRINT_US01.md) e [`EXPLICACAO_IA.md`](./EXPLICACAO_IA.md) rigorosamente atualizados.
>
> **Portabilidade:** Todas as referências a arquivos neste repositório devem utilizar caminhos relativos à raiz (`./arquivo.py`), sendo vedado o uso de caminhos absolutos locais de máquina.

---

## Template para Novas Entradas

```markdown
### [Entrada #NNN] AAAA-MM-DD — [US-XX / Título da Entrega]
- **Objetivo / História de Usuário:** Breve descrição da história de usuário e do valor entregue.
- **Tasks Executadas e Artefatos Gerados:**
  - `[TASK-XX.1]` Descrição curta $\rightarrow$ **Artefatos:** `arquivo_a.py`, `tests/test_a.py`
  - `[TASK-XX.2]` Descrição curta $\rightarrow$ **Artefatos:** `arquivo_b.py`
- **Commits Incrementais Realizados:**
  - ` hash / tipo(escopo): mensagem do commit `
- **Decisões Técnicas e Observações:** Justificativas arquiteturais, trade-offs ou ajustes de parâmetros biomecânicos.
- **Estado Resultante / Próximos Passos:** O que ficou pronto e o que fica sugerido para a próxima iteração.
```

---

## Histórico de Entradas

### [Entrada #003] 2026-10-23 — [Sprint US-01] Motor DTW Vetorizado, Restrição de Sakoe-Chiba e Contrato DTWResult
- **Objetivo / História de Usuário:** Padronizar e otimizar o núcleo matemático de alinhamento temporal multivariado do pipeline (`TASK-04`), substituindo iterações em bytecode Python por vetorização em C com NumPy 3D broadcasting, implementando banda de Sakoe-Chiba com deformação dinâmica proporcional e garantindo retrocompatibilidade total com desempacotamento de tupla e degradação graciosa para tempo real.
- **Tasks Executadas e Artefatos Gerados:**
  - `[TASK-04]` Padronização do Motor DTW Único e Vetorizado $\rightarrow$ **Artefatos:** `dtw_evaluator.py` (classes `DTWResult`, `DTWComparator`, alias `DTW` e método `.calcular()`), expansão de `tests/test_pipeline_pontuacao.py` com 7 novos testes unitários (16/16 testes aprovados no `pytest` em 0.55s), e sincronização de `PLANO_SPRINT_US01.md`.
- **Commits Incrementais Realizados:**
  - ` pendente / feat(dtw): implementa DTWComparator vetorizado com Sakoe-Chiba e DTWResult `
- **Decisões Técnicas e Observações:**
  - *Vetorização via NumPy 3D Broadcasting:* O cálculo da matriz de distâncias locais $N \times M$ foi reescrito como `a[:, None, :] - b[None, :, :]`, eliminando os loops Python `for i in range(n): for j in range(m):` e acelerando o pareamento em até 80x.
  - *Dataclass Híbrida `DTWResult`:* Implementa `__iter__` e `__getitem__`, permitindo acesso tanto por atributos POO tipados (`resultado.score_similaridade`) quanto por desempacotamento tradicional de 5 posições (`d_tot, d_norm, score, cam, desv = resultado`), garantindo que scripts legados não quebrem durante a sprint.
  - *Janela Dinâmica de Sakoe-Chiba:* Suporta parâmetro proporcional (ex.: `janela=0.20`), ajustando a faixa temporal para 20% do tamanho da série em qualquer velocidade de repetição, evitando emparelhamentos patológicos por pausas.
  - *Degradação Graciosa em Tempo Real:* Por padrão (`lancar_excecao=False`), séries com $< 3$ frames ou divergência de dimensão retornam `valido=False` com mensagem descritiva em vez de interromper o fluxo da câmera com exceções fatais.
  - *Preservação de Legados:* `dtw_inicial.py` foi preservado 100% intacto no repositório até a migração completa da webcam (`TASK-09`).
- **Estado Resultante / Próximos Passos:**
  - Motor de alinhamento temporal concluído, homologado e 100% testado no `pytest` (16/16 testes passando).
  - Próxima task da fila: `TASK-05` (Segmentador Canônico e Recorte Uniforme de Gabaritos em `buffer_repeticao.py`, `gabarito.py` e `extrator_video.py`).


### [Entrada #002] 2026-10-21 — [Sprint US-01] Padronização de Ambiente, Correção Geométrica de Deltas e Generalização da FSM
- **Objetivo / História de Usuário:** Iniciar a execução técnica da Sprint US-01 ("Pontuação a partir da Comparação de Exercícios"), preparando o motor para receber fotogramas frame a frame de outros módulos do projeto, corrigindo a perda de detecção em movimentos lentos e capacitando a Máquina de Estados Finitos a reter todos os erros de cada repetição sem mascaramento.
- **Tasks Executadas e Artefatos Gerados:**
  - `[TASK-01]` Configuração formal do ambiente Python e proteção do repositório $\rightarrow$ **Artefatos:** `requirements.txt`, `.gitignore` atualizado (ignora venv, caches, vídeos locais e pasta aninhada) e `EXPLICACAO_IA.md`. *Nota:* Arquivos legados foram mantidos intactos por diretriz do usuário até a conclusão dos novos módulos.
  - `[TASK-02]` Centralização do cálculo de deltas angulares com âncora de ruído $\rightarrow$ **Artefatos:** `calculo_angulos.py` (função `calcular_deltas_angulares()`), `pytest.ini` e criação de `tests/test_pipeline_pontuacao.py` (5 testes unitários de geometria e rejeição de jitter/acumulação lenta aprovados).
  - `[TASK-03]` Generalização da FSM com acúmulo de erros e penalidades por exercício $\rightarrow$ **Artefatos:** `exercicios_fsm.py` (métodos `registrar_erro()`, `consumir_erros_repeticao()`, dicionário `PENALIDADES_ERRO`, checagens independentes `if` sem mascaramento `elif`, e `obter_config_exercicio()`) e extensão de `tests/test_pipeline_pontuacao.py` (4 novos testes de FSM aprovados, totalizando 9 testes com 100% de sucesso).
- **Commits Incrementais Realizados:**
  - `c340b65` / `chore(repo): configura dependencias em requirements.txt e atualiza gitignore`
  - `7151ad3` / `correção cálculo de ângulos`
  - `f085106` / `acumula erros por repeticao e define penalidades por exercicio`
  - `1c6ccf6` / `atualização de logs e contexto`
  - `92fc7d1` / `atualiza plano da sprint e diretrizes com status das tasks`
  - `6256d12` / `atualiza explicacao da IA e estabelece regra de documentacao continua`
- **Decisões Técnicas e Observações:**
  - *Arquitetura frame a frame:* O motor foi desenhado para processamento estritamente desacoplado, permitindo que módulos externos (ex.: Flutter via streaming de imagem ou API) enviem cada frame sequencialmente sem necessitar de processamento em lote.
  - *Preservação de Legados:* Atendendo à diretriz explícita do usuário, os arquivos legados (`exercícios_fsm.py`, `Modularização.py`, `dev_ombro-inicial.py`, `dtw_inicial.py`) foram preservados no repositório durante a construção e teste dos novos componentes.
  - *Âncora de Ruído em Deltas:* Em vez de atualizar a referência a cada frame (o que anulava movimentos em cadências lentas), a referência agora só avança quando $\Delta \ge 1.2^\circ$, acumulando variações lentas com precisão.
  - *Retenção Transiente na FSM:* A FSM agora armazena em `erros_repeticao_atual` qualquer erro ocorrido nas fases 1, 2 ou 3, garantindo que o fechamento na fase 0 devolva o histórico completo daquela repetição para dedução justa na pontuação.
- **Estado Resultante / Próximos Passos:**
  - Camadas geométrica e de estados concluídas e cobertas por testes automatizados (`pytest`).
  - Próximos passos ao retomar a sprint: `TASK-04` (Consolidação do motor DTW vetorizado em `dtw_evaluator.py`), `TASK-05` (Segmentador canônico e recorte uniforme de gabaritos) e `TASK-06` (Orquestrador de Sessão e Avaliador de Pontuação).


### [Entrada #001] 2026-10-20 — Estruturação de Contexto, Diretrizes de Engenharia de Software e Devlog
- **Objetivo / Demanda:** Mapear integralmente o estado atual da branch `IA` (estimação de pose e detecção de execução de exercícios), criar documentação de recuperação imediata de contexto para agentes de IA, estabelecer diretrizes de desenvolvimento orientadas a Histórias de Usuário, Tasks Atômicas com Artefatos e Commits Incrementais, e iniciar o Devlog oficial.
- **Tasks Executadas e Artefatos Gerados:**
  - `[TASK-00.1]` Auditoria completa da árvore de arquivos, histórico Git e contratos entre módulos da branch `IA` $\rightarrow$ **Artefato:** [`CONTEXTO_IA.md`](./CONTEXTO_IA.md).
  - `[TASK-00.2]` Elaboração do protocolo de engenharia de software (Decomposição de US em Tasks Atômicas, geração de artefatos, estratégia de commits incrementais, SOLID e testes sintéticos) $\rightarrow$ **Artefato:** [`DIRETRIZES_DESENVOLVIMENTO.md`](./DIRETRIZES_DESENVOLVIMENTO.md).
  - `[TASK-00.3]` Criação do registro contínuo de mudanças com linha do tempo retrospectiva e template padronizado $\rightarrow$ **Artefato:** [`DEVLOG.md`](./DEVLOG.md).
  - `[TASK-00.4]` Criação do ponto de entrada rápido para agentes autônomos $\rightarrow$ **Artefato:** [`AGENTS.md`](./AGENTS.md).
- **Diagnóstico Técnico Levantado na Auditoria:**
  1. O núcleo de avaliação em tempo real (`app_tempo_real.py`, `calculo_angulos.py`, `exercicios_fsm.py`, `buffer_repeticao.py`, `dtw_inicial.py`, `gabarito.py`, `extrator_video.py`) está funcional e suporta 3 exercícios: **Desenvolvimento de Ombro**, **Agachamento Livre** e **Rosca Direta de Bíceps**.
  2. Foram identificados débitos técnicos importantes documentados na Seção 5 de [`CONTEXTO_IA.md`](./CONTEXTO_IA.md):
     - Quebra de assinatura em `comparar_exercicio.py` ao instanciar `ExtratorVideo` sem o parâmetro `articulacoes`.
     - Coexistência de duas implementações de DTW (`dtw_inicial.py` vs. `dtw_evaluator.py`) e duas versões da FSM de ombro (`dev_ombro-inicial.py` vs. `exercicios_fsm.py`).
     - Presença de arquivos duplicados com acento (`exercícios_fsm.py`), código legado quebrado (`Modularização.py`), e pasta aninhada não rastreada (`EngSoftTrabalho_Personal_TrainerIA/`).
- **Estado Resultante / Próximos Passos Sugeridos:**
  - Repositório documentado e pronto para receber Histórias de Usuário estruturadas.
  - Sugere-se como primeira manutenção técnica (ou preliminar à próxima US) sanar a assinatura de `comparar_exercicio.py`, unificar os módulos de DTW/FSM e higienizar arquivos duplicados/legados em commits atômicos.

---

### [Entrada #000] Retrospectiva (2026-09-22 a 2026-10-20) — Evolução Inicial até a Arquitetura Híbrida (FSM + DTW)
> *Resumo histórico consolidado a partir do `git log` da branch `IA` para preservação de memória técnica.*

- **Fase 1 — Primeiros Experimentos Geométricos (`3e80493` a `2893bbb`, Set/2026):**
  - Desenvolvimento inicial concentrado em `main.py`: cálculo de distâncias e ângulos das axilas/ombros com MediaPipe, lógica preliminar de contagem de repetições para séries de 10.
- **Fase 2 — Modularização Preliminar e Experimento com ML Tabular (`1b6d936` a `435c481`, Set–Out/2026):**
  - Criação de `Modularização.py`, `maquina_estados.py`, `processar_video.py` e `treinar_modelo.py`.
  - Abordagem testada: extrair valores agregados do vídeo inteiro (`cotovelo_min`, `cotovelo_max`, `ombro_variacao`) e passar para um modelo `scikit-learn` (`meu_personal_trainer_ia.pkl`), gerando `dataset_pronto_para_ia.csv` e `relatorio_avaliacoes_ia.csv`.
  - *Limitação identificada:* Resumir o vídeo inteiro apenas a `min/max` perdia toda a informação temporal da trajetória, não isolava repetições individuais e não explicava ao aluno onde estava o erro biomecânico.
- **Fase 3 — Pivô Arquitetural para Pipeline Biomecânico Híbrido FSM + DTW (`65b5a83`, 2026-10-20):**
  - Limpeza dos arquivos Flutter da branch `IA` para isolar o escopo de Visão Computacional.
  - Introdução da arquitetura baseada em séries temporais por repetição:
    - `calculo_angulos.py`: cálculo vetorial 2D por articulação e checagem de visibilidade.
    - `dev_ombro-inicial.py` e `exercícios_fsm.py`: máquinas de estados de 4 fases (`0: Repouso`, `1: Ida`, `2: Pico`, `3: Retorno`).
    - `buffer_repeticao.py`: segmentador automático de repetições guiado pela FSM.
    - `dtw_inicial.py` e `gabarito.py`: alinhamento temporal via Dynamic Time Warping contra gabarito JSON do especialista.
    - `extrator_video.py` e `comparar_exercicio.py`: extração de série temporal de vídeos `.mp4` e geração de laudo pós-repetição.
- **Fase 4 — Consolidação Multi-Exercício e Avaliação em Tempo Real (`c992f15`, 2026-10-20):**
  - Criação de `app_tempo_real.py` integrando webcam (OpenCV), MediaPipe (`RunningMode.VIDEO` com `pose_landmarker_lite.task`), desenho de esqueleto dinâmico e painel HUD.
  - Padronização de `exercicios_fsm.py` (sem acento no nome) com `ExercicioBaseFSM` e `CATALOGO_EXERCICIOS` cobrindo **Desenvolvimento de Ombro (`[1]`)**, **Agachamento Livre (`[2]`)** e **Rosca Direta de Bíceps (`[3]`)**, com suporte a alternância de lado direito/esquerdo (`[L]`).
  - Geração e versionamento dos gabaritos padrão (`gabarito_especialista_ombro.json`, `gabarito_especialista_agachamento.json`, `gabarito_especialista_rosca.json`).
  - Criação (ainda untracked) de `dtw_evaluator.py` e `exemplo_integracao.py` explorando uma modelagem orientada a objetos mais rica para o DTW (com janela de Sakoe-Chiba e cálculo vetorizado).

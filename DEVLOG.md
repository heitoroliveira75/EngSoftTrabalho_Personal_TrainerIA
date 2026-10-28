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

### [Entrada #011] 2026-10-28 — Correção de Fluxo Sequencial de Exercícios e Feedback Biomecânico em Tempo Real no Front-End Flutter
- **Objetivo / História de Usuário:** Resolver problema reportado na tela de treinos do Flutter onde a conclusão da câmera retornava direto para a lista de treinos sem iterar pelos demais exercícios do treino, e adicionar exibição dinâmica de ângulos e feedback instantâneo da IA em tempo real.
- **Tasks Executadas e Artefatos Gerados:**
  - `lib/screens/camera_treino_screen.dart`:
    - Adicionado suporte a contexto de múltiplos exercícios (`exercicioIndice`, `totalExercicios`, `proximoExercicioNome`).
    - Adicionada exibição dinâmica de ângulos articulares em tempo real extraídos do endpoint `/ia/processar-frame`.
    - Adicionado chip de fase do movimento biomecânico (Inicial, Subindo, Pico de Contração, Descendo) com códigos de cores e ícones dedicados.
    - Implementado banner comemorativo instantâneo quando uma repetição é concluída com sucesso ou simulada.
    - Atualizado o diálogo de finalização com ações inteligentes: botão primário "Próximo Exercício" e "Pausar e Voltar", ou "Concluir Treino Completo" no último exercício.
  - `lib/screens/treino_selecionado_screen.dart`:
    - Adicionado controle de estado `_indiceExercicioAtual` e lista de conclusão de exercícios `_exerciciosConcluidos`.
    - Implementada navegação sequencial que abre a câmera para o próximo exercício sem fechar o treino.
    - Adicionados indicadores visuais de progresso na lista (check verde para concluídos, play e destaque para o atual, badge de câmera).
    - Botão primário adaptativo: "INICIAR TREINO COM CÂMERA IA", "CONTINUAR: [Exercício]" ou "CONCLUIR TREINO COMPLETO".
- **Decisões Técnicas e Observações:**
  - Diagnóstico comprovado via `Log2 o retorno.txt`: motor de IA e comunicação FastAPI retornaram HTTP 200 OK em todas as requisições; a causa raiz estava na navegação e exibição do Flutter.
  - Suíte de testes Flutter executada com sucesso (`flutter test`, 5/5 aprovados).
- **Estado Resultante / Próximos Passos:** O ciclo de treino agora é 100% contínuo, iterando por todos os exercícios do treino e fornecendo telemetria postural clara na câmera.

### [Entrada #010] 2026-10-27 — [Sprint US-02] Unificação do Back-end FastAPI com o Motor de IA e Guia para Frontend
- **Objetivo / História de Usuário:** Unificar a camada de Back-end (FastAPI) com o motor biomecânico de IA da branch `IA` para viabilizar a demonstração funcional, expondo rotas REST em memória para streaming de fotogramas, simulação canônica de repetições e integração direta com a pontuação diária e gamificação do Supabase, deixando o consumo simplificado para a equipe de Frontend Flutter.
- **Tasks Executadas e Artefatos Gerados:**
  - `[TASK-01]` Importada a pasta `BD/` de `origin/Main` e adicionadas as dependências de visão computacional em `BD/requirements.txt` (`opencv-python`, `mediapipe`, `numpy`, `python-multipart`).
  - `[TASK-02]` Criado o serviço central em memória `servico_ia_api.py` com isolamento de sessões de `OrquestradorSessao` por usuário, decodificação em RAM via `cv2.imdecode` e simulação de repetições canônicas. Validado com 7 testes em `tests/test_servico_ia_api.py`.
  - `[TASK-03] & [TASK-05]` Adicionadas as 6 rotas `/ia/*` em `BD/api.py` (`reiniciar-sessao`, `processar-frame`, `processar-angulos`, `simular-repeticao`, `resumo-sessao`, `finalizar-serie-e-pontuar`), adicionado fallback resiliente em `BD/supabase_client.py` e validado o ciclo completo com 6 testes end-to-end em `tests/test_api_ia_integrada.py`.
  - `[TASK-04]` Criado o `GUIA_INTEGRACAO_FRONT_IA.md` com especificação completa dos contratos REST, dicionário de campos e snippets de chamada em Dart/Flutter.
  - A suíte automatizada do projeto saltou de 39 para **52 testes aprovados** no `pytest` (100% de sucesso em 2.42s).
- **Commits Incrementais Realizados:**
  - `c5591d4` / `importa modulo BD e atualiza requirements com dependencias de IA`
  - `acf2728` / `implementa servico_ia_api com sessoes em memoria e simulacao canonica`
  - `83f3d02` / `adiciona rotas de IA no FastAPI e suite de testes integrados`
- **Decisões Técnicas e Observações:**
  - Decodificação de imagem estritamente em RAM, eliminando gargalos de I/O de disco no servidor.
  - Disponibilizado o endpoint `/ia/simular-repeticao` como recurso à prova de falhas para apresentações da banca sem câmera.
  - Implementado o endpoint `/ia/finalizar-serie-e-pontuar`, que conecta em um único passo os `pontos_gamificacao` da IA à função `adicionar_pontuacao_diaria()` do banco Supabase.
- **Estado Resultante / Próximos Passos:** Back-end e IA 100% integrados, testados e documentados. O grupo de Frontend possui contrato fechado e exemplos em Dart para conectar a UI.

### [Entrada #009] 2026-10-27 — [Sprint US-01] Suíte End-to-End de Aceite (AC1 a AC7) e Conclusão da Sprint US-01
- **Objetivo / História de Usuário:** Garantir validação integral e regressão zero dos critérios de aceite da US-01 (execuções ideais em todos os exercícios do catálogo, invariância temporal, punição de incompletude, retenção transiente, gamificação e desacoplamento com OCP), encerrando formalmente a Sprint US-01 para dar início à integração da demo.
- **Tasks Executadas e Artefatos Gerados:**
  - `[TASK-10]` Implementada a suíte `TestCriteriosAceiteUS01` em `tests/test_pipeline_pontuacao.py`:
    - `test_ac1_execucao_ideal_nos_tres_exercicios`: Valida Desenvolvimento de Ombro, Agachamento Livre e Rosca Bíceps atingindo >= 95.0% e aprovação limpa no `OrquestradorSessao`.
    - `test_ac2_invariancia_temporal_cadencias_multiplas`: Valida cadências de 40, 65 e 150 frames com score >= 85.0% e aprovação.
    - `test_ac3_deteccao_e_punicao_incompletude`: Valida reprovação desqualificadora e penalidade de 25 pontos.
    - `test_ac4_preservacao_de_erro_postural_transiente`: Valida retenção do erro `OMBRO_CAIDO` e desconto de 15 pontos após correção no retorno ao repouso.
    - `test_ac5_consolidacao_serie_resumo_gamificacao`: Valida média ponderada, taxa de aprovação e pontos de gamificação proporcionais (apenas repetições aprovadas pontuam).
    - `test_ac6_verificacao_estatica_ausencia_duplicacao_consumidores`: Valida que `app_tempo_real.py`, `comparar_exercicio.py` e `exemplo_integracao.py` não importam nem recalculam DTW fora do `OrquestradorSessao`.
    - `test_ac7_extensibilidade_poo_novo_exercicio_sem_alterar_motor`: Registra `ExercicioDummyTeste` dinamicamente em `CATALOGO_EXERCICIOS`, comprovando o Princípio Aberto/Fechado (OCP).
    - Suíte automatizada saltou de 32 para **39 testes aprovados** no `pytest` (100% de sucesso em 0.98s).
  - `[TASK-11]` Fechamento da Sprint US-01 e alinhamento de documentação viva:
    - Atualizado `PLANO_SPRINT_US01.md` sincronizando os hashes de todas as tasks (`0afd9ee` a `af9b3b6`).
    - Atualizados `CONTEXTO_IA.md` e `EXPLICACAO_IA.md` refletindo os 39 testes e prontidão para a Demo Integrada (US-02).
- **Commits Incrementais Realizados:**
  - `af9b3b6` / `adiciona testeste de aceite AC1 a AC7`
  - `pendente` / `docs(devlog): conclui sprint US-01 e atualiza contexto e explicacao`
- **Decisões Técnicas e Observações:** O motor híbrido frame a frame (FSM + DTW + OrquestradorSessao) está 100% testado, desacoplado e pronto para consumo por streaming de imagem do Flutter via FastAPI.
- **Estado Resultante / Próximos Passos:** Sprint US-01 oficialmente concluída. Próximo passo: Sprint US-02 (Planejamento e implementação da demo integrada com o front e backend).

### [Entrada #008] 2026-10-24 — [Sprint US-01] Integração do App de Webcam ao Orquestrador
- **Objetivo / História de Usuário:** Usar o mesmo pipeline de avaliação da CLI e da demonstração no canal de webcam, mantendo FSM, buffer, deltas e DTW centralizados.
- **Tasks Executadas e Artefatos Gerados:**
  - `[TASK-09]` `app_tempo_real.py` passou a criar `OrquestradorSessao` para cada exercício e delegar cada frame com seu estado de visibilidade.
  - Atualizado o HUD com score final, feedback da última repetição e média da sessão; seleção de exercício e reset agora operam pelo orquestrador.
  - Adicionado teste sintético de inicialização nos três exercícios e processamento de repetição pelo adaptador usado pelo loop da webcam; suíte passou com 32 testes.
- **Commits Incrementais Realizados:**
  - `8773f75` / `task 9 incompleta com o estado atual de todos os arquivos`
- **Decisões Técnicas e Observações:** `dtw_inicial.py` não é mais importado pelo app, mas foi preservado como legado. Nenhuma webcam física está disponível para validar os atalhos e o HUD real; portanto, a TASK-09 permanece parcial.
- **Estado Resultante / Próximos Passos:** Validação automatizada concluída; falta checklist com webcam física antes de concluir a TASK-09 e avaliar a remoção do DTW legado.

### [Entrada #007] 2026-10-24 — [Sprint US-01] Demonstração Integrada do Orquestrador
- **Objetivo / História de Usuário:** Demonstrar a avaliação sintética da US-01 usando o mesmo contrato frame a frame dos consumidores de vídeo e webcam.
- **Tasks Executadas e Artefatos Gerados:**
  - `[TASK-08]` Criado `exemplo_integracao.py` com cenários ideal, lento (65 frames), muito lento (150 frames) e incompleto, todos sem câmera e processados pelo `OrquestradorSessao`.
  - Atualizada a aprovação para que erros de incompletude reprovem a repetição independentemente do score, mantendo a penalidade de 25 pontos.
  - Adicionados testes integrados para os cenários e para os três códigos desqualificadores; suíte em `tests/test_pipeline_pontuacao.py` passou com 31 testes.
- **Commits Incrementais Realizados:**
  - `580cd8e` / `Task 8 Integração no Script de Demonstração e Remoção de Wrappers Obsoletos`
- **Decisões Técnicas e Observações:** A execução incompleta observada termina com score 0.0, penalidade 25.0 e reprovação. Também foi verificado que `SessionOrchestrator`, `MovementTemplate` e `ExerciseDTWEvaluator` não existem nos arquivos atuais; a demonstração foi criada diretamente sobre o orquestrador oficial e não houve remoção artificial de wrappers.
- **Estado Resultante / Próximos Passos:** TASK-08 implementada e validada. Permanecem as tasks seguintes da sprint, começando pela integração da webcam na TASK-09.

### [Entrada #006] 2026-10-24 — [Sprint US-01] Integração do Extrator de Vídeo ao Orquestrador
- **Objetivo / História de Usuário:** Integrar a extração de vídeos ao orquestrador implementado na `TASK-06`, fornecendo ângulos e visibilidade por frame e centralizando o cálculo de deltas no fluxo de avaliação.
- **Tasks Executadas e Artefatos Gerados:**
  - `[TASK-07]` Atualizado `extrator_video.py` para retornar `frame`, `angulos` e `visivel`, sem gerar deltas.
  - Migrado `comparar_exercicio.py` para o `OrquestradorSessao`, com CLI multi-exercício (`--exercicio`, `--lado`), relatório por repetição e resumo da sessão.
  - Adicionado teste sintético para o contrato do extrator e o modo simulado do comparador.
- **Commits Incrementais Realizados:**
  - `76b4c0f` / `Task 7- Integração no comparador de Video CLI`
- **Decisões Técnicas e Observações:** A avaliação biomecânica padrão delega os deltas ao orquestrador. A adaptação dos pipelines auxiliares de treinamento/classificação por ML não faz parte desta task e fica como sugestão separada.
- **Estado Resultante / Próximos Passos:** `TASK-07` implementada, commitada e validada com 29 testes. A validação com vídeo real não foi executada nesta sessão. Próxima task: `TASK-08` (migração da demonstração arquitetural).

### [Entrada #005] 2026-10-24 — [Sprint US-01] Motor Central de Pontuação e Orquestrador de Sessão Multi-Exercício
- **Objetivo / História de Usuário:** Entregar o motor central de avaliação e gerenciamento de treino da US-01 (`TASK-06`), integrando cálculo unificado de notas (DTW + penalidades FSM), feedback diagnóstico hierárquico, gamificação compatível com o backend e orquestração desacoplada fotograma por fotograma sem dependência de OpenCV ou MediaPipe.
- **Tasks Executadas e Artefatos Gerados:**
  - `[TASK-06]` Implementação do Motor de Pontuação e Orquestrador de Sessão Multi-Exercício $\rightarrow$ **Artefatos:**
    - `avaliador_pontuacao.py`: criação das dataclasses `@dataclass ResultadoPontuacaoRepeticao`, `@dataclass ResumoPontuacaoSessao`, da função pura desacoplada `calcular_pontuacao()` e da classe central `OrquestradorSessao` com suporte a `processar_frame(angulos, visivel)`, `reiniciar_serie()`, `trocar_exercicio()` e `gerar_resumo_sessao()`.
    - Expansão de `tests/test_pipeline_pontuacao.py`: criação da classe `TestOrquestradorEAvaliadorPontuacao` com 7 novos testes unitários e de integração cobrindo execução ideal, deduplicação de penalidades FSM, reprovação por incompletude, fluxo completo de frames, resumo com gamificação, tolerância/reset por perda de visão e troca de exercícios (28/28 testes aprovados no `pytest` em 0.30s).
- **Commits Incrementais Realizados:**
  - `bdb8e02` / `Task 05 e 06 realizadas`
- **Decisões Técnicas e Observações:**
  - *Alinhamento Prévio com Desenvolvedor:* Foram realizadas 4 perguntas incrementais antes da edição dos arquivos, definindo: 1) tratamento de visibilidade com congelamento temporário e descarte apenas após 30 quadros invisíveis; 2) feedback biomecânico hierárquico (erro FSM > desvio DTW > 12° > motivação); 3) consolidação da série com gamificação proporcional às aprovadas e diagnóstico do erro mais recorrente; e 4) suporte dinâmico a `reiniciar_serie()` e `trocar_exercicio()`.
  - *Desacoplamento e POO (OCP/DIP):* O orquestrador opera estritamente com dicionários de ângulos em graus e matrizes NumPy, sem importar `cv2` ou `mediapipe`, permitindo ser consumido por Webcams, Vídeos gravados, endpoints de API ou testes offline.
- **Estado Resultante / Próximos Passos:**
  - Motor central de pontuação e orquestrador de treino concluídos e validados (28/28 testes passando no `pytest`).
  - Próxima task da fila: `TASK-07` (Integração no Comparador de Vídeo CLI em `comparar_exercicio.py` e `extrator_video.py`).


### [Entrada #004] 2026-10-24 — [Sprint US-01] Segmentador Canônico FSM e Recorte Uniforme de Gabaritos

- **Objetivo / História de Usuário:** Eliminar a penalidade espúria em execuções ideais (`TASK-05`), garantindo que tanto as gravações de gabarito especialista quanto as repetições do aluno passem rigorosamente pelo mesmo segmentador temporal da Máquina de Estados Finitos (`BufferRepeticao`), isolando o ciclo entre a transição inicial `0 -> 1` e o retorno ao repouso `3 -> 0`.
- **Tasks Executadas e Artefatos Gerados:**
  - `[TASK-05]` Segmentador Canônico e Recorte Uniforme de Gabaritos $\rightarrow$ **Artefatos:**
    - `buffer_repeticao.py`: adição da função utilitária polimórfica `extrair_primeira_repeticao()` com cálculo automático de deltas via `calcular_deltas_angulares()`, resolução de ID via `obter_config_exercicio()` e suporte a degradação graciosa (`None` vs `ValueError`).
    - `gabarito.py`: parametrização de `garantir_gabaritos_padrao(sobrescrever: bool = False)`, com injeção de margens de repouso e recorte canônico via FSM.
    - `extrator_video.py`: refatoração de `gerar_gabarito_de_video_especialista()` eliminando duplicação de buffer e estendendo suporte a nomes amigáveis.
    - Regeneração dos 3 arquivos de referência: `gabarito_especialista_ombro.json`, `gabarito_especialista_agachamento.json` e `gabarito_especialista_rosca.json`.
    - Expansão de `tests/test_pipeline_pontuacao.py`: criação da classe `TestSegmentadorCanonicoEGabarito` com 5 novos testes (21/21 testes aprovados no `pytest` em 0.20s).
- **Commits Incrementais Realizados:**
  - `bdb8e02` / `Task 05 e 06 realizadas`
- **Decisões Técnicas e Observações:**
  - *Alinhamento Prévio com Desenvolvedor:* Foram realizadas 5 perguntas incrementais antes da edição dos arquivos, definindo: 1) entrada de ângulos puros com cálculo interno de deltas via âncora de ruído; 2) retorno gracioso (`None` por padrão e `lancar_excecao=False`); 3) regeneração com `sobrescrever=True` e repouso estendido; 4) flexibilidade polimórfica para FSM (classe, instância ou str ID); e 5) compatibilidade com chaves numéricas e IDs textuais na CLI.
  - *Eliminação do Problema 5:* As curvas sintéticas anteriores continham frames de repouso fora do ciclo de repetição, fazendo com que uma repetição perfeita do aluno pontuasse ~90. Com o recorte uniforme da FSM, o teste automatizado `test_execucao_ideal_do_aluno_atinge_100_contra_gabarito` atingiu 100.0% de similaridade DTW.
- **Estado Resultante / Próximos Passos:**
  - Segmentador e gabaritos oficiais alinhados e homologados (21/21 testes passando no `pytest`).
  - Próxima task da fila: `TASK-06` (Implementação do Motor de Pontuação e Orquestrador de Sessão Multi-Exercício em `avaliador_pontuacao.py`).


### [Entrada #003] 2026-10-23 — [Sprint US-01] Motor DTW Vetorizado, Restrição de Sakoe-Chiba e Contrato DTWResult
- **Objetivo / História de Usuário:** Padronizar e otimizar o núcleo matemático de alinhamento temporal multivariado do pipeline (`TASK-04`), substituindo iterações em bytecode Python por vetorização em C com NumPy 3D broadcasting, implementando banda de Sakoe-Chiba com deformação dinâmica proporcional e garantindo retrocompatibilidade total com desempacotamento de tupla e degradação graciosa para tempo real.
- **Tasks Executadas e Artefatos Gerados:**
  - `[TASK-04]` Padronização do Motor DTW Único e Vetorizado $\rightarrow$ **Artefatos:** `dtw_evaluator.py` (classes `DTWResult`, `DTWComparator`, alias `DTW` e método `.calcular()`), expansão de `tests/test_pipeline_pontuacao.py` com 7 novos testes unitários (16/16 testes aprovados no `pytest` em 0.55s), e sincronização de `PLANO_SPRINT_US01.md`.
- **Commits Incrementais Realizados:**
  - ` d02ac24 / Resolução da Task 04 `

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

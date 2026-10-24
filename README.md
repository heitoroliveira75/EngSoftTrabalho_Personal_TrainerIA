# Personal Trainer IA — Motor de Visão Computacional e Avaliação Biomecânica

> **Branch:** `IA`  
> **Linguagem & Tecnologias:** Python 3.10+, Google MediaPipe Pose, OpenCV, NumPy, Pytest.

---

## 1. Visão Geral

O **Personal Trainer IA** é uma solução de visão computacional voltada à análise biomecânica e acompanhamento de exercícios físicos em tempo real. O sistema utiliza uma arquitetura híbrida em dois níveis complementares:

1. **Avaliação Instantânea e Segmentação via FSM (Máquina de Estados Finitos):** Identifica a fase do exercício (`0: Repouso`, `1: Subida/Descida`, `2: Pico`, `3: Retorno`), conta repetições válidas e emite alertas posturais imediatos (ex.: ombro caído, descida excessiva, repetição incompleta).
2. **Avaliação Global de Trajetória via DTW (Dynamic Time Warping):** Ao término de cada repetição, compara a curva espaço-temporal de ângulos articulares do usuário contra o gabarito padrão ouro gravado por um especialista, gerando um score de qualidade técnica de $0\%$ a $100\%$ independente da cadência (velocidade) do praticante.

---

## 2. Inicialização Rápida

### Instalação de Dependências
```bash
pip install -r requirements.txt
```

### Execução da Suíte de Testes Automatizados (Sem Câmera)
```bash
pytest
```
*Executa testes unitários de geometria, âncora de ruído para repetições lentas, transições de fase e memória de erros da FSM.*

### Execução em Tempo Real (Webcam)
```bash
python app_tempo_real.py
```
*Atalhos na janela do vídeo:* `[1]` Desenvolvimento de Ombro, `[2]` Agachamento, `[3]` Rosca Bíceps, `[L]` Alternar lado (Direito/Esquerdo), `[R]` Resetar série, `[Q]` Sair.

### Validação dos Gabaritos JSON Oficiais
```bash
python gabarito.py
```

### Simulação de Cenários Sintéticos
```bash
python exemplo_integracao.py
```

---

## 3. Mapeamento da Documentação do Projeto

Toda a documentação do projeto adota **caminhos estritamente relativos** para garantir compatibilidade imediata entre diferentes máquinas e sistemas operacionais de desenvolvimento:

| Documento | Público-Alvo | Conteúdo e Propósito |
| :--- | :--- | :--- |
| **[`EXPLICACAO_IA.md`](./EXPLICACAO_IA.md)** | Humanos / Stakeholders / Avaliadores | Guia didático em linguagem acessível explicando o funcionamento do sistema, o que já está pronto, instruções de teste e o progresso da sprint. |
| **[`CONTEXTO_IA.md`](./CONTEXTO_IA.md)** | Desenvolvedores & Agentes de IA | Documento técnico detalhado com arquitetura de classes, contratos, mapeamento de arquivos (em desenvolvimento ativo vs. legados preservados) e débitos técnicos. |
| **[`PLANO_SPRINT_US01.md`](./PLANO_SPRINT_US01.md)** | Equipe de Desenvolvimento | Plano técnico da sprint atual (`US-01`), decomposição atômica de tasks, critérios de aceite mensuráveis e rastreabilidade viva com o `git log`. |
| **[`DIRETRIZES_DESENVOLVIMENTO.md`](./DIRETRIZES_DESENVOLVIMENTO.md)** | Engenharia de Software | Protocolo obrigatório de desenvolvimento (SOLID, testes sintéticos, commits incrementais semânticos, portabilidade multiplataforma e governança). |
| **[`DEVLOG.md`](./DEVLOG.md)** | Rastreabilidade Contínua | Diário de bordo cronológico registrando entregas, decisões técnicas, hashes de commits e estado do repositório a cada sessão. |
| **[`AGENTS.md`](./AGENTS.md)** | Agentes Autônomos de IA | Ponto de entrada obrigatório contendo regras inegociáveis de engenharia de software e skills normativas do repositório. |

---

## 4. Estrutura Resumida de Diretórios

```text
├── tests/
│   └── test_pipeline_pontuacao.py    # Testes unitários automatizados (pytest)
├── app_tempo_real.py                 # Interface com webcam e HUD OpenCV
├── exemplo_integracao.py              # Demonstração sintética do orquestrador (sem câmera)
├── calculo_angulos.py                # Geometria 2D e âncora de ruído para deltas
├── exercicios_fsm.py                 # Máquinas de estados finitos e catálogo
├── buffer_repeticao.py               # Segmentador temporal de repetições
├── dtw_evaluator.py                  # Motor DTW vetorizado (orientado a objetos)
├── gabarito.py                       # Leitor e gerador de curvas padrão ouro JSON
├── extrator_video.py                 # Extração de gabarito via vídeo de especialista
├── gabarito_especialista_*.json      # Gabaritos de referência oficiais
├── requirements.txt                  # Dependências Python oficiais
├── pytest.ini                        # Configuração do ambiente de testes
└── *.md                              # Documentação viva e governança da branch
```

-- ==============================================================================
-- SCRIPT DE RESET E POVOAMENTO DE EXERCÍCIOS E TREINOS (PADRÃO IA)
-- Personal Trainer IA - Engenharia de Software
--
-- Numeração Oficial Reservada para a IA:
--   ID 1: Desenvolvimento com Halteres (Ombros)  -> Visão Computacional (Ombro/Cotovelo)
--   ID 2: Agachamento Livre (Pernas)             -> Visão Computacional (Joelho/Quadril)
--   ID 3: Rosca Direta (Bíceps)                  -> Visão Computacional (Cotovelo)
--
-- Seguido de todos os exercícios de Peito, Costas, Pernas, Ombros, Braços e Abdômen.
-- ==============================================================================

-- 1. Limpeza em cascata das tabelas associativas e de treinos/exercícios
TRUNCATE TABLE public.treino_exercicios RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.treinos RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.exercicios RESTART IDENTITY CASCADE;

-- Reinicia as sequências de ID para começar do 1
ALTER SEQUENCE IF EXISTS public.exercicios_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS public.treinos_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS public.treino_exercicios_id_seq RESTART WITH 1;

-- 2. Inserção dos 30 Exercícios Oficiais (IDs 1, 2 e 3 RIGOROSAMENTE reservados para a IA)
INSERT INTO public.exercicios (id, nome, descricao, grupo_muscular) VALUES
-- ================= IA CORE (IDs 1, 2 e 3) =================
(1, 'Desenvolvimento com Halteres', 'Press vertical para deltoides com monitoramento biomecânico de cotovelos e ombros pela IA.', 'Ombros'),
(2, 'Agachamento Livre', 'Exercício composto para quadríceps e glúteos com validação de amplitude e alinhamento pela IA.', 'Pernas'),
(3, 'Rosca Direta', 'Flexão de cotovelos com halteres ou barra com análise de trajetória angular pela IA.', 'Bíceps'),

-- ================= PEITORAL =================
(4, 'Supino Reto', 'Exercício básico composto com barra ou halteres.', 'Peitoral'),
(5, 'Supino Inclinado', 'Foco na porção clavicular (superior) do peitoral.', 'Peitoral'),
(6, 'Crucifixo Reto', 'Abertura com halteres no banco reto para isolamento peitoral.', 'Peitoral'),
(7, 'Crossover na Polia', 'Isolamento de peitoral com cabos na polia regulável.', 'Peitoral'),
(8, 'Flexão de Braço', 'Exercício funcional de peitoral e core com peso corporal.', 'Peitoral'),

-- ================= COSTAS =================
(9, 'Puxada Frontal', 'Puxada alta na polia com pegada aberta para dorsais.', 'Costas'),
(10, 'Remada Baixa', 'Remada sentado na polia com triângulo para densidade de dorsais.', 'Costas'),
(11, 'Remada Curvada', 'Remada livre com barra ou halteres para ativação de costas.', 'Costas'),
(12, 'Barra Fixa', 'Elevação corporal na barra fixa com pegada pronada.', 'Costas'),
(13, 'Pulldown', 'Isolamento de grandes dorsais na polia com barra reta ou corda.', 'Costas'),

-- ================= PERNAS =================
(14, 'Leg Press 45°', 'Prensa inclinada para membros inferiores e quadríceps.', 'Pernas'),
(15, 'Cadeira Extensora', 'Isolamento de quadríceps em máquina extensora.', 'Pernas'),
(16, 'Mesa Flexora', 'Isolamento de posteriores de coxa (isquiotibiais).', 'Pernas'),
(17, 'Panturrilha em Pé', 'Elevação plantar para panturrilhas em máquina ou degrau.', 'Pernas'),

-- ================= OMBROS =================
(18, 'Elevação Lateral', 'Foco no deltoide medial/lateral com halteres.', 'Ombros'),
(19, 'Elevação Frontal', 'Foco no deltoide anterior com halteres ou anilha.', 'Ombros'),
(20, 'Crucifixo Invertido', 'Foco no deltoide posterior e romboides.', 'Ombros'),

-- ================= BÍCEPS =================
(21, 'Rosca Alternada', 'Flexão alternada de cotovelos com halteres e supinação.', 'Bíceps'),
(22, 'Rosca Martelo', 'Pegada neutra para ativação do braquial e antebraço.', 'Bíceps'),
(23, 'Rosca Scott', 'Isolamento no banco Scott evitando impulsos.', 'Bíceps'),

-- ================= TRÍCEPS =================
(24, 'Tríceps Corda', 'Extensão de cotovelos na polia alta com corda.', 'Tríceps'),
(25, 'Tríceps Pulley', 'Extensão na polia alta com barra reta ou V.', 'Tríceps'),
(26, 'Tríceps Testa', 'Extensão deitado com halteres ou barra W.', 'Tríceps'),
(27, 'Mergulho no Banco', 'Extensão de tríceps apoiado em banco com peso corporal.', 'Tríceps'),

-- ================= ABDÔMEN & CORE =================
(28, 'Abdominal Supra', 'Flexão de tronco no solo para reto abdominal.', 'Abdômen'),
(29, 'Prancha Abdominal', 'Isometria de core no solo em decúbito ventral.', 'Abdômen'),
(30, 'Elevação de Pernas', 'Foco na porção infra-abdominal e flexores de quadril.', 'Abdômen');

-- Atualiza a sequência de exercícios para continuar após o ID 30
SELECT setval('public.exercicios_id_seq', (SELECT MAX(id) FROM public.exercicios));

-- 3. Inserção dos Treinos Pré-montados Oficiais (com metadados JSON e pre_montado = true)
INSERT INTO public.treinos (id, usuario_id, nome, descricao, pre_montado) VALUES
(
  1,
  NULL,
  'Iniciante: Superiores & Ombros IA',
  '{"dificuldade": "Iniciante", "duracao_minutos": 30, "pontos_totais": 150, "texto": "Foco em membros superiores com acompanhamento biomecânico em tempo real pela IA.", "exercicios": [{"exercicio_id": 1, "nome": "Desenvolvimento com Halteres", "series": 3, "repeticoes": 10, "pontos": 50}, {"exercicio_id": 3, "nome": "Rosca Direta", "series": 3, "repeticoes": 12, "pontos": 50}, {"exercicio_id": 29, "nome": "Prancha Abdominal", "series": 3, "repeticoes": 30, "pontos": 50}]}',
  TRUE
),
(
  2,
  NULL,
  'Iniciante: Pernas & Core IA',
  '{"dificuldade": "Iniciante", "duracao_minutos": 35, "pontos_totais": 160, "texto": "Treino de pernas com análise de amplitude e profundidade do agachamento pela IA.", "exercicios": [{"exercicio_id": 2, "nome": "Agachamento Livre", "series": 3, "repeticoes": 12, "pontos": 60}, {"exercicio_id": 14, "nome": "Leg Press 45°", "series": 3, "repeticoes": 12, "pontos": 50}, {"exercicio_id": 28, "nome": "Abdominal Supra", "series": 3, "repeticoes": 15, "pontos": 50}]}',
  TRUE
),
(
  3,
  NULL,
  'Intermediário: Full Body IA Biomecânica',
  '{"dificuldade": "Intermediário", "duracao_minutos": 45, "pontos_totais": 250, "texto": "Treino completo integrando os 3 exercícios chave monitorados pela visão computacional.", "exercicios": [{"exercicio_id": 1, "nome": "Desenvolvimento com Halteres", "series": 4, "repeticoes": 10, "pontos": 70}, {"exercicio_id": 2, "nome": "Agachamento Livre", "series": 4, "repeticoes": 12, "pontos": 70}, {"exercicio_id": 3, "nome": "Rosca Direta", "series": 4, "repeticoes": 10, "pontos": 60}, {"exercicio_id": 8, "nome": "Flexão de Braço", "series": 3, "repeticoes": 12, "pontos": 50}]}',
  TRUE
),
(
  4,
  NULL,
  'Avançado: Hipertrofia & Força Total IA',
  '{"dificuldade": "Avançado", "duracao_minutos": 55, "pontos_totais": 350, "texto": "Rotina intensa com alta cadência e validação técnica em tempo real pela IA.", "exercicios": [{"exercicio_id": 2, "nome": "Agachamento Livre", "series": 4, "repeticoes": 15, "pontos": 80}, {"exercicio_id": 1, "nome": "Desenvolvimento com Halteres", "series": 4, "repeticoes": 12, "pontos": 80}, {"exercicio_id": 3, "nome": "Rosca Direta", "series": 4, "repeticoes": 12, "pontos": 70}, {"exercicio_id": 18, "nome": "Elevação Lateral", "series": 4, "repeticoes": 12, "pontos": 60}, {"exercicio_id": 24, "nome": "Tríceps Corda", "series": 4, "repeticoes": 15, "pontos": 60}]}',
  TRUE
);

SELECT setval('public.treinos_id_seq', (SELECT MAX(id) FROM public.treinos));

-- 4. Inserção na Tabela Associativa public.treino_exercicios
-- Treino 1 (Iniciante: Superiores & Ombros IA)
INSERT INTO public.treino_exercicios (treino_id, exercicio_id, ordem, series, repeticoes) VALUES
(1, 1, 1, 3, 10),  -- Desenvolvimento com Halteres (IA #1)
(1, 3, 2, 3, 12),  -- Rosca Direta (IA #3)
(1, 29, 3, 3, 30); -- Prancha Abdominal

-- Treino 2 (Iniciante: Pernas & Core IA)
INSERT INTO public.treino_exercicios (treino_id, exercicio_id, ordem, series, repeticoes) VALUES
(2, 2, 1, 3, 12),  -- Agachamento Livre (IA #2)
(2, 14, 2, 3, 12), -- Leg Press 45°
(2, 28, 3, 3, 15); -- Abdominal Supra

-- Treino 3 (Intermediário: Full Body IA)
INSERT INTO public.treino_exercicios (treino_id, exercicio_id, ordem, series, repeticoes) VALUES
(3, 1, 1, 4, 10),  -- Desenvolvimento com Halteres (IA #1)
(3, 2, 2, 4, 12),  -- Agachamento Livre (IA #2)
(3, 3, 3, 4, 10),  -- Rosca Direta (IA #3)
(3, 8, 4, 3, 12);  -- Flexão de Braço

-- Treino 4 (Avançado: Hipertrofia & Força Total IA)
INSERT INTO public.treino_exercicios (treino_id, exercicio_id, ordem, series, repeticoes) VALUES
(4, 2, 1, 4, 15),  -- Agachamento Livre (IA #2)
(4, 1, 2, 4, 12),  -- Desenvolvimento com Halteres (IA #1)
(4, 3, 3, 4, 12),  -- Rosca Direta (IA #3)
(4, 18, 4, 4, 12), -- Elevação Lateral
(4, 24, 5, 4, 15); -- Tríceps Corda

SELECT setval('public.treino_exercicios_id_seq', (SELECT MAX(id) FROM public.treino_exercicios));

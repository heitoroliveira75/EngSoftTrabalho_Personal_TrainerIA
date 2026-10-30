-- ==============================================================================
-- SCRIPT SQL DE CADASTRO/SINCRONIZAÇÃO DE EXERCÍCIOS (MOLDE Exercicios.txt)
-- Personal Trainer IA - Banco de Dados Supabase / PostgreSQL
--
-- IDs Oficiais do Motor de Visão Computacional (IA):
--   * ID 16: Desenvolvimento com Halteres (Ombros)
--   * ID 11: Agachamento Livre (Pernas)
--   * ID 20: Rosca Direta (Bíceps)
-- ==============================================================================

-- Inserção ou atualização dos 30 exercícios oficiais respeitando os IDs do Exercicios.txt:
INSERT INTO public.exercicios (id, nome, descricao, grupo_muscular) VALUES
(1, 'Supino Reto', 'Exercício básico com barra ou halteres', 'Peitoral'),
(2, 'Supino Inclinado', 'Foco na porção clavicular do peitoral', 'Peitoral'),
(3, 'Crucifixo Reto', 'Abertura com halteres no banco reto', 'Peitoral'),
(4, 'Crossover na Polia', 'Isolamento com cabos na polia', 'Peitoral'),
(5, 'Flexão de Braço', 'Exercício com peso corporal', 'Peitoral'),
(6, 'Puxada Frontal', 'Puxada alta na polia com pegada aberta', 'Costas'),
(7, 'Remada Baixa', 'Remada sentado na polia com triângulo', 'Costas'),
(8, 'Remada Curvada', 'Remada livre com barra ou halteres', 'Costas'),
(9, 'Barra Fixa', 'Elevação corporal na barra pronada', 'Costas'),
(10, 'Pulldown', 'Isolamento de grandes dorsais na polia', 'Costas'),
(11, 'Agachamento Livre', 'Exercício composto para quadríceps e glúteos', 'Pernas'), -- [IA: Joelho/Quadril]
(12, 'Leg Press 45°', 'Prensa inclinada para membros inferiores', 'Pernas'),
(13, 'Cadeira Extensora', 'Isolamento de quadríceps', 'Pernas'),
(14, 'Mesa Flexora', 'Isolamento de posteriores de coxa', 'Pernas'),
(15, 'Panturrilha em Pé', 'Elevação para panturrilhas', 'Pernas'),
(16, 'Desenvolvimento com Halteres', 'Press vertical para deltoides', 'Ombros'), -- [IA: Ombro/Cotovelo]
(17, 'Elevação Lateral', 'Foco no deltoide medial/lateral', 'Ombros'),
(18, 'Elevação Frontal', 'Foco no deltoide anterior', 'Ombros'),
(19, 'Crucifixo Invertido', 'Foco no deltoide posterior', 'Ombros'),
(20, 'Rosca Direta', 'Flexão de cotovelos com barra reta ou W', 'Bíceps'), -- [IA: Cotovelo]
(21, 'Rosca Alternada', 'Flexão alternada com halteres', 'Bíceps'),
(22, 'Rosca Martelo', 'Pegada neutra para braquial e antebraço', 'Bíceps'),
(23, 'Rosca Scott', 'Isolamento no banco Scott', 'Bíceps'),
(24, 'Tríceps Corda', 'Extensão na polia alta com corda', 'Tríceps'),
(25, 'Tríceps Pulley', 'Extensão na polia com barra', 'Tríceps'),
(26, 'Tríceps Testa', 'Extensão deitado com halteres ou barra W', 'Tríceps'),
(27, 'Mergulho no Banco', 'Extensão de tríceps com peso corporal', 'Tríceps'),
(28, 'Abdominal Supra', 'Flexão de tronco no solo', 'Abdômen'),
(29, 'Prancha Abdominal', 'Isometria de core no solo', 'Abdômen'),
(30, 'Elevação de Pernas', 'Foco no infra-abdominal', 'Abdômen')
ON CONFLICT (id) DO UPDATE SET
  nome = EXCLUDED.nome,
  descricao = EXCLUDED.descricao,
  grupo_muscular = EXCLUDED.grupo_muscular;

-- Sincroniza a sequence da tabela para não gerar conflitos em novos cadastros manuais
SELECT setval('public.exercicios_id_seq', (SELECT MAX(id) FROM public.exercicios));

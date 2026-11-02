-- ============================================================
-- SCRIPT DE CRIAÇÃO DA TABELA DE TREINOS EM DUPLA
-- Feature: Treino Cooperativo em Dupla (Turn-Based Workout)
-- Arquivo: BD/script_treino_dupla.sql
-- ============================================================

-- 1. TABELA PRINCIPAL DE SESSÕES EM DUPLA
CREATE TABLE IF NOT EXISTS public.sessoes_treino_dupla (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    host_id UUID NOT NULL REFERENCES public.usuarios(id) ON DELETE CASCADE,
    convidado_id UUID NOT NULL REFERENCES public.usuarios(id) ON DELETE CASCADE,
    treino_id BIGINT REFERENCES public.treinos(id) ON DELETE SET NULL,
    dados_treino JSONB DEFAULT '{}'::jsonb, -- Armazena snapshot dos exercícios, séries e repetições
    status VARCHAR(30) NOT NULL DEFAULT 'pendente', 
    -- Valores possíveis para status: 
    -- 'pendente', 'aceito', 'recusado', 'cancelado', 'em_andamento', 'finalizado', 'interrompido'

    -- Controle de Turno e Sequência Biomecânica
    turno_usuario_id UUID REFERENCES public.usuarios(id),
    indice_exercicio_atual INT NOT NULL DEFAULT 0,
    serie_atual INT NOT NULL DEFAULT 1,
    total_series INT NOT NULL DEFAULT 3,

    -- Gamificação Cooperativa (Multiplicador 1.2x = +20% bônus)
    pontos_host INT NOT NULL DEFAULT 0,
    pontos_convidado INT NOT NULL DEFAULT 0,
    pontos_finais_cada INT NOT NULL DEFAULT 0,
    multiplicador_aplicado NUMERIC(3,2) NOT NULL DEFAULT 1.20,

    -- Metadados temporais
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    finalizado_em TIMESTAMP WITH TIME ZONE,

    -- Garantir que host e convidado sejam usuários distintos
    CONSTRAINT chk_dupla_distinta CHECK (host_id != convidado_id)
);

-- 2. ÍNDICES DE PERFORMANCE PARA BUSCAS RÁPIDAS
CREATE INDEX IF NOT EXISTS idx_dupla_host ON public.sessoes_treino_dupla(host_id, status);
CREATE INDEX IF NOT EXISTS idx_dupla_convidado ON public.sessoes_treino_dupla(convidado_id, status);
CREATE INDEX IF NOT EXISTS idx_dupla_status ON public.sessoes_treino_dupla(status);
CREATE INDEX IF NOT EXISTS idx_dupla_created_at ON public.sessoes_treino_dupla(created_at DESC);

-- 3. TRIGGER PARA ATUALIZAÇÃO AUTOMÁTICA DE updated_at
CREATE OR REPLACE FUNCTION public.handle_updated_at_dupla()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_atualizar_updated_at_dupla ON public.sessoes_treino_dupla;
CREATE TRIGGER trg_atualizar_updated_at_dupla
    BEFORE UPDATE ON public.sessoes_treino_dupla
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at_dupla();

-- 4. POLÍTICAS DE RLS (ROW LEVEL SECURITY)
ALTER TABLE public.sessoes_treino_dupla ENABLE ROW LEVEL SECURITY;

-- Usuários autenticados podem visualizar e interagir com sessões onde são Host ou Convidado
DROP POLICY IF EXISTS "Participantes podem visualizar sessoes de dupla" ON public.sessoes_treino_dupla;
CREATE POLICY "Participantes podem visualizar sessoes de dupla"
    ON public.sessoes_treino_dupla
    FOR SELECT
    USING (
        auth.uid() = host_id OR auth.uid() = convidado_id
    );

DROP POLICY IF EXISTS "Participantes podem atualizar sessoes de dupla" ON public.sessoes_treino_dupla;
CREATE POLICY "Participantes podem atualizar sessoes de dupla"
    ON public.sessoes_treino_dupla
    FOR UPDATE
    USING (
        auth.uid() = host_id OR auth.uid() = convidado_id
    );

DROP POLICY IF EXISTS "Host pode criar sessao de dupla" ON public.sessoes_treino_dupla;
CREATE POLICY "Host pode criar sessao de dupla"
    ON public.sessoes_treino_dupla
    FOR INSERT
    WITH CHECK (
        auth.uid() = host_id
    );

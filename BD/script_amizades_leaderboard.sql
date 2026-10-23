-- ==============================================================================
-- SCRIPT DE CRIAÇÃO: SISTEMA DE AMIZADES E LEADERBOARD
-- Projeto: Personal Trainer IA
-- SGBD: PostgreSQL (Supabase)
-- Data: 2026-10-23
-- ==============================================================================

-- 1. CRIAÇÃO DA TABELA DE AMIZADES
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.amizades (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID NOT NULL REFERENCES public.usuarios(id) ON DELETE CASCADE,
    amigo_id UUID NOT NULL REFERENCES public.usuarios(id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL DEFAULT 'pendente',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Garante que um usuário não pode solicitar amizade a si mesmo
    CONSTRAINT chk_nao_auto_amizade CHECK (usuario_id != amigo_id),

    -- Garante status válidos
    CONSTRAINT chk_status_valido CHECK (status IN ('pendente', 'aceito', 'recusado', 'bloqueado'))
);

-- Impede que existam pares duplicados de amizade em qualquer direção (A -> B ou B -> A)
CREATE UNIQUE INDEX IF NOT EXISTS uq_amizade_par_bidirecional 
ON public.amizades (LEAST(usuario_id, amigo_id), GREATEST(usuario_id, amigo_id));


-- 2. ÍNDICES DE PERFORMANCE
-- ------------------------------------------------------------------------------
-- Acelera a consulta de amizades por usuário e por status
CREATE INDEX IF NOT EXISTS idx_amizades_usuario_status ON public.amizades(usuario_id, status);
CREATE INDEX IF NOT EXISTS idx_amizades_amigo_status ON public.amizades(amigo_id, status);

-- Acelera a busca de usuários por nome (insensível a maiúsculas/minúsculas)
CREATE INDEX IF NOT EXISTS idx_usuarios_nome_busca ON public.usuarios (LOWER(nome));


-- 3. TRIGGER PARA ATUALIZAÇÃO AUTOMÁTICA DE 'updated_at'
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_amizades_updated_at ON public.amizades;

CREATE TRIGGER trigger_amizades_updated_at
BEFORE UPDATE ON public.amizades
FOR EACH ROW
EXECUTE FUNCTION public.handle_updated_at();


-- 4. POLÍTICAS DE SEGURANÇA (ROW-LEVEL SECURITY - RLS)
-- ------------------------------------------------------------------------------
ALTER TABLE public.amizades ENABLE ROW LEVEL SECURITY;

-- Consulta: usuários autenticados só visualizam suas próprias amizades e solicitações
CREATE POLICY "Usuarios podem visualizar suas proprias amizades"
ON public.amizades
FOR SELECT
TO authenticated
USING (usuario_id = auth.uid() OR amigo_id = auth.uid());

-- Inserção: usuário autenticado só pode enviar solicitações em seu próprio nome
CREATE POLICY "Usuarios podem enviar solicitacoes de amizade"
ON public.amizades
FOR INSERT
TO authenticated
WITH CHECK (usuario_id = auth.uid());

-- Atualização: apenas quem recebeu a solicitação pode aceitar ou recusar
CREATE POLICY "Destinatario pode responder solicitacao de amizade"
ON public.amizades
FOR UPDATE
TO authenticated
USING (amigo_id = auth.uid())
WITH CHECK (amigo_id = auth.uid());

-- Exclusão: qualquer uma das partes pode desfazer a amizade ou cancelar a solicitação
CREATE POLICY "Usuarios podem desfazer amizades"
ON public.amizades
FOR DELETE
TO authenticated
USING (usuario_id = auth.uid() OR amigo_id = auth.uid());


-- 5. FUNÇÃO SQL: OBTENÇÃO DA LEADERBOARD DE AMIGOS
-- ------------------------------------------------------------------------------
-- Esta função pode ser chamada diretamente via RPC no Supabase ou via FastAPI.
-- Retorna os dados do ranking semanal e streak dos amigos aceitos + o próprio usuário logado.
CREATE OR REPLACE FUNCTION public.obter_leaderboard_amigos(p_usuario_id UUID)
RETURNS TABLE (
    id UUID,
    nome TEXT,
    pontuacao_semanal INTEGER,
    sequencia INTEGER,
    maior_sequencia INTEGER
) 
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
    WITH ids_participantes AS (
        -- Amigos confirmados (onde o usuário foi o solicitante)
        SELECT amigo_id AS participante_id
        FROM public.amizades
        WHERE usuario_id = p_usuario_id AND status = 'aceito'

        UNION

        -- Amigos confirmados (onde o usuário foi o destinatário)
        SELECT usuario_id AS participante_id
        FROM public.amizades
        WHERE amigo_id = p_usuario_id AND status = 'aceito'

        UNION

        -- O próprio usuário para compor o ranking
        SELECT p_usuario_id AS participante_id
    )
    SELECT 
        u.id,
        u.nome,
        COALESCE(u.pontuacao_semanal, 0) AS pontuacao_semanal,
        COALESCE(u.sequencia, 0) AS sequencia,
        COALESCE(u.maior_sequencia, 0) AS maior_sequencia
    FROM public.usuarios u
    INNER JOIN ids_participantes p ON u.id = p.participante_id
    ORDER BY u.pontuacao_semanal DESC, u.sequencia DESC, u.nome ASC;
$$;

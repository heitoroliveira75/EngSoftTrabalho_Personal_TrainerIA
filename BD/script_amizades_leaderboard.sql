-- ==============================================================================
-- SCRIPT DE CRIAÇÃO: SISTEMA DE AMIZADES E LEADERBOARD (GLOBAL E AMIGOS)
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

-- Acelera a Leaderboard Global (ordenação por pontos semanais e streak)
CREATE INDEX IF NOT EXISTS idx_usuarios_leaderboard_global 
ON public.usuarios (pontuacao_semanal DESC, sequencia DESC);


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


-- 5. FUNÇÕES SQL: LEADERBOARDS (RPC)
-- ------------------------------------------------------------------------------

-- 5.1. LEADERBOARD DE AMIGOS
-- Retorna o ranking entre o usuário e seus amigos confirmados, com posição calculada.
CREATE OR REPLACE FUNCTION public.obter_leaderboard_amigos(p_usuario_id UUID)
RETURNS TABLE (
    posicao BIGINT,
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
        ROW_NUMBER() OVER (
            ORDER BY COALESCE(u.pontuacao_semanal, 0) DESC, COALESCE(u.sequencia, 0) DESC, u.nome ASC
        ) AS posicao,
        u.id,
        u.nome,
        COALESCE(u.pontuacao_semanal, 0) AS pontuacao_semanal,
        COALESCE(u.sequencia, 0) AS sequencia,
        COALESCE(u.maior_sequencia, 0) AS maior_sequencia
    FROM public.usuarios u
    INNER JOIN ids_participantes p ON u.id = p.participante_id
    ORDER BY posicao ASC;
$$;


-- 5.2. LEADERBOARD GLOBAL (TODOS OS USUÁRIOS)
-- Retorna o ranking geral do app com paginação/limite configurável.
CREATE OR REPLACE FUNCTION public.obter_leaderboard_global(p_limite INTEGER DEFAULT 100)
RETURNS TABLE (
    posicao BIGINT,
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
    SELECT 
        ROW_NUMBER() OVER (
            ORDER BY COALESCE(u.pontuacao_semanal, 0) DESC, COALESCE(u.sequencia, 0) DESC, u.nome ASC
        ) AS posicao,
        u.id,
        u.nome,
        COALESCE(u.pontuacao_semanal, 0) AS pontuacao_semanal,
        COALESCE(u.sequencia, 0) AS sequencia,
        COALESCE(u.maior_sequencia, 0) AS maior_sequencia
    FROM public.usuarios u
    LIMIT p_limite;
$$;


-- 5.3. POSIÇÃO INDIVIDUAL DO USUÁRIO NO RANKING GLOBAL
-- Permite exibir em card fixo a colocação exata do usuário logado (ex: "Sua posição: #142").
CREATE OR REPLACE FUNCTION public.obter_minha_posicao_global(p_usuario_id UUID)
RETURNS BIGINT
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
    WITH ranking AS (
        SELECT 
            id,
            ROW_NUMBER() OVER (
                ORDER BY COALESCE(pontuacao_semanal, 0) DESC, COALESCE(sequencia, 0) DESC, nome ASC
            ) AS posicao
        FROM public.usuarios
    )
    SELECT posicao FROM ranking WHERE id = p_usuario_id;
$$;


-- 5.4. BUSCA DE USUÁRIOS POR NOME (SECURITY DEFINER)
-- Permite que a API e clientes busquem atletas da comunidade mesmo com RLS ativado na tabela usuarios
CREATE OR REPLACE FUNCTION public.buscar_usuarios(p_termo TEXT, p_limite INTEGER DEFAULT 20)
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
    SELECT 
        u.id,
        u.nome,
        COALESCE(u.pontuacao_semanal, 0) AS pontuacao_semanal,
        COALESCE(u.sequencia, 0) AS sequencia,
        COALESCE(u.maior_sequencia, 0) AS maior_sequencia
    FROM public.usuarios u
    WHERE LOWER(u.nome) LIKE '%' || LOWER(p_termo) || '%'
    LIMIT p_limite;
$$;


-- 5.5. ENVIAR SOLICITAÇÃO DE AMIZADE (SECURITY DEFINER)
CREATE OR REPLACE FUNCTION public.enviar_solicitacao_amizade(p_usuario_id UUID, p_amigo_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_existente RECORD;
    v_resultado RECORD;
BEGIN
    IF p_usuario_id = p_amigo_id THEN
        RAISE EXCEPTION 'Não é permitido adicionar a si mesmo.';
    END IF;

    SELECT id, status INTO v_existente 
    FROM public.amizades
    WHERE (usuario_id = p_usuario_id AND amigo_id = p_amigo_id)
       OR (usuario_id = p_amigo_id AND amigo_id = p_usuario_id)
    LIMIT 1;

    IF FOUND THEN
        IF v_existente.status = 'aceito' THEN
            RAISE EXCEPTION 'Vocês já são amigos.';
        ELSIF v_existente.status = 'pendente' THEN
            RAISE EXCEPTION 'Já existe uma solicitação pendente entre vocês.';
        ELSE
            UPDATE public.amizades
            SET status = 'pendente', usuario_id = p_usuario_id, amigo_id = p_amigo_id, updated_at = NOW()
            WHERE id = v_existente.id
            RETURNING * INTO v_resultado;
            RETURN to_jsonb(v_resultado);
        END IF;
    END IF;

    INSERT INTO public.amizades (usuario_id, amigo_id, status)
    VALUES (p_usuario_id, p_amigo_id, 'pendente')
    RETURNING * INTO v_resultado;

    RETURN to_jsonb(v_resultado);
END;
$$;


-- 5.6. RESPONDER SOLICITAÇÃO DE AMIZADE (SECURITY DEFINER)
CREATE OR REPLACE FUNCTION public.responder_solicitacao(p_solicitacao_id UUID, p_novo_status TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_resultado RECORD;
BEGIN
    UPDATE public.amizades
    SET status = p_novo_status, updated_at = NOW()
    WHERE id = p_solicitacao_id
    RETURNING * INTO v_resultado;

    RETURN to_jsonb(v_resultado);
END;
$$;


-- 5.7. REMOVER AMIZADE (SECURITY DEFINER)
CREATE OR REPLACE FUNCTION public.remover_amigo(p_usuario_id UUID, p_amigo_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    DELETE FROM public.amizades
    WHERE (usuario_id = p_usuario_id AND amigo_id = p_amigo_id)
       OR (usuario_id = p_amigo_id AND amigo_id = p_usuario_id);
    RETURN TRUE;
END;
$$;


-- 5.8. LISTAR AMIGOS CONFIRMADOS (SECURITY DEFINER)
CREATE OR REPLACE FUNCTION public.listar_amigos(p_usuario_id UUID)
RETURNS TABLE (
    amizade_id UUID,
    id UUID,
    nome TEXT,
    sequencia INTEGER,
    pontos INTEGER
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
    WITH amigos_ids AS (
        SELECT id AS amizade_id, amigo_id AS amigo_usuario_id
        FROM public.amizades
        WHERE usuario_id = p_usuario_id AND status = 'aceito'
        UNION
        SELECT id AS amizade_id, usuario_id AS amigo_usuario_id
        FROM public.amizades
        WHERE amigo_id = p_usuario_id AND status = 'aceito'
    )
    SELECT 
        a.amizade_id,
        u.id,
        u.nome,
        COALESCE(u.sequencia, 0) AS sequencia,
        COALESCE(u.pontuacao_semanal, 0) AS pontos
    FROM public.usuarios u
    INNER JOIN amigos_ids a ON u.id = a.amigo_usuario_id;
$$;


-- 5.9. LISTAR CONVITES PENDENTES (SECURITY DEFINER)
CREATE OR REPLACE FUNCTION public.listar_solicitacoes_pendentes(p_usuario_id UUID)
RETURNS TABLE (
    id UUID,
    solicitante_id UUID,
    nome TEXT,
    sequencia INTEGER,
    pontos INTEGER,
    created_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
    SELECT 
        a.id,
        a.usuario_id AS solicitante_id,
        COALESCE(u.nome, 'Usuário') AS nome,
        COALESCE(u.sequencia, 0) AS sequencia,
        COALESCE(u.pontuacao_semanal, 0) AS pontos,
        a.created_at
    FROM public.amizades a
    LEFT JOIN public.usuarios u ON a.usuario_id = u.id
    WHERE a.amigo_id = p_usuario_id AND a.status = 'pendente'
    ORDER BY a.created_at DESC;
$$;

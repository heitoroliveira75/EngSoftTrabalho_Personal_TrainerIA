-- ==============================================================================
-- SCRIPT DE PRIVACIDADE DE PERFIL (PÚBLICO / PRIVADO PARA AMIGOS) E CÓPIA DE TREINOS
-- Projeto: Personal Trainer IA
-- SGBD: PostgreSQL (Supabase)
-- Data: 2026-11-24
--
-- Regra de Visibilidade (Opção B):
--   1. Perfil Público (perfil_publico = TRUE, padrão):
--      Qualquer atleta autenticado pode visualizar os treinos personalizados do usuário e copiá-los.
--   2. Perfil Privado (perfil_publico = FALSE):
--      Apenas o próprio usuário e seus AMIGOS CONFIRMADOS (status = 'aceito' em public.amizades)
--      podem visualizar e copiar seus treinos personalizados. Desconhecidos no Leaderboard Global
--      continuam vendo pontuação, sequência (streak) e posição no ranking, mas os treinos ficam ocultos.
-- ==============================================================================

-- 1. ADIÇÃO DA COLUNA 'perfil_publico' NA TABELA public.usuarios
-- ------------------------------------------------------------------------------
ALTER TABLE public.usuarios
ADD COLUMN IF NOT EXISTS perfil_publico BOOLEAN NOT NULL DEFAULT TRUE;

COMMENT ON COLUMN public.usuarios.perfil_publico IS
'Define se os treinos personalizados do usuário são visíveis para toda a comunidade (TRUE) ou apenas para amigos confirmados (FALSE).';


-- 2. FUNÇÃO AUXILIAR: VERIFICAR SE DOIS USUÁRIOS SÃO AMIGOS CONFIRMADOS
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.sao_amigos_confirmados(p_usuario_a UUID, p_usuario_b UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM public.amizades
        WHERE status = 'aceito'
          AND (
              (usuario_id = p_usuario_a AND amigo_id = p_usuario_b)
              OR
              (usuario_id = p_usuario_b AND amigo_id = p_usuario_a)
          )
    );
$$;


-- 3. FUNÇÃO AUXILIAR: VERIFICAR SE O SOLICITANTE PODE VER OS TREINOS DO ALVO
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.pode_visualizar_treinos_usuario(p_alvo_id UUID, p_solicitante_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
    SELECT
        -- 1. O próprio dono sempre pode ver
        (p_alvo_id = p_solicitante_id)
        OR
        -- 2. O perfil do usuário alvo é público
        EXISTS (
            SELECT 1
            FROM public.usuarios u
            WHERE u.id = p_alvo_id
              AND COALESCE(u.perfil_publico, TRUE) = TRUE
        )
        OR
        -- 3. O perfil é privado, mas o solicitante é amigo confirmado
        (
            p_solicitante_id IS NOT NULL
            AND public.sao_amigos_confirmados(p_alvo_id, p_solicitante_id)
        );
$$;


-- 4. POLÍTICAS DE SEGURANÇA (ROW-LEVEL SECURITY - RLS)
-- ------------------------------------------------------------------------------
ALTER TABLE public.usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.treinos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.treino_exercicios ENABLE ROW LEVEL SECURITY;

-- 4.1. Políticas na tabela public.usuarios
DROP POLICY IF EXISTS "Usuarios autenticados podem visualizar perfis" ON public.usuarios;
CREATE POLICY "Usuarios autenticados podem visualizar perfis"
ON public.usuarios
FOR SELECT
TO authenticated
USING (true);

DROP POLICY IF EXISTS "Usuarios podem atualizar seu proprio perfil" ON public.usuarios;
CREATE POLICY "Usuarios podem atualizar seu proprio perfil"
ON public.usuarios
FOR UPDATE
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- 4.2. Políticas na tabela public.treinos (Respeitando Opção B: Público ou Amigo Confirmado)
DROP POLICY IF EXISTS "Visualizacao de treinos pre-montados, proprios, publicos ou de amigos" ON public.treinos;
CREATE POLICY "Visualizacao de treinos pre-montados, proprios, publicos ou de amigos"
ON public.treinos
FOR SELECT
TO authenticated
USING (
    COALESCE(pre_montado, FALSE) = TRUE
    OR usuario_id = auth.uid()
    OR public.pode_visualizar_treinos_usuario(usuario_id, auth.uid())
);

DROP POLICY IF EXISTS "Usuarios podem criar seus proprios treinos" ON public.treinos;
CREATE POLICY "Usuarios podem criar seus proprios treinos"
ON public.treinos
FOR INSERT
TO authenticated
WITH CHECK (usuario_id = auth.uid());

DROP POLICY IF EXISTS "Usuarios podem atualizar seus proprios treinos" ON public.treinos;
CREATE POLICY "Usuarios podem atualizar seus proprios treinos"
ON public.treinos
FOR UPDATE
TO authenticated
USING (usuario_id = auth.uid())
WITH CHECK (usuario_id = auth.uid());

DROP POLICY IF EXISTS "Usuarios podem excluir seus proprios treinos" ON public.treinos;
CREATE POLICY "Usuarios podem excluir seus proprios treinos"
ON public.treinos
FOR DELETE
TO authenticated
USING (usuario_id = auth.uid());

-- 4.3. Políticas na tabela public.treino_exercicios
DROP POLICY IF EXISTS "Visualizacao de exercicios de treinos acessiveis" ON public.treino_exercicios;
CREATE POLICY "Visualizacao de exercicios de treinos acessiveis"
ON public.treino_exercicios
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.treinos t
        WHERE t.id = treino_exercicios.treino_id
          AND (
              COALESCE(t.pre_montado, FALSE) = TRUE
              OR t.usuario_id = auth.uid()
              OR public.pode_visualizar_treinos_usuario(t.usuario_id, auth.uid())
          )
    )
);

DROP POLICY IF EXISTS "Usuarios podem gerenciar exercicios de seus proprios treinos" ON public.treino_exercicios;
CREATE POLICY "Usuarios podem gerenciar exercicios de seus proprios treinos"
ON public.treino_exercicios
FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.treinos t
        WHERE t.id = treino_exercicios.treino_id
          AND t.usuario_id = auth.uid()
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1
        FROM public.treinos t
        WHERE t.id = treino_exercicios.treino_id
          AND t.usuario_id = auth.uid()
    )
);


-- 5. FUNÇÕES RPC (SECURITY DEFINER) PARA O BACKEND E FRONTEND
-- ------------------------------------------------------------------------------

-- 5.1. ALTERAR PRIVACIDADE DO PERFIL
CREATE OR REPLACE FUNCTION public.alterar_privacidade_perfil(
    p_usuario_id UUID,
    p_perfil_publico BOOLEAN
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_usuario RECORD;
BEGIN
    UPDATE public.usuarios
    SET perfil_publico = COALESCE(p_perfil_publico, TRUE)
    WHERE id = p_usuario_id
    RETURNING id, nome, perfil_publico INTO v_usuario;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Usuário não encontrado.';
    END IF;

    RETURN jsonb_build_object(
        'id', v_usuario.id,
        'nome', v_usuario.nome,
        'perfil_publico', v_usuario.perfil_publico
    );
END;
$$;


-- 5.2. OBTER PERFIL COMPLETO DE ATLETA COM RANKING E PERMISSÃO DE VISUALIZAÇÃO DE TREINOS
CREATE OR REPLACE FUNCTION public.obter_perfil_atleta(
    p_alvo_id UUID,
    p_solicitante_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
DECLARE
    v_usuario RECORD;
    v_posicao_global BIGINT;
    v_ja_amigo BOOLEAN := FALSE;
    v_solicitacao_pendente BOOLEAN := FALSE;
    v_pode_ver_treinos BOOLEAN := FALSE;
BEGIN
    SELECT
        u.id,
        u.nome,
        COALESCE(u.pontuacao_diaria, 0) AS pontuacao_diaria,
        COALESCE(u.pontuacao_semanal, 0) AS pontuacao_semanal,
        COALESCE(u.pontuacao_total, 0) AS pontuacao_total,
        COALESCE(u.sequencia, 0) AS sequencia,
        GREATEST(COALESCE(u.maior_sequencia, 0), COALESCE(u.sequencia, 0)) AS maior_sequencia,
        COALESCE(u.checagem, FALSE) AS checagem,
        COALESCE(u.perfil_publico, TRUE) AS perfil_publico
    INTO v_usuario
    FROM public.usuarios u
    WHERE u.id = p_alvo_id
    LIMIT 1;

    IF NOT FOUND THEN
        RETURN NULL;
    END IF;

    -- Calcula posição global
    SELECT r.posicao INTO v_posicao_global
    FROM (
        SELECT
            id,
            ROW_NUMBER() OVER (
                ORDER BY COALESCE(pontuacao_semanal, 0) DESC, COALESCE(sequencia, 0) DESC, nome ASC
            ) AS posicao
        FROM public.usuarios
    ) r
    WHERE r.id = p_alvo_id;

    -- Verifica relação de amizade com o solicitante (se informado)
    IF p_solicitante_id IS NOT NULL AND p_solicitante_id != p_alvo_id THEN
        v_ja_amigo := public.sao_amigos_confirmados(p_alvo_id, p_solicitante_id);

        SELECT EXISTS (
            SELECT 1
            FROM public.amizades
            WHERE status = 'pendente'
              AND (
                  (usuario_id = p_solicitante_id AND amigo_id = p_alvo_id)
                  OR
                  (usuario_id = p_alvo_id AND amigo_id = p_solicitante_id)
              )
        ) INTO v_solicitacao_pendente;
    END IF;

    v_pode_ver_treinos := (
        p_alvo_id = p_solicitante_id
        OR v_usuario.perfil_publico = TRUE
        OR v_ja_amigo = TRUE
    );

    RETURN jsonb_build_object(
        'id', v_usuario.id,
        'nome', v_usuario.nome,
        'pontuacao_diaria', v_usuario.pontuacao_diaria,
        'pontuacao_semanal', v_usuario.pontuacao_semanal,
        'pontuacao_total', v_usuario.pontuacao_total,
        'sequencia', v_usuario.sequencia,
        'maior_sequencia', v_usuario.maior_sequencia,
        'checagem', v_usuario.checagem,
        'perfil_publico', v_usuario.perfil_publico,
        'posicao_global', v_posicao_global,
        'ja_amigo', v_ja_amigo,
        'solicitacao_pendente', v_solicitacao_pendente,
        'pode_visualizar_treinos', v_pode_ver_treinos
    );
END;
$$;


-- 5.3. LISTAR TREINOS DE UM ATLETA RESPEITANDO PRIVACIDADE (OPÇÃO B)
CREATE OR REPLACE FUNCTION public.listar_treinos_atleta_visiveis(
    p_alvo_id UUID,
    p_solicitante_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
DECLARE
    v_perfil_publico BOOLEAN := TRUE;
    v_ja_amigo BOOLEAN := FALSE;
    v_pode_ver BOOLEAN := FALSE;
    v_treinos JSONB;
BEGIN
    SELECT COALESCE(u.perfil_publico, TRUE)
    INTO v_perfil_publico
    FROM public.usuarios u
    WHERE u.id = p_alvo_id;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'sucesso', FALSE,
            'mensagem', 'Usuário não encontrado.',
            'pode_visualizar_treinos', FALSE,
            'treinos', '[]'::jsonb
        );
    END IF;

    IF p_solicitante_id IS NOT NULL AND p_solicitante_id != p_alvo_id THEN
        v_ja_amigo := public.sao_amigos_confirmados(p_alvo_id, p_solicitante_id);
    END IF;

    v_pode_ver := (
        p_alvo_id = p_solicitante_id
        OR v_perfil_publico = TRUE
        OR v_ja_amigo = TRUE
    );

    IF NOT v_pode_ver THEN
        RETURN jsonb_build_object(
            'sucesso', TRUE,
            'perfil_publico', v_perfil_publico,
            'ja_amigo', v_ja_amigo,
            'pode_visualizar_treinos', FALSE,
            'treinos_ocultos_privacidade', TRUE,
            'mensagem', 'Este perfil é privado. Adicione este atleta como amigo para visualizar e copiar seus treinos.',
            'treinos', '[]'::jsonb
        );
    END IF;

    SELECT COALESCE(
        jsonb_agg(
            jsonb_build_object(
                'id', t.id,
                'usuario_id', t.usuario_id,
                'nome', t.nome,
                'descricao', t.descricao,
                'pre_montado', t.pre_montado,
                'created_at', t.created_at,
                'treino_exercicios', COALESCE(
                    (
                        SELECT jsonb_agg(
                            jsonb_build_object(
                                'id', te.id,
                                'treino_id', te.treino_id,
                                'exercicio_id', te.exercicio_id,
                                'ordem', te.ordem,
                                'series', te.series,
                                'repeticoes', te.repeticoes,
                                'exercicios', jsonb_build_object(
                                    'id', e.id,
                                    'nome', e.nome,
                                    'grupo_muscular', e.grupo_muscular
                                )
                            )
                            ORDER BY te.ordem ASC, te.id ASC
                        )
                        FROM public.treino_exercicios te
                        LEFT JOIN public.exercicios e ON e.id = te.exercicio_id
                        WHERE te.treino_id = t.id
                    ),
                    '[]'::jsonb
                )
            )
            ORDER BY t.id DESC
        ),
        '[]'::jsonb
    )
    INTO v_treinos
    FROM public.treinos t
    WHERE t.usuario_id = p_alvo_id;

    RETURN jsonb_build_object(
        'sucesso', TRUE,
        'perfil_publico', v_perfil_publico,
        'ja_amigo', v_ja_amigo,
        'pode_visualizar_treinos', TRUE,
        'treinos_ocultos_privacidade', FALSE,
        'treinos', v_treinos
    );
END;
$$;

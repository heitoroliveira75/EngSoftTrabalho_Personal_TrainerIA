-- ============================================================
-- SCRIPT DE ATUALIZAÇÃO: TRIGGER DE CRÉDITO DE PONTOS EM DUPLA
-- Arquivo: BD/script_credito_pontos_dupla.sql
-- ============================================================

-- Executa com privilégios SECURITY DEFINER para contornar qualquer bloqueio de RLS
CREATE OR REPLACE FUNCTION public.trg_creditar_pontos_treino_dupla()
RETURNS TRIGGER AS $$
DECLARE
    v_pontos_finais INT;
    v_media NUMERIC;
BEGIN
    -- Dispara no momento exato em que a sessão é concluída
    IF NEW.status = 'finalizado' AND (OLD.status IS DISTINCT FROM 'finalizado') THEN
        v_media := (COALESCE(NEW.pontos_host, 0) + COALESCE(NEW.pontos_convidado, 0)) / 2.0;
        v_pontos_finais := COALESCE(NEW.pontos_finais_cada, ROUND(v_media * 1.20)::INT);
        
        IF v_pontos_finais > 0 THEN
            -- 1. Credita para o Host (pontuação total + bônus cooperativo)
            UPDATE public.usuarios
            SET pontuacao_diaria = COALESCE(pontuacao_diaria, 0) + v_pontos_finais,
                pontuacao_semanal = COALESCE(pontuacao_semanal, 0) + v_pontos_finais,
                pontuacao_total = COALESCE(pontuacao_total, 0) + v_pontos_finais,
                sequencia = COALESCE(sequencia, 0) + 1,
                maior_sequencia = GREATEST(COALESCE(maior_sequencia, 0), COALESCE(sequencia, 0) + 1),
                checagem = true
            WHERE id = NEW.host_id;

            -- 2. Credita para o Convidado (pontuação total + bônus cooperativo)
            UPDATE public.usuarios
            SET pontuacao_diaria = COALESCE(pontuacao_diaria, 0) + v_pontos_finais,
                pontuacao_semanal = COALESCE(pontuacao_semanal, 0) + v_pontos_finais,
                pontuacao_total = COALESCE(pontuacao_total, 0) + v_pontos_finais,
                sequencia = COALESCE(sequencia, 0) + 1,
                maior_sequencia = GREATEST(COALESCE(maior_sequencia, 0), COALESCE(sequencia, 0) + 1),
                checagem = true
            WHERE id = NEW.convidado_id;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_creditar_pontos_dupla ON public.sessoes_treino_dupla;
CREATE TRIGGER trigger_creditar_pontos_dupla
    AFTER UPDATE ON public.sessoes_treino_dupla
    FOR EACH ROW
    EXECUTE FUNCTION public.trg_creditar_pontos_treino_dupla();

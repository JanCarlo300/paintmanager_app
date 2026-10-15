-- ============================================================
-- Item 1.2 — A obra só inicia com orçamento Aprovado
-- Execute este script no SQL Editor do Supabase Dashboard.
-- RODE DEPOIS do orcamento_status_3_opcoes.sql.
-- Seguro rodar duas vezes.
-- ============================================================
-- Regra (decisão do Jan, 15/10/2026): a obra só sai de "Não Iniciada"
-- (para Em Andamento, Pausada ou Concluída) se tiver pelo menos um
-- orçamento com status "Aprovado". Pendente ou Recusado não liberam.
-- O app já faz essa checagem; o trigger repete no banco para que
-- nenhum outro caminho burle a regra.
--
-- Migração: obras "Em Andamento" sem orçamento aprovado voltam para
-- "Não Iniciada". As que já estão Pausadas ou Concluídas não mudam.
--
-- COMO DESFAZER A TRAVA (a migração não volta sozinha):
--   DROP TRIGGER IF EXISTS trg_obra_inicia_com_orcamento_aprovado ON public.obra;
--   DROP FUNCTION IF EXISTS public.validar_inicio_obra();
-- ============================================================

-- 1. Antes de migrar: obras que VÃO voltar para "Não Iniciada".
--    (Aparece como resultado só se for a última consulta; ver item 4.)
DROP TABLE IF EXISTS obras_revertidas_1_2;
CREATE TEMP TABLE obras_revertidas_1_2 AS
SELECT id_obra, titulo_da_obra, cliente_nome
FROM public.obra o
WHERE o.status = 'Em Andamento'
  AND NOT EXISTS (
    SELECT 1 FROM public.orcamento orc
    WHERE orc.id_obra = o.id_obra AND orc.status = 'Aprovado'
  );

-- 2. Migração
UPDATE public.obra o
SET status = 'Não Iniciada'
WHERE o.status = 'Em Andamento'
  AND NOT EXISTS (
    SELECT 1 FROM public.orcamento orc
    WHERE orc.id_obra = o.id_obra AND orc.status = 'Aprovado'
  );

-- 3. Trava no banco
CREATE OR REPLACE FUNCTION public.validar_inicio_obra()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  -- O app reenvia o status em toda edição; só valida se ele mudou.
  IF TG_OP = 'UPDATE' AND NEW.status IS NOT DISTINCT FROM OLD.status THEN
    RETURN NEW;
  END IF;
  IF NEW.status IS NULL OR NEW.status = 'Não Iniciada' THEN
    RETURN NEW;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.orcamento orc
    WHERE orc.id_obra = NEW.id_obra AND orc.status = 'Aprovado'
  ) THEN
    RAISE EXCEPTION 'A obra só pode ser iniciada depois que um orçamento dela for Aprovado.'
      USING ERRCODE = 'check_violation';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_obra_inicia_com_orcamento_aprovado ON public.obra;
CREATE TRIGGER trg_obra_inicia_com_orcamento_aprovado
  BEFORE INSERT OR UPDATE OF status ON public.obra
  FOR EACH ROW
  EXECUTE FUNCTION public.validar_inicio_obra();

-- 4. Resultado: obras que voltaram para "Não Iniciada" nesta execução.
SELECT * FROM obras_revertidas_1_2;

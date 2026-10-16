-- ============================================================
-- RF011 — Receita/despesa ligada de verdade à obra
-- Execute este script no SQL Editor do Supabase Dashboard.
-- Rode DEPOIS do etapa_2_busca_com_filtro.sql. Seguro rodar duas vezes.
-- ============================================================
-- Antes, a transação guardava só o TÍTULO da obra (obra_titulo, texto):
-- duas obras com o mesmo título se misturavam e renomear a obra deixava
-- os lançamentos órfãos. Agora há o vínculo id_obra.
--
-- Decisões do Jan (15/10/2026):
--   * o vínculo é OPCIONAL (despesas gerais ficam sem obra);
--   * só obras "Em Andamento" ou "Concluída" recebem lançamentos
--     (DERS: obra em andamento; concluída para o pagamento final).
--
-- 1. Coluna id_obra (obra_titulo continua, só para exibição).
-- 2. Migração: liga os lançamentos antigos à obra cujo título bate
--    exatamente — só quando existe UMA obra com aquele título.
-- 3. Trava: ao gravar/trocar a obra do lançamento, ela precisa estar
--    Em Andamento ou Concluída; o título em cache é preenchido sozinho.
-- 4. Busca de obras para o campo do formulário (só esses dois status).
--
-- COMO DESFAZER:
--   DROP TRIGGER IF EXISTS trg_validar_obra_da_transacao ON public.transacao;
--   DROP FUNCTION IF EXISTS public.validar_obra_da_transacao();
--   DROP FUNCTION IF EXISTS public.buscar_obras_para_lancamento(TEXT, INT);
--   ALTER TABLE public.transacao DROP COLUMN IF EXISTS id_obra;
-- ============================================================

-- 1. Vínculo
ALTER TABLE public.transacao
  ADD COLUMN IF NOT EXISTS id_obra BIGINT REFERENCES public.obra(id_obra) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_transacao_id_obra ON public.transacao (id_obra);

-- 2. Migração (antes da trava, para não esbarrar nela)
DROP TRIGGER IF EXISTS trg_validar_obra_da_transacao ON public.transacao;

UPDATE public.transacao t
SET id_obra = o.id_obra
FROM public.obra o
WHERE t.id_obra IS NULL
  AND btrim(coalesce(t.obra_titulo, '')) <> ''
  AND lower(btrim(o.titulo_da_obra)) = lower(btrim(t.obra_titulo))
  AND (SELECT count(*) FROM public.obra o2
       WHERE lower(btrim(o2.titulo_da_obra)) = lower(btrim(t.obra_titulo))) = 1;

-- 3. Trava
CREATE OR REPLACE FUNCTION public.validar_obra_da_transacao()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_status TEXT;
  v_titulo TEXT;
BEGIN
  IF TG_OP = 'UPDATE' AND NEW.id_obra IS NOT DISTINCT FROM OLD.id_obra THEN
    RETURN NEW;
  END IF;
  IF NEW.id_obra IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT o.status, o.titulo_da_obra INTO v_status, v_titulo
  FROM public.obra o WHERE o.id_obra = NEW.id_obra;

  IF v_status IS NULL OR v_status NOT IN ('Em Andamento', 'Concluída') THEN
    RAISE EXCEPTION 'Só é possível lançar receita/despesa em obra Em Andamento ou Concluída.'
      USING ERRCODE = 'check_violation';
  END IF;

  NEW.obra_titulo := v_titulo;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_validar_obra_da_transacao
  BEFORE INSERT OR UPDATE OF id_obra ON public.transacao
  FOR EACH ROW
  EXECUTE FUNCTION public.validar_obra_da_transacao();

-- 4. Busca para o campo "Vincular à Obra" do lançamento
CREATE OR REPLACE FUNCTION public.buscar_obras_para_lancamento(termo TEXT DEFAULT '', limite INT DEFAULT 20)
RETURNS SETOF public.obra
LANGUAGE sql
STABLE
SET search_path = public, extensions
AS $$
  WITH p AS (SELECT public.padrao_busca(termo) AS pad)
  SELECT o.*
  FROM public.obra o, p
  WHERE o.status IN ('Em Andamento', 'Concluída')
    AND (btrim(coalesce(termo, '')) = ''
         OR lower(unaccent(coalesce(o.titulo_da_obra, ''))) LIKE p.pad
         OR lower(unaccent(coalesce(o.cliente_nome, '')))   LIKE p.pad)
  ORDER BY o.created_at DESC
  LIMIT greatest(coalesce(limite, 20), 1);
$$;

REVOKE EXECUTE ON FUNCTION public.buscar_obras_para_lancamento(TEXT, INT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.buscar_obras_para_lancamento(TEXT, INT) TO authenticated;

-- Resultado: lançamentos que citam uma obra pelo título mas NÃO puderam
-- ser ligados (título repetido ou obra renomeada/excluída). Dá para
-- ligá-los à mão editando o lançamento no app.
SELECT id_transacao, descricao, valor, obra_titulo
FROM public.transacao
WHERE id_obra IS NULL AND btrim(coalesce(obra_titulo, '')) <> ''
ORDER BY id_transacao;

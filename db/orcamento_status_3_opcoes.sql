-- ============================================================
-- Etapa 1 — Status do orçamento: só Pendente, Aprovado e Recusado
-- Execute este script no SQL Editor do Supabase Dashboard.
-- RODE ANTES do rf_item_1_2_obra_inicia_com_orcamento_aprovado.sql.
-- Seguro rodar duas vezes.
-- ============================================================
-- Migração dos dados existentes (decisão do Jan, 15/10/2026):
--   * "Rejeitado" (nome antigo) -> "Recusado"
--   * "Concluído"               -> "Aprovado" (só se conclui depois de
--     aprovado; quem conclui é a obra, não o orçamento)
--   * vazio/nulo                -> "Pendente"
-- Compara sem diferenciar maiúsculas/minúsculas para pegar variações.
--
-- COMO DESFAZER A TRAVA (os dados migrados não voltam sozinhos):
--   ALTER TABLE public.orcamento DROP CONSTRAINT IF EXISTS orcamento_status_valido;
-- ============================================================

UPDATE public.orcamento SET status = 'Recusado'
WHERE lower(btrim(status)) IN ('rejeitado', 'recusado') AND status <> 'Recusado';

UPDATE public.orcamento SET status = 'Aprovado'
WHERE lower(btrim(status)) IN ('concluído', 'concluido', 'aprovado') AND status <> 'Aprovado';

UPDATE public.orcamento SET status = 'Pendente'
WHERE status IS NULL OR (lower(btrim(status)) IN ('', 'pendente') AND status <> 'Pendente');

ALTER TABLE public.orcamento ALTER COLUMN status SET DEFAULT 'Pendente';
ALTER TABLE public.orcamento ALTER COLUMN status SET NOT NULL;

ALTER TABLE public.orcamento DROP CONSTRAINT IF EXISTS orcamento_status_valido;
ALTER TABLE public.orcamento
  ADD CONSTRAINT orcamento_status_valido
  CHECK (status IN ('Pendente', 'Aprovado', 'Recusado'));

-- Conferência: só podem aparecer Pendente, Aprovado e Recusado.
SELECT status, count(*) AS quantidade
FROM public.orcamento
GROUP BY status
ORDER BY status;

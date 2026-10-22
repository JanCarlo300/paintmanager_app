-- ============================================================
-- DIAGNÓSTICO (só leitura) — por que uma obra entra ou não no
-- Relatório de Progresso do MÊS ATUAL ("Este Mês")
-- Execute no SQL Editor do Supabase. Não altera nada.
-- ============================================================
-- Regra do app (pdf_relatorios.dart):
--   * Não Iniciada  -> não entra no progresso; vai para "Obras a iniciar"
--                      se foi cadastrada até o fim do período;
--   * começou depois do fim do período -> fica de fora;
--   * Em Andamento / Pausada -> entra;
--   * Concluída -> entra se terminou do INÍCIO do período em diante.
--     "Terminou" = data_conclusao; se estiver vazia, usa a previsão de término.
-- ============================================================

WITH periodo AS (
  SELECT date_trunc('month', current_date)::date AS inicio,
         (date_trunc('month', current_date) + interval '1 month - 1 day')::date AS fim
)
SELECT
  o.id_obra,
  o.titulo_da_obra,
  o.status,
  o.data_inicio,
  o.data_previsao_termino,
  o.data_conclusao,
  o.created_at::date AS cadastrada_em,
  CASE
    WHEN o.status = 'Não Iniciada' AND o.created_at::date <= p.fim THEN 'entra em "Obras a iniciar"'
    WHEN o.status = 'Não Iniciada' THEN 'fora: cadastrada depois do período'
    WHEN o.data_inicio > p.fim THEN 'fora: começa depois do fim do período'
    WHEN o.status = 'Concluída' AND o.data_conclusao IS NULL
         AND o.data_previsao_termino < p.inicio
      THEN 'fora: concluída SEM data de conclusão e previsão de término antes do período'
    WHEN o.status = 'Concluída' AND o.data_conclusao < p.inicio
      THEN 'fora: concluída antes do início do período'
    ELSE 'entra no progresso'
  END AS no_relatorio_do_mes
FROM public.obra o CROSS JOIN periodo p
ORDER BY no_relatorio_do_mes, o.status, o.titulo_da_obra;

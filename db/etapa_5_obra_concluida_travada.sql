-- ============================================================
-- Etapa 5 — Obra concluída fica travada
-- Execute este script no SQL Editor do Supabase Dashboard.
-- Seguro rodar duas vezes.
-- ============================================================
-- Regras (decisão do Jan, 15/10/2026):
--   * concluir com etapas pendentes marca todas como concluídas
--     (o app pede confirmação antes);
--   * concluída é DEFINITIVA: status e etapas não mudam mais, para
--     ninguém (nem Administrador).
--
-- 1. Migração: obras já "Concluída" com etapa pendente ou progresso
--    abaixo de 100% (ex.: a obra que ficou em 80%) passam a ter todas
--    as etapas concluídas e progresso 100%.
-- 2. Trava: trigger que recusa mudar status, etapas ou progresso de
--    uma obra concluída. Os outros dados (título, endereço, prazos,
--    materiais) continuam editáveis.
--
-- COMO DESFAZER A TRAVA (a migração não volta sozinha):
--   DROP TRIGGER IF EXISTS trg_proteger_obra_concluida ON public.obra;
--   DROP FUNCTION IF EXISTS public.proteger_obra_concluida();
--   DROP FUNCTION IF EXISTS public.normalizar_etapas(JSONB);
-- ============================================================

-- Compara etapas só pelo que importa (nome e concluída), ignorando ordem
-- das chaves e campos extras que versões antigas possam ter gravado.
CREATE OR REPLACE FUNCTION public.normalizar_etapas(etapas JSONB)
RETURNS JSONB
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT coalesce(
    jsonb_agg(
      jsonb_build_object(
        'nome', e.valor->>'nome',
        'concluida', coalesce((e.valor->>'concluida')::boolean, false)
      )
      ORDER BY e.ordem
    ),
    '[]'::jsonb
  )
  FROM jsonb_array_elements(coalesce(etapas, '[]'::jsonb)) WITH ORDINALITY AS e(valor, ordem);
$$;

-- 1. Migração (roda antes da trava, senão a própria trava a recusaria)
DROP TRIGGER IF EXISTS trg_proteger_obra_concluida ON public.obra;

DROP TABLE IF EXISTS obras_corrigidas_etapa_5;
CREATE TEMP TABLE obras_corrigidas_etapa_5 AS
SELECT id_obra, titulo_da_obra, progresso AS progresso_antes
FROM public.obra o
WHERE o.status = 'Concluída'
  AND (o.progresso < 100
       OR EXISTS (
         SELECT 1 FROM jsonb_array_elements(coalesce(o.etapas_servico, '[]'::jsonb)) e
         WHERE coalesce((e->>'concluida')::boolean, false) = false
       ));

UPDATE public.obra o
SET etapas_servico = (
      SELECT coalesce(
        jsonb_agg(e.valor || jsonb_build_object('concluida', true) ORDER BY e.ordem),
        '[]'::jsonb
      )
      FROM jsonb_array_elements(coalesce(o.etapas_servico, '[]'::jsonb))
           WITH ORDINALITY AS e(valor, ordem)
    ),
    progresso = 100
WHERE o.id_obra IN (SELECT id_obra FROM obras_corrigidas_etapa_5);

-- 2. Trava
CREATE OR REPLACE FUNCTION public.proteger_obra_concluida()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF OLD.status = 'Concluída' THEN
    IF NEW.status IS DISTINCT FROM OLD.status THEN
      RAISE EXCEPTION 'Obra concluída: o status não pode mais ser alterado.'
        USING ERRCODE = 'check_violation';
    END IF;
    IF public.normalizar_etapas(NEW.etapas_servico) IS DISTINCT FROM public.normalizar_etapas(OLD.etapas_servico)
       OR NEW.progresso IS DISTINCT FROM OLD.progresso THEN
      RAISE EXCEPTION 'Obra concluída: etapas bloqueadas.'
        USING ERRCODE = 'check_violation';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_proteger_obra_concluida
  BEFORE UPDATE ON public.obra
  FOR EACH ROW
  EXECUTE FUNCTION public.proteger_obra_concluida();

-- Resultado: obras concluídas que foram corrigidas para 100% nesta execução.
SELECT * FROM obras_corrigidas_etapa_5;

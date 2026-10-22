-- ============================================================
-- Diagnóstico (SOMENTE LEITURA) — tabelas antigas
-- etapas, financeiro, material, observacao
-- Execute no SQL Editor do Supabase e mande o resultado.
-- ============================================================
-- Lista tudo FORA dessas 4 tabelas que dependa delas: chaves
-- estrangeiras, views, funções e políticas RLS. Resultado vazio =
-- nada depende delas e a exclusão é segura.
-- A última coluna mostra quantas linhas cada tabela antiga tem.
-- ============================================================

WITH antigas(nome) AS (
  VALUES ('etapas'), ('financeiro'), ('material'), ('observacao')
)
SELECT 'chave estrangeira' AS tipo,
       c.conrelid::regclass::text AS objeto,
       c.confrelid::regclass::text AS tabela_antiga
FROM pg_constraint c
WHERE c.contype = 'f'
  AND c.confrelid::regclass::text IN (SELECT nome FROM antigas)
  AND c.conrelid::regclass::text NOT IN (SELECT nome FROM antigas)

UNION ALL
SELECT DISTINCT 'view', v.relname::text, t.relname::text
FROM pg_depend d
JOIN pg_rewrite r ON r.oid = d.objid
JOIN pg_class v ON v.oid = r.ev_class
JOIN pg_class t ON t.oid = d.refobjid
WHERE t.relname IN (SELECT nome FROM antigas)
  AND v.relname <> t.relname

UNION ALL
SELECT 'função', p.proname::text, a.nome
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
CROSS JOIN antigas a
WHERE n.nspname = 'public'
  AND p.prosrc ~* ('\m' || a.nome || '\M')

UNION ALL
SELECT 'política RLS', pol.polname || ' (em ' || pol.polrelid::regclass::text || ')', a.nome
FROM pg_policy pol
CROSS JOIN antigas a
WHERE pol.polrelid::regclass::text NOT IN (SELECT nome FROM antigas)
  AND (coalesce(pg_get_expr(pol.polqual, pol.polrelid), '') || ' ' ||
       coalesce(pg_get_expr(pol.polwithcheck, pol.polrelid), ''))
      ~* ('\m' || a.nome || '\M')

UNION ALL
SELECT 'linhas na tabela', 'etapas',     (SELECT count(*) FROM public.etapas)::text
UNION ALL
SELECT 'linhas na tabela', 'financeiro', (SELECT count(*) FROM public.financeiro)::text
UNION ALL
SELECT 'linhas na tabela', 'material',   (SELECT count(*) FROM public.material)::text
UNION ALL
SELECT 'linhas na tabela', 'observacao', (SELECT count(*) FROM public.observacao)::text;

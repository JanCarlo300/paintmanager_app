-- ============================================================
-- Diagnóstico (SOMENTE LEITURA) — sobras do modelo do TFC I
-- Execute no SQL Editor do Supabase e mande o resultado.
-- ============================================================
-- 1. Tabela 'funcionario': o app não a usa (funcionário é um registro
--    de 'usuario' com função "Funcionário"). Lista o que depende dela
--    e quantas linhas tem.
-- 2. Colunas de 'orcamento' que o app NÃO usa — entre elas está a
--    coluna que apontava para a tabela 'etapas' (já apagada).
-- Nada é alterado.
-- ============================================================

SELECT 'funcionario: linhas' AS tipo,
       (SELECT count(*) FROM public.funcionario)::text AS detalhe

UNION ALL
SELECT 'funcionario: chave estrangeira em',
       c.conrelid::regclass::text || ' (' || c.conname || ')'
FROM pg_constraint c
WHERE c.contype = 'f'
  AND c.confrelid = 'public.funcionario'::regclass
  AND c.conrelid <> 'public.funcionario'::regclass

UNION ALL
SELECT DISTINCT 'funcionario: view', v.relname::text
FROM pg_depend d
JOIN pg_rewrite r ON r.oid = d.objid
JOIN pg_class v ON v.oid = r.ev_class
WHERE d.refobjid = 'public.funcionario'::regclass
  AND v.relname <> 'funcionario'

UNION ALL
SELECT 'funcionario: função', p.proname::text
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public' AND p.prosrc ~* '\mfuncionario\M'

UNION ALL
SELECT 'orcamento: coluna não usada pelo app',
       column_name || ' (' || data_type || ', '
         || (SELECT count(*) FROM public.orcamento)::text || ' orçamentos)'
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'orcamento'
  AND column_name NOT IN (
    'id_orcamento', 'id_obra', 'cliente_nome', 'descricao', 'data_criacao',
    'data_validade', 'status', 'itens_servico', 'material_incluso',
    'valor_material', 'valor_mao_obra', 'valor_desconto', 'valor_total',
    'forma_pagamento', 'created_at', 'updated_at'
  );

-- ============================================================
-- Limpeza — exclui as tabelas antigas do modelo do TFC I
-- etapas, financeiro, material, observacao
-- Execute no SQL Editor do Supabase Dashboard.
-- Seguro rodar duas vezes.
-- ============================================================
-- Base da decisão (diagnostico_tabelas_antigas.sql, 15/10/2026):
--   * o app não lê nem grava nessas tabelas (o Financeiro usa 'transacao');
--   * nenhuma view, função ou política RLS depende delas;
--   * as 4 estão vazias (0 linhas);
--   * única dependência: uma chave estrangeira em 'orcamento' que
--     aponta para 'etapas'. Só a chave é removida; a tabela e os
--     orçamentos continuam intactos.
--
-- TRAVA: se alguma das 4 tabelas tiver linhas, o script PARA sem
-- apagar nada (aí é preciso decidir o que fazer com os dados).
--
-- O DROP abaixo NÃO usa CASCADE de propósito: se aparecer alguma
-- dependência que o diagnóstico não viu, o banco recusa em vez de
-- apagar junto.
--
-- COMO DESFAZER: só recriando as tabelas vazias a partir do DER do
-- TFC I; como estavam vazias, não há dados a restaurar.
-- ============================================================

DO $$
DECLARE
  total BIGINT := 0;
  t     TEXT;
  qtd   BIGINT;
BEGIN
  FOREACH t IN ARRAY ARRAY['etapas', 'financeiro', 'material', 'observacao'] LOOP
    IF to_regclass('public.' || t) IS NOT NULL THEN
      EXECUTE format('SELECT count(*) FROM public.%I', t) INTO qtd;
      total := total + qtd;
    END IF;
  END LOOP;

  IF total > 0 THEN
    RAISE EXCEPTION 'Abortado: as tabelas antigas têm % linha(s). Nada foi apagado.', total;
  END IF;
END $$;

-- Guarda o nome da coluna de 'orcamento' que apontava para 'etapas',
-- para conferir se sobrou coluna órfã (ver consulta final).
DROP TABLE IF EXISTS fk_removidas_limpeza;
CREATE TEMP TABLE fk_removidas_limpeza AS
SELECT c.conname::text AS constraint_removida,
       a.attname::text AS coluna_em_orcamento
FROM pg_constraint c
JOIN pg_attribute a
  ON a.attrelid = c.conrelid AND a.attnum = ANY (c.conkey)
WHERE c.contype = 'f'
  AND c.conrelid = 'public.orcamento'::regclass
  AND c.confrelid = to_regclass('public.etapas');

DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN
    SELECT constraint_removida FROM fk_removidas_limpeza
  LOOP
    EXECUTE format('ALTER TABLE public.orcamento DROP CONSTRAINT %I', r.constraint_removida);
  END LOOP;
END $$;

DROP TABLE IF EXISTS public.etapas;
DROP TABLE IF EXISTS public.financeiro;
DROP TABLE IF EXISTS public.material;
DROP TABLE IF EXISTS public.observacao;

-- Conferência 1: o que foi removido de 'orcamento' (se a tabela
-- ficar vazia, a chave já não existia). 'coluna_em_orcamento' é a
-- coluna que ficou sem uso: me diga o nome para eu avaliar se ela
-- também pode sair.
SELECT * FROM fk_removidas_limpeza;

-- Conferência 2: tabelas que restaram em 'public' (devem ser só as
-- do app: cliente, equipe_obra, obra, obra_mensagem, orcamento,
-- transacao, usuario).
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
ORDER BY table_name;

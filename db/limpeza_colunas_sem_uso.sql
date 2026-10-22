-- ============================================================
-- Limpeza: colunas sem uso em 'obra' e 'transacao'
-- Execute no SQL Editor do Supabase Dashboard. Seguro rodar duas vezes.
-- Tudo roda numa TRANSAÇÃO: se der qualquer erro, nada muda.
--
-- ORDEM: instale PRIMEIRO o app novo (ele não usa mais estas colunas) e só
-- depois rode este script. Com o app antigo, salvar obra/lançamento daria erro.
-- ============================================================
-- O QUE SAI (levantado em 22/10/2026):
--   obra.anotacoes            1 obra com texto — JÁ migrado para o chat como
--                             "Observação importada" (rf_item_2_3_chat_obra.sql);
--                             o texto vai para a tabela de backup antes.
--   obra.id_orcamento         vazia; o vínculo certo é orcamento.id_obra.
--   obra.data_fim             vazia; criada à mão, nunca usada pelo app.
--   transacao.comprovante_url vazia; o anexo de comprovante nunca foi feito.
--   transacao.id_orcamento    vazia; o lançamento se liga à obra (id_obra).
--
-- TRAVA: se alguma coluna (fora 'anotacoes') tiver dado, o script PARA sem
-- apagar nada. O DROP não usa CASCADE: se algo depender da coluna, o banco
-- recusa e nada muda.
--
-- COMO DESFAZER: recriar as colunas e devolver o texto do backup:
--   ALTER TABLE public.obra ADD COLUMN anotacoes TEXT;
--   UPDATE public.obra o SET anotacoes = b.valor
--     FROM public.backup_colunas_removidas b
--    WHERE b.tabela = 'obra' AND b.coluna = 'anotacoes' AND b.id = o.id_obra;
--   (as outras colunas estavam vazias: basta recriá-las com ADD COLUMN)
-- ============================================================

BEGIN;

-- 1. Backup do que tiver conteúdo (só leitura para o Administrador).
CREATE TABLE IF NOT EXISTS public.backup_colunas_removidas (
  tabela      TEXT        NOT NULL,
  id          BIGINT      NOT NULL,
  coluna      TEXT        NOT NULL,
  valor       TEXT,
  copiado_em  TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (tabela, id, coluna)
);
ALTER TABLE public.backup_colunas_removidas ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "backup: admin le" ON public.backup_colunas_removidas;
CREATE POLICY "backup: admin le" ON public.backup_colunas_removidas
  FOR SELECT USING (public.eh_admin());

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_schema = 'public' AND table_name = 'obra' AND column_name = 'anotacoes') THEN
    EXECUTE $q$
      INSERT INTO public.backup_colunas_removidas (tabela, id, coluna, valor)
      SELECT 'obra', id_obra, 'anotacoes', anotacoes
      FROM public.obra
      WHERE anotacoes IS NOT NULL AND btrim(anotacoes) <> ''
      ON CONFLICT (tabela, id, coluna) DO NOTHING
    $q$;
  END IF;
END $$;

-- 2. Trava: as outras colunas precisam estar vazias.
DO $$
DECLARE
  alvo   RECORD;
  linhas BIGINT;
BEGIN
  FOR alvo IN
    SELECT * FROM (VALUES
      ('obra', 'id_orcamento'), ('obra', 'data_fim'),
      ('transacao', 'comprovante_url'), ('transacao', 'id_orcamento')
    ) AS t(tabela, coluna)
  LOOP
    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_schema = 'public' AND table_name = alvo.tabela AND column_name = alvo.coluna) THEN
      EXECUTE format(
        'SELECT count(*) FROM public.%I WHERE %I IS NOT NULL AND %I::text <> %L',
        alvo.tabela, alvo.coluna, alvo.coluna, '')
        INTO linhas;
      IF linhas > 0 THEN
        RAISE EXCEPTION 'Abortado: %.% tem % linha(s) com dado. Nada foi apagado.',
          alvo.tabela, alvo.coluna, linhas;
      END IF;
    END IF;
  END LOOP;
END $$;

-- 3. Remove as colunas.
ALTER TABLE public.obra      DROP COLUMN IF EXISTS anotacoes;
ALTER TABLE public.obra      DROP COLUMN IF EXISTS id_orcamento;
ALTER TABLE public.obra      DROP COLUMN IF EXISTS data_fim;
ALTER TABLE public.transacao DROP COLUMN IF EXISTS comprovante_url;
ALTER TABLE public.transacao DROP COLUMN IF EXISTS id_orcamento;

COMMIT;

-- 4. Conferência (um resultado só): colunas que restaram nas duas tabelas
--    e o que foi para o backup.
SELECT 'coluna ' || table_name AS tipo, column_name::text AS nome
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name IN ('obra', 'transacao')
UNION ALL
SELECT 'backup', tabela || '.' || coluna || ' (id ' || id || ')'
FROM public.backup_colunas_removidas
ORDER BY tipo, nome;

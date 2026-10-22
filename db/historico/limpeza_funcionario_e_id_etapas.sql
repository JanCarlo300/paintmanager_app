-- ============================================================
-- Limpeza (parte 2) — últimas sobras do modelo do TFC I
--   * tabela 'funcionario'
--   * coluna 'orcamento.id_etapas'
-- Execute no SQL Editor do Supabase Dashboard. Seguro rodar duas vezes.
-- ============================================================
-- Base da decisão (diagnostico_funcionario_e_orcamento.sql, 15/10/2026):
--   * 'funcionario' tem 0 linhas e nada depende dela; o app não a usa
--     (funcionário é um registro de 'usuario' com função "Funcionário");
--   * 'id_etapas' é a única coluna de 'orcamento' que o app não usa;
--     apontava para a tabela 'etapas', que estava vazia e já foi apagada.
--
-- TRAVA: o script PARA sem apagar nada se 'funcionario' tiver linhas ou
-- se algum orçamento tiver 'id_etapas' preenchido.
-- O DROP não usa CASCADE: se surgir dependência, o banco recusa.
--
-- COMO DESFAZER: as duas estavam vazias, não há dados a restaurar;
-- recriar só pela estrutura do DER do TFC I, se um dia for preciso.
-- ============================================================

DO $$
DECLARE
  linhas_funcionario BIGINT := 0;
  orcamentos_com_etapa BIGINT := 0;
BEGIN
  IF to_regclass('public.funcionario') IS NOT NULL THEN
    SELECT count(*) INTO linhas_funcionario FROM public.funcionario;
  END IF;

  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_schema = 'public' AND table_name = 'orcamento'
               AND column_name = 'id_etapas') THEN
    EXECUTE 'SELECT count(*) FROM public.orcamento WHERE id_etapas IS NOT NULL'
      INTO orcamentos_com_etapa;
  END IF;

  IF linhas_funcionario > 0 OR orcamentos_com_etapa > 0 THEN
    RAISE EXCEPTION 'Abortado: funcionario tem % linha(s) e % orçamento(s) têm id_etapas preenchido. Nada foi apagado.',
      linhas_funcionario, orcamentos_com_etapa;
  END IF;
END $$;

ALTER TABLE public.orcamento DROP COLUMN IF EXISTS id_etapas;
DROP TABLE IF EXISTS public.funcionario;

-- Conferência (um resultado só):
--   * "tabela": devem sobrar só as do app — chat_leitura, cliente,
--     equipe_obra, obra, obra_mensagem, orcamento, transacao, usuario;
--   * "orcamento: coluna não usada pelo app": não deve aparecer nenhuma.
SELECT 'tabela' AS tipo, table_name::text AS nome
FROM information_schema.tables
WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
UNION ALL
SELECT 'orcamento: coluna não usada pelo app', column_name::text
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'orcamento'
  AND column_name NOT IN (
    'id_orcamento', 'id_obra', 'cliente_nome', 'descricao', 'data_criacao',
    'data_validade', 'status', 'itens_servico', 'material_incluso',
    'valor_material', 'valor_mao_obra', 'valor_desconto', 'valor_total',
    'forma_pagamento', 'created_at', 'updated_at'
  )
ORDER BY tipo, nome;

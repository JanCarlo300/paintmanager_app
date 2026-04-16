-- ============================================================
-- MIGRAÇÃO PAINTMANAGER — Tabela 'orcamento' + FK para 'obra' + RLS
-- Execute este script no SQL Editor do Supabase Dashboard.
-- Pré-requisito: tabela 'obra' já criada (supabase_migrate_obra.sql).
-- ============================================================

-- 1. CRIAR TABELA
CREATE TABLE IF NOT EXISTS public.orcamento (
  id_orcamento           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  id_obra                BIGINT                REFERENCES public.obra(id_obra) ON DELETE CASCADE,
  cliente_nome           VARCHAR(255)          DEFAULT '',               -- cache desnormalizado para exibição rápida
  descricao              TEXT                  NOT NULL DEFAULT '',
  data_criacao           DATE                  NOT NULL DEFAULT CURRENT_DATE,
  data_validade          DATE                  NOT NULL DEFAULT (CURRENT_DATE + INTERVAL '30 days'),
  status                 VARCHAR(30)           DEFAULT 'Pendente',       -- Pendente | Aprovado | Rejeitado | Concluído
  itens_servico          JSONB                 DEFAULT '[]'::jsonb,      -- [{descricao, metragem, valor_unitario, subtotal}]
  material_incluso       BOOLEAN               DEFAULT false,
  valor_material         DOUBLE PRECISION      DEFAULT 0,
  valor_mao_obra         DOUBLE PRECISION      DEFAULT 0,
  valor_desconto         DOUBLE PRECISION      DEFAULT 0,
  valor_total            DOUBLE PRECISION      DEFAULT 0,
  forma_pagamento        VARCHAR(50)           DEFAULT 'PIX',
  created_at             TIMESTAMPTZ           DEFAULT now(),
  updated_at             TIMESTAMPTZ           DEFAULT now()
);

-- 2. ÍNDICES
CREATE INDEX IF NOT EXISTS idx_orcamento_id_obra   ON public.orcamento (id_obra);
CREATE INDEX IF NOT EXISTS idx_orcamento_status    ON public.orcamento (status);
CREATE INDEX IF NOT EXISTS idx_orcamento_data      ON public.orcamento (data_criacao DESC);

-- 3. TRIGGER para atualizar updated_at automaticamente
-- (reutiliza a function 'atualizar_updated_at' criada na migração de clientes)
DROP TRIGGER IF EXISTS trg_orcamento_updated_at ON public.orcamento;
CREATE TRIGGER trg_orcamento_updated_at
  BEFORE UPDATE ON public.orcamento
  FOR EACH ROW
  EXECUTE FUNCTION public.atualizar_updated_at();

-- 4. HABILITAR ROW LEVEL SECURITY
ALTER TABLE public.orcamento ENABLE ROW LEVEL SECURITY;

-- 5. POLÍTICAS RLS — Apenas usuários autenticados
-- SELECT
DROP POLICY IF EXISTS "Autenticados podem ler orcamentos" ON public.orcamento;
CREATE POLICY "Autenticados podem ler orcamentos"
  ON public.orcamento
  FOR SELECT
  USING (auth.role() = 'authenticated');

-- INSERT
DROP POLICY IF EXISTS "Autenticados podem inserir orcamentos" ON public.orcamento;
CREATE POLICY "Autenticados podem inserir orcamentos"
  ON public.orcamento
  FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

-- UPDATE
DROP POLICY IF EXISTS "Autenticados podem atualizar orcamentos" ON public.orcamento;
CREATE POLICY "Autenticados podem atualizar orcamentos"
  ON public.orcamento
  FOR UPDATE
  USING (auth.role() = 'authenticated');

-- DELETE
DROP POLICY IF EXISTS "Autenticados podem excluir orcamentos" ON public.orcamento;
CREATE POLICY "Autenticados podem excluir orcamentos"
  ON public.orcamento
  FOR DELETE
  USING (auth.role() = 'authenticated');

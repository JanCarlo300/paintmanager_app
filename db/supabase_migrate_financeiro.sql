-- ============================================================
-- MIGRAÇÃO PAINTMANAGER — Tabela 'transacao' + FKs + RLS
-- Execute este script no SQL Editor do Supabase Dashboard.
-- Pré-requisitos: tabelas 'cliente' e 'orcamento' já criadas.
-- ============================================================

-- 0. FUNÇÃO AUXILIAR (idempotente — CREATE OR REPLACE não quebra se já existir)
CREATE OR REPLACE FUNCTION public.atualizar_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 1. CRIAR TABELA
CREATE TABLE IF NOT EXISTS public.transacao (
  id_transacao        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  descricao           TEXT                  NOT NULL DEFAULT '',
  tipo                VARCHAR(20)           NOT NULL DEFAULT 'Despesa',         -- Receita | Despesa
  categoria           VARCHAR(50)           DEFAULT 'Outros',                   -- Mão de Obra | Materiais | Ferramentas | Transporte | Alimentação | Outros
  valor               DOUBLE PRECISION      NOT NULL DEFAULT 0,
  data_transacao      DATE                  NOT NULL DEFAULT CURRENT_DATE,
  status              VARCHAR(20)           DEFAULT 'Efetivado',               -- Efetivado | Pendente | Atrasado
  forma_pagamento     VARCHAR(30)           DEFAULT 'PIX',                     -- PIX | Cartão de Crédito | Dinheiro | Boleto
  id_cliente          BIGINT                REFERENCES public.cliente(id_cliente) ON DELETE SET NULL,
  id_orcamento        BIGINT                REFERENCES public.orcamento(id_orcamento) ON DELETE SET NULL,
  cliente_nome        VARCHAR(255)          DEFAULT '',                         -- cache desnormalizado para exibição rápida
  obra_titulo         VARCHAR(255)          DEFAULT '',                         -- cache desnormalizado para exibição rápida
  comprovante_url     TEXT                  DEFAULT '',
  created_at          TIMESTAMPTZ           DEFAULT now(),
  updated_at          TIMESTAMPTZ           DEFAULT now()
);

-- 2. ÍNDICES
CREATE INDEX IF NOT EXISTS idx_transacao_tipo           ON public.transacao (tipo);
CREATE INDEX IF NOT EXISTS idx_transacao_data           ON public.transacao (data_transacao DESC);
CREATE INDEX IF NOT EXISTS idx_transacao_status         ON public.transacao (status);
CREATE INDEX IF NOT EXISTS idx_transacao_id_cliente     ON public.transacao (id_cliente);
CREATE INDEX IF NOT EXISTS idx_transacao_id_orcamento   ON public.transacao (id_orcamento);

-- 3. TRIGGER para atualizar updated_at automaticamente
-- (reutiliza a function 'atualizar_updated_at' criada na migração de clientes)
DROP TRIGGER IF EXISTS trg_transacao_updated_at ON public.transacao;
CREATE TRIGGER trg_transacao_updated_at
  BEFORE UPDATE ON public.transacao
  FOR EACH ROW
  EXECUTE FUNCTION public.atualizar_updated_at();

-- 4. HABILITAR ROW LEVEL SECURITY
ALTER TABLE public.transacao ENABLE ROW LEVEL SECURITY;

-- 5. POLÍTICAS RLS — Apenas usuários autenticados
-- SELECT
DROP POLICY IF EXISTS "Autenticados podem ler transacoes" ON public.transacao;
CREATE POLICY "Autenticados podem ler transacoes"
  ON public.transacao
  FOR SELECT
  USING (auth.role() = 'authenticated');

-- INSERT
DROP POLICY IF EXISTS "Autenticados podem inserir transacoes" ON public.transacao;
CREATE POLICY "Autenticados podem inserir transacoes"
  ON public.transacao
  FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

-- UPDATE
DROP POLICY IF EXISTS "Autenticados podem atualizar transacoes" ON public.transacao;
CREATE POLICY "Autenticados podem atualizar transacoes"
  ON public.transacao
  FOR UPDATE
  USING (auth.role() = 'authenticated');

-- DELETE
DROP POLICY IF EXISTS "Autenticados podem excluir transacoes" ON public.transacao;
CREATE POLICY "Autenticados podem excluir transacoes"
  ON public.transacao
  FOR DELETE
  USING (auth.role() = 'authenticated');

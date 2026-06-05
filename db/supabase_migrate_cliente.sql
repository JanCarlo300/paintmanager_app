-- ============================================================
-- MIGRAÇÃO PAINTMANAGER — Tabela 'cliente' + RLS
-- Execute este script no SQL Editor do Supabase Dashboard.
-- ============================================================

-- 1. CRIAR TABELA (caso não exista)
CREATE TABLE IF NOT EXISTS public.cliente (
  id_cliente   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nome         VARCHAR(255) NOT NULL,
  email        VARCHAR(255) DEFAULT '',
  telefone     VARCHAR(30)  DEFAULT '',
  cpf_cnpj     VARCHAR(20)  DEFAULT '',
  endereco     TEXT         DEFAULT '',
  status       BOOLEAN      DEFAULT true,
  created_at   TIMESTAMPTZ  DEFAULT now(),
  updated_at   TIMESTAMPTZ  DEFAULT now()
);

-- 2. ÍNDICE para buscas por nome (ordenação padrão do app)
CREATE INDEX IF NOT EXISTS idx_cliente_nome ON public.cliente (nome);

-- 3. TRIGGER para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION public.atualizar_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Remove trigger anterior caso exista, para evitar duplicação
DROP TRIGGER IF EXISTS trg_cliente_updated_at ON public.cliente;
CREATE TRIGGER trg_cliente_updated_at
  BEFORE UPDATE ON public.cliente
  FOR EACH ROW
  EXECUTE FUNCTION public.atualizar_updated_at();

-- 4. HABILITAR ROW LEVEL SECURITY
ALTER TABLE public.cliente ENABLE ROW LEVEL SECURITY;

-- 5. POLÍTICAS RLS — Apenas usuários autenticados
-- SELECT
DROP POLICY IF EXISTS "Autenticados podem ler clientes" ON public.cliente;
CREATE POLICY "Autenticados podem ler clientes"
  ON public.cliente
  FOR SELECT
  USING (auth.role() = 'authenticated');

-- INSERT
DROP POLICY IF EXISTS "Autenticados podem inserir clientes" ON public.cliente;
CREATE POLICY "Autenticados podem inserir clientes"
  ON public.cliente
  FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

-- UPDATE
DROP POLICY IF EXISTS "Autenticados podem atualizar clientes" ON public.cliente;
CREATE POLICY "Autenticados podem atualizar clientes"
  ON public.cliente
  FOR UPDATE
  USING (auth.role() = 'authenticated');

-- DELETE
DROP POLICY IF EXISTS "Autenticados podem excluir clientes" ON public.cliente;
CREATE POLICY "Autenticados podem excluir clientes"
  ON public.cliente
  FOR DELETE
  USING (auth.role() = 'authenticated');

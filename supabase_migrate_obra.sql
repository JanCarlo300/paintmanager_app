-- ============================================================
-- MIGRAÇÃO PAINTMANAGER — Tabela 'obra' + FK para 'cliente' + RLS
-- Execute este script no SQL Editor do Supabase Dashboard.
-- ============================================================

-- 1. CRIAR TABELA (caso não exista)
CREATE TABLE IF NOT EXISTS public.obra (
  id_obra                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  id_cliente             BIGINT NOT NULL REFERENCES public.cliente(id_cliente) ON DELETE RESTRICT,
  id_orcamento           BIGINT,                          -- FK futura para tabela orcamento
  titulo_da_obra         VARCHAR(255)  NOT NULL,
  endereco               TEXT          DEFAULT '',
  data_inicio            DATE          NOT NULL DEFAULT CURRENT_DATE,
  data_previsao_termino  DATE,
  data_conclusao         DATE,
  status                 VARCHAR(30)   DEFAULT 'Não Iniciada',   -- Não Iniciada | Em Andamento | Pausada | Concluída
  progresso              NUMERIC(5,2)  DEFAULT 0,                -- 0.00 a 100.00
  cliente_nome           VARCHAR(255)  DEFAULT '',               -- cache desnormalizado para exibição rápida
  etapas_servico         JSONB         DEFAULT '[]'::jsonb,      -- [{nome, concluida}]
  anotacoes              TEXT          DEFAULT '',
  materiais_faltantes    JSONB         DEFAULT '[]'::jsonb,      -- ["item1", "item2"]
  created_at             TIMESTAMPTZ   DEFAULT now(),
  updated_at             TIMESTAMPTZ   DEFAULT now()
);

-- 2. ÍNDICES
CREATE INDEX IF NOT EXISTS idx_obra_id_cliente ON public.obra (id_cliente);
CREATE INDEX IF NOT EXISTS idx_obra_status     ON public.obra (status);
CREATE INDEX IF NOT EXISTS idx_obra_data_inicio ON public.obra (data_inicio DESC);

-- 3. TRIGGER para atualizar updated_at automaticamente
-- (reutiliza a function 'atualizar_updated_at' criada na migração de clientes)
DROP TRIGGER IF EXISTS trg_obra_updated_at ON public.obra;
CREATE TRIGGER trg_obra_updated_at
  BEFORE UPDATE ON public.obra
  FOR EACH ROW
  EXECUTE FUNCTION public.atualizar_updated_at();

-- 4. HABILITAR ROW LEVEL SECURITY
ALTER TABLE public.obra ENABLE ROW LEVEL SECURITY;

-- 5. POLÍTICAS RLS — Apenas usuários autenticados
-- SELECT
DROP POLICY IF EXISTS "Autenticados podem ler obras" ON public.obra;
CREATE POLICY "Autenticados podem ler obras"
  ON public.obra
  FOR SELECT
  USING (auth.role() = 'authenticated');

-- INSERT
DROP POLICY IF EXISTS "Autenticados podem inserir obras" ON public.obra;
CREATE POLICY "Autenticados podem inserir obras"
  ON public.obra
  FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

-- UPDATE
DROP POLICY IF EXISTS "Autenticados podem atualizar obras" ON public.obra;
CREATE POLICY "Autenticados podem atualizar obras"
  ON public.obra
  FOR UPDATE
  USING (auth.role() = 'authenticated');

-- DELETE
DROP POLICY IF EXISTS "Autenticados podem excluir obras" ON public.obra;
CREATE POLICY "Autenticados podem excluir obras"
  ON public.obra
  FOR DELETE
  USING (auth.role() = 'authenticated');

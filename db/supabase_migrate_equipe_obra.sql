-- ============================================================
-- MIGRAÇÃO PAINTMANAGER — RF010: Alocar Equipe à Obra
-- Execute este script no SQL Editor do Supabase Dashboard.
-- ============================================================

-- 1. CRIAR TABELA (caso não exista)
-- Relação muitos-para-muitos entre obra e usuario (funcionários alocados).
CREATE TABLE IF NOT EXISTS public.equipe_obra (
  id_equipe_obra  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  obra_id         BIGINT NOT NULL REFERENCES public.obra(id_obra) ON DELETE CASCADE,
  usuario_id      BIGINT NOT NULL REFERENCES public.usuario(id_usuario) ON DELETE CASCADE,
  criado_em       TIMESTAMPTZ DEFAULT now(),
  UNIQUE (obra_id, usuario_id)
);

-- 2. ÍNDICES
CREATE INDEX IF NOT EXISTS idx_equipe_obra_obra_id ON public.equipe_obra (obra_id);
CREATE INDEX IF NOT EXISTS idx_equipe_obra_usuario_id ON public.equipe_obra (usuario_id);

-- 3. HABILITAR ROW LEVEL SECURITY
ALTER TABLE public.equipe_obra ENABLE ROW LEVEL SECURITY;

-- 4. POLÍTICAS — mesmo padrão das outras tabelas do projeto:
--    qualquer usuário autenticado pode ler/inserir/excluir.
DROP POLICY IF EXISTS "Autenticados podem ler equipe_obra" ON public.equipe_obra;
CREATE POLICY "Autenticados podem ler equipe_obra"
  ON public.equipe_obra
  FOR SELECT
  USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Autenticados podem inserir equipe_obra" ON public.equipe_obra;
CREATE POLICY "Autenticados podem inserir equipe_obra"
  ON public.equipe_obra
  FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Autenticados podem excluir equipe_obra" ON public.equipe_obra;
CREATE POLICY "Autenticados podem excluir equipe_obra"
  ON public.equipe_obra
  FOR DELETE
  USING (auth.role() = 'authenticated');

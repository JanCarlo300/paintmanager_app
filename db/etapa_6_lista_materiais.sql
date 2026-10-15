-- ============================================================
-- Etapa 6 — "Materiais faltantes" vira "Lista de materiais"
-- Execute este script no SQL Editor do Supabase Dashboard.
-- Seguro rodar duas vezes.
-- ============================================================
-- Decisões do Jan (15/10/2026):
--   * cada item tem descrição, quantidade e unidade:
--       [{"descricao": "Tinta acrílica fosca", "quantidade": 3, "unidade": "lata 18 L"}]
--   * os itens antigos de "materiais_faltantes" eram só testes e podem
--     ser apagados — por isso a coluna antiga é removida SEM backup;
--   * a lista é editada em "Editar Obra" (Administrador e Gerente);
--     pedidos de material do dia a dia vão pelo chat da obra.
--
-- COMO DESFAZER (os itens de teste antigos não voltam):
--   ALTER TABLE public.obra DROP COLUMN IF EXISTS lista_materiais;
--   ALTER TABLE public.obra ADD COLUMN materiais_faltantes JSONB DEFAULT '[]'::jsonb;
-- ============================================================

ALTER TABLE public.obra
  ADD COLUMN IF NOT EXISTS lista_materiais JSONB NOT NULL DEFAULT '[]'::jsonb;

ALTER TABLE public.obra DROP CONSTRAINT IF EXISTS obra_lista_materiais_array;
ALTER TABLE public.obra
  ADD CONSTRAINT obra_lista_materiais_array
  CHECK (jsonb_typeof(lista_materiais) = 'array');

ALTER TABLE public.obra DROP COLUMN IF EXISTS materiais_faltantes;

-- Conferência: deve mostrar 'lista_materiais' e NÃO 'materiais_faltantes'.
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'obra'
  AND column_name IN ('lista_materiais', 'materiais_faltantes');

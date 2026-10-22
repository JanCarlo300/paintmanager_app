-- ============================================================
-- Endereço da obra no padrão dos sites de compra: CEP, número e complemento
-- Execute no SQL Editor do Supabase Dashboard. Seguro rodar duas vezes.
-- Depende de: obra_bairro_cidade_uf.sql (bairro, cidade, uf).
-- ============================================================
-- O PROBLEMA:
--   Rua, número, quadra e lote iam juntos num texto só. Sem CEP e sem número
--   separados, o mapa e o "Como chegar" não tinham como achar a porta.
--
-- A CORREÇÃO (como no checkout de uma loja):
--   * cep          — o app preenche rua, bairro, cidade e UF pelo ViaCEP;
--   * numero       — número da casa ("S/N" quando não tem);
--   * complemento  — quadra, lote, bloco, apartamento...
--   A coluna 'endereco' passa a guardar só a rua/avenida (obras antigas
--   continuam com o texto que já tinham, e seguem funcionando).
--
-- Nada é apagado e nenhum dado existente é alterado.
--
-- COMO DESFAZER:
--   ALTER TABLE public.obra DROP CONSTRAINT IF EXISTS obra_cep_formato;
--   ALTER TABLE public.obra DROP COLUMN IF EXISTS cep,
--     DROP COLUMN IF EXISTS numero, DROP COLUMN IF EXISTS complemento;
-- ============================================================

ALTER TABLE public.obra ADD COLUMN IF NOT EXISTS cep         VARCHAR(9);
ALTER TABLE public.obra ADD COLUMN IF NOT EXISTS numero      VARCHAR(20);
ALTER TABLE public.obra ADD COLUMN IF NOT EXISTS complemento VARCHAR(100);

-- CEP guardado só com números (8 dígitos) ou vazio.
ALTER TABLE public.obra DROP CONSTRAINT IF EXISTS obra_cep_formato;
ALTER TABLE public.obra ADD CONSTRAINT obra_cep_formato
  CHECK (cep IS NULL OR cep = '' OR cep ~ '^[0-9]{8}$');

-- Conferência: as 3 colunas devem aparecer.
SELECT column_name AS coluna, data_type AS tipo, character_maximum_length AS tamanho
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'obra'
  AND column_name IN ('cep', 'numero', 'complemento')
ORDER BY column_name;

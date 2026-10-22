-- ============================================================
-- Endereço da obra em partes: Bairro, Cidade e UF
-- Execute no SQL Editor do Supabase Dashboard. Seguro rodar duas vezes.
-- ============================================================
-- O PROBLEMA:
--   O endereço era um texto único ("Rua Rodezir Baylao QD.N Lt19 Bairro
--   Eldorado"), quase sempre sem cidade e estado. Sem isso o mapa gratuito
--   (OpenStreetMap) não encontra o local e o "Como chegar" do Google Maps
--   não sabe para qual cidade traçar a rota.
--
-- A CORREÇÃO:
--   * 3 colunas novas em 'obra': bairro, cidade e uf. A coluna 'endereco'
--     continua guardando rua, número, quadra e lote;
--   * as colunas aceitam vazio (obras antigas continuam válidas); o app
--     passa a exigir Cidade e UF ao cadastrar ou editar uma obra;
--   * UF só aceita 2 letras maiúsculas (ex.: GO).
--
-- Nada é apagado e nenhum dado existente é alterado. As obras antigas
-- ficam com cidade/UF vazias até serem editadas no app.
--
-- COMO DESFAZER:
--   ALTER TABLE public.obra DROP CONSTRAINT IF EXISTS obra_uf_formato;
--   ALTER TABLE public.obra DROP COLUMN IF EXISTS bairro,
--     DROP COLUMN IF EXISTS cidade, DROP COLUMN IF EXISTS uf;
-- ============================================================

ALTER TABLE public.obra ADD COLUMN IF NOT EXISTS bairro VARCHAR(100);
ALTER TABLE public.obra ADD COLUMN IF NOT EXISTS cidade VARCHAR(100);
ALTER TABLE public.obra ADD COLUMN IF NOT EXISTS uf     CHAR(2);

ALTER TABLE public.obra DROP CONSTRAINT IF EXISTS obra_uf_formato;
ALTER TABLE public.obra ADD CONSTRAINT obra_uf_formato
  CHECK (uf IS NULL OR uf = '' OR uf ~ '^[A-Z]{2}$');

-- Conferência: as 3 colunas devem aparecer.
SELECT column_name AS coluna, data_type AS tipo, character_maximum_length AS tamanho
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'obra'
  AND column_name IN ('bairro', 'cidade', 'uf')
ORDER BY column_name;

-- ============================================================
-- Ponto exato da obra (GPS ou link do Google Maps/WhatsApp)
-- Execute no SQL Editor do Supabase Dashboard. Seguro rodar duas vezes.
-- ============================================================
-- O PROBLEMA:
--   O "Como chegar" procurava o endereço em texto. O Google acha a rua,
--   mas não a quadra/lote dos bairros novos, então não chegava no lote.
--
-- A CORREÇÃO:
--   * coluna 'localizacao_exata' em 'obra':
--       true  = latitude/longitude vieram do GPS no local ou de um link de
--               localização (ponto exato) -> o "Como chegar" vai direto ao pino;
--       false = latitude/longitude vieram da busca pelo endereço (ponto
--               aproximado, só para o mapinho) -> o "Como chegar" usa o texto.
--   * todas as obras atuais ficam com false (os pontos delas são aproximados).
--
-- Nada é apagado.
--
-- COMO DESFAZER:
--   ALTER TABLE public.obra DROP COLUMN IF EXISTS localizacao_exata;
-- ============================================================

ALTER TABLE public.obra
  ADD COLUMN IF NOT EXISTS localizacao_exata BOOLEAN NOT NULL DEFAULT false;

-- Conferência: quantas obras têm ponto exato (no início, 0).
SELECT localizacao_exata AS ponto_exato, count(*) AS obras
FROM public.obra
GROUP BY localizacao_exata;

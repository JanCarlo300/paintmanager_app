-- ============================================================
-- Item 3.2 — Coordenadas da obra (latitude/longitude)
-- Execute este script no SQL Editor do Supabase Dashboard.
-- ============================================================
-- Guarda a coordenada geocodificada a partir do endereço no momento
-- do cadastro/edição da obra (via Nominatim/OpenStreetMap, de graça,
-- sem chave de API). Colunas opcionais: se a geocodificação falhar
-- (sem internet, endereço não encontrado), a obra é salva normalmente
-- só sem coordenada, e o app cai de volta para abrir o mapa pelo
-- endereço em texto.

ALTER TABLE public.obra
  ADD COLUMN IF NOT EXISTS latitude  DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;

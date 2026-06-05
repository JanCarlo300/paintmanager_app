-- ==============================================================
-- ATUALIZAÇÃO DE RLS (Row Level Security) - Tabela Usuario
-- ==============================================================
-- Execute este script no SQL Editor do Supabase.

-- 1. Garante que o RLS está ativado na tabela
ALTER TABLE public.usuario ENABLE ROW LEVEL SECURITY;

-- 2. Remove política anterior de leitura anônima se existir (opcional, evita duplicação)
DROP POLICY IF EXISTS "Permitir leitura de email por CPF para login" ON public.usuario;
DROP POLICY IF EXISTS "Permitir leitura anonima na tabela usuario" ON public.usuario;

-- 3. Cria uma nova política permitindo SELECT
-- Essa política permite que o app faça a busca inicial do e-mail a partir do CPF
-- sem estar autenticado. (Para maior segurança, você também poderia restringir 
-- os campos retornados ou permitir a leitura geral para facilitar o desenvolvimento).
CREATE POLICY "Permitir leitura de email por CPF para login" 
ON public.usuario 
FOR SELECT 
USING (true);

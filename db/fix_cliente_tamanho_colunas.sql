-- ============================================================
-- Correção — erro "value too long for type character varying(45)"
-- ao cadastrar cliente + CPF/CNPJ do cliente opcional.
-- Execute este script no SQL Editor do Supabase Dashboard.
-- ============================================================
-- A tabela 'cliente' real no Supabase foi criada com colunas menores
-- (VARCHAR(45)) que o script original supabase_migrate_cliente.sql.
-- Um endereço como "R. Aguia Q 6, 26 - Liberdade, Rio Verde - GO"
-- passa de 45 caracteres e o banco recusa.
--
-- Este script só AUMENTA os limites (TEXT não tem tamanho máximo),
-- então nenhum dado existente é cortado ou perdido.
-- ============================================================

ALTER TABLE public.cliente
  ALTER COLUMN nome     TYPE TEXT,
  ALTER COLUMN email    TYPE TEXT,
  ALTER COLUMN telefone TYPE TEXT,
  ALTER COLUMN endereco TYPE TEXT,
  ALTER COLUMN cpf_cnpj TYPE TEXT,
  ALTER COLUMN cpf_cnpj DROP NOT NULL;

-- CPF/CNPJ opcional: "sem documento" passa a ser NULL em vez de texto vazio.
UPDATE public.cliente SET cpf_cnpj = NULL WHERE btrim(cpf_cnpj) = '';

-- Diagnóstico: lista colunas de texto com limite pequeno que ainda
-- existem em outras tabelas. Se aparecer alguma linha, me mande o
-- resultado — pode causar o mesmo erro em outra tela.
SELECT table_name, column_name, character_maximum_length
FROM information_schema.columns
WHERE table_schema = 'public'
  AND data_type = 'character varying'
  AND character_maximum_length <= 100
ORDER BY table_name, column_name;

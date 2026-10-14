-- ============================================================
-- Correção — colunas VARCHAR(45) em 'obra' e 'usuario'
-- Execute este script no SQL Editor do Supabase Dashboard.
-- ============================================================
-- O diagnóstico do fix_cliente_tamanho_colunas.sql mostrou o mesmo
-- limite de 45 caracteres em campos de texto livre que o app usa.
-- Um endereço de obra, título de obra, nome ou e-mail de usuário
-- maior que 45 caracteres daria o mesmo erro "value too long".
--
-- Só AUMENTA os limites (TEXT), nenhum dado é cortado ou perdido.
--
-- Ficam como estão, de propósito:
--   * colunas de status/tipo/forma de pagamento: recebem valores fixos
--     curtos escolhidos no app ("Pendente", "Pix"...), cabem folgado;
--   * usuario.cpf: guarda só os 11 dígitos;
--   * tabelas etapas, financeiro, material, observacao: sobras do
--     modelo antigo, o app não lê nem grava nelas.
-- ============================================================

ALTER TABLE public.obra
  ALTER COLUMN endereco       TYPE TEXT,
  ALTER COLUMN titulo_da_obra TYPE TEXT;

ALTER TABLE public.usuario
  ALTER COLUMN nome  TYPE TEXT,
  ALTER COLUMN email TYPE TEXT;

-- Conferência: não deve aparecer nenhuma das 4 colunas acima.
SELECT table_name, column_name, character_maximum_length
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('obra', 'usuario')
  AND data_type = 'character varying'
ORDER BY table_name, column_name;

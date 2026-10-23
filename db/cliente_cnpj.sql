-- ============================================================
-- Cliente: validação de CNPJ (Módulo 11) além do CPF
-- Execute no SQL Editor do Supabase Dashboard. Seguro rodar duas vezes.
-- Depende de: rf_item_3_1_validacao_cpf.sql (função cpf_valido).
-- ============================================================
-- O PROBLEMA:
--   O campo "CPF ou CNPJ" do cliente só validava CPF. Um CNPJ com 14
--   números entrava sem conferir os dígitos verificadores.
--
-- A CORREÇÃO:
--   * função cnpj_valido(texto) — Módulo 11 com os pesos do CNPJ;
--   * o trigger do cliente passa a aceitar: vazio, CPF válido (11) ou
--     CNPJ válido (14). Qualquer outra coisa é recusada.
--   Só vale para cadastros novos ou quando o documento é alterado:
--   clientes antigos não são tocados.
--
-- COMO DESFAZER: rodar de novo rf_item_3_1_validacao_cpf.sql (volta o
-- trigger anterior) e DROP FUNCTION IF EXISTS public.cnpj_valido(TEXT);
-- ============================================================

CREATE OR REPLACE FUNCTION public.cnpj_valido(cnpj TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  d     TEXT := regexp_replace(coalesce(cnpj, ''), '[^0-9]', '', 'g');
  pesos1 INT[] := ARRAY[5,4,3,2,9,8,7,6,5,4,3,2];
  pesos2 INT[] := ARRAY[6,5,4,3,2,9,8,7,6,5,4,3,2];
  soma  INT;
  resto INT;
  dv1   INT;
  dv2   INT;
BEGIN
  IF length(d) <> 14 OR d = repeat(substr(d, 1, 1), 14) THEN
    RETURN false;
  END IF;

  soma := 0;
  FOR i IN 1..12 LOOP
    soma := soma + substr(d, i, 1)::INT * pesos1[i];
  END LOOP;
  resto := soma % 11;
  dv1 := CASE WHEN resto < 2 THEN 0 ELSE 11 - resto END;

  soma := 0;
  FOR i IN 1..13 LOOP
    soma := soma + substr(d, i, 1)::INT * pesos2[i];
  END LOOP;
  resto := soma % 11;
  dv2 := CASE WHEN resto < 2 THEN 0 ELSE 11 - resto END;

  RETURN substr(d, 13, 1)::INT = dv1 AND substr(d, 14, 1)::INT = dv2;
END;
$$;

CREATE OR REPLACE FUNCTION public.validar_documento_cliente()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  d TEXT := regexp_replace(coalesce(NEW.cpf_cnpj, ''), '[^0-9]', '', 'g');
BEGIN
  IF TG_OP = 'UPDATE' AND NEW.cpf_cnpj IS NOT DISTINCT FROM OLD.cpf_cnpj THEN
    RETURN NEW;
  END IF;
  IF d = '' THEN
    RETURN NEW;
  END IF;
  IF length(d) = 11 AND public.cpf_valido(d) THEN
    RETURN NEW;
  END IF;
  IF length(d) = 14 AND public.cnpj_valido(d) THEN
    RETURN NEW;
  END IF;
  RAISE EXCEPTION 'CPF ou CNPJ do cliente inválido.' USING ERRCODE = 'check_violation';
END;
$$;

DROP TRIGGER IF EXISTS trg_validar_documento_cliente ON public.cliente;
CREATE TRIGGER trg_validar_documento_cliente
  BEFORE INSERT OR UPDATE OF cpf_cnpj ON public.cliente
  FOR EACH ROW
  EXECUTE FUNCTION public.validar_documento_cliente();

-- Conferência: os 2 primeiros true, os outros false.
SELECT public.cnpj_valido('11.222.333/0001-81') AS valido_1,
       public.cnpj_valido('11.444.777/0001-61') AS valido_2,
       public.cnpj_valido('11.222.333/0001-80') AS dv_errado,
       public.cnpj_valido('11.111.111/1111-11') AS repetido,
       public.cnpj_valido('1122233300')         AS incompleto;

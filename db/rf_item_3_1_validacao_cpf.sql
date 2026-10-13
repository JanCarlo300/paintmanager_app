-- ============================================================
-- Item 3.1 — Validação de CPF (Módulo 11) no banco
-- Execute este script no SQL Editor do Supabase Dashboard.
-- Rode ANTES o db/fix_cliente_tamanho_colunas.sql.
-- ============================================================
-- O app já valida o CPF nos formulários (lib/src/core/validadores/
-- validador_cpf.dart). Este script repete a mesma regra no banco, para
-- que nenhum CPF inválido entre por outro caminho (Edge Function,
-- painel do Supabase, chamada direta à API).
--
-- A checagem só acontece quando o CPF é INSERIDO ou ALTERADO. Registros
-- antigos com CPF inválido continuam funcionando normalmente (login,
-- troca de senha, ativar/inativar) até alguém editar o CPF deles.
--
-- COMO DESFAZER:
--   DROP TRIGGER IF EXISTS trg_validar_cpf_usuario ON public.usuario;
--   DROP TRIGGER IF EXISTS trg_validar_documento_cliente ON public.cliente;
--   DROP FUNCTION IF EXISTS public.validar_cpf_usuario();
--   DROP FUNCTION IF EXISTS public.validar_documento_cliente();
--   DROP FUNCTION IF EXISTS public.cpf_valido(TEXT);
-- ============================================================

-- 1. REGRA DO MÓDULO 11
CREATE OR REPLACE FUNCTION public.cpf_valido(cpf TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  d     TEXT := regexp_replace(coalesce(cpf, ''), '[^0-9]', '', 'g');
  soma  INT;
  resto INT;
  dv1   INT;
  dv2   INT;
BEGIN
  IF length(d) <> 11 THEN RETURN FALSE; END IF;
  -- 000.000.000-00, 111.111.111-11 etc.
  IF d = repeat(substr(d, 1, 1), 11) THEN RETURN FALSE; END IF;

  soma := 0;
  FOR i IN 1..9 LOOP
    soma := soma + substr(d, i, 1)::INT * (11 - i);
  END LOOP;
  resto := soma % 11;
  dv1 := CASE WHEN resto < 2 THEN 0 ELSE 11 - resto END;

  soma := 0;
  FOR i IN 1..10 LOOP
    soma := soma + substr(d, i, 1)::INT * (12 - i);
  END LOOP;
  resto := soma % 11;
  dv2 := CASE WHEN resto < 2 THEN 0 ELSE 11 - resto END;

  RETURN substr(d, 10, 1)::INT = dv1 AND substr(d, 11, 1)::INT = dv2;
END;
$$;

-- 2. USUÁRIO — CPF obrigatório e válido
CREATE OR REPLACE FUNCTION public.validar_cpf_usuario()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  -- O app reenvia o CPF em toda edição; só valida se ele mudou de fato.
  IF TG_OP = 'UPDATE' AND NEW.cpf IS NOT DISTINCT FROM OLD.cpf THEN
    RETURN NEW;
  END IF;
  IF NOT public.cpf_valido(NEW.cpf) THEN
    RAISE EXCEPTION 'CPF inválido.' USING ERRCODE = 'check_violation';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validar_cpf_usuario ON public.usuario;
CREATE TRIGGER trg_validar_cpf_usuario
  BEFORE INSERT OR UPDATE OF cpf ON public.usuario
  FOR EACH ROW
  EXECUTE FUNCTION public.validar_cpf_usuario();

-- 3. CLIENTE — documento opcional; se for CPF (11 dígitos), tem que ser válido.
--    CNPJ (14 dígitos) é aceito como está.
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
  IF d = '' OR length(d) = 14 THEN
    RETURN NEW;
  END IF;
  IF NOT public.cpf_valido(d) THEN
    RAISE EXCEPTION 'CPF do cliente inválido.' USING ERRCODE = 'check_violation';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validar_documento_cliente ON public.cliente;
CREATE TRIGGER trg_validar_documento_cliente
  BEFORE INSERT OR UPDATE OF cpf_cnpj ON public.cliente
  FOR EACH ROW
  EXECUTE FUNCTION public.validar_documento_cliente();

-- 4. CONFERÊNCIA (o resultado aparece embaixo do editor)
--    Esperado: true, true, false, false, false
SELECT public.cpf_valido('529.982.247-25') AS valido_1,
       public.cpf_valido('123.456.789-09') AS valido_2,
       public.cpf_valido('529.982.247-24') AS dv_errado,
       public.cpf_valido('111.111.111-11') AS repetido,
       public.cpf_valido('5299822')        AS incompleto;

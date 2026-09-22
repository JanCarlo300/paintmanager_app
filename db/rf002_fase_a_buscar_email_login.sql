-- ============================================================
-- RF002 — Recuperar Senha — FASE A (segura, não remove nada)
-- ============================================================
-- O QUE ESTE SCRIPT FAZ:
--   Cria UMA função nova chamada 'buscar_email_por_login'.
--   Ela recebe um texto (CPF ou e-mail) e devolve APENAS o e-mail
--   do usuário ATIVO correspondente — nunca CPF, telefone,
--   função ou qualquer outro dado da tabela 'usuario'.
--
-- O QUE ESTE SCRIPT *NÃO* FAZ:
--   - Não apaga nem altera a política "Permitir leitura de email
--     por CPF para login" (de rls_policy_usuario.sql). Ela continua
--     existindo, então o login do app de hoje NÃO É AFETADO.
--   - Não altera nenhuma tabela, nenhuma coluna, nenhum dado.
--   - Não mexe em nenhum outro usuário nem no admin.
--
-- É seguro rodar este script quantas vezes quiser: ele usa
-- "CREATE OR REPLACE", então só substitui a função por ela mesma.
--
-- COMO RODAR:
--   1. Abra o SQL Editor do seu projeto no Supabase.
--   2. Cole este arquivo inteiro.
--   3. Clique em "Run".
--   4. Role até o fim deste arquivo e rode as 3 consultas de teste
--      (estão comentadas com "--", descomente uma de cada vez).
--
-- COMO DESFAZER (se algo parecer errado):
--   Rode apenas esta linha:
--     DROP FUNCTION IF EXISTS public.buscar_email_por_login(text);
--   Isso remove só a função nova. Nada mais do banco é afetado,
--   porque nada mais foi alterado por este script.
-- ============================================================

CREATE OR REPLACE FUNCTION public.buscar_email_por_login(p_login text)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER      -- roda com privilégio de leitura da tabela,
                       -- mesmo chamada por alguém sem sessão (anon)
SET search_path = public  -- trava o schema usado, por segurança
AS $$
DECLARE
  v_login_limpo text;
  v_email       text;
BEGIN
  v_login_limpo := trim(p_login);

  -- Login vazio ou nulo: não faz consulta nenhuma
  IF v_login_limpo IS NULL OR v_login_limpo = '' THEN
    RETURN NULL;
  END IF;

  IF v_login_limpo LIKE '%@%' THEN
    -- Contém "@": trata como e-mail
    SELECT u.email INTO v_email
    FROM public.usuario u
    WHERE lower(u.email) = lower(v_login_limpo)
      AND u.status = true      -- só usuário ativo
    LIMIT 1;
  ELSE
    -- Sem "@": trata como CPF (remove pontos/traço/espaços, só números)
    SELECT u.email INTO v_email
    FROM public.usuario u
    WHERE u.cpf = regexp_replace(v_login_limpo, '[^0-9]', '', 'g')
      AND u.status = true      -- só usuário ativo
    LIMIT 1;
  END IF;

  RETURN v_email;  -- pode vir NULL se não achar — o app trata isso
                    -- com uma mensagem genérica, sem revelar se o
                    -- CPF/e-mail existe ou não no sistema
END;
$$;

-- Permissão: qualquer pessoa (mesmo sem estar logada) pode CHAMAR
-- esta função — mas ela só devolve um e-mail, nunca a tabela inteira.
REVOKE ALL ON FUNCTION public.buscar_email_por_login(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.buscar_email_por_login(text) TO anon, authenticated;

-- ============================================================
-- TESTES (rode um de cada vez, descomentando a linha)
-- ============================================================

-- 1) Buscar pelo CPF do admin cadastrado em supabase_migration.sql
--    Deve devolver: jancarloalmeida36@gmail.com
-- SELECT public.buscar_email_por_login('03595976100');

-- 2) Buscar pelo e-mail do mesmo admin — deve devolver o mesmo e-mail
-- SELECT public.buscar_email_por_login('jancarloalmeida36@gmail.com');

-- 3) Buscar um CPF que não existe — deve devolver NULL (vazio)
-- SELECT public.buscar_email_por_login('00000000000');

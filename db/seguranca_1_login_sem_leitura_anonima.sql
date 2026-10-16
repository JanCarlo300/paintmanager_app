-- ============================================================
-- Segurança 1 — RF002 Fase B: fecha a leitura anônima da tabela usuario
-- Execute no SQL Editor do Supabase Dashboard. Seguro rodar duas vezes.
-- ============================================================
-- O PROBLEMA:
--   Para o login achar o e-mail a partir do CPF, existia a política
--   "Permitir leitura de email por CPF para login" com USING (true):
--   QUALQUER PESSOA, sem estar logada, podia ler a tabela 'usuario'
--   inteira (nome, e-mail, CPF, telefone e função de todos) usando a
--   chave pública que vai dentro do APK.
--
-- A CORREÇÃO:
--   * o app passa a usar a função 'buscar_email_por_login' (SECURITY
--     DEFINER), que devolve só o e-mail de um usuário ativo;
--   * a política aberta é removida;
--   * a leitura para quem ESTÁ logado é garantida (o app precisa dela
--     depois do login) — recriada aqui caso não exista no banco.
--
-- ORDEM: instale primeiro o APK novo (o antigo depende da leitura
-- anônima para logar) e depois rode este script.
--
-- COMO DESFAZER (volta a brecha — só em emergência):
--   CREATE POLICY "Permitir leitura de email por CPF para login"
--     ON public.usuario FOR SELECT USING (true);
-- ============================================================

-- 1. Função segura usada pelo login e pela recuperação de senha
--    (a mesma do rf002_fase_a_buscar_email_login.sql; recriada para o
--    script não depender de ele ter sido rodado).
CREATE OR REPLACE FUNCTION public.buscar_email_por_login(p_login text)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_login_limpo text;
  v_email       text;
BEGIN
  v_login_limpo := trim(p_login);
  IF v_login_limpo IS NULL OR v_login_limpo = '' THEN
    RETURN NULL;
  END IF;

  IF v_login_limpo LIKE '%@%' THEN
    SELECT u.email INTO v_email
    FROM public.usuario u
    WHERE lower(u.email) = lower(v_login_limpo) AND u.status = true
    LIMIT 1;
  ELSE
    SELECT u.email INTO v_email
    FROM public.usuario u
    WHERE u.cpf = regexp_replace(v_login_limpo, '[^0-9]', '', 'g') AND u.status = true
    LIMIT 1;
  END IF;

  RETURN v_email;
END;
$$;

REVOKE ALL ON FUNCTION public.buscar_email_por_login(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.buscar_email_por_login(text) TO anon, authenticated;

-- 2. Leitura para quem está logado (garantida antes de remover a aberta)
ALTER TABLE public.usuario ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Usuarios autenticados podem ler" ON public.usuario;
CREATE POLICY "Usuarios autenticados podem ler"
  ON public.usuario
  FOR SELECT
  USING (auth.role() = 'authenticated');

-- 3. Remove a leitura anônima (nomes usados pelos scripts antigos)
DROP POLICY IF EXISTS "Permitir leitura de email por CPF para login" ON public.usuario;
DROP POLICY IF EXISTS "Permitir leitura anonima na tabela usuario" ON public.usuario;

-- 4. Conferência: políticas que restaram em 'usuario'.
--    NÃO pode sobrar nenhuma de SELECT com condição "true" (aberta a
--    qualquer um). As esperadas: leitura de autenticados, inserção de
--    autenticados e as de atualização (admin e próprio registro).
SELECT policyname AS politica, cmd AS operacao, qual AS condicao
FROM pg_policies
WHERE schemaname = 'public' AND tablename = 'usuario'
ORDER BY cmd, policyname;

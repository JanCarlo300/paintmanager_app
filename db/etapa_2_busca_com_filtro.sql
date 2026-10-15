-- ============================================================
-- Etapa 2 — Busca com filtro (cliente, obra e funcionário)
-- Execute este script no SQL Editor do Supabase Dashboard.
-- Seguro rodar duas vezes.
-- ============================================================
-- O app deixa de carregar todos os registros em caixas seletoras: ao
-- digitar, ele chama estas funções, que filtram NO BANCO e devolvem no
-- máximo 'limite' linhas (padrão 20).
--
--   * sem diferenciar maiúsculas/minúsculas nem acentos ("jose" acha
--     "José"), usando a extensão 'unaccent';
--   * clientes: por nome, CPF/CNPJ e telefone (só os dígitos contam
--     para CPF e telefone, então "64 9999" acha "(64) 99995-3540");
--   * obras: por título e nome do cliente;
--   * funcionários: por nome, só ativos e ainda não alocados na obra.
--
-- As funções rodam com as permissões de quem chama (RLS vale): um
-- Funcionário só encontra as obras em que está alocado.
--
-- COMO DESFAZER:
--   DROP FUNCTION IF EXISTS public.buscar_clientes(TEXT, INT);
--   DROP FUNCTION IF EXISTS public.buscar_obras(TEXT, INT);
--   DROP FUNCTION IF EXISTS public.buscar_funcionarios_disponiveis(BIGINT, TEXT, INT);
--   DROP FUNCTION IF EXISTS public.padrao_busca(TEXT);
-- ============================================================

CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA extensions;

-- "Jo_é 50%" -> '%jo\_e 50\%%' (minúsculo, sem acento, curingas escapados)
CREATE OR REPLACE FUNCTION public.padrao_busca(termo TEXT)
RETURNS TEXT
LANGUAGE sql
STABLE
SET search_path = public, extensions
AS $$
  SELECT '%' ||
         replace(replace(replace(lower(unaccent(coalesce(btrim(termo), ''))),
                 '\', '\\'), '%', '\%'), '_', '\_') ||
         '%';
$$;

CREATE OR REPLACE FUNCTION public.buscar_clientes(termo TEXT DEFAULT '', limite INT DEFAULT 20)
RETURNS SETOF public.cliente
LANGUAGE sql
STABLE
SET search_path = public, extensions
AS $$
  WITH p AS (
    SELECT public.padrao_busca(termo) AS pad,
           regexp_replace(coalesce(termo, ''), '\D', '', 'g') AS digitos
  )
  SELECT c.*
  FROM public.cliente c, p
  WHERE btrim(coalesce(termo, '')) = ''
     OR lower(unaccent(coalesce(c.nome, ''))) LIKE p.pad
     OR (p.digitos <> '' AND (
           regexp_replace(coalesce(c.cpf_cnpj, ''),  '\D', '', 'g') LIKE '%' || p.digitos || '%'
        OR regexp_replace(coalesce(c.telefone, ''), '\D', '', 'g') LIKE '%' || p.digitos || '%'))
  ORDER BY c.nome
  LIMIT greatest(coalesce(limite, 20), 1);
$$;

CREATE OR REPLACE FUNCTION public.buscar_obras(termo TEXT DEFAULT '', limite INT DEFAULT 20)
RETURNS SETOF public.obra
LANGUAGE sql
STABLE
SET search_path = public, extensions
AS $$
  WITH p AS (SELECT public.padrao_busca(termo) AS pad)
  SELECT o.*
  FROM public.obra o, p
  WHERE btrim(coalesce(termo, '')) = ''
     OR lower(unaccent(coalesce(o.titulo_da_obra, ''))) LIKE p.pad
     OR lower(unaccent(coalesce(o.cliente_nome, '')))   LIKE p.pad
  ORDER BY o.created_at DESC
  LIMIT greatest(coalesce(limite, 20), 1);
$$;

CREATE OR REPLACE FUNCTION public.buscar_funcionarios_disponiveis(
  p_obra_id BIGINT,
  termo TEXT DEFAULT '',
  limite INT DEFAULT 20
)
RETURNS SETOF public.usuario
LANGUAGE sql
STABLE
SET search_path = public, extensions
AS $$
  WITH p AS (SELECT public.padrao_busca(termo) AS pad)
  SELECT u.*
  FROM public.usuario u, p
  WHERE u.funcao = 'Funcionário'
    AND u.status = true
    AND NOT EXISTS (
      SELECT 1 FROM public.equipe_obra eo
      WHERE eo.obra_id = p_obra_id AND eo.usuario_id = u.id_usuario
    )
    AND (btrim(coalesce(termo, '')) = ''
         OR lower(unaccent(coalesce(u.nome, ''))) LIKE p.pad)
  ORDER BY u.nome
  LIMIT greatest(coalesce(limite, 20), 1);
$$;

REVOKE EXECUTE ON FUNCTION public.buscar_clientes(TEXT, INT) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.buscar_obras(TEXT, INT) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.buscar_funcionarios_disponiveis(BIGINT, TEXT, INT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.buscar_clientes(TEXT, INT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.buscar_obras(TEXT, INT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.buscar_funcionarios_disponiveis(BIGINT, TEXT, INT) TO authenticated;

-- Conferência: deve listar clientes que tenham "jose" (com ou sem acento)
-- no nome, ou 0 linhas se não houver nenhum — sem dar erro.
SELECT nome, cpf_cnpj, telefone FROM public.buscar_clientes('jose', 5);

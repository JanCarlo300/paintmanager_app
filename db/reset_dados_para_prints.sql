-- ============================================================
-- Reset dos dados para os prints do Manual do usuário (TFC II)
-- Execute no SQL Editor do Supabase Dashboard.
--
-- ANTES DE RODAR: exportar cada tabela em CSV (Table Editor → Export).
--
-- O QUE FICA: só a conta do Administrador (usuario.id_usuario = 2) e o login
-- dela em auth.users. Troque <EMAIL_DO_ADMIN> (uma vez só, lá embaixo) pelo
-- e-mail dessa conta.
--
-- O QUE SAI: TODAS as linhas de chat_leitura, obra_mensagem, equipe_obra,
-- transacao, orcamento, obra, cliente e backup_colunas_removidas; os outros
-- usuários (tabela usuario) e os logins deles (auth.users).
--
-- TRAVAS (se alguma falhar, o script PARA e nada muda):
--   - o e-mail não foi trocado ou não existe em auth.users;
--   - o e-mail não é o login do usuario 2, ou o usuario 2 não é Administrador;
--   - o "depois" não deu usuario = 1, auth.users = 1 e as demais = 0.
--
-- TRIGGERS: nenhum trigger do projeto roda em DELETE (todos são de INSERT ou
-- UPDATE), então não é preciso desativar nenhum. A ordem abaixo apaga primeiro
-- quem aponta para os outros; assim o banco não precisa fazer nenhum
-- ON DELETE SET NULL, que dispararia o trigger de UPDATE da transacao.
--
-- NUMERAÇÃO: as tabelas esvaziadas voltam a contar do id 1 (TRUNCATE ...
-- RESTART IDENTITY, que o ROLLBACK também desfaz). A tabela usuario NÃO volta,
-- porque o admin continua lá com o id 2: o próximo usuário recebe o número
-- seguinte ao último já usado.
--
-- MODO TESTE: termina com ROLLBACK, então nada fica gravado. Se no editor
-- aparecer só "Success. No rows returned", as travas passaram mesmo assim:
-- se uma contagem estivesse errada, o script teria parado com erro.
-- ============================================================

BEGIN;

-- 0. Conta mantida -------------------------------------------------------------
CREATE TEMP TABLE reset_admin ON COMMIT DROP AS
SELECT '<EMAIL_DO_ADMIN>'::text AS email, 2::bigint AS id_usuario, NULL::uuid AS auth_id;

DO $$
DECLARE
  v_email  text;
  v_auth   uuid;
  v_funcao text;
  v_qtd    int;
BEGIN
  SELECT email INTO v_email FROM reset_admin;
  IF v_email !~ '^[^<>@[:space:]]+@[^<>@[:space:]]+$' THEN
    RAISE EXCEPTION 'Troque <EMAIL_DO_ADMIN> pelo e-mail do Administrador. Nada foi apagado.';
  END IF;

  SELECT count(*) INTO v_qtd FROM auth.users WHERE lower(email) = lower(v_email);
  IF v_qtd <> 1 THEN
    RAISE EXCEPTION 'Encontrei % login(s) com esse e-mail em auth.users (esperado 1). Nada foi apagado.', v_qtd;
  END IF;
  SELECT id INTO v_auth FROM auth.users WHERE lower(email) = lower(v_email);

  SELECT funcao INTO v_funcao
  FROM public.usuario
  WHERE id_usuario = 2 AND auth_id = v_auth;
  IF v_funcao IS NULL THEN
    RAISE EXCEPTION 'O e-mail informado não é o login do usuario 2. Nada foi apagado.';
  END IF;
  IF v_funcao <> 'Administrador' THEN
    RAISE EXCEPTION 'O usuario 2 é "%", não Administrador. Nada foi apagado.', v_funcao;
  END IF;

  UPDATE reset_admin SET auth_id = v_auth;
END $$;

-- 1. Contagem ANTES ----------------------------------------------------------
-- (esperado_antes = números conferidos em 25/10/2026, só para comparar)
CREATE TEMP TABLE reset_contagem (
  ordem int, tabela text, esperado_antes int, antes int, depois int
) ON COMMIT DROP;

INSERT INTO reset_contagem (ordem, tabela, esperado_antes, antes) VALUES
  (1,  'chat_leitura',             21, (SELECT count(*) FROM public.chat_leitura)),
  (2,  'obra_mensagem',             6, (SELECT count(*) FROM public.obra_mensagem)),
  (3,  'equipe_obra',               5, (SELECT count(*) FROM public.equipe_obra)),
  (4,  'transacao',                 4, (SELECT count(*) FROM public.transacao)),
  (5,  'orcamento',                 7, (SELECT count(*) FROM public.orcamento)),
  (6,  'obra',                      8, (SELECT count(*) FROM public.obra)),
  (7,  'cliente',                   6, (SELECT count(*) FROM public.cliente)),
  (8,  'backup_colunas_removidas',  1, (SELECT count(*) FROM public.backup_colunas_removidas)),
  (9,  'usuario',                   4, (SELECT count(*) FROM public.usuario)),
  (10, 'auth.users',                4, (SELECT count(*) FROM auth.users));

-- 2. Exclusões, na ordem das dependências --------------------------------------
DELETE FROM public.chat_leitura;              -- → usuario, obra
DELETE FROM public.obra_mensagem;             -- → usuario, obra
DELETE FROM public.equipe_obra;               -- → usuario, obra
DELETE FROM public.transacao;                 -- → obra, cliente
DELETE FROM public.orcamento;                 -- → obra
DELETE FROM public.obra;                      -- → cliente (RESTRICT)
DELETE FROM public.cliente;
DELETE FROM public.backup_colunas_removidas;  -- backup da limpeza de 22/10

DELETE FROM public.usuario
WHERE id_usuario <> (SELECT id_usuario FROM reset_admin);

-- Logins dos outros usuários (apaga junto sessões e identidades do Supabase Auth)
DELETE FROM auth.users
WHERE id <> (SELECT auth_id FROM reset_admin);

-- 3. Numeração das tabelas esvaziadas volta para 1 ------------------------------
-- As tabelas já estão vazias: o TRUNCATE aqui só reinicia a numeração. Se outra
-- tabela (fora desta lista) apontar para alguma delas, o banco recusa e nada muda.
TRUNCATE public.chat_leitura, public.obra_mensagem, public.equipe_obra,
         public.transacao, public.orcamento, public.obra, public.cliente,
         public.backup_colunas_removidas
  RESTART IDENTITY;

-- 4. Contagem DEPOIS ---------------------------------------------------------
UPDATE reset_contagem SET depois = CASE tabela
  WHEN 'chat_leitura'             THEN (SELECT count(*) FROM public.chat_leitura)
  WHEN 'obra_mensagem'            THEN (SELECT count(*) FROM public.obra_mensagem)
  WHEN 'equipe_obra'              THEN (SELECT count(*) FROM public.equipe_obra)
  WHEN 'transacao'                THEN (SELECT count(*) FROM public.transacao)
  WHEN 'orcamento'                THEN (SELECT count(*) FROM public.orcamento)
  WHEN 'obra'                     THEN (SELECT count(*) FROM public.obra)
  WHEN 'cliente'                  THEN (SELECT count(*) FROM public.cliente)
  WHEN 'backup_colunas_removidas' THEN (SELECT count(*) FROM public.backup_colunas_removidas)
  WHEN 'usuario'                  THEN (SELECT count(*) FROM public.usuario)
  WHEN 'auth.users'               THEN (SELECT count(*) FROM auth.users)
END;

-- Trava final: usuario = 1, auth.users = 1, o resto = 0.
DO $$
DECLARE
  v_erradas text;
BEGIN
  SELECT string_agg(format('%s = %s', tabela, depois), ', ' ORDER BY ordem) INTO v_erradas
  FROM reset_contagem
  WHERE depois <> CASE WHEN tabela IN ('usuario', 'auth.users') THEN 1 ELSE 0 END;
  IF v_erradas IS NOT NULL THEN
    RAISE EXCEPTION 'Contagem final inesperada (%). Nada foi apagado.', v_erradas;
  END IF;
END $$;

-- 5. Quadro antes × depois -----------------------------------------------------
SELECT tabela, esperado_antes, antes, depois
FROM reset_contagem
ORDER BY ordem;

-- Conferiu as contagens? Troque ROLLBACK por COMMIT e rode de novo.
ROLLBACK;

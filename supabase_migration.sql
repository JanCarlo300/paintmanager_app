-- ============================================================
-- MIGRAÇÃO PAINTMANAGER — Adaptação da Tabela 'usuario' + Admin
-- Cole este script inteiro no SQL Editor do Supabase e execute.
-- ============================================================

-- 1. ADICIONAR COLUNAS FALTANTES NA TABELA 'usuario'
-- A tabela usuario atual possui id_usuario inteiro, precisamos adicionar as outras
ALTER TABLE public.usuario
ADD COLUMN IF NOT EXISTS auth_id UUID UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
ADD COLUMN IF NOT EXISTS telefone VARCHAR DEFAULT '',
ADD COLUMN IF NOT EXISTS primeiro_acesso BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS criado_em TIMESTAMPTZ DEFAULT now();

-- 2. AJUSTAR TIPO DA COLUNA STATUS
-- No Firestore o status pode ter vindo como string, vamos converter para boolean
-- Removendo e recriando para evitar erros de cast complexos caso esteja vindo com 'Ativo'/'Inativo'
ALTER TABLE public.usuario DROP COLUMN IF EXISTS status;
ALTER TABLE public.usuario ADD COLUMN status BOOLEAN DEFAULT true;

-- 3. Habilitar Row Level Security (RLS)
ALTER TABLE public.usuario ENABLE ROW LEVEL SECURITY;

-- 4. Política: Usuários autenticados podem LER todos os registros
-- Usa DROP POLICY IF EXISTS primeiro para caso você rode mais de uma vez
DROP POLICY IF EXISTS "Usuarios autenticados podem ler" ON public.usuario;
CREATE POLICY "Usuarios autenticados podem ler"
  ON public.usuario
  FOR SELECT
  USING (auth.role() = 'authenticated');

-- 5. Política: Usuários autenticados podem INSERIR
DROP POLICY IF EXISTS "Usuarios autenticados podem inserir" ON public.usuario;
CREATE POLICY "Usuarios autenticados podem inserir"
  ON public.usuario
  FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

-- 6. Política: Admins podem ATUALIZAR qualquer registro
DROP POLICY IF EXISTS "Admins podem atualizar" ON public.usuario;
CREATE POLICY "Admins podem atualizar"
  ON public.usuario
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.usuario u
      WHERE u.auth_id = auth.uid() AND u.funcao = 'Administrador'
    )
  );

-- 7. Política: Usuário pode atualizar SEU PRÓPRIO registro (para primeiro_acesso)
DROP POLICY IF EXISTS "Usuario pode atualizar proprio registro" ON public.usuario;
CREATE POLICY "Usuario pode atualizar proprio registro"
  ON public.usuario
  FOR UPDATE
  USING (auth_id = auth.uid());

-- ============================================================
-- 8. CRIAR O USUÁRIO ADMINISTRADOR no Auth e na Tabela Public
--    Email: jancarloalmeida36@gmail.com
--    CPF: 03595976100
--    Senha: 12345678jc
-- ============================================================

-- Cria o usuário no Supabase Auth
SELECT supabase_auth_admin.create_user(
  '{"email": "jancarloalmeida36@gmail.com", "password": "12345678jc", "email_confirm": true}'::jsonb
);

-- Como a tabela tem id_usuario inteiro (e imagino que possa ser serial/auto-increment ou não),
-- Vamos usar uma sequência para não dar hardcode em um ID, ou geramos um ID alto
CREATE SEQUENCE IF NOT EXISTS usuario_id_seq;
ALTER TABLE public.usuario ALTER COLUMN id_usuario SET DEFAULT nextval('usuario_id_seq');

-- Insere os dados do admin na tabela 'usuario'
-- Se já existir esse email, não insere duplicado
INSERT INTO public.usuario (auth_id, nome, email, cpf, telefone, funcao, status, primeiro_acesso)
SELECT 
  id,
  'Jan Carlo',
  'jancarloalmeida36@gmail.com',
  '03595976100',
  '',
  'Administrador',
  true,
  false
FROM auth.users
WHERE email = 'jancarloalmeida36@gmail.com'
-- Postgres exige conflito sob constraint única, e só "usuario_pkey" (id_usuario) e "usuario_auth_id_key" são garantidas.
-- Evitaremos erro fazendo check com WHERE NOT EXISTS
AND NOT EXISTS (
  SELECT 1 FROM public.usuario WHERE email = 'jancarloalmeida36@gmail.com'
);

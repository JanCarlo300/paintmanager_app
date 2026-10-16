-- ============================================
-- SEED: Administrador Principal — PaintManager
-- CPF: <CPF_DO_ADMIN> | Senha: <SENHA_INICIAL_DO_ADMIN>
-- ============================================
-- Execute este script no SQL Editor do Supabase Dashboard.

DO $$
DECLARE
  v_auth_id uuid;
BEGIN
  -- 1) Tentar encontrar o id do usuário se o email já existe
  SELECT id INTO v_auth_id 
  FROM auth.users 
  WHERE email = '<EMAIL_DO_ADMIN>';

  IF v_auth_id IS NOT NULL THEN
    -- Recupera o usuário mudando apenas a senha
    UPDATE auth.users 
    SET encrypted_password = crypt('<SENHA_INICIAL_DO_ADMIN>', gen_salt('bf')),
        updated_at = now()
    WHERE id = v_auth_id;
  ELSE
    -- E-mail não existe, criar um novo registro no auth.users
    v_auth_id := gen_random_uuid();
    INSERT INTO auth.users (
      instance_id, id, aud, role,
      email, encrypted_password,
      email_confirmed_at, created_at, updated_at,
      confirmation_token, recovery_token,
      raw_app_meta_data, raw_user_meta_data,
      is_super_admin
    )
    VALUES (
      '00000000-0000-0000-0000-000000000000',
      v_auth_id,
      'authenticated', 'authenticated',
      '<EMAIL_DO_ADMIN>',
      crypt('<SENHA_INICIAL_DO_ADMIN>', gen_salt('bf')),
      now(), now(), now(),
      '', '',
      '{"provider":"email","providers":["email"]}'::jsonb,
      '{}'::jsonb,
      false
    );
  END IF;

  -- 2) Atualizar ou inserir na tabela public.usuario
  IF EXISTS (SELECT 1 FROM public.usuario WHERE email = '<EMAIL_DO_ADMIN>') THEN
    UPDATE public.usuario
    SET auth_id = v_auth_id,
        nome = '<NOME_DO_ADMIN>',
        cpf = '<CPF_DO_ADMIN>',
        telefone = '64984250962',
        funcao = 'Administrador',
        status = true,
        primeiro_acesso = false
    WHERE email = '<EMAIL_DO_ADMIN>';
  ELSE
    -- Se não encontrar por email, insere o registro vinculando ao auth_id correto
    INSERT INTO public.usuario (
      auth_id, nome, email, cpf, telefone, funcao,
      status, primeiro_acesso, criado_em
    )
    VALUES (
      v_auth_id,
      '<NOME_DO_ADMIN>',
      '<EMAIL_DO_ADMIN>',
      '<CPF_DO_ADMIN>',
      '64984250962',
      'Administrador',
      true,
      false,
      now()
    );
  END IF;

END $$;

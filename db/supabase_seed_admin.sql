-- ============================================
-- SEED: Administrador Principal — PaintManager
-- CPF: 03595976100 | Senha: 12345678jc
-- ============================================
-- Execute este script no SQL Editor do Supabase Dashboard.

DO $$
DECLARE
  v_auth_id uuid;
BEGIN
  -- 1) Tentar encontrar o id do usuário se o email já existe
  SELECT id INTO v_auth_id 
  FROM auth.users 
  WHERE email = 'jancarloalmeida36@gmail.com';

  IF v_auth_id IS NOT NULL THEN
    -- Recupera o usuário mudando apenas a senha
    UPDATE auth.users 
    SET encrypted_password = crypt('12345678jc', gen_salt('bf')),
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
      'jancarloalmeida36@gmail.com',
      crypt('12345678jc', gen_salt('bf')),
      now(), now(), now(),
      '', '',
      '{"provider":"email","providers":["email"]}'::jsonb,
      '{}'::jsonb,
      false
    );
  END IF;

  -- 2) Atualizar ou inserir na tabela public.usuario
  IF EXISTS (SELECT 1 FROM public.usuario WHERE email = 'jancarloalmeida36@gmail.com') THEN
    UPDATE public.usuario
    SET auth_id = v_auth_id,
        nome = 'jan carlo almeida leal',
        cpf = '03595976100',
        telefone = '64984250962',
        funcao = 'Administrador',
        status = true,
        primeiro_acesso = false
    WHERE email = 'jancarloalmeida36@gmail.com';
  ELSE
    -- Se não encontrar por email, insere o registro vinculando ao auth_id correto
    INSERT INTO public.usuario (
      auth_id, nome, email, cpf, telefone, funcao,
      status, primeiro_acesso, criado_em
    )
    VALUES (
      v_auth_id,
      'jan carlo almeida leal',
      'jancarloalmeida36@gmail.com',
      '03595976100',
      '64984250962',
      'Administrador',
      true,
      false,
      now()
    );
  END IF;

END $$;

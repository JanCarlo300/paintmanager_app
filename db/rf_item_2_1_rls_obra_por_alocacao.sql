-- ============================================================
-- Item 2.1 — RLS: Funcionário só lê obras em que está alocado
-- Execute este script no SQL Editor do Supabase Dashboard.
-- ============================================================
-- O QUE ESTE SCRIPT FAZ:
--   Hoje, QUALQUER usuário autenticado pode ler a tabela 'obra'
--   inteira (política "Autenticados podem ler obras", sem condição
--   nenhuma além de estar logado). O app já filtra isso na tela para
--   o Funcionário, mas o banco em si não impunha nada — alguém com a
--   sessão de um Funcionário, acessando a API diretamente (sem passar
--   pelo app), ainda conseguiria ler todas as obras.
--
--   Este script substitui essa política por uma que respeita a
--   alocação: Administrador e Gerente continuam vendo tudo;
--   Funcionário só vê as obras em que está na tabela 'equipe_obra'.
--
-- IMPORTANTE — teste antes de confiar:
--   Depois de rodar, faça login como Administrador e como Gerente e
--   confirme que a tela de Obras continua mostrando todas. Depois
--   logue como um Funcionário alocado em pelo menos 1 obra e confirme
--   que só aparece(m) a(s) obra(s) dele.
--
-- COMO DESFAZER (se algo quebrar):
--   DROP POLICY IF EXISTS "Leitura de obras respeita alocacao do funcionario" ON public.obra;
--   CREATE POLICY "Autenticados podem ler obras"
--     ON public.obra FOR SELECT USING (auth.role() = 'authenticated');
--   (isso volta exatamente ao comportamento de antes deste script)
-- ============================================================

DROP POLICY IF EXISTS "Autenticados podem ler obras" ON public.obra;

CREATE POLICY "Leitura de obras respeita alocacao do funcionario"
  ON public.obra
  FOR SELECT
  USING (
    -- Administrador e Gerente: acesso total, sem restrição.
    EXISTS (
      SELECT 1 FROM public.usuario u
      WHERE u.auth_id = auth.uid()
        AND u.funcao IN ('Administrador', 'Gerente')
    )
    OR
    -- Funcionário: só obras em que está na equipe alocada.
    EXISTS (
      SELECT 1 FROM public.equipe_obra eo
      JOIN public.usuario u ON u.id_usuario = eo.usuario_id
      WHERE eo.obra_id = public.obra.id_obra
        AND u.auth_id = auth.uid()
    )
  );

-- As políticas de INSERT/UPDATE/DELETE da tabela 'obra' não mudam
-- aqui: "Nova Obra" e "trocar status" já ficam escondidos na tela para
-- o Funcionário (item 2.1 feito no app). Se quiser bloquear também no
-- banco essas outras ações, é um script à parte — me avise.

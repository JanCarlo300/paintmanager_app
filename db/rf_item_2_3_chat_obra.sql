-- ============================================================
-- Item 2.3 — Chat da Obra (substitui o campo "Anotações")
-- Execute este script no SQL Editor do Supabase Dashboard.
-- ============================================================
-- O QUE ESTE SCRIPT FAZ:
--   1. Cria a tabela 'obra_mensagem' (uma linha por mensagem do chat).
--   2. Preenche autor_nome/autor_funcao automaticamente a partir da
--      tabela 'usuario' (o app não consegue "fingir" outro autor).
--   3. RLS: mesma regra da tabela 'obra' (item 2.1) — Administrador e
--      Gerente leem/escrevem em qualquer obra; Funcionário só nas obras
--      em que está alocado. Ninguém edita nem apaga mensagem.
--   4. Copia o texto atual de "Anotações" de cada obra como a 1ª
--      mensagem do chat ("Observação importada").
--   5. Liga o Realtime na tabela (mensagens aparecem na hora).
--
-- A coluna 'obra.anotacoes' NÃO é apagada — fica como backup. O app
-- simplesmente para de usá-la.
--
-- COMO DESFAZER:
--   ALTER PUBLICATION supabase_realtime DROP TABLE public.obra_mensagem;
--   DROP TABLE IF EXISTS public.obra_mensagem;
--   DROP FUNCTION IF EXISTS public.preencher_autor_mensagem();
-- ============================================================

-- 1. TABELA
CREATE TABLE IF NOT EXISTS public.obra_mensagem (
  id_mensagem   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  obra_id       BIGINT NOT NULL REFERENCES public.obra(id_obra) ON DELETE CASCADE,
  usuario_id    BIGINT REFERENCES public.usuario(id_usuario) ON DELETE SET NULL,  -- NULL = mensagem importada
  autor_nome    TEXT NOT NULL DEFAULT '',
  autor_funcao  TEXT NOT NULL DEFAULT '',
  texto         TEXT NOT NULL CHECK (btrim(texto) <> ''),
  criado_em     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_obra_mensagem_obra_criado
  ON public.obra_mensagem (obra_id, criado_em);

-- 2. AUTOR PREENCHIDO PELO BANCO
CREATE OR REPLACE FUNCTION public.preencher_autor_mensagem()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.usuario_id IS NOT NULL THEN
    SELECT u.nome, u.funcao INTO NEW.autor_nome, NEW.autor_funcao
    FROM public.usuario u
    WHERE u.id_usuario = NEW.usuario_id;
  END IF;
  NEW.criado_em := now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_preencher_autor_mensagem ON public.obra_mensagem;
CREATE TRIGGER trg_preencher_autor_mensagem
  BEFORE INSERT ON public.obra_mensagem
  FOR EACH ROW
  EXECUTE FUNCTION public.preencher_autor_mensagem();

-- 3. RLS
ALTER TABLE public.obra_mensagem ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Leitura do chat respeita alocacao" ON public.obra_mensagem;
CREATE POLICY "Leitura do chat respeita alocacao"
  ON public.obra_mensagem
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.usuario u
      WHERE u.auth_id = auth.uid()
        AND u.funcao IN ('Administrador', 'Gerente')
    )
    OR
    EXISTS (
      SELECT 1 FROM public.equipe_obra eo
      JOIN public.usuario u ON u.id_usuario = eo.usuario_id
      WHERE eo.obra_id = obra_mensagem.obra_id
        AND u.auth_id = auth.uid()
    )
  );

-- Só pode enviar em nome de si mesmo, e só em obra que pode acessar.
DROP POLICY IF EXISTS "Envio no chat respeita alocacao" ON public.obra_mensagem;
CREATE POLICY "Envio no chat respeita alocacao"
  ON public.obra_mensagem
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.usuario u
      WHERE u.auth_id = auth.uid()
        AND u.id_usuario = obra_mensagem.usuario_id
    )
    AND (
      EXISTS (
        SELECT 1 FROM public.usuario u
        WHERE u.auth_id = auth.uid()
          AND u.funcao IN ('Administrador', 'Gerente')
      )
      OR
      EXISTS (
        SELECT 1 FROM public.equipe_obra eo
        JOIN public.usuario u ON u.id_usuario = eo.usuario_id
        WHERE eo.obra_id = obra_mensagem.obra_id
          AND u.auth_id = auth.uid()
      )
    )
  );

-- 4. MIGRA AS ANOTAÇÕES ANTIGAS (só roda uma vez: ignora obra que já tem mensagem importada)
INSERT INTO public.obra_mensagem (obra_id, usuario_id, autor_nome, autor_funcao, texto)
SELECT o.id_obra, NULL, 'Observação importada', 'Sistema', o.anotacoes
FROM public.obra o
WHERE o.anotacoes IS NOT NULL
  AND btrim(o.anotacoes) <> ''
  AND NOT EXISTS (
    SELECT 1 FROM public.obra_mensagem m
    WHERE m.obra_id = o.id_obra AND m.usuario_id IS NULL
  );

-- 5. REALTIME
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'obra_mensagem'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.obra_mensagem;
  END IF;
END $$;

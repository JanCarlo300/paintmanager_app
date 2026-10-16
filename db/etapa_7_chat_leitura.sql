-- ============================================================
-- Etapa 7 — Aviso de mensagens novas do chat na tela de Obras
-- Execute este script no SQL Editor do Supabase Dashboard.
-- Rode DEPOIS do rf_item_2_3_chat_obra.sql. Seguro rodar duas vezes.
-- ============================================================
-- Regra (decisão do Jan, 15/10/2026): todos veem o aviso, cada um nas
-- suas obras — Administrador e Gerente em todas, Funcionário nas obras
-- em que está alocado. Mensagem enviada pela própria pessoa não conta,
-- nem a "observação importada" das antigas Anotações.
--
--   * chat_leitura: até quando cada usuário leu o chat de cada obra;
--   * chat_nao_lidas(): quantas mensagens novas há por obra, para quem
--     está logado (respeita a RLS do chat: Funcionário só conta as
--     obras em que está alocado);
--   * marcar_chat_lido(obra): chamada quando o chat é aberto.
--
-- Ponto de partida: tudo que já existe hoje conta como lido, para o
-- aviso não acender em todas as obras de uma vez. Só mensagens novas,
-- a partir de agora, geram aviso.
--
-- COMO DESFAZER:
--   DROP FUNCTION IF EXISTS public.chat_nao_lidas();
--   DROP FUNCTION IF EXISTS public.marcar_chat_lido(BIGINT);
--   DROP TABLE IF EXISTS public.chat_leitura;
-- ============================================================

CREATE TABLE IF NOT EXISTS public.chat_leitura (
  usuario_id  BIGINT NOT NULL REFERENCES public.usuario(id_usuario) ON DELETE CASCADE,
  obra_id     BIGINT NOT NULL REFERENCES public.obra(id_obra) ON DELETE CASCADE,
  lido_ate    TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (usuario_id, obra_id)
);

ALTER TABLE public.chat_leitura ENABLE ROW LEVEL SECURITY;

-- Cada um só lê e grava a própria marcação de leitura.
DROP POLICY IF EXISTS "Leitura propria do chat_leitura" ON public.chat_leitura;
CREATE POLICY "Leitura propria do chat_leitura"
  ON public.chat_leitura FOR SELECT
  USING (EXISTS (SELECT 1 FROM public.usuario u
                 WHERE u.id_usuario = chat_leitura.usuario_id AND u.auth_id = auth.uid()));

DROP POLICY IF EXISTS "Insercao propria do chat_leitura" ON public.chat_leitura;
CREATE POLICY "Insercao propria do chat_leitura"
  ON public.chat_leitura FOR INSERT
  WITH CHECK (EXISTS (SELECT 1 FROM public.usuario u
                      WHERE u.id_usuario = chat_leitura.usuario_id AND u.auth_id = auth.uid()));

DROP POLICY IF EXISTS "Atualizacao propria do chat_leitura" ON public.chat_leitura;
CREATE POLICY "Atualizacao propria do chat_leitura"
  ON public.chat_leitura FOR UPDATE
  USING (EXISTS (SELECT 1 FROM public.usuario u
                 WHERE u.id_usuario = chat_leitura.usuario_id AND u.auth_id = auth.uid()));

-- Ponto de partida (só cria o que falta; não mexe em leituras já registradas).
INSERT INTO public.chat_leitura (usuario_id, obra_id, lido_ate)
SELECT u.id_usuario, o.id_obra, now()
FROM public.usuario u
CROSS JOIN public.obra o
ON CONFLICT (usuario_id, obra_id) DO NOTHING;

CREATE OR REPLACE FUNCTION public.marcar_chat_lido(p_obra_id BIGINT)
RETURNS VOID
LANGUAGE sql
AS $$
  INSERT INTO public.chat_leitura (usuario_id, obra_id, lido_ate)
  SELECT u.id_usuario, p_obra_id, now()
  FROM public.usuario u
  WHERE u.auth_id = auth.uid()
  ON CONFLICT (usuario_id, obra_id) DO UPDATE SET lido_ate = excluded.lido_ate;
$$;

CREATE OR REPLACE FUNCTION public.chat_nao_lidas()
RETURNS TABLE (obra_id BIGINT, nao_lidas BIGINT)
LANGUAGE sql
STABLE
AS $$
  WITH eu AS (
    SELECT u.id_usuario FROM public.usuario u WHERE u.auth_id = auth.uid()
  )
  SELECT m.obra_id, count(*)::BIGINT
  FROM public.obra_mensagem m
  CROSS JOIN eu
  LEFT JOIN public.chat_leitura l
    ON l.obra_id = m.obra_id AND l.usuario_id = eu.id_usuario
  WHERE m.usuario_id IS NOT NULL
    AND m.usuario_id <> eu.id_usuario
    AND m.criado_em > coalesce(l.lido_ate, '-infinity'::timestamptz)
  GROUP BY m.obra_id;
$$;

REVOKE EXECUTE ON FUNCTION public.marcar_chat_lido(BIGINT) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.chat_nao_lidas() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.marcar_chat_lido(BIGINT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.chat_nao_lidas() TO authenticated;

-- Conferência: quantas marcações de leitura existem (usuários x obras).
SELECT count(*) AS marcacoes_de_leitura FROM public.chat_leitura;

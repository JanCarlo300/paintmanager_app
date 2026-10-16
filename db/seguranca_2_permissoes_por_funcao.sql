-- ============================================================
-- Segurança 2 — Permissões por função também no banco (RLS)
-- Execute no SQL Editor do Supabase Dashboard. Seguro rodar duas vezes.
-- Tudo roda numa TRANSAÇÃO: se der qualquer erro, nada muda.
-- ============================================================
-- O PROBLEMA:
--   A divisão Administrador / Gerente / Funcionário valia só nas telas.
--   No banco, qualquer usuário logado lia e alterava cliente, orçamento,
--   financeiro e usuários pela API. Pior: a regra "usuário pode
--   atualizar o próprio registro" deixava um Funcionário mudar a própria
--   função para "Administrador", e qualquer logado podia inserir em
--   'usuario'.
--
-- A REGRA (a mesma matriz que o app já aplica + DERS: só Administrador
-- exclui obras, usuários e registros financeiros):
--
--   tabela       | Administrador | Gerente               | Funcionário
--   -------------+---------------+-----------------------+------------------------------
--   cliente      | tudo          | tudo, menos excluir   | nada
--   orcamento    | tudo          | tudo                  | nada
--   transacao    | tudo          | tudo, menos excluir   | nada
--   obra         | tudo          | tudo, menos excluir   | lê as alocadas; altera só o
--                |               |                       | checklist (etapas/progresso)
--   equipe_obra  | tudo          | tudo                  | vê a equipe das suas obras
--   usuario      | tudo          | lê todos              | lê o próprio e os colegas das
--                |               |                       | suas obras; altera só o
--                |               |                       | "primeiro acesso"
--
--   obra_mensagem e chat_leitura já tinham regras próprias e não mudam.
--   Usuário INATIVO perde as permissões mesmo com a sessão aberta
--   (continua lendo o próprio registro, para o login avisar "inativo").
--
-- COMO FUNCIONA: todas as políticas antigas destas 6 tabelas são
-- apagadas (no PostgreSQL, uma política aberta que sobrasse anularia as
-- novas) e recriadas. As funções auxiliares são SECURITY DEFINER para
-- consultar a função do usuário sem cair em recursão nas políticas.
--
-- TESTE DEPOIS DE RODAR: entrar como Administrador, Gerente e
-- Funcionário e usar as telas normalmente (lista no fim da resposta).
--
-- COMO DESFAZER: rodar de novo os scripts antigos de cada tabela
-- (supabase_migrate_*.sql, rf_item_2_1_rls_obra_por_alocacao.sql,
-- seguranca_1_login_sem_leitura_anonima.sql) e apagar os 2 triggers:
--   DROP TRIGGER IF EXISTS trg_limitar_edicao_obra_funcionario ON public.obra;
--   DROP TRIGGER IF EXISTS trg_limitar_edicao_proprio_usuario ON public.usuario;
-- ============================================================

BEGIN;

-- ------------------------------------------------------------
-- 1. Funções auxiliares (quem é o usuário logado)
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.minha_funcao()
RETURNS TEXT LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT u.funcao FROM public.usuario u
  WHERE u.auth_id = auth.uid() AND u.status = true
  LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.meu_id_usuario()
RETURNS BIGINT LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT u.id_usuario FROM public.usuario u
  WHERE u.auth_id = auth.uid() AND u.status = true
  LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.eh_admin()
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT coalesce(public.minha_funcao() = 'Administrador', false);
$$;

CREATE OR REPLACE FUNCTION public.eh_gestor()
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT coalesce(public.minha_funcao() IN ('Administrador', 'Gerente'), false);
$$;

-- Obras em que o usuário logado está alocado.
CREATE OR REPLACE FUNCTION public.minhas_obras()
RETURNS SETOF BIGINT LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT eo.obra_id FROM public.equipe_obra eo
  WHERE eo.usuario_id = public.meu_id_usuario();
$$;

REVOKE ALL ON FUNCTION public.minha_funcao(), public.meu_id_usuario(), public.eh_admin(),
  public.eh_gestor(), public.minhas_obras() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.minha_funcao(), public.meu_id_usuario(), public.eh_admin(),
  public.eh_gestor(), public.minhas_obras() TO authenticated;

-- ------------------------------------------------------------
-- 2. Apaga TODAS as políticas antigas das 6 tabelas
-- ------------------------------------------------------------
DO $$
DECLARE p RECORD;
BEGIN
  FOR p IN
    SELECT policyname, tablename FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename IN ('cliente', 'orcamento', 'transacao', 'obra', 'equipe_obra', 'usuario')
  LOOP
    EXECUTE format('DROP POLICY %I ON public.%I', p.policyname, p.tablename);
  END LOOP;
END $$;

ALTER TABLE public.cliente     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orcamento   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transacao   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.obra        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.equipe_obra ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.usuario     ENABLE ROW LEVEL SECURITY;

-- ------------------------------------------------------------
-- 3. cliente — Administrador e Gerente; só Administrador exclui
-- ------------------------------------------------------------
CREATE POLICY "cliente: gestores leem"       ON public.cliente FOR SELECT USING (public.eh_gestor());
CREATE POLICY "cliente: gestores inserem"    ON public.cliente FOR INSERT WITH CHECK (public.eh_gestor());
CREATE POLICY "cliente: gestores alteram"    ON public.cliente FOR UPDATE USING (public.eh_gestor()) WITH CHECK (public.eh_gestor());
CREATE POLICY "cliente: admin exclui"        ON public.cliente FOR DELETE USING (public.eh_admin());

-- ------------------------------------------------------------
-- 4. orcamento — Administrador e Gerente
-- ------------------------------------------------------------
CREATE POLICY "orcamento: gestores leem"     ON public.orcamento FOR SELECT USING (public.eh_gestor());
CREATE POLICY "orcamento: gestores inserem"  ON public.orcamento FOR INSERT WITH CHECK (public.eh_gestor());
CREATE POLICY "orcamento: gestores alteram"  ON public.orcamento FOR UPDATE USING (public.eh_gestor()) WITH CHECK (public.eh_gestor());
CREATE POLICY "orcamento: gestores excluem"  ON public.orcamento FOR DELETE USING (public.eh_gestor());

-- ------------------------------------------------------------
-- 5. transacao — Administrador e Gerente; só Administrador exclui (DERS)
-- ------------------------------------------------------------
CREATE POLICY "transacao: gestores leem"     ON public.transacao FOR SELECT USING (public.eh_gestor());
CREATE POLICY "transacao: gestores inserem"  ON public.transacao FOR INSERT WITH CHECK (public.eh_gestor());
CREATE POLICY "transacao: gestores alteram"  ON public.transacao FOR UPDATE USING (public.eh_gestor()) WITH CHECK (public.eh_gestor());
CREATE POLICY "transacao: admin exclui"      ON public.transacao FOR DELETE USING (public.eh_admin());

-- ------------------------------------------------------------
-- 6. obra — gestores tudo (só Admin exclui); Funcionário só nas alocadas
-- ------------------------------------------------------------
CREATE POLICY "obra: gestores e alocados leem" ON public.obra FOR SELECT
  USING (public.eh_gestor() OR id_obra IN (SELECT public.minhas_obras()));
CREATE POLICY "obra: gestores inserem" ON public.obra FOR INSERT
  WITH CHECK (public.eh_gestor());
CREATE POLICY "obra: gestores e alocados alteram" ON public.obra FOR UPDATE
  USING (public.eh_gestor() OR id_obra IN (SELECT public.minhas_obras()))
  WITH CHECK (public.eh_gestor() OR id_obra IN (SELECT public.minhas_obras()));
CREATE POLICY "obra: admin exclui" ON public.obra FOR DELETE
  USING (public.eh_admin());

-- O Funcionário pode ALTERAR a obra, mas só o checklist: a política não
-- separa colunas, então este trigger mantém o valor antigo de todo o
-- resto (o app reenvia a obra inteira ao marcar uma etapa).
-- Sem usuário logado (SQL Editor, Edge Function) não há o que limitar.
CREATE OR REPLACE FUNCTION public.limitar_edicao_obra_funcionario()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  v_etapas    public.obra.etapas_servico%TYPE := NEW.etapas_servico;
  v_progresso public.obra.progresso%TYPE      := NEW.progresso;
BEGIN
  IF auth.uid() IS NULL OR public.eh_gestor() THEN
    RETURN NEW;
  END IF;
  NEW := OLD;
  NEW.etapas_servico := v_etapas;
  NEW.progresso      := v_progresso;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_limitar_edicao_obra_funcionario ON public.obra;
CREATE TRIGGER trg_limitar_edicao_obra_funcionario
  BEFORE UPDATE ON public.obra
  FOR EACH ROW EXECUTE FUNCTION public.limitar_edicao_obra_funcionario();

-- ------------------------------------------------------------
-- 7. equipe_obra — gestores alocam; Funcionário vê a equipe das suas obras
-- ------------------------------------------------------------
CREATE POLICY "equipe_obra: gestores e alocados leem" ON public.equipe_obra FOR SELECT
  USING (public.eh_gestor() OR obra_id IN (SELECT public.minhas_obras()));
CREATE POLICY "equipe_obra: gestores inserem" ON public.equipe_obra FOR INSERT
  WITH CHECK (public.eh_gestor());
CREATE POLICY "equipe_obra: gestores excluem" ON public.equipe_obra FOR DELETE
  USING (public.eh_gestor());

-- ------------------------------------------------------------
-- 8. usuario — Admin gerencia; cada um vê o próprio; Funcionário vê os
--    colegas das suas obras. Cadastro novo só pela Edge Function
--    (service_role) ou por Administrador.
-- ------------------------------------------------------------
CREATE POLICY "usuario: leitura conforme funcao" ON public.usuario FOR SELECT
  USING (
    public.eh_gestor()
    OR auth_id = auth.uid()
    OR id_usuario IN (
      SELECT eo.usuario_id FROM public.equipe_obra eo
      WHERE eo.obra_id IN (SELECT public.minhas_obras())
    )
  );
CREATE POLICY "usuario: admin insere" ON public.usuario FOR INSERT
  WITH CHECK (public.eh_admin());
CREATE POLICY "usuario: admin altera qualquer um" ON public.usuario FOR UPDATE
  USING (public.eh_admin()) WITH CHECK (public.eh_admin());
CREATE POLICY "usuario: altera o proprio registro" ON public.usuario FOR UPDATE
  USING (auth_id = auth.uid()) WITH CHECK (auth_id = auth.uid());
-- Sem política de DELETE: usuário é inativado, nunca apagado.

-- No próprio registro, quem não é Administrador só muda "primeiro acesso"
-- (troca de senha obrigatória) — nunca a função, o status ou o CPF: o
-- resto volta ao valor antigo.
CREATE OR REPLACE FUNCTION public.limitar_edicao_proprio_usuario()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  v_primeiro_acesso public.usuario.primeiro_acesso%TYPE := NEW.primeiro_acesso;
BEGIN
  IF auth.uid() IS NULL OR public.eh_admin() THEN
    RETURN NEW;
  END IF;
  NEW := OLD;
  NEW.primeiro_acesso := v_primeiro_acesso;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_limitar_edicao_proprio_usuario ON public.usuario;
CREATE TRIGGER trg_limitar_edicao_proprio_usuario
  BEFORE UPDATE ON public.usuario
  FOR EACH ROW EXECUTE FUNCTION public.limitar_edicao_proprio_usuario();

COMMIT;

-- ------------------------------------------------------------
-- 9. Conferência: políticas das 6 tabelas (devem ser só as criadas acima)
-- ------------------------------------------------------------
SELECT tablename AS tabela, cmd AS operacao, policyname AS politica
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('cliente', 'orcamento', 'transacao', 'obra', 'equipe_obra', 'usuario')
ORDER BY tablename, cmd, policyname;

// Edge Function: criar-usuario
// ============================================================
// Cria um usuário novo (Auth + tabela 'usuario') inteiramente no
// servidor, usando a service_role key. Diferente do signUp() chamado
// direto do app, isso NUNCA troca a sessão de quem está chamando —
// por isso resolve o bug de "o admin virar o funcionário recém-criado".
//
// Só quem já está autenticado E é Administrador pode chamar esta função.
//
// COMO IMPLANTAR (sem precisar da Supabase CLI):
//   1. No painel do Supabase: Edge Functions -> Create a new function.
//   2. Nome da função: criar-usuario
//   3. Cole este arquivo inteiro no editor e clique em Deploy.
//   Não é preciso configurar nenhuma variável de ambiente: SUPABASE_URL,
//   SUPABASE_SERVICE_ROLE_KEY e SUPABASE_ANON_KEY já ficam disponíveis
//   automaticamente para toda Edge Function do projeto.
// ============================================================

import { createClient } from "npm:@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

function jsonResponse(body: unknown, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return jsonResponse({ error: "Não autenticado." }, 401);
    }

    // Cliente com privilégio total (só existe dentro da função, nunca no app)
    const supabaseAdmin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

    // Cliente que representa quem está chamando, para identificar com segurança
    const supabaseCaller = createClient(SUPABASE_URL, ANON_KEY, {
      global: { headers: { Authorization: authHeader } },
    });

    // 1. Identifica quem está chamando
    const { data: { user: chamador }, error: erroAuth } = await supabaseCaller.auth.getUser();
    if (erroAuth || !chamador) {
      return jsonResponse({ error: "Sessão inválida. Faça login novamente." }, 401);
    }

    // 2. Confere se quem está chamando é Administrador ativo
    const { data: perfilChamador, error: erroPerfil } = await supabaseAdmin
      .from("usuario")
      .select("funcao, status")
      .eq("auth_id", chamador.id)
      .maybeSingle();

    if (
      erroPerfil ||
      !perfilChamador ||
      perfilChamador.funcao !== "Administrador" ||
      perfilChamador.status !== true
    ) {
      return jsonResponse({ error: "Apenas administradores podem cadastrar usuários." }, 403);
    }

    // 3. Lê e valida os dados do novo usuário
    const { nome, email, cpf, telefone, funcao } = await req.json();

    if (!nome || !email || !cpf || !funcao) {
      return jsonResponse({ error: "Preencha todos os campos obrigatórios." }, 400);
    }

    const cpfLimpo = String(cpf).replace(/\D/g, "");
    if (cpfLimpo.length !== 11) {
      return jsonResponse({ error: "CPF inválido." }, 400);
    }

    // 4. Cria a conta no Auth, já confirmada (senha inicial = CPF)
    const { data: novoAuthUser, error: erroCriacao } = await supabaseAdmin.auth.admin.createUser({
      email,
      password: cpfLimpo,
      email_confirm: true,
    });

    if (erroCriacao || !novoAuthUser?.user) {
      const mensagem = erroCriacao?.message?.includes("already been registered")
        ? "Este e-mail já está cadastrado no sistema."
        : (erroCriacao?.message ?? "Erro ao criar usuário.");
      return jsonResponse({ error: mensagem }, 400);
    }

    // 5. Insere o registro correspondente na tabela 'usuario'
    const { error: erroInsercao } = await supabaseAdmin.from("usuario").insert({
      auth_id: novoAuthUser.user.id,
      nome,
      email,
      cpf: cpfLimpo,
      telefone: telefone ?? "",
      funcao,
      status: true,
      primeiro_acesso: true,
    });

    if (erroInsercao) {
      // Evita deixar uma conta órfã no Auth sem registro correspondente
      await supabaseAdmin.auth.admin.deleteUser(novoAuthUser.user.id);
      return jsonResponse({ error: "Erro ao salvar dados do usuário: " + erroInsercao.message }, 500);
    }

    return jsonResponse({ sucesso: true, auth_id: novoAuthUser.user.id }, 200);
  } catch (e) {
    return jsonResponse({ error: "Erro interno: " + String(e) }, 500);
  }
});

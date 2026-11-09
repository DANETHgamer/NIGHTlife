import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const reply = (status: number, body: Record<string, unknown>) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: cors });
  }

  if (req.method !== "POST") {
    return reply(405, { error: "Método não permitido." });
  }

  const url = Deno.env.get("SUPABASE_URL");
  const anon = Deno.env.get("SUPABASE_ANON_KEY");
  const secret = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!url || !anon || !secret) {
    return reply(500, { error: "Configure os segredos da função no Supabase." });
  }

  const authHeader = req.headers.get("Authorization") || "";

  if (!authHeader.startsWith("Bearer ")) {
    return reply(401, { error: "Faça login como Administrador Supremo." });
  }

  const caller = createClient(url, anon, {
    global: { headers: { Authorization: authHeader } },
    auth: { persistSession: false },
  });

  const { data: who, error: whoError } =
    await caller.auth.getUser(authHeader.slice(7));

  if (
    whoError ||
    who.user?.email?.toLowerCase() !== "danethgamer5@gmail.com"
  ) {
    return reply(403, {
      error: "Somente o Administrador Supremo pode cadastrar administradores.",
    });
  }

  const { data: access, error: accessError } =
    await caller.rpc("nightlife_obter_nivel_acesso");

  if (accessError || access?.nivel !== "supremo") {
    return reply(403, { error: "Permissão suprema não confirmada." });
  }

  let data: any;

  try {
    data = await req.json();
  } catch {
    return reply(400, { error: "Dados inválidos." });
  }

  const nome = String(data.nome_completo || "").trim();
  const cpf = String(data.cpf || "").replace(/\D/g, "");
  const telefone = String(data.telefone || "").trim();
  const email = String(data.email || "").trim().toLowerCase();
  const senha = String(data.senha || "");
  const estado = String(data.estado || "").trim().toUpperCase();

  if (nome.length < 2 || nome.length > 120)
    return reply(400, { error: "Informe o nome completo." });

  if (!/^\d{11}$/.test(cpf))
    return reply(400, { error: "CPF deve conter 11 números." });

  if (telefone.length < 8 || telefone.length > 20)
    return reply(400, { error: "Informe um telefone válido." });

  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email))
    return reply(400, { error: "Informe um e-mail válido." });

  if (senha.length < 8 || senha.length > 72)
    return reply(400, {
      error: "A senha inicial deve ter de 8 a 72 caracteres.",
    });

  if (!/^[A-Z]{2}$/.test(estado))
    return reply(400, { error: "Selecione um estado válido." });

  const admin = createClient(url, secret, {
    auth: { persistSession: false },
  });

  const { data: userPage, error: listError } =
    await admin.auth.admin.listUsers({ page: 1, perPage: 1000 });

  if (listError)
    return reply(500, {
      error: "Não foi possível validar contas existentes.",
    });

  if (userPage.users.some((u: any) => u.email?.toLowerCase() === email))
    return reply(409, { error: "Já existe uma conta com esse e-mail." });

  const { data: created, error: createError } =
    await admin.auth.admin.createUser({
      email,
      password: senha,
      email_confirm: true,
      user_metadata: {
        full_name: nome,
        phone: telefone,
      },
    });

  if (createError || !created.user)
    return reply(400, {
      error: createError?.message || "Não foi possível criar a conta.",
    });

  const { error: roleError } = await caller.rpc(
    "nightlife_criar_admin_regional_com_nome",
    {
      p_email: email,
      p_estado: estado,
      p_cidades: [],
      p_nome_completo: nome,
    }
  );

  if (roleError) {
    await admin.auth.admin.deleteUser(created.user.id);
    return reply(400, { error: roleError.message });
  }

  const { error: detailsError } = await admin
    .from("nightlife_dados_pessoais_admins_regionais")
    .insert({
      usuario_id: created.user.id,
      nome_completo: nome,
      cpf,
      telefone,
    });

  if (detailsError) {
    await admin.auth.admin.deleteUser(created.user.id);
    return reply(400, {
      error:
        detailsError.code === "23505"
          ? "Este CPF já está cadastrado."
          : "Dados pessoais não puderam ser salvos; a conta foi revertida.",
    });
  }

  return reply(201, {
    success: true,
    email,
    estado,
  });
});
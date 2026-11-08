-- NIGHTlife: painel dos oito administradores regionais e contagem de clientes por estado.
-- Não apaga nem altera estabelecimentos, usuários, planos ou pagamentos.

CREATE TABLE IF NOT EXISTS public.nightlife_dados_admins_regionais (
  usuario_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  nome_completo text NOT NULL CHECK (length(trim(nome_completo)) BETWEEN 2 AND 120),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.nightlife_dados_admins_regionais ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.nightlife_dados_admins_regionais FROM anon, authenticated, PUBLIC;

CREATE OR REPLACE FUNCTION public.nightlife_criar_admin_regional_com_nome(
  p_email text,
  p_estado text,
  p_cidades text[] DEFAULT '{}',
  p_nome_completo text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_usuario_id uuid;
  v_total integer;
BEGIN
  IF NOT public.nightlife_eh_admin_supremo() THEN
    RAISE EXCEPTION 'Somente o Administrador Supremo pode cadastrar administradores regionais.';
  END IF;

  IF p_nome_completo IS NULL OR length(trim(p_nome_completo)) < 2 OR length(trim(p_nome_completo)) > 120 THEN
    RAISE EXCEPTION 'Informe o nome completo do administrador.';
  END IF;

  SELECT id INTO v_usuario_id
  FROM auth.users
  WHERE lower(email) = lower(trim(p_email))
  LIMIT 1;

  IF v_usuario_id IS NULL THEN
    RAISE EXCEPTION 'Não existe uma conta de login com esse e-mail. A criação de conta e senha será feita pelo cadastro seguro de administradores.';
  END IF;

  SELECT count(*) INTO v_total FROM public.nightlife_admins_regionais;
  IF NOT EXISTS (SELECT 1 FROM public.nightlife_admins_regionais WHERE usuario_id = v_usuario_id)
     AND v_total >= 8 THEN
    RAISE EXCEPTION 'O limite de oito administradores regionais já foi atingido.';
  END IF;

  PERFORM public.nightlife_criar_admin_regional(p_email, p_estado, coalesce(p_cidades, '{}'::text[]));

  INSERT INTO public.nightlife_dados_admins_regionais(usuario_id, nome_completo, atualizado_em)
  VALUES (v_usuario_id, trim(p_nome_completo), now())
  ON CONFLICT (usuario_id) DO UPDATE
    SET nome_completo = EXCLUDED.nome_completo, atualizado_em = now();
END;
$$;

CREATE OR REPLACE FUNCTION public.nightlife_listar_painel_admins_regionais()
RETURNS TABLE(
  usuario_id uuid,
  email text,
  nome_completo text,
  estado text,
  ativo boolean,
  criado_em timestamptz,
  total_estabelecimentos bigint,
  estabelecimentos_ativos bigint
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  IF NOT public.nightlife_eh_admin_supremo() THEN
    RAISE EXCEPTION 'Acesso exclusivo do Administrador Supremo.';
  END IF;

  RETURN QUERY
  SELECT
    a.usuario_id,
    u.email::text,
    coalesce(
      nullif(d.nome_completo, ''),
      nullif(u.raw_user_meta_data->>'full_name', ''),
      nullif(u.raw_user_meta_data->>'nome_completo', ''),
      split_part(coalesce(u.email, ''), '@', 1)
    )::text,
    trim(a.estado)::text,
    a.ativo,
    a.criado_em,
    count(e.id)::bigint,
    count(e.id) FILTER (WHERE e.ativo IS DISTINCT FROM false)::bigint
  FROM public.nightlife_admins_regionais a
  JOIN auth.users u ON u.id = a.usuario_id
  LEFT JOIN public.nightlife_dados_admins_regionais d ON d.usuario_id = a.usuario_id
  LEFT JOIN public.estabelecimentos e
    ON upper(trim(coalesce(e.estado, ''))) = upper(trim(a.estado))
  GROUP BY a.usuario_id, u.email, d.nome_completo, u.raw_user_meta_data, a.estado, a.ativo, a.criado_em
  ORDER BY a.criado_em ASC
  LIMIT 8;
END;
$$;

REVOKE ALL ON FUNCTION public.nightlife_criar_admin_regional_com_nome(text,text,text[],text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.nightlife_listar_painel_admins_regionais() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.nightlife_criar_admin_regional_com_nome(text,text,text[],text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.nightlife_listar_painel_admins_regionais() TO authenticated;

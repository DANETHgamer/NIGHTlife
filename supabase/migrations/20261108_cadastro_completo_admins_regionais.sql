-- NIGHTlife: cadastro seguro dos administradores regionais.
CREATE TABLE IF NOT EXISTS public.nightlife_dados_pessoais_admins_regionais (
  usuario_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  nome_completo text NOT NULL,
  cpf text NOT NULL UNIQUE CHECK (cpf ~ '^[0-9]{11}$'),
  telefone text NOT NULL,
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.nightlife_dados_pessoais_admins_regionais ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.nightlife_dados_pessoais_admins_regionais FROM anon, authenticated, PUBLIC;

DROP FUNCTION IF EXISTS public.nightlife_listar_painel_admins_regionais();
CREATE FUNCTION public.nightlife_listar_painel_admins_regionais()
RETURNS TABLE(usuario_id uuid,email text,nome_completo text,cpf text,telefone text,estado text,ativo boolean,criado_em timestamptz,total_estabelecimentos bigint,estabelecimentos_ativos bigint)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth AS $$
BEGIN
  IF NOT public.nightlife_eh_admin_supremo() THEN RAISE EXCEPTION 'Acesso exclusivo do Administrador Supremo.'; END IF;
  RETURN QUERY
  SELECT a.usuario_id,u.email::text,d.nome_completo,d.cpf,d.telefone,trim(a.estado)::text,a.ativo,a.criado_em,count(e.id)::bigint,count(e.id) FILTER (WHERE e.ativo IS DISTINCT FROM false)::bigint
  FROM public.nightlife_admins_regionais a
  JOIN auth.users u ON u.id=a.usuario_id
  JOIN public.nightlife_dados_pessoais_admins_regionais d ON d.usuario_id=a.usuario_id
  LEFT JOIN public.estabelecimentos e ON upper(trim(coalesce(e.estado,'')))=upper(trim(a.estado))
  GROUP BY a.usuario_id,u.email,d.nome_completo,d.cpf,d.telefone,a.estado,a.ativo,a.criado_em
  ORDER BY a.criado_em ASC LIMIT 8;
END; $$;
REVOKE ALL ON FUNCTION public.nightlife_listar_painel_admins_regionais() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.nightlife_listar_painel_admins_regionais() TO authenticated;
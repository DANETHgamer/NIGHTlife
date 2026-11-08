-- NIGHTlife: estrutura de administracao regional e controle nacional
-- Execute no Supabase SQL Editor depois de revisar o backup do projeto.
-- Esta migration nao remove estabelecimentos nem altera planos/pagamentos.

ALTER TABLE public.estabelecimentos
  ADD COLUMN IF NOT EXISTS cidade text,
  ADD COLUMN IF NOT EXISTS estado char(2);

-- Identifica o primeiro cadastro conhecido sem alterar endereco, telefone ou plano.
UPDATE public.estabelecimentos
SET cidade = 'Jaraguá do Sul', estado = 'SC'
WHERE cidade IS NULL
  AND estado IS NULL
  AND endereco ILIKE '%jaragua%do%sul%';

CREATE TABLE IF NOT EXISTS public.nightlife_admins_regionais (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id uuid NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  estado char(2) NOT NULL CHECK (estado = upper(estado)),
  cidades text[] NOT NULL DEFAULT '{}',
  ativo boolean NOT NULL DEFAULT true,
  criado_por uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  criado_em timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_nightlife_admins_regionais_usuario
  ON public.nightlife_admins_regionais(usuario_id, ativo);

ALTER TABLE public.nightlife_admins_regionais ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins regionais veem seu proprio acesso" ON public.nightlife_admins_regionais;
CREATE POLICY "Admins regionais veem seu proprio acesso"
ON public.nightlife_admins_regionais
FOR SELECT TO authenticated
USING (
  usuario_id = auth.uid()
  OR EXISTS (
    SELECT 1 FROM public.perfis p
    WHERE p.id = auth.uid() AND p.tipo = 'admin'
  )
);

CREATE OR REPLACE FUNCTION public.nightlife_eh_admin_supremo()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.perfis p
    WHERE p.id = auth.uid() AND p.tipo = 'admin'
  );
$$;

CREATE OR REPLACE FUNCTION public.nightlife_admin_regional_tem_acesso(p_estabelecimento_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.nightlife_admins_regionais a
    JOIN public.estabelecimentos e ON e.id = p_estabelecimento_id
    WHERE a.usuario_id = auth.uid()
      AND a.ativo = true
      AND upper(trim(a.estado)) = upper(trim(e.estado))
      AND (
        cardinality(a.cidades) = 0
        OR lower(trim(coalesce(e.cidade, ''))) = ANY (
          ARRAY(SELECT lower(trim(c)) FROM unnest(a.cidades) AS c)
        )
      )
  );
$$;

CREATE OR REPLACE FUNCTION public.nightlife_obter_nivel_acesso()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE v_admin record;
BEGIN
  IF public.nightlife_eh_admin_supremo() THEN
    RETURN jsonb_build_object('nivel','supremo','estado',null,'cidades',jsonb_build_array());
  END IF;

  SELECT estado, cidades INTO v_admin
  FROM public.nightlife_admins_regionais
  WHERE usuario_id = auth.uid() AND ativo = true
  LIMIT 1;

  IF FOUND THEN
    RETURN jsonb_build_object(
      'nivel','regional',
      'estado',trim(v_admin.estado),
      'cidades',to_jsonb(v_admin.cidades)
    );
  END IF;

  RETURN jsonb_build_object('nivel','proprietario');
END;
$$;

CREATE OR REPLACE FUNCTION public.nightlife_criar_admin_regional(
  p_email text,
  p_estado text,
  p_cidades text[] DEFAULT '{}'
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE v_usuario_id uuid;
BEGIN
  IF NOT public.nightlife_eh_admin_supremo() THEN
    RAISE EXCEPTION 'Somente o Administrador Supremo pode criar administradores regionais.';
  END IF;

  IF p_email IS NULL OR length(trim(p_email)) < 5 OR length(trim(p_email)) > 254 THEN
    RAISE EXCEPTION 'Informe um e-mail válido.';
  END IF;

  IF p_estado IS NULL OR length(trim(p_estado)) <> 2 OR upper(trim(p_estado)) !~ '^[A-Z]{2}$' THEN
    RAISE EXCEPTION 'Informe a sigla válida do estado, por exemplo SC.';
  END IF;

  SELECT id INTO v_usuario_id
  FROM auth.users
  WHERE lower(email) = lower(trim(p_email))
  LIMIT 1;

  IF v_usuario_id IS NULL THEN
    RAISE EXCEPTION 'Não existe uma conta cadastrada com esse e-mail. Crie a conta primeiro.';
  END IF;

  IF v_usuario_id = auth.uid() THEN
    RAISE EXCEPTION 'Sua conta principal não pode ser rebaixada para administrador regional.';
  END IF;

  INSERT INTO public.nightlife_admins_regionais(usuario_id, estado, cidades, ativo, criado_por)
  VALUES (
    v_usuario_id,
    upper(trim(p_estado)),
    coalesce(p_cidades, '{}'),
    true,
    auth.uid()
  )
  ON CONFLICT (usuario_id)
  DO UPDATE SET
    estado = EXCLUDED.estado,
    cidades = EXCLUDED.cidades,
    ativo = true,
    criado_por = auth.uid();
END;
$$;

CREATE OR REPLACE FUNCTION public.nightlife_definir_status_admin_regional(
  p_usuario_id uuid,
  p_ativo boolean
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.nightlife_eh_admin_supremo() THEN
    RAISE EXCEPTION 'Somente o Administrador Supremo pode alterar administradores regionais.';
  END IF;

  UPDATE public.nightlife_admins_regionais
  SET ativo = p_ativo
  WHERE usuario_id = p_usuario_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Administrador regional não encontrado.';
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.nightlife_listar_admins_regionais()
RETURNS TABLE(
  usuario_id uuid,
  email text,
  estado text,
  cidades text[],
  ativo boolean,
  criado_em timestamptz
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
  SELECT a.usuario_id, u.email::text, trim(a.estado)::text, a.cidades, a.ativo, a.criado_em
  FROM public.nightlife_admins_regionais a
  JOIN auth.users u ON u.id = a.usuario_id
  ORDER BY a.criado_em DESC;
END;
$$;

CREATE OR REPLACE FUNCTION public.nightlife_listar_estabelecimentos_controle()
RETURNS TABLE(
  id uuid,
  nome text,
  cidade text,
  estado text,
  endereco text,
  telefone text,
  status_plano text,
  vencimento_em timestamptz,
  ativo boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.nightlife_eh_admin_supremo()
     AND NOT EXISTS (
       SELECT 1 FROM public.nightlife_admins_regionais a
       WHERE a.usuario_id = auth.uid() AND a.ativo = true
     ) THEN
    RAISE EXCEPTION 'Acesso negado à Central de Controle.';
  END IF;

  RETURN QUERY
  SELECT e.id, e.nome::text, e.cidade::text, trim(e.estado)::text,
         e.endereco::text, e.telefone::text, e.status_plano::text,
         e.vencimento_em, e.ativo
  FROM public.estabelecimentos e
  WHERE public.nightlife_eh_admin_supremo()
     OR public.nightlife_admin_regional_tem_acesso(e.id)
  ORDER BY e.criado_em DESC;
END;
$$;

CREATE OR REPLACE FUNCTION public.nightlife_resumo_central_controle()
RETURNS TABLE(
  total_estabelecimentos bigint,
  estabelecimentos_ativos bigint,
  estabelecimentos_inativos bigint,
  estado_administrado text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE v_estado text;
BEGIN
  IF public.nightlife_eh_admin_supremo() THEN
    v_estado := 'BR';
  ELSE
    SELECT trim(a.estado) INTO v_estado
    FROM public.nightlife_admins_regionais a
    WHERE a.usuario_id = auth.uid() AND a.ativo = true
    LIMIT 1;

    IF v_estado IS NULL THEN
      RAISE EXCEPTION 'Acesso negado à Central de Controle.';
    END IF;
  END IF;

  RETURN QUERY
  SELECT count(*),
         count(*) FILTER (WHERE e.ativo = true),
         count(*) FILTER (WHERE e.ativo = false),
         v_estado
  FROM public.estabelecimentos e
  WHERE public.nightlife_eh_admin_supremo()
     OR public.nightlife_admin_regional_tem_acesso(e.id);
END;
$$;

CREATE OR REPLACE FUNCTION public.nightlife_alterar_status_estabelecimento_regional(
  p_estabelecimento_id uuid,
  p_ativo boolean
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.nightlife_admin_regional_tem_acesso(p_estabelecimento_id) THEN
    RAISE EXCEPTION 'Você só pode administrar estabelecimentos da sua região.';
  END IF;

  UPDATE public.estabelecimentos
  SET ativo = p_ativo
  WHERE id = p_estabelecimento_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Estabelecimento não encontrado.';
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.nightlife_eh_admin_supremo() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.nightlife_admin_regional_tem_acesso(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.nightlife_obter_nivel_acesso() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.nightlife_criar_admin_regional(text,text,text[]) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.nightlife_definir_status_admin_regional(uuid,boolean) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.nightlife_listar_admins_regionais() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.nightlife_listar_estabelecimentos_controle() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.nightlife_resumo_central_controle() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.nightlife_alterar_status_estabelecimento_regional(uuid,boolean) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.nightlife_obter_nivel_acesso() TO authenticated;
GRANT EXECUTE ON FUNCTION public.nightlife_criar_admin_regional(text,text,text[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.nightlife_definir_status_admin_regional(uuid,boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION public.nightlife_listar_admins_regionais() TO authenticated;
GRANT EXECUTE ON FUNCTION public.nightlife_listar_estabelecimentos_controle() TO authenticated;
GRANT EXECUTE ON FUNCTION public.nightlife_resumo_central_controle() TO authenticated;
GRANT EXECUTE ON FUNCTION public.nightlife_alterar_status_estabelecimento_regional(uuid,boolean) TO authenticated;

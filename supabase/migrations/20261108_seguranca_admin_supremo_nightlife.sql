-- NIGHTlife: garante que somente a conta principal seja Administrador Supremo.
-- Esta migration não apaga usuários, estabelecimentos, planos ou pagamentos.

CREATE OR REPLACE FUNCTION public.nightlife_eh_admin_supremo()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM auth.users u
    WHERE u.id = auth.uid()
      AND lower(coalesce(u.email, '')) = 'danethgamer5@gmail.com'
  );
$$;

REVOKE ALL ON FUNCTION public.nightlife_eh_admin_supremo() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.nightlife_eh_admin_supremo() TO authenticated;

-- Revalida o nível usando a função acima: conta principal, regional ativo ou proprietário.
CREATE OR REPLACE FUNCTION public.nightlife_obter_nivel_acesso()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_admin record;
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

REVOKE ALL ON FUNCTION public.nightlife_obter_nivel_acesso() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.nightlife_obter_nivel_acesso() TO authenticated;

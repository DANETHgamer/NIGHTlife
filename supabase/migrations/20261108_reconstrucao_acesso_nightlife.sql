-- NIGHTlife | Reconstrucao segura do controle de acesso
-- Mantem os usuarios, estabelecimentos, eventos, planos e pagamentos existentes.
-- Nao apaga tabelas nem redefine senhas.
-- Conta Suprema exclusiva: danethgamer5@gmail.com

CREATE OR REPLACE FUNCTION public.nightlife_eh_admin_supremo()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM auth.users AS u
    WHERE u.id = auth.uid()
      AND lower(coalesce(u.email, '')) = 'danethgamer5@gmail.com'
  );
$$;

REVOKE ALL ON FUNCTION public.nightlife_eh_admin_supremo() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.nightlife_eh_admin_supremo() TO authenticated;

CREATE OR REPLACE FUNCTION public.nightlife_obter_nivel_acesso()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_estado text;
  v_cidades text[];
BEGIN
  -- Nivel 1: Administrador Supremo, reconhecido pelo e-mail da conta principal.
  IF public.nightlife_eh_admin_supremo() THEN
    RETURN jsonb_build_object(
      'nivel', 'supremo',
      'estado', null,
      'cidades', jsonb_build_array()
    );
  END IF;

  -- Nivel 2: Administrador Regional ativo.
  SELECT trim(a.estado)::text, coalesce(a.cidades, '{}'::text[])
    INTO v_estado, v_cidades
  FROM public.nightlife_admins_regionais AS a
  WHERE a.usuario_id = auth.uid()
    AND a.ativo = true
  LIMIT 1;

  IF FOUND THEN
    RETURN jsonb_build_object(
      'nivel', 'regional',
      'estado', v_estado,
      'cidades', to_jsonb(v_cidades)
    );
  END IF;

  -- Nivel 3: Proprietario. O acesso aos seus estabelecimentos continua
  -- limitado pelas politicas RLS e pelo vinculo usuario_id.
  RETURN jsonb_build_object('nivel', 'proprietario');
END;
$$;

REVOKE ALL ON FUNCTION public.nightlife_obter_nivel_acesso() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.nightlife_obter_nivel_acesso() TO authenticated;

-- Permite que as rotinas administrativas existentes usem a verificacao
-- atualizada da conta Suprema. Nenhum dado e removido ou recriado.

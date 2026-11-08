-- NIGHTlife: controles exclusivos do Administrador Supremo
-- Conta suprema fixada ao e-mail pessoal informado pelo titular.

CREATE OR REPLACE FUNCTION public.nightlife_eh_admin_supremo()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1 FROM auth.users u
    WHERE u.id = auth.uid()
      AND lower(trim(u.email)) = 'danethgamer5@gmail.com'
  );
$$;

CREATE OR REPLACE FUNCTION public.nightlife_salvar_chave_pix_admin(p_chave_pix text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.nightlife_eh_admin_supremo() THEN
    RAISE EXCEPTION 'Somente o Administrador Supremo pode alterar a chave Pix.';
  END IF;
  IF p_chave_pix IS NULL OR length(trim(p_chave_pix)) < 3 OR length(trim(p_chave_pix)) > 200 THEN
    RAISE EXCEPTION 'Informe uma chave Pix válida.';
  END IF;
  INSERT INTO public.configuracoes_plataforma (id, chave_pix)
  VALUES (1, trim(p_chave_pix))
  ON CONFLICT (id) DO UPDATE SET chave_pix = EXCLUDED.chave_pix;
END;
$$;

CREATE OR REPLACE FUNCTION public.nightlife_excluir_estabelecimento_desativado(p_estabelecimento_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.nightlife_eh_admin_supremo() THEN
    RAISE EXCEPTION 'Acesso exclusivo do Administrador Supremo.';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.estabelecimentos
    WHERE id = p_estabelecimento_id AND ativo = false
  ) THEN
    RAISE EXCEPTION 'Somente estabelecimentos desativados podem ser excluídos.';
  END IF;
  DELETE FROM public.estabelecimentos WHERE id = p_estabelecimento_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.nightlife_remover_admin_regional(p_usuario_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.nightlife_eh_admin_supremo() THEN
    RAISE EXCEPTION 'Acesso exclusivo do Administrador Supremo.';
  END IF;
  IF p_usuario_id = auth.uid() THEN
    RAISE EXCEPTION 'A conta principal não pode ser removida.';
  END IF;
  DELETE FROM public.nightlife_admins_regionais WHERE usuario_id = p_usuario_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Vínculo regional não encontrado.';
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION public.nightlife_eh_admin_supremo() TO authenticated;
GRANT EXECUTE ON FUNCTION public.nightlife_salvar_chave_pix_admin(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.nightlife_excluir_estabelecimento_desativado(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.nightlife_remover_admin_regional(uuid) TO authenticated;

-- NIGHTlife | Acesso reservado do proprietário e chave Pix centralizada
-- Execute este arquivo uma única vez no Supabase SQL Editor.
-- Não altera nem remove estabelecimentos, usuários, planos ou pagamentos.

ALTER TABLE public.estabelecimentos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Proprietario ve seus estabelecimentos NIGHTlife" ON public.estabelecimentos;
CREATE POLICY "Proprietario ve seus estabelecimentos NIGHTlife"
ON public.estabelecimentos FOR SELECT TO authenticated
USING (usuario_id = auth.uid());

DROP POLICY IF EXISTS "Proprietario cadastra seu estabelecimento NIGHTlife" ON public.estabelecimentos;
CREATE POLICY "Proprietario cadastra seu estabelecimento NIGHTlife"
ON public.estabelecimentos FOR INSERT TO authenticated
WITH CHECK (usuario_id = auth.uid());

CREATE OR REPLACE FUNCTION public.nightlife_vincular_estabelecimentos_proprietario()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_email text;
  v_total integer;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Entre na sua conta para vincular os estabelecimentos.';
  END IF;

  SELECT lower(email) INTO v_email FROM auth.users WHERE id = auth.uid();
  IF v_email IS NULL OR v_email = '' THEN
    RAISE EXCEPTION 'Não foi possível identificar o e-mail da conta.';
  END IF;

  UPDATE public.estabelecimentos
  SET usuario_id = auth.uid()
  WHERE usuario_id IS NULL
    AND position(lower('E-mail: ' || v_email) in lower(coalesce(descricao,''))) > 0;

  GET DIAGNOSTICS v_total = ROW_COUNT;
  RETURN v_total;
END;
$$;

REVOKE ALL ON FUNCTION public.nightlife_vincular_estabelecimentos_proprietario() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.nightlife_vincular_estabelecimentos_proprietario() TO authenticated;

CREATE OR REPLACE FUNCTION public.nightlife_obter_chave_pix_proprietario()
RETURNS text
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_chave text;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Acesso permitido somente para contas autenticadas.';
  END IF;

  IF coalesce(public.nightlife_obter_nivel_acesso()->>'nivel','') <> 'proprietario' THEN
    RAISE EXCEPTION 'Esta consulta é exclusiva da Área do Proprietário.';
  END IF;

  SELECT chave_pix INTO v_chave
  FROM public.configuracoes_plataforma
  WHERE id = 1
  LIMIT 1;

  RETURN v_chave;
END;
$$;

REVOKE ALL ON FUNCTION public.nightlife_obter_chave_pix_proprietario() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.nightlife_obter_chave_pix_proprietario() TO authenticated;

-- NIGHTlife: códigos de visita presencial gerados pelo cliente e confirmados pelo estabelecimento.
-- Execute esta migration uma única vez no Supabase SQL Editor.
CREATE TABLE IF NOT EXISTS public.visitas_nightlife (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  estabelecimento_id uuid NOT NULL REFERENCES public.estabelecimentos(id) ON DELETE CASCADE,
  codigo text NOT NULL UNIQUE,
  visitante_id text NOT NULL,
  status text NOT NULL DEFAULT 'pendente' CHECK(status IN ('pendente','confirmado')),
  criado_em timestamptz NOT NULL DEFAULT now(),
  expira_em timestamptz NOT NULL DEFAULT (now() + interval '24 hours'),
  confirmado_em timestamptz
);
CREATE INDEX IF NOT EXISTS idx_visitas_nightlife_estabelecimento_status ON public.visitas_nightlife(estabelecimento_id,status,criado_em DESC);
ALTER TABLE public.visitas_nightlife ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Proprietarios leem visitas do estabelecimento" ON public.visitas_nightlife;
CREATE POLICY "Proprietarios leem visitas do estabelecimento" ON public.visitas_nightlife FOR SELECT TO authenticated USING (
 EXISTS(SELECT 1 FROM public.estabelecimentos e WHERE e.id=estabelecimento_id AND e.usuario_id=auth.uid())
 OR EXISTS(SELECT 1 FROM public.perfis p WHERE p.id=auth.uid() AND p.tipo='admin')
);
CREATE OR REPLACE FUNCTION public.gerar_visita_nightlife(p_estabelecimento_id uuid,p_visitante_id text)
RETURNS text LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$
DECLARE v_codigo text;
BEGIN
 IF p_visitante_id IS NULL OR length(p_visitante_id)<8 OR length(p_visitante_id)>120 THEN RAISE EXCEPTION 'Identificador de visitante inválido.'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.estabelecimentos WHERE id=p_estabelecimento_id AND ativo=true AND status_plano IN ('teste','ativo','tolerancia')) THEN RAISE EXCEPTION 'Estabelecimento indisponível para visitas pelo NIGHTlife.'; END IF;
 v_codigo := 'NL-' || upper(substr(replace(gen_random_uuid()::text,'-',''),1,8));
 INSERT INTO public.visitas_nightlife(estabelecimento_id,codigo,visitante_id) VALUES(p_estabelecimento_id,v_codigo,p_visitante_id);
 RETURN v_codigo;
END; $$;
GRANT EXECUTE ON FUNCTION public.gerar_visita_nightlife(uuid,text) TO anon,authenticated;
CREATE OR REPLACE FUNCTION public.confirmar_visita_nightlife(p_codigo text)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$
DECLARE v_estabelecimento uuid;
BEGIN
 SELECT estabelecimento_id INTO v_estabelecimento FROM public.visitas_nightlife
 WHERE codigo=upper(trim(p_codigo)) AND status='pendente' AND expira_em>now();
 IF v_estabelecimento IS NULL THEN RAISE EXCEPTION 'Código inválido, já utilizado ou expirado.'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.estabelecimentos e WHERE e.id=v_estabelecimento AND (e.usuario_id=auth.uid() OR EXISTS(SELECT 1 FROM public.perfis p WHERE p.id=auth.uid() AND p.tipo='admin'))) THEN RAISE EXCEPTION 'Você não tem permissão para confirmar esta visita.'; END IF;
 UPDATE public.visitas_nightlife SET status='confirmado',confirmado_em=now() WHERE codigo=upper(trim(p_codigo)) AND status='pendente';
 IF NOT FOUND THEN RAISE EXCEPTION 'Este código já foi utilizado.'; END IF;
END; $$;
GRANT EXECUTE ON FUNCTION public.confirmar_visita_nightlife(text) TO authenticated;
CREATE OR REPLACE FUNCTION public.resumo_visitas_confirmadas_nightlife(p_estabelecimento_id uuid)
RETURNS TABLE(visitas_confirmadas bigint) LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$
BEGIN
 IF NOT EXISTS(SELECT 1 FROM public.estabelecimentos e WHERE e.id=p_estabelecimento_id AND (e.usuario_id=auth.uid() OR EXISTS(SELECT 1 FROM public.perfis p WHERE p.id=auth.uid() AND p.tipo='admin'))) THEN RAISE EXCEPTION 'Acesso negado às visitas.'; END IF;
 RETURN QUERY SELECT count(*) FROM public.visitas_nightlife v WHERE v.estabelecimento_id=p_estabelecimento_id AND v.status='confirmado';
END; $$;
GRANT EXECUTE ON FUNCTION public.resumo_visitas_confirmadas_nightlife(uuid) TO authenticated;

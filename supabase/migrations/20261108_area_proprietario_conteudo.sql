-- NIGHTlife | Conteúdo gerenciado pelos proprietários
-- Fotos, eventos e promoções ficam limitados ao estabelecimento do usuário autenticado.
-- Execute uma única vez no Supabase SQL Editor.

CREATE TABLE IF NOT EXISTS public.fotos_estabelecimentos_nightlife (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  estabelecimento_id uuid NOT NULL REFERENCES public.estabelecimentos(id) ON DELETE CASCADE,
  caminho text NOT NULL,
  legenda text,
  criado_em timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_fotos_estabelecimento_nightlife ON public.fotos_estabelecimentos_nightlife(estabelecimento_id, criado_em DESC);
ALTER TABLE public.fotos_estabelecimentos_nightlife ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Fotos publicas NIGHTlife" ON public.fotos_estabelecimentos_nightlife;
CREATE POLICY "Fotos publicas NIGHTlife" ON public.fotos_estabelecimentos_nightlife FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS "Proprietario publica fotos do proprio estabelecimento NIGHTlife" ON public.fotos_estabelecimentos_nightlife;
CREATE POLICY "Proprietario publica fotos do proprio estabelecimento NIGHTlife" ON public.fotos_estabelecimentos_nightlife FOR INSERT TO authenticated WITH CHECK (EXISTS (SELECT 1 FROM public.estabelecimentos e WHERE e.id=estabelecimento_id AND e.usuario_id=auth.uid()));
DROP POLICY IF EXISTS "Proprietario remove fotos do proprio estabelecimento NIGHTlife" ON public.fotos_estabelecimentos_nightlife;
CREATE POLICY "Proprietario remove fotos do proprio estabelecimento NIGHTlife" ON public.fotos_estabelecimentos_nightlife FOR DELETE TO authenticated USING (EXISTS (SELECT 1 FROM public.estabelecimentos e WHERE e.id=estabelecimento_id AND e.usuario_id=auth.uid()));

CREATE TABLE IF NOT EXISTS public.promocoes_estabelecimentos_nightlife (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  estabelecimento_id uuid NOT NULL REFERENCES public.estabelecimentos(id) ON DELETE CASCADE,
  titulo text NOT NULL CHECK (char_length(titulo) BETWEEN 3 AND 100),
  descricao text,
  preco text,
  inicio date NOT NULL DEFAULT current_date,
  fim date NOT NULL,
  ativo boolean NOT NULL DEFAULT true,
  criado_em timestamptz NOT NULL DEFAULT now(),
  CHECK (fim >= inicio)
);
CREATE INDEX IF NOT EXISTS idx_promocoes_estabelecimento_nightlife ON public.promocoes_estabelecimentos_nightlife(estabelecimento_id, ativo, fim);
ALTER TABLE public.promocoes_estabelecimentos_nightlife ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Promocoes vigentes publicas NIGHTlife" ON public.promocoes_estabelecimentos_nightlife;
CREATE POLICY "Promocoes vigentes publicas NIGHTlife" ON public.promocoes_estabelecimentos_nightlife FOR SELECT TO anon, authenticated USING (ativo=true AND inicio<=current_date AND fim>=current_date);
DROP POLICY IF EXISTS "Proprietario consulta suas promocoes NIGHTlife" ON public.promocoes_estabelecimentos_nightlife;
CREATE POLICY "Proprietario consulta suas promocoes NIGHTlife" ON public.promocoes_estabelecimentos_nightlife FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM public.estabelecimentos e WHERE e.id=estabelecimento_id AND e.usuario_id=auth.uid()));
DROP POLICY IF EXISTS "Proprietario cria promocoes NIGHTlife" ON public.promocoes_estabelecimentos_nightlife;
CREATE POLICY "Proprietario cria promocoes NIGHTlife" ON public.promocoes_estabelecimentos_nightlife FOR INSERT TO authenticated WITH CHECK (EXISTS (SELECT 1 FROM public.estabelecimentos e WHERE e.id=estabelecimento_id AND e.usuario_id=auth.uid()));
DROP POLICY IF EXISTS "Proprietario altera promocoes NIGHTlife" ON public.promocoes_estabelecimentos_nightlife;
CREATE POLICY "Proprietario altera promocoes NIGHTlife" ON public.promocoes_estabelecimentos_nightlife FOR UPDATE TO authenticated USING (EXISTS (SELECT 1 FROM public.estabelecimentos e WHERE e.id=estabelecimento_id AND e.usuario_id=auth.uid())) WITH CHECK (EXISTS (SELECT 1 FROM public.estabelecimentos e WHERE e.id=estabelecimento_id AND e.usuario_id=auth.uid()));
DROP POLICY IF EXISTS "Proprietario remove promocoes NIGHTlife" ON public.promocoes_estabelecimentos_nightlife;
CREATE POLICY "Proprietario remove promocoes NIGHTlife" ON public.promocoes_estabelecimentos_nightlife FOR DELETE TO authenticated USING (EXISTS (SELECT 1 FROM public.estabelecimentos e WHERE e.id=estabelecimento_id AND e.usuario_id=auth.uid()));

-- O cadastro antigo permitia inserções sem vínculo. A partir desta migration,
-- somente o dono autenticado pode criar ou alterar eventos do próprio estabelecimento.
ALTER TABLE public.eventos ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Permitir cadastro de eventos" ON public.eventos;
DROP POLICY IF EXISTS "proprietarios_cadastram_eventos" ON public.eventos;
DROP POLICY IF EXISTS "Proprietario cria eventos do proprio estabelecimento NIGHTlife" ON public.eventos;
CREATE POLICY "Proprietario cria eventos do proprio estabelecimento NIGHTlife" ON public.eventos FOR INSERT TO authenticated WITH CHECK (EXISTS (SELECT 1 FROM public.estabelecimentos e WHERE e.id=estabelecimento_id AND e.usuario_id=auth.uid()));
DROP POLICY IF EXISTS "Proprietario altera eventos do proprio estabelecimento NIGHTlife" ON public.eventos;
CREATE POLICY "Proprietario altera eventos do proprio estabelecimento NIGHTlife" ON public.eventos FOR UPDATE TO authenticated USING (EXISTS (SELECT 1 FROM public.estabelecimentos e WHERE e.id=estabelecimento_id AND e.usuario_id=auth.uid())) WITH CHECK (EXISTS (SELECT 1 FROM public.estabelecimentos e WHERE e.id=estabelecimento_id AND e.usuario_id=auth.uid()));
DROP POLICY IF EXISTS "Proprietario remove eventos do proprio estabelecimento NIGHTlife" ON public.eventos;
CREATE POLICY "Proprietario remove eventos do proprio estabelecimento NIGHTlife" ON public.eventos FOR DELETE TO authenticated USING (EXISTS (SELECT 1 FROM public.estabelecimentos e WHERE e.id=estabelecimento_id AND e.usuario_id=auth.uid()));

-- Bucket público para visualização das fotos; gravação e exclusão somente pelo dono.
INSERT INTO storage.buckets (id,name,public,file_size_limit,allowed_mime_types)
VALUES ('nightlife-estabelecimentos','nightlife-estabelecimentos',true,5242880,ARRAY['image/jpeg','image/png','image/webp'])
ON CONFLICT (id) DO UPDATE SET public=true,file_size_limit=5242880,allowed_mime_types=ARRAY['image/jpeg','image/png','image/webp'];
DROP POLICY IF EXISTS "Fotos NIGHTlife visiveis publicamente" ON storage.objects;
CREATE POLICY "Fotos NIGHTlife visiveis publicamente" ON storage.objects FOR SELECT TO anon,authenticated USING (bucket_id='nightlife-estabelecimentos');
DROP POLICY IF EXISTS "Dono envia fotos NIGHTlife" ON storage.objects;
CREATE POLICY "Dono envia fotos NIGHTlife" ON storage.objects FOR INSERT TO authenticated WITH CHECK (
 bucket_id='nightlife-estabelecimentos'
 AND EXISTS (SELECT 1 FROM public.estabelecimentos e WHERE e.id::text=(storage.foldername(name))[1] AND e.usuario_id=auth.uid())
);
DROP POLICY IF EXISTS "Dono apaga fotos NIGHTlife" ON storage.objects;
CREATE POLICY "Dono apaga fotos NIGHTlife" ON storage.objects FOR DELETE TO authenticated USING (
 bucket_id='nightlife-estabelecimentos'
 AND EXISTS (SELECT 1 FROM public.estabelecimentos e WHERE e.id::text=(storage.foldername(name))[1] AND e.usuario_id=auth.uid())
);

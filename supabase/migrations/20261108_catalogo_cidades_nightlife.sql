-- NIGHTlife: catalogo de cidades prioritarias para busca por estado/cidade
ALTER TABLE public.estabelecimentos
  ADD COLUMN IF NOT EXISTS cidade text,
  ADD COLUMN IF NOT EXISTS estado char(2);

CREATE TABLE IF NOT EXISTS public.nightlife_cidades (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  estado char(2) NOT NULL,
  cidade text NOT NULL,
  prioridade smallint NOT NULL DEFAULT 100,
  ativa boolean NOT NULL DEFAULT true,
  UNIQUE (estado, cidade)
);

ALTER TABLE public.nightlife_cidades ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Publico consulta cidades ativas NIGHTlife" ON public.nightlife_cidades;
CREATE POLICY "Publico consulta cidades ativas NIGHTlife"
ON public.nightlife_cidades FOR SELECT TO anon, authenticated
USING (ativa = true);

INSERT INTO public.nightlife_cidades (estado,cidade,prioridade) VALUES
('SC','Florianópolis',1),
('SC','Balneário Camboriú',2),
('SC','Joinville',3),
('SC','Blumenau',4),
('SC','Itajaí',5),
('SC','Camboriú',6),
('SC','Itapema',7),
('SC','Jaraguá do Sul',8),
('SC','Criciúma',9),
('SC','Chapecó',10)
ON CONFLICT (estado,cidade) DO UPDATE
SET prioridade = EXCLUDED.prioridade, ativa = true;

-- Corrige a cidade do primeiro cliente usando o texto do endereço, inclusive a grafia
-- "jargua" que apareceu no cadastro. Não altera nome, telefone, endereço ou plano.
UPDATE public.estabelecimentos
SET cidade = 'Jaraguá do Sul', estado = 'SC'
WHERE cidade IS NULL
  AND (lower(coalesce(endereco,'')) LIKE '%jaragua%'
       OR lower(coalesce(endereco,'')) LIKE '%jargua%');

CREATE INDEX IF NOT EXISTS idx_estabelecimentos_estado_cidade_ativo
ON public.estabelecimentos (estado, cidade, ativo);

ALTER TABLE public.estabelecimentos
  ADD COLUMN IF NOT EXISTS cadastro_informativo boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS fonte_url text,
  ADD COLUMN IF NOT EXISTS fonte_consultada_em date;

ALTER TABLE public.estabelecimentos
  DROP CONSTRAINT IF EXISTS estabelecimentos_informativo_sem_cobranca;
ALTER TABLE public.estabelecimentos
  ADD CONSTRAINT estabelecimentos_informativo_sem_cobranca
  CHECK (
    NOT cadastro_informativo
    OR (
      usuario_id IS NULL
      AND status_plano = 'informativo'
      AND mensalidade = 0
      AND teste_termina_em IS NULL
      AND vencimento_em IS NULL
      AND tolerancia_ate IS NULL
      AND fonte_url IS NOT NULL
      AND fonte_consultada_em IS NOT NULL
    )
  );

DROP POLICY IF EXISTS "Publico le apenas estabelecimentos publicados"
  ON public.estabelecimentos;
CREATE POLICY "Publico le apenas estabelecimentos publicados"
  ON public.estabelecimentos FOR SELECT TO anon
  USING (
    ativo IS TRUE
    AND visivel_publico IS TRUE
    AND (
      (cadastro_informativo IS TRUE AND status_plano = 'informativo')
      OR
      (cadastro_informativo IS FALSE AND status_plano IN ('teste', 'ativo', 'tolerancia'))
    )
  );

GRANT SELECT (
  id, nome, endereco, telefone, horario_funcionamento, tipo,
  cidade, estado, ativo, criado_em, latitude, longitude,
  cadastro_informativo, fonte_url, fonte_consultada_em
) ON TABLE public.estabelecimentos TO anon;

CREATE OR REPLACE VIEW public.estabelecimentos_publicos
WITH (security_barrier = true, security_invoker = true)
AS
SELECT
  id, nome, endereco, telefone, horario_funcionamento, tipo,
  cidade, estado, ativo, criado_em, latitude, longitude,
  cadastro_informativo, fonte_url, fonte_consultada_em
FROM public.estabelecimentos;

GRANT SELECT ON TABLE public.estabelecimentos_publicos TO anon, authenticated;

CREATE OR REPLACE FUNCTION public.gerar_visita_nightlife(
  p_estabelecimento_id uuid,
  p_visitante_id text
)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_codigo text;
BEGIN
  IF p_visitante_id IS NULL OR length(p_visitante_id) < 8 OR length(p_visitante_id) > 120 THEN
    RAISE EXCEPTION 'Identificador de visitante inválido.';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.estabelecimentos
    WHERE id = p_estabelecimento_id
      AND ativo IS TRUE
      AND cadastro_informativo IS FALSE
      AND status_plano IN ('teste', 'ativo', 'tolerancia')
  ) THEN
    RAISE EXCEPTION 'Estabelecimento indisponível para visitas pelo NIGHTlife.';
  END IF;

  v_codigo := 'NL-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8));
  INSERT INTO public.visitas_nightlife (estabelecimento_id, codigo, visitante_id)
  VALUES (p_estabelecimento_id, v_codigo, p_visitante_id);

  RETURN v_codigo;
END;
$function$;

create or replace view public.estabelecimentos_publicos
with (security_barrier = true, security_invoker = false)
as
select id, nome, endereco, telefone, horario_funcionamento, tipo, cidade, estado, ativo, criado_em
from public.estabelecimentos
where ativo is true
  and visivel_publico is true
  and status_plano in ('teste', 'ativo', 'tolerancia');

grant select on public.estabelecimentos_publicos to anon, authenticated;

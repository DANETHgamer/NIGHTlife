drop policy if exists "Envio publico de cadastro pendente" on public.estabelecimentos;
create policy "Publico le apenas estabelecimentos publicados"
on public.estabelecimentos for select to anon
using (
  ativo is true
  and visivel_publico is true
  and status_plano in ('teste', 'ativo', 'tolerancia')
);

create or replace view public.estabelecimentos_publicos
with (security_barrier = true, security_invoker = true)
as
select id, nome, endereco, telefone, horario_funcionamento, tipo, cidade, estado, ativo, criado_em
from public.estabelecimentos;

grant select (id, nome, endereco, telefone, horario_funcionamento, tipo, cidade, estado, ativo, criado_em)
on table public.estabelecimentos to anon;
grant select on table public.estabelecimentos_publicos to anon, authenticated;

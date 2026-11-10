alter table public.estabelecimentos
  add column if not exists latitude numeric(9,6),
  add column if not exists longitude numeric(9,6);

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.estabelecimentos'::regclass
      and conname = 'estabelecimentos_latitude_range'
  ) then
    alter table public.estabelecimentos
      add constraint estabelecimentos_latitude_range
      check (latitude is null or latitude between -90 and 90);
  end if;
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.estabelecimentos'::regclass
      and conname = 'estabelecimentos_longitude_range'
  ) then
    alter table public.estabelecimentos
      add constraint estabelecimentos_longitude_range
      check (longitude is null or longitude between -180 and 180);
  end if;
end $$;

create or replace view public.estabelecimentos_publicos
with (security_barrier = true, security_invoker = true)
as
select id, nome, endereco, telefone, horario_funcionamento, tipo, cidade, estado, ativo, criado_em, latitude, longitude
from public.estabelecimentos;

grant select (latitude, longitude) on table public.estabelecimentos to anon;
grant insert (latitude, longitude) on table public.estabelecimentos to anon, authenticated;
grant update (latitude, longitude) on table public.estabelecimentos to authenticated;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.estabelecimentos'::regclass
      and conname = 'estabelecimentos_coordinates_pair'
  ) then
    alter table public.estabelecimentos
      add constraint estabelecimentos_coordinates_pair
      check ((latitude is null) = (longitude is null));
  end if;
end $$;

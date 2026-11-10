-- Keep legacy payment amounts for historical records while defaulting new charges to R$ 9.99.
alter table public.pagamentos
  alter column valor set default 9.99;

alter table public.pagamentos
  drop constraint if exists pagamentos_valor_check;

alter table public.pagamentos
  add constraint pagamentos_valor_positive_check
  check (valor > 0);

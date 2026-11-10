alter table public.eventos
  add column if not exists data_fim date,
  add column if not exists horario_fim time without time zone;

-- Preserve existing events and assign a three-hour default end
-- where their start uses the form's HH:MM format.
update public.eventos
set data_fim = (data_evento::timestamp + horario::time + interval '3 hours')::date,
    horario_fim = (data_evento::timestamp + horario::time + interval '3 hours')::time
where data_fim is null
  and data_evento is not null
  and horario ~ '^\d{2}:\d{2}$';

alter table public.eventos
  add constraint eventos_fim_pair_check
  check (
    (data_fim is null and horario_fim is null)
    or (data_fim is not null and horario_fim is not null)
  );

alter table public.eventos
  add constraint eventos_fim_posterior_inicio_check
  check (
    data_fim is null
    or (
      data_evento is not null
      and horario ~ '^\d{2}:\d{2}$'
      and (data_fim + horario_fim) > (data_evento + horario::time)
    )
  );

create index if not exists eventos_data_fim_horario_fim_idx
  on public.eventos (data_fim, horario_fim)
  where data_fim is not null;

create or replace function public.apagar_eventos_encerrados_nightlife()
returns integer
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  removidos integer;
begin
  delete from public.eventos
  where data_fim is not null
    and ((data_fim + horario_fim) at time zone 'America/Sao_Paulo') <= now();

  get diagnostics removidos = row_count;
  return removidos;
end;
$$;

revoke all on function public.apagar_eventos_encerrados_nightlife() from public, anon, authenticated;

select cron.unschedule(jobid)
from cron.job
where jobname = 'limpar-eventos-encerrados-nightlife';

select cron.schedule(
  'limpar-eventos-encerrados-nightlife',
  '*/5 * * * *',
  'select public.apagar_eventos_encerrados_nightlife();'
);

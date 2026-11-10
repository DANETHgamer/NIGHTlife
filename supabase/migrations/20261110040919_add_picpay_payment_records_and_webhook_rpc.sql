alter table public.pagamentos
  add column if not exists provedor text not null default 'manual',
  add column if not exists picpay_order_number text,
  add column if not exists picpay_payment_link_id text,
  add column if not exists picpay_checkout_url text,
  add column if not exists picpay_brcode text,
  add column if not exists picpay_txid text;

alter table public.pagamentos
  add constraint pagamentos_provedor_check
  check (provedor in ('manual', 'picpay'));

alter table public.pagamentos
  drop constraint if exists pagamentos_status_check;

alter table public.pagamentos
  add constraint pagamentos_status_check
  check (status in ('pago', 'pendente', 'falhou', 'expirado', 'estornado'));

create unique index if not exists pagamentos_picpay_order_number_uidx
  on public.pagamentos (picpay_order_number)
  where picpay_order_number is not null;

create unique index if not exists pagamentos_picpay_link_id_uidx
  on public.pagamentos (picpay_payment_link_id)
  where picpay_payment_link_id is not null;

create index if not exists pagamentos_picpay_pending_by_establishment_idx
  on public.pagamentos (estabelecimento_id, criado_em desc)
  where provedor = 'picpay' and status = 'pendente';

create or replace function public.registrar_webhook_picpay_nightlife(
  p_payment_link_id text,
  p_txid text,
  p_charge_amount integer,
  p_event_status text
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  pagamento public.pagamentos%rowtype;
begin
  if p_payment_link_id is null or length(p_payment_link_id) > 200 then
    raise exception 'Link de pagamento inválido.';
  end if;
  if p_charge_amount <> 999 then
    raise exception 'Valor da cobrança não corresponde à mensalidade.';
  end if;
  if p_event_status not in ('PAYED', 'REFUNDED', 'PARTREFUNDED') then
    return jsonb_build_object('processed', false, 'reason', 'status_ignored');
  end if;

  select * into pagamento
  from public.pagamentos
  where picpay_payment_link_id = p_payment_link_id
    and provedor = 'picpay'
  for update;

  if not found then
    raise exception 'Cobrança PicPay não encontrada.';
  end if;

  if p_event_status = 'PAYED' then
    if pagamento.status = 'pago' then
      return jsonb_build_object('processed', true, 'duplicate', true);
    end if;
    if pagamento.status <> 'pendente' then
      raise exception 'Cobrança não está pendente.';
    end if;

    update public.pagamentos
    set status = 'pago', pago_em = now(), picpay_txid = nullif(p_txid, '')
    where id = pagamento.id;

    update public.estabelecimentos
    set status_plano = 'ativo', mensalidade = 9.99,
        vencimento_em = pagamento.vencimento_em,
        tolerancia_ate = pagamento.vencimento_em + interval '2 days'
    where id = pagamento.estabelecimento_id;

    return jsonb_build_object('processed', true, 'duplicate', false);
  end if;

  if pagamento.status in ('pago', 'pendente') then
    update public.pagamentos
    set status = 'estornado',
        picpay_txid = coalesce(nullif(p_txid, ''), picpay_txid)
    where id = pagamento.id;

    if pagamento.status = 'pago' then
      update public.estabelecimentos
      set status_plano = 'expirado', vencimento_em = now(), tolerancia_ate = now()
      where id = pagamento.estabelecimento_id
        and vencimento_em = pagamento.vencimento_em;
    end if;
  end if;

  return jsonb_build_object('processed', true, 'duplicate', false);
end;
$$;

revoke all on function public.registrar_webhook_picpay_nightlife(text, text, integer, text)
  from public, anon, authenticated;
grant execute on function public.registrar_webhook_picpay_nightlife(text, text, integer, text)
  to service_role;

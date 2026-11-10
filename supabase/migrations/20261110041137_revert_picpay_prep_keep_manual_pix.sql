drop function if exists public.registrar_webhook_picpay_nightlife(text, text, integer, text);

drop index if exists public.pagamentos_picpay_order_number_uidx;
drop index if exists public.pagamentos_picpay_link_id_uidx;
drop index if exists public.pagamentos_picpay_pending_by_establishment_idx;

alter table public.pagamentos
  drop constraint if exists pagamentos_provedor_check;

alter table public.pagamentos
  drop constraint if exists pagamentos_status_check;

alter table public.pagamentos
  add constraint pagamentos_status_check
  check (status in ('pago', 'pendente'));

alter table public.pagamentos
  drop column if exists picpay_order_number,
  drop column if exists picpay_payment_link_id,
  drop column if exists picpay_checkout_url,
  drop column if exists picpay_brcode,
  drop column if exists picpay_txid,
  drop column if exists provedor;

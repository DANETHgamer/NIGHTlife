alter table public.estabelecimentos alter column mensalidade set default 9.99;

update public.estabelecimentos set mensalidade = 9.99 where mensalidade = 25.00;

drop policy if exists "Envio publico de cadastro pendente" on public.estabelecimentos;
create policy "Envio publico de cadastro pendente"
on public.estabelecimentos for insert to anon
with check (
  usuario_id is null
  and status_plano = 'teste'
  and mensalidade = 9.99
  and ativo = false
);

drop policy if exists "Proprietario cadastra estabelecimento pendente" on public.estabelecimentos;
create policy "Proprietario cadastra estabelecimento pendente"
on public.estabelecimentos for insert to authenticated
with check (
  usuario_id = (select auth.uid())
  and status_plano = 'teste'
  and mensalidade = 9.99
  and ativo = false
);

create or replace function public.registrar_renovacao_nightlife(p_estabelecimento_id uuid)
returns void language plpgsql security definer set search_path to 'public'
as $function$
declare v_vencimento_atual timestamptz; v_novo_vencimento timestamptz;
begin
 if not exists(select 1 from public.perfis where id=auth.uid() and tipo='admin') then
   raise exception 'Acesso permitido somente ao administrador.';
 end if;
 select vencimento_em into v_vencimento_atual from public.estabelecimentos where id=p_estabelecimento_id for update;
 if not found then raise exception 'Estabelecimento não encontrado.'; end if;
 v_novo_vencimento:=greatest(coalesce(v_vencimento_atual,now()),now())+interval '30 days';
 update public.estabelecimentos set status_plano='ativo',mensalidade=9.99,vencimento_em=v_novo_vencimento,tolerancia_ate=v_novo_vencimento+interval '2 days' where id=p_estabelecimento_id;
 insert into public.pagamentos(estabelecimento_id,valor,pago_em,vencimento_em,status)
 values(p_estabelecimento_id,9.99,now(),v_novo_vencimento,'pago');
end;
$function$;

create or replace function public.gerar_notificacoes_planos_nightlife()
returns void language plpgsql security definer set search_path to 'public'
as $function$
begin
 insert into public.notificacoes_nightlife(estabelecimento_id,usuario_id,tipo,mensagem,referencia_data)
 select id,usuario_id,'fim_teste','Seu teste grátis termina amanhã. A mensalidade é de R$ 9,99.',teste_termina_em::date
 from public.estabelecimentos where status_plano='teste' and usuario_id is not null
 and now()>=teste_termina_em-interval '1 day' and now()<teste_termina_em
 on conflict(estabelecimento_id,tipo,referencia_data) do nothing;
 insert into public.notificacoes_nightlife(estabelecimento_id,usuario_id,tipo,mensagem,referencia_data)
 select id,usuario_id,'fim_tolerancia','Seu prazo para renovar termina amanhã. Renove para manter seu estabelecimento visível.',tolerancia_ate::date
 from public.estabelecimentos where status_plano='tolerancia' and usuario_id is not null
 and now()>=tolerancia_ate-interval '1 day' and now()<tolerancia_ate
 on conflict(estabelecimento_id,tipo,referencia_data) do nothing;
end;
$function$;

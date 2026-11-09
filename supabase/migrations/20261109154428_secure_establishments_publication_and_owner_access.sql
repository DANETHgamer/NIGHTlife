alter table public.estabelecimentos alter column ativo set default false;

drop policy if exists "Publico pode visualizar estabelecimentos" on public.estabelecimentos;
drop policy if exists "Usuarios podem visualizar estabelecimentos" on public.estabelecimentos;
drop policy if exists "Proprietario cadastra seu estabelecimento" on public.estabelecimentos;
drop policy if exists "Proprietario edita seu estabelecimento" on public.estabelecimentos;
drop policy if exists "Proprietario exclui seu estabelecimento" on public.estabelecimentos;

create policy "Proprietario e administracao visualizam estabelecimento"
on public.estabelecimentos for select to authenticated
using (
  usuario_id = (select auth.uid())
  or exists (
    select 1 from public.perfis p
    where p.id = (select auth.uid()) and p.tipo = 'admin'
  )
  or public.nightlife_eh_admin_supremo()
);

create policy "Envio publico de cadastro pendente"
on public.estabelecimentos for insert to anon
with check (
  usuario_id is null
  and status_plano = 'teste'
  and mensalidade = 25
  and ativo = false
);

create policy "Proprietario cadastra estabelecimento pendente"
on public.estabelecimentos for insert to authenticated
with check (
  usuario_id = (select auth.uid())
  and status_plano = 'teste'
  and mensalidade = 25
  and ativo = false
);

create policy "Proprietario edita dados de perfil"
on public.estabelecimentos for update to authenticated
using (usuario_id = (select auth.uid()))
with check (usuario_id = (select auth.uid()));

revoke all privileges on table public.estabelecimentos from anon, authenticated;
grant select on table public.estabelecimentos to authenticated;
grant insert (nome, endereco, telefone, horario_funcionamento, descricao, tipo, cidade, estado)
on table public.estabelecimentos to anon;
grant insert (nome, endereco, telefone, horario_funcionamento, descricao, tipo, cidade, estado, usuario_id)
on table public.estabelecimentos to authenticated;
grant update (nome, endereco, telefone, tipo)
on table public.estabelecimentos to authenticated;
grant select on table public.estabelecimentos_publicos to anon, authenticated;

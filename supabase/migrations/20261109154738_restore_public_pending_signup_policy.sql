create policy "Envio publico de cadastro pendente"
on public.estabelecimentos for insert to anon
with check (
  usuario_id is null
  and status_plano = 'teste'
  and mensalidade = 25
  and ativo = false
);

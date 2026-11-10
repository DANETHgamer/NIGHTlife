# Segurança

## Controles implementados

- A view pública estabelecimentos_publicos usa security_invoker=true e expõe apenas campos do catálogo.
- O papel anon recebe leitura somente das colunas públicas; RLS limita a registros ativos, visíveis e publicados.
- Cadastros informativos têm status separado e cobrança zero, guardam a fonte consultada e são identificados como não parceiros; a vitrine omite visitas e avaliações e a RPC também bloqueia códigos de visita.
- Inserções de estabelecimento ficam pendentes e inativas. O proprietário não recebe permissão de alterar plano, cobrança, ativação ou visibilidade via grants de coluna.
- RPCs de gestão e proprietário foram restringidas a authenticated; cinco RPCs públicas de negócio continuam acessíveis por anon para fluxos de visitante.
- A chave usada no front-end é publicável. Nenhuma chave privilegiada deve ser colocada no repositório.
- O arquivo .gitignore exclui configuração local e arquivos gerados.
- O mapa envia requisições de tiles ao OpenStreetMap com atribuição visível; endereços não são geocodificados nem enviados ao serviço.

## Pendências

1. Proteção contra senhas vazadas: o advisor do Supabase indicou que está desativada. A organização está no plano Free; segundo a [documentação oficial](https://supabase.com/docs/guides/auth/password-security), esse recurso está disponível no Pro ou superior. A alteração também exige ação no painel, que não está acessível nesta conexão. Não altere o plano sem aprovar o custo.
2. Edge Function: criar-admin-regional agora está com verify_jwt=true (versão 2), além de validar explicitamente o Bearer token e o nível supremo no código. O email supremo fixo ainda deve ser substituído por uma atribuição administrativa controlável e auditável.
3. Rate limiting: controles antifraude baseados em navegador são falsificáveis. Aplique cotas no servidor e monitore avaliações, visitas e resgates.
4. Storage: mantenha o bucket público somente para fotos destinadas ao catálogo; não use esse bucket para documentos privados.
5. Operação: habilite MFA para administradores, proteja a branch main e revogue/rotacione qualquer segredo que tenha sido exposto no histórico Git.

## Verificação

Após mudanças de banco, confira advisors do Supabase, grants, políticas RLS e funções afetadas. A revisão desta data consultou metadados e não executou tentativas de escrita/exploração nem testes da aplicação.

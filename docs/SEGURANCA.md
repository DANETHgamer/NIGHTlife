# Segurança

## Controles implementados

- A view pública estabelecimentos_publicos expõe somente campos do catálogo e usa security_invoker=true.
- Acesso anônimo à tabela-base não inclui descricao nem outros campos privados; RLS restringe linhas publicadas.
- Inserções de estabelecimento ficam pendentes e inativas. O proprietário não recebe permissão de alterar plano, cobrança, ativação ou visibilidade via grants de coluna.
- RPCs de gestão e proprietário foram restringidas a authenticated; cinco RPCs públicas de negócio continuam acessíveis por anon para fluxos de visitante.
- A chave usada no front-end é publicável. Nenhuma chave privilegiada deve ser colocada no repositório.
- O arquivo .gitignore exclui configuração local e arquivos gerados.

## Pendências

1. Proteção contra senhas vazadas: o advisor do Supabase indicou que está desativada. O conector atual não oferece alteração dessa configuração; habilite no painel Supabase em Authentication > Settings > Password Security e confirme as regras de senha. Verifique o plano e comunique usuários se a mudança impedir senhas comprometidas.
2. Verificação de Edge Function: criar-admin-regional está com verify_jwt=false; o código faz validação explícita do Bearer token e do nível supremo, mas habilitar validação JWT na plataforma é uma camada extra a avaliar e implantar junto da função.
3. Rate limiting: controles antifraude baseados em navegador são falsificáveis. Aplique cotas no servidor e monitore avaliações, visitas e resgates.
4. Storage: mantenha o bucket público somente para fotos destinadas ao catálogo; não use esse bucket para documentos privados.
5. Operação: habilite MFA para administradores, proteja a branch main e revogue/rotacione qualquer segredo que tenha sido exposto no histórico Git.

## Verificação

Após mudanças de banco, confira advisors do Supabase, grants, políticas RLS e funções afetadas. A revisão desta data consultou metadados e não executou tentativas de escrita/exploração nem testes da aplicação.

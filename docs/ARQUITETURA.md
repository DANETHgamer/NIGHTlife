# Arquitetura atual

## Componentes

Navegador (HTML/CSS/JavaScript) -> Supabase Auth e Data API -> PostgreSQL com RLS.
O navegador também acessa RPCs/Edge Functions e Storage. Operações privilegiadas devem ser validadas no banco ou no servidor.

## Stack escolhida

- Interface: HTML, CSS e JavaScript sem framework. É simples de hospedar e atende ao tamanho atual, mas scripts e estilos repetidos tornam as páginas difíceis de evoluir.
- Dados: PostgreSQL gerenciado pelo Supabase. O modelo relacional é adequado a estabelecimentos, perfis, avaliações, visitas, ofertas e pagamentos; RLS e constraints devem proteger cada operação.
- Autenticação: Supabase Auth. As páginas estáticas usam a chave publicável do projeto; ela identifica o projeto e não é segredo. As permissões dependem das políticas do banco.
- Fotos: Supabase Storage, bucket público para imagens de locais e políticas de escrita por proprietário.
- Back-end: funções SQL SECURITY DEFINER e Edge Functions para operações que não devem depender do cliente.

## Fluxos de dados

- O catálogo lê a view public.estabelecimentos_publicos, limitada aos campos públicos.
- Novos cadastros entram pendentes e inativos; um administrador deve ativar o local.
- Alterações de perfil do proprietário são limitadas por RLS e grants de coluna.
- Operações administrativas e publicação passam por funções autorizadas.
- Avaliação, geração de visita, interação, visualização de oferta e pedido de resgate têm operações públicas limitadas; devem manter validação, cotas e proteção contra abuso no servidor.

## Escala e próximos passos

PostgreSQL pode crescer com o produto se houver paginação, índices nas chaves estrangeiras/filtros e medição de consultas. O projeto ainda carrega scripts de várias páginas diretamente no navegador; recomenda-se migrar gradualmente funções comuns para arquivos JavaScript compartilhados, sem reescrever os fluxos de uma vez.

Pagamentos: o código observado usa Pix manual. Antes da automação, escolha um gateway e crie um fluxo backend com webhook assinado, idempotência e estados de cobrança. Não aceite preço, confirmação ou credenciais enviados pelo navegador.

Mapas: não há mapa nem coordenadas normalizadas no modelo atual. Defina um provedor e uma política de privacidade antes de enviar endereço/localização a serviço de geocodificação. Prefira geocodificação no servidor e coordenadas normalizadas; restrinja as chaves públicas se o fornecedor exigir chave de cliente.

## Limites conhecidos

A publicação do site e as configurações de domínio/CDN não estão conectadas a este repositório pela integração disponível; não se deve presumir que um commit em main já esteja visível no domínio.

# NIGHTlife

Plataforma de vida noturna e eventos.

## Visão geral

O site é uma aplicação web estática em HTML, CSS e JavaScript. O Supabase fornece autenticação, PostgreSQL, Row Level Security (RLS), funções RPC e armazenamento de fotos. A interface não possui etapa de compilação nem dependências npm neste momento.

## Estrutura

- Páginas HTML na raiz: catálogo, cadastro, autenticação, painéis e eventos.
- `supabase/functions/`: Edge Functions.
- `supabase/migrations/`: alterações SQL versionadas.
- `docs/`: arquitetura, segurança e operação.

## Executar para desenvolvimento

Abra a pasta com um servidor estático local (por exemplo, a extensão Live Server do VS Code). Não é necessário instalar dependências npm. O projeto utiliza a URL do Supabase e uma chave publicável no navegador; essa chave é pública por natureza e a proteção real depende de RLS. **Nunca** coloque uma chave secreta ou `service_role` em páginas HTML, JavaScript público ou no Git.

## Banco e migrações

Consulte [docs/OPERACAO.md](docs/OPERACAO.md) antes de aplicar SQL. Migrações de segurança recentes foram adicionadas em `supabase/migrations`. As migrações históricas já existentes no repositório não correspondem integralmente ao histórico registrado pelo Supabase; não recrie um ambiente novo executando todos os arquivos sem primeiro reconciliar a linha de base.

## Segurança e arquitetura

- [Visão de arquitetura](docs/ARQUITETURA.md)
- [Operação, publicação e migrações](docs/OPERACAO.md)
- [Controles e pendências de segurança](docs/SEGURANCA.md)

## Pagamentos e mapas

O fluxo de Pix ainda é manual e não tem gateway automatizado. A vitrine agora inclui mapa Leaflet com tiles OpenStreetMap e pinos manuais; os locais antigos precisam receber coordenadas no painel do proprietário. Consulte a documentação de arquitetura antes de escolher o gateway; credenciais privadas ficam no backend/Edge Function.

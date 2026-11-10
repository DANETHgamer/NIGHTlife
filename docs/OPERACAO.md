# Operação e controle de versão

## Mudanças de código

1. Crie uma branch de trabalho para cada mudança.
2. Faça commits pequenos com mensagens que descrevam a alteração.
3. Revise o diff e os arquivos afetados antes de integrar à main.
4. Depois de publicar, confirme o commit e a versão carregada no site.
5. Não armazene credenciais, dumps de produção, dados pessoais ou chaves privilegiadas no Git.

O repositório não tem workflow de CI/CD detectado e os commits consultados não exibiam verificações de CI. A proteção da branch main não pôde ser consultada com a permissão atual da integração; confirme essa configuração no GitHub.

## Migrações Supabase

- Arquivos novos devem usar nome temporal ordenável e conter somente SQL necessário.
- Revise o SQL antes de aplicar; prefira alterações aditivas, transacionais e reversíveis quando possível.
- Aplique em ambiente de desenvolvimento antes de produção quando houver ambiente disponível.
- Registre a mesma migração no projeto e no repositório; confira advisors e grants após a aplicação.
- Nunca use migração para contornar RLS ou registrar dados reais/sensíveis.
- Os cinco arquivos com prefixo 20261109 e as migrações com prefixo 20261110 registram as correções de segurança, mapa, mensalidade, pagamentos e encerramento automático de eventos.
- O repositório já continha 12 arquivos SQL históricos, mas o histórico de migrações do projeto Supabase estava vazio no início desta revisão. Ainda falta reconciliar o baseline completo antes de usar todos os arquivos antigos para recriar um banco do zero.

## Publicação do site

Não foi possível identificar nem acessar o provedor de hospedagem a partir das conexões disponíveis. Commits em main podem publicar automaticamente somente se o provedor estiver configurado para acompanhar essa branch; verifique o painel de hospedagem e o domínio após cada publicação.

## Dados pessoais e suporte

Não copie dados reais de usuários para issues ou documentos públicos. Mantenha informações de responsáveis fora das colunas públicas e estabeleça um processo para atender solicitações de acesso, correção e exclusão.

## Eventos

- O painel do proprietário permite criar, editar e excluir eventos próprios. Para publicar ou editar, informe início, data final e horário final; o banco valida que o fim seja posterior ao início.
- O catálogo público mostra eventos até o horário final informado. O job `limpar-eventos-encerrados-nightlife` roda a cada cinco minutos via Supabase Cron e remove permanentemente os eventos encerrados.
- A remoção é definitiva (não vai para lixeira). Verifique a duração e o fuso antes de publicar. A limpeza usa o fuso `America/Sao_Paulo`.
- Eventos existentes foram preservados e receberam duração padrão de três horas quando a data e hora inicial estavam no formato válido.

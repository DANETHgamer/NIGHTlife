-- NIGHTlife: expansão do catálogo nacional de cidades prioritárias
-- Critério: capital + cinco municípios mais populosos por UF, com base no Censo 2022 do IBGE.
-- O Distrito Federal entra com Brasília. Mantém também as cidades extras já escolhidas para SC.

INSERT INTO public.nightlife_cidades (estado, cidade, prioridade) VALUES
-- AC
('AC','Rio Branco',1),('AC','Cruzeiro do Sul',2),('AC','Tarauacá',3),('AC','Sena Madureira',4),('AC','Feijó',5),('AC','Brasiléia',6),
-- AL
('AL','Maceió',1),('AL','Arapiraca',2),('AL','Rio Largo',3),('AL','Palmeira dos Índios',4),('AL','União dos Palmares',5),('AL','Penedo',6),
-- AP
('AP','Macapá',1),('AP','Santana',2),('AP','Laranjal do Jari',3),('AP','Oiapoque',4),('AP','Porto Grande',5),('AP','Mazagão',6),
-- AM
('AM','Manaus',1),('AM','Itacoatiara',2),('AM','Manacapuru',3),('AM','Parintins',4),('AM','Tefé',5),('AM','Coari',6),
-- BA
('BA','Salvador',1),('BA','Feira de Santana',2),('BA','Vitória da Conquista',3),('BA','Camaçari',4),('BA','Juazeiro',5),('BA','Lauro de Freitas',6),
-- CE
('CE','Fortaleza',1),('CE','Caucaia',2),('CE','Juazeiro do Norte',3),('CE','Maracanaú',4),('CE','Sobral',5),('CE','Crato',6),
-- DF
('DF','Brasília',1),
-- ES
('ES','Vitória',1),('ES','Serra',2),('ES','Vila Velha',3),('ES','Cariacica',4),('ES','Linhares',5),('ES','Cachoeiro de Itapemirim',6),
-- GO
('GO','Goiânia',1),('GO','Aparecida de Goiânia',2),('GO','Anápolis',3),('GO','Rio Verde',4),('GO','Águas Lindas de Goiás',5),('GO','Luziânia',6),
-- MA
('MA','São Luís',1),('MA','Imperatriz',2),('MA','São José de Ribamar',3),('MA','Timon',4),('MA','Caxias',5),('MA','Paço do Lumiar',6),
-- MT
('MT','Cuiabá',1),('MT','Várzea Grande',2),('MT','Rondonópolis',3),('MT','Sinop',4),('MT','Sorriso',5),('MT','Tangará da Serra',6),
-- MS
('MS','Campo Grande',1),('MS','Dourados',2),('MS','Três Lagoas',3),('MS','Corumbá',4),('MS','Ponta Porã',5),('MS','Naviraí',6),
-- MG
('MG','Belo Horizonte',1),('MG','Uberlândia',2),('MG','Contagem',3),('MG','Juiz de Fora',4),('MG','Betim',5),('MG','Montes Claros',6),
-- PA
('PA','Belém',1),('PA','Ananindeua',2),('PA','Santarém',3),('PA','Parauapebas',4),('PA','Marabá',5),('PA','Castanhal',6),
-- PB
('PB','João Pessoa',1),('PB','Campina Grande',2),('PB','Santa Rita',3),('PB','Patos',4),('PB','Bayeux',5),('PB','Cabedelo',6),
-- PR
('PR','Curitiba',1),('PR','Londrina',2),('PR','Maringá',3),('PR','Ponta Grossa',4),('PR','Cascavel',5),('PR','São José dos Pinhais',6),
-- PE
('PE','Recife',1),('PE','Jaboatão dos Guararapes',2),('PE','Petrolina',3),('PE','Caruaru',4),('PE','Olinda',5),('PE','Paulista',6),
-- PI
('PI','Teresina',1),('PI','Parnaíba',2),('PI','Picos',3),('PI','Piripiri',4),('PI','Floriano',5),('PI','Campo Maior',6),
-- RJ
('RJ','Rio de Janeiro',1),('RJ','São Gonçalo',2),('RJ','Duque de Caxias',3),('RJ','Nova Iguaçu',4),('RJ','Niterói',5),('RJ','Belford Roxo',6),
-- RN
('RN','Natal',1),('RN','Mossoró',2),('RN','Parnamirim',3),('RN','São Gonçalo do Amarante',4),('RN','Macaíba',5),('RN','Ceará-Mirim',6),
-- RS
('RS','Porto Alegre',1),('RS','Caxias do Sul',2),('RS','Canoas',3),('RS','Pelotas',4),('RS','Santa Maria',5),('RS','Gravataí',6),
-- RO
('RO','Porto Velho',1),('RO','Ji-Paraná',2),('RO','Ariquemes',3),('RO','Vilhena',4),('RO','Cacoal',5),('RO','Rolim de Moura',6),
-- RR
('RR','Boa Vista',1),('RR','Rorainópolis',2),('RR','Alto Alegre',3),('RR','Caracaraí',4),('RR','Mucajaí',5),('RR','Cantá',6),
-- SC: cidades prioritárias por população + cidades adicionais escolhidas para o lançamento NIGHTlife
('SC','Florianópolis',1),('SC','Joinville',2),('SC','Blumenau',3),('SC','São José',4),('SC','Itajaí',5),('SC','Chapecó',6),
('SC','Balneário Camboriú',7),('SC','Camboriú',8),('SC','Itapema',9),('SC','Jaraguá do Sul',10),('SC','Criciúma',11),
-- SP
('SP','São Paulo',1),('SP','Guarulhos',2),('SP','Campinas',3),('SP','São Bernardo do Campo',4),('SP','Santo André',5),('SP','Osasco',6),
-- SE
('SE','Aracaju',1),('SE','Nossa Senhora do Socorro',2),('SE','Itabaiana',3),('SE','Lagarto',4),('SE','São Cristóvão',5),('SE','Estância',6),
-- TO
('TO','Palmas',1),('TO','Araguaína',2),('TO','Gurupi',3),('TO','Porto Nacional',4),('TO','Paraíso do Tocantins',5),('TO','Colinas do Tocantins',6)
ON CONFLICT (estado, cidade) DO UPDATE
SET prioridade = EXCLUDED.prioridade, ativa = true;

-- Confirmação simples: quantidade de cidades ativas por estado.
SELECT estado, COUNT(*) AS cidades_ativas
FROM public.nightlife_cidades
WHERE ativa = true
GROUP BY estado
ORDER BY estado;

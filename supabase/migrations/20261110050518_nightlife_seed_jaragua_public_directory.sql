WITH candidatos(nome,endereco,horario_funcionamento,tipo,fonte_url) AS (
  VALUES
  ('Sinners Pub','Rua Leopoldo Mahnke, 76 - Centro','Qui: 20:30–02:00; sex/sáb: 21:00–02:00','Pub / bar','https://degusta.jdv.com.br/listing/sinners-pub/'),
  ('Pirata Rock Bar','Rua Olívio Domingos Brugnago, 501 - Vila Nova','Qua/qui: 18:00–02:00; sex/sáb: 18:00–03:00; dom: 18:00–00:00','Pub / bar','https://www.cylex.com.br/jaragua-do-sul/pirata-rock-bar-12581311.html'),
  ('ZG Lounge','Rua Presidente Epitácio Pessoa, 1228 - Centro','Qui–sáb: 22:00–02:00','Lounge / tabacaria','https://www.waze.com/live-map/directions/zg-lounge-r.-pres.-epitacio-pessoa-1228-jaragua-do-sul?to=place.w.203752959.2037595128.3715206'),
  ('nu.vem','Rua Max Wilhelm, 786 - Vila Baependi','Sex/sáb: 18:30–02:00','Casa noturna','https://www.cylex.com.br/jaragua-do-sul/nu-vem-12853628.html'),
  ('Tap Reinoldo','Rua Reinoldo Rau, 340 - Centro','Geralmente até perto das 02:00, conforme programação; confirme antes de sair','Bar','https://www.jdv.com.br/tantofaz/guia-madrugada-jaragua-do-sul-lugares-abertos/'),
  ('Melindroso','Rua Expedicionário Antônio Carlos Ferreira, 578 - Centro','Geralmente até perto das 02:00; confirme antes de sair','Bar de coquetéis','https://www.jdv.com.br/tantofaz/guia-madrugada-jaragua-do-sul-lugares-abertos/'),
  ('Lico Bar','Rua Domingos Rodrigues da Nova, 188, sala 5 - Centro','Qua–sáb: 19:00–04:00; dom: 15:00–23:30','Pub lounge','https://listatudo.com.br/santa-catarina/norte-de-santa-catarina/jaragua-do-sul/festas-e-eventos/locais/bares-e-choperias/licoreria-bar-e-comercio-de-bebidas-e-generos-alimenticios/'),
  ('Stage Pub','Rua Josef Fontana, 45 - Centro','Qui–sáb: 22:00–04:00','Pub','https://www.cylex.com.br/jaragua-do-sul/stage-pub-12581313.html'),
  ('Bar do Nens','Rua Felipe Schmidt, 79 - Centro','Sex: 22:00–03:00; sáb: 21:00–04:00','Bar','https://www.cylex.com.br/jaragua-do-sul/bar-do-nens-13479886.html'),
  ('Stop Dog','Rodovia Prefeito Engelbert Oechsler, 629 - Chico de Paulo','Sex/sáb: 18:00–04:00; demais dias: até 00:00','Lanchonete','https://wepede.com.br/r/stop-dog-vkvns/'),
  ('Caetano Lanches e Chopperia','Rua Domingos Anacleto Garcia, 1026 - Três Rios do Norte','Dom: 18:00–02:00; sex/sáb: 18:00–04:00','Lanchonete / choperia','https://www.locaisdobrasil.com.br/encontre/lanches/jaragua-do-sul-sc'),
  ('Macuco Sinuca','Rua Roberto Ziemann, 1963 - Amizade','Sex/sáb: 16:00–02:00','Sinuca / bar','https://www.locaisdobrasil.com.br/encontre/bares-perto-de-mim-em-jaragua-do-sul-sc'),
  ('Nosso Bar','Rua Carlos Oechsler, 1151','Sex: 14:00–02:00; sáb: 14:00–03:00','Bar','https://restaurantguru.com/Nosso-Bar-Jaragua-do-Sul'),
  ('Deck Lounge | Extra Bar','Rua Presidente Epitácio Pessoa, 869 - Centro','Dom: 18:00–02:00; sex/sáb: 18:00–04:00','Bar','https://www.locaisdobrasil.com.br/encontre/bares/jaragua-do-sul-sc/deck-lounge-extra-bar/660f4cbda451b0ad1fb9b200'),
  ('Bebidas Jaraguá • BJ','Rua Erwino Menegotti, 1850 - Rau','Qui–sáb: 09:00–02:00; demais dias: até 00:00','Conveniência / bebidas','https://www.waze.com/live-map/directions/br/sc/bebidas-jaragua-%2A-bj?to=place.ChIJ_61FjdCV3pQRmlJqo2-3Doc')
)
INSERT INTO public.estabelecimentos (
  nome, endereco, telefone, horario_funcionamento, descricao, tipo,
  usuario_id, status_plano, mensalidade, teste_termina_em, vencimento_em,
  tolerancia_ate, visivel_publico, ativo, cidade, estado, fotos,
  cadastro_informativo, fonte_url, fonte_consultada_em
)
SELECT
  c.nome, c.endereco, NULL, c.horario_funcionamento,
  'Cadastro informativo com dados publicados em fonte externa. O estabelecimento não confirmou este perfil e não é parceiro oficial do NIGHTlife. Horários podem mudar; confirme diretamente antes de sair.',
  c.tipo,
  NULL, 'informativo', 0, NULL, NULL, NULL, TRUE, TRUE,
  'Jaraguá do Sul', 'SC', ARRAY[]::text[],
  TRUE, c.fonte_url, DATE '2026-11-10'
FROM candidatos c
WHERE NOT EXISTS (
  SELECT 1
  FROM public.estabelecimentos e
  WHERE e.cadastro_informativo IS TRUE
    AND lower(trim(e.nome)) = lower(trim(c.nome))
    AND e.cidade = 'Jaraguá do Sul'
    AND trim(e.estado) = 'SC'
);
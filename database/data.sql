ALTER DATABASE :db SET postgrest.claims.user_id TO '';

INSERT INTO rs.users (id, username, password) VALUES
       ('36bcf3b6-7a88-4de2-ac77-6d92e0fd6109', 'user1', 'secret'),
       ('c291dc50-dad6-4bc9-bb54-7317ca03d20d', 'user2', 'secret'),
       ('5e3f1ab7-646b-4476-afc0-d2ae42cd18c6', 'user3', 'secret'),
       ('17b6486f-f0a6-4a7f-b107-eda2cc597e5f', 'user4', 'secret'),
       ('ce0878df-29ba-4ffe-809c-41c0a2c2cd91', 'user5', 'secret'),
       ('624a66e6-e1cc-4337-80a1-1a69b67fa23e', 'user6', 'secret');

INSERT INTO rs.estados (id, nome, uf, regiao) VALUES
       ('1', 'Acre', 'AC', 'Norte'),
       ('2', 'Alagoas', 'AL', 'Nordeste'),
       ('3', 'Amapá', 'AP', 'Norte');

INSERT INTO rs.cidades (id, estado_id, codigo, nome, uf) VALUES
       (1,1,2,'A City','AC'),
       (2,2,2,'B City','AL'),
       (3,2,2,'C City','AL'),
       (4,3,2,'D City','AP');

INSERT INTO rs.afiliados (user_id, nome, birthday, cidade_id, estado_id) VALUES
       (1, 'A Name', '1990-06-10', 2, 2),
       (2, 'B Name', '1991-06-10', 2, 2),
       (3, 'C Name', '1992-06-10', 3, 2),
       (4, 'D Name', '1993-06-10', 4, 3),
       (5, 'E Name', '1994-06-10', 4, 3);

INSERT INTO rs.regra_afiliados (user_id, role_name, access_level, city_id, state_id) VALUES
       (1, 'rs_role_afiliado', 'municipal'::access_level_kind, 2, null),
       (3, 'rs_role_afiliado', 'estadual'::access_level_kind, null, 2),
       (4, 'rs_role_afiliado', 'nacional'::access_level_kind, null, null);


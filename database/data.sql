ALTER DATABASE :db SET postgrest.claims.user_id TO '';

INSERT INTO rs.users (id, username, password) VALUES
       (1, 'user1', 'secret'),
       (2, 'user2', 'secret'),
       (3, 'user3', 'secret'),
       (4, 'user4', 'secret'),
       (5, 'user5', 'secret'),
       (6, 'user6', 'secret');

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
       (1, 'rs_role_afiliado', 'municipal', 2, null),
       (3, 'rs_role_afiliado', 'estadual', null, 2),
       (4, 'rs_role_afiliado', 'nacional', null, null);


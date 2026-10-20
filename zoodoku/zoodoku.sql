-- ============================================================
--  ZOODOKU - base de datos
--  Juego diario: rellena un tablero 3x3 con animales que cumplan
--  la condicion de su fila y la de su columna.
--
--  Importar desde phpMyAdmin (pestana Importar) o con:
--      mysql -u root < zoodoku.sql
-- ============================================================

CREATE DATABASE IF NOT EXISTS zoodoku
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE zoodoku;

-- Borramos en orden inverso por las claves foraneas
DROP VIEW  IF EXISTS v_rareza;
DROP VIEW  IF EXISTS v_parejas;
DROP VIEW  IF EXISTS v_animal_criterio;
DROP TABLE IF EXISTS respuestas;
DROP TABLE IF EXISTS tableros;
DROP TABLE IF EXISTS animal_etiqueta;
DROP TABLE IF EXISTS criterios;
DROP TABLE IF EXISTS etiquetas;
DROP TABLE IF EXISTS animales;


-- ============================================================
--  TABLAS
-- ============================================================

-- Un animal con sus datos "de una sola respuesta" (clase, dieta, tamano).
-- Tamano orientativo segun el peso de un adulto:
--   pequeno < 5 kg  |  mediano 5-100 kg  |  grande > 100 kg
CREATE TABLE animales (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(60) NOT NULL UNIQUE,
  clase VARCHAR(15) NOT NULL
    CHECK (clase IN ('mamifero','ave','reptil','anfibio','pez','invertebrado')),
  dieta VARCHAR(15) NOT NULL
    CHECK (dieta IN ('carnivoro','herbivoro','omnivoro','insectivoro')),
  tamano VARCHAR(10) NOT NULL
    CHECK (tamano IN ('pequeno','mediano','grande'))
);

-- Datos que un animal puede tener varias veces:
-- donde vive (habitat), en que continentes (continente) y rasgos (rasgo).
CREATE TABLE etiquetas (
  id INT AUTO_INCREMENT PRIMARY KEY,
  tipo VARCHAR(15) NOT NULL
    CHECK (tipo IN ('habitat','continente','rasgo')),
  nombre VARCHAR(30) NOT NULL,
  UNIQUE (tipo, nombre)
);

-- Relacion muchos a muchos entre animales y etiquetas
CREATE TABLE animal_etiqueta (
  animal_id INT NOT NULL,
  etiqueta_id INT NOT NULL,
  PRIMARY KEY (animal_id, etiqueta_id),
  FOREIGN KEY (animal_id) REFERENCES animales(id),
  FOREIGN KEY (etiqueta_id) REFERENCES etiquetas(id)
);

-- Condiciones que pueden salir en las cabeceras del tablero.
-- tipo + valor dicen que mira la condicion:
--   tipo 'clase'      -> animales.clase = valor
--   tipo 'dieta'      -> animales.dieta = valor
--   tipo 'tamano'     -> animales.tamano = valor
--   tipo 'habitat', 'continente' o 'rasgo' -> etiquetas.nombre = valor
-- texto es lo que ve el jugador y icono un emoji decorativo.
-- Si activo = 0 la condicion no se usa (porque hay pocos animales).
CREATE TABLE criterios (
  id INT AUTO_INCREMENT PRIMARY KEY,
  tipo VARCHAR(15) NOT NULL,
  valor VARCHAR(30) NOT NULL,
  texto VARCHAR(60) NOT NULL,
  icono VARCHAR(8) NOT NULL DEFAULT '',
  activo TINYINT NOT NULL DEFAULT 1,
  UNIQUE (tipo, valor)
);

-- Un tablero por dia: 3 criterios para las filas y 3 para las columnas
CREATE TABLE tableros (
  id INT AUTO_INCREMENT PRIMARY KEY,
  fecha DATE NOT NULL UNIQUE,
  fila1 INT NOT NULL,
  fila2 INT NOT NULL,
  fila3 INT NOT NULL,
  col1 INT NOT NULL,
  col2 INT NOT NULL,
  col3 INT NOT NULL,
  FOREIGN KEY (fila1) REFERENCES criterios(id),
  FOREIGN KEY (fila2) REFERENCES criterios(id),
  FOREIGN KEY (fila3) REFERENCES criterios(id),
  FOREIGN KEY (col1) REFERENCES criterios(id),
  FOREIGN KEY (col2) REFERENCES criterios(id),
  FOREIGN KEY (col3) REFERENCES criterios(id)
);

-- Cada acierto de un jugador. Solo guardamos los aciertos, y sirven
-- para calcular la rareza (que porcentaje de jugadores eligio cada animal).
-- celda va de 0 a 8 (izquierda a derecha, arriba a abajo).
-- jugador es un identificador anonimo que genera el navegador.
CREATE TABLE respuestas (
  id INT AUTO_INCREMENT PRIMARY KEY,
  tablero_id INT NOT NULL,
  celda TINYINT NOT NULL CHECK (celda BETWEEN 0 AND 8),
  animal_id INT NOT NULL,
  jugador VARCHAR(40) NOT NULL,
  creada_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (tablero_id, celda, jugador),
  FOREIGN KEY (tablero_id) REFERENCES tableros(id),
  FOREIGN KEY (animal_id) REFERENCES animales(id)
);


-- ============================================================
--  DATOS: ETIQUETAS
-- ============================================================
INSERT INTO etiquetas (id, tipo, nombre) VALUES
  (1, 'habitat', 'bosque'),
  (2, 'habitat', 'selva'),
  (3, 'habitat', 'sabana'),
  (4, 'habitat', 'desierto'),
  (5, 'habitat', 'oceano'),
  (6, 'habitat', 'agua_dulce'),
  (7, 'habitat', 'montana'),
  (8, 'habitat', 'polar'),
  (9, 'continente', 'europa'),
  (10, 'continente', 'asia'),
  (11, 'continente', 'africa'),
  (12, 'continente', 'america'),
  (13, 'continente', 'oceania'),
  (14, 'continente', 'antartida'),
  (15, 'rasgo', 'nocturno'),
  (16, 'rasgo', 'vuela'),
  (17, 'rasgo', 'acuatico'),
  (18, 'rasgo', 'venenoso'),
  (19, 'rasgo', 'cuernos'),
  (20, 'rasgo', 'manada'),
  (21, 'rasgo', 'migratorio'),
  (22, 'rasgo', 'marsupial'),
  (23, 'rasgo', 'rayas_manchas'),
  (24, 'rasgo', 'caparazon'),
  (25, 'rasgo', 'domestico');


-- ============================================================
--  DATOS: ANIMALES
-- ============================================================
INSERT INTO animales (id, nombre, clase, dieta, tamano) VALUES
  (1, 'León', 'mamifero', 'carnivoro', 'grande'),
  (2, 'Tigre', 'mamifero', 'carnivoro', 'grande'),
  (3, 'Leopardo', 'mamifero', 'carnivoro', 'mediano'),
  (4, 'Jaguar', 'mamifero', 'carnivoro', 'mediano'),
  (5, 'Puma', 'mamifero', 'carnivoro', 'mediano'),
  (6, 'Guepardo', 'mamifero', 'carnivoro', 'mediano'),
  (7, 'Leopardo de las nieves', 'mamifero', 'carnivoro', 'mediano'),
  (8, 'Lince ibérico', 'mamifero', 'carnivoro', 'mediano'),
  (9, 'Hiena manchada', 'mamifero', 'carnivoro', 'mediano'),
  (10, 'Lobo gris', 'mamifero', 'carnivoro', 'mediano'),
  (11, 'Zorro rojo', 'mamifero', 'omnivoro', 'mediano'),
  (12, 'Oso pardo', 'mamifero', 'omnivoro', 'grande'),
  (13, 'Oso polar', 'mamifero', 'carnivoro', 'grande'),
  (14, 'Panda gigante', 'mamifero', 'herbivoro', 'grande'),
  (15, 'Elefante africano', 'mamifero', 'herbivoro', 'grande'),
  (16, 'Elefante asiático', 'mamifero', 'herbivoro', 'grande'),
  (17, 'Jirafa', 'mamifero', 'herbivoro', 'grande'),
  (18, 'Cebra', 'mamifero', 'herbivoro', 'grande'),
  (19, 'Hipopótamo', 'mamifero', 'herbivoro', 'grande'),
  (20, 'Rinoceronte blanco', 'mamifero', 'herbivoro', 'grande'),
  (21, 'Búfalo africano', 'mamifero', 'herbivoro', 'grande'),
  (22, 'Ñu', 'mamifero', 'herbivoro', 'grande'),
  (23, 'Gacela de Thomson', 'mamifero', 'herbivoro', 'mediano'),
  (24, 'Canguro rojo', 'mamifero', 'herbivoro', 'mediano'),
  (25, 'Koala', 'mamifero', 'herbivoro', 'mediano'),
  (26, 'Wombat', 'mamifero', 'herbivoro', 'mediano'),
  (27, 'Demonio de Tasmania', 'mamifero', 'carnivoro', 'mediano'),
  (28, 'Ornitorrinco', 'mamifero', 'carnivoro', 'pequeno'),
  (29, 'Zarigüeya', 'mamifero', 'omnivoro', 'pequeno'),
  (30, 'Dromedario', 'mamifero', 'herbivoro', 'grande'),
  (31, 'Llama', 'mamifero', 'herbivoro', 'grande'),
  (32, 'Alpaca', 'mamifero', 'herbivoro', 'mediano'),
  (33, 'Perro', 'mamifero', 'omnivoro', 'mediano'),
  (34, 'Gato doméstico', 'mamifero', 'carnivoro', 'pequeno'),
  (35, 'Caballo', 'mamifero', 'herbivoro', 'grande'),
  (36, 'Vaca', 'mamifero', 'herbivoro', 'grande'),
  (37, 'Oveja', 'mamifero', 'herbivoro', 'mediano'),
  (38, 'Cabra', 'mamifero', 'herbivoro', 'mediano'),
  (39, 'Cerdo', 'mamifero', 'omnivoro', 'grande'),
  (40, 'Conejo', 'mamifero', 'herbivoro', 'pequeno'),
  (41, 'Ardilla roja', 'mamifero', 'omnivoro', 'pequeno'),
  (42, 'Erizo', 'mamifero', 'insectivoro', 'pequeno'),
  (43, 'Murciélago común', 'mamifero', 'insectivoro', 'pequeno'),
  (44, 'Delfín mular', 'mamifero', 'carnivoro', 'grande'),
  (45, 'Ballena azul', 'mamifero', 'carnivoro', 'grande'),
  (46, 'Orca', 'mamifero', 'carnivoro', 'grande'),
  (47, 'Foca común', 'mamifero', 'carnivoro', 'mediano'),
  (48, 'Morsa', 'mamifero', 'carnivoro', 'grande'),
  (49, 'Nutria europea', 'mamifero', 'carnivoro', 'mediano'),
  (50, 'Castor', 'mamifero', 'herbivoro', 'mediano'),
  (51, 'Mapache', 'mamifero', 'omnivoro', 'mediano'),
  (52, 'Mofeta rayada', 'mamifero', 'omnivoro', 'pequeno'),
  (53, 'Gorila de montaña', 'mamifero', 'herbivoro', 'grande'),
  (54, 'Chimpancé', 'mamifero', 'omnivoro', 'mediano'),
  (55, 'Orangután', 'mamifero', 'omnivoro', 'mediano'),
  (56, 'Lémur de cola anillada', 'mamifero', 'omnivoro', 'pequeno'),
  (57, 'Perezoso de tres dedos', 'mamifero', 'herbivoro', 'pequeno'),
  (58, 'Armadillo de nueve bandas', 'mamifero', 'insectivoro', 'mediano'),
  (59, 'Oso hormiguero gigante', 'mamifero', 'insectivoro', 'mediano'),
  (60, 'Pangolín', 'mamifero', 'insectivoro', 'mediano'),
  (61, 'Alce', 'mamifero', 'herbivoro', 'grande'),
  (62, 'Reno', 'mamifero', 'herbivoro', 'mediano'),
  (63, 'Ciervo rojo', 'mamifero', 'herbivoro', 'grande'),
  (64, 'Jabalí', 'mamifero', 'omnivoro', 'mediano'),
  (65, 'Bisonte europeo', 'mamifero', 'herbivoro', 'grande'),
  (66, 'Cabra montés', 'mamifero', 'herbivoro', 'mediano'),
  (67, 'Yak', 'mamifero', 'herbivoro', 'grande'),
  (68, 'Tapir', 'mamifero', 'herbivoro', 'grande'),
  (69, 'Capibara', 'mamifero', 'herbivoro', 'mediano'),
  (70, 'Suricata', 'mamifero', 'insectivoro', 'pequeno'),
  (71, 'Águila real', 'ave', 'carnivoro', 'mediano'),
  (72, 'Águila calva', 'ave', 'carnivoro', 'mediano'),
  (73, 'Búho real', 'ave', 'carnivoro', 'pequeno'),
  (74, 'Lechuza común', 'ave', 'carnivoro', 'pequeno'),
  (75, 'Halcón peregrino', 'ave', 'carnivoro', 'pequeno'),
  (76, 'Cóndor andino', 'ave', 'carnivoro', 'mediano'),
  (77, 'Buitre leonado', 'ave', 'carnivoro', 'mediano'),
  (78, 'Guacamayo azul y amarillo', 'ave', 'herbivoro', 'pequeno'),
  (79, 'Tucán', 'ave', 'omnivoro', 'pequeno'),
  (80, 'Colibrí', 'ave', 'herbivoro', 'pequeno'),
  (81, 'Flamenco común', 'ave', 'omnivoro', 'pequeno'),
  (82, 'Pingüino emperador', 'ave', 'carnivoro', 'mediano'),
  (83, 'Avestruz', 'ave', 'omnivoro', 'grande'),
  (84, 'Emú', 'ave', 'omnivoro', 'mediano'),
  (85, 'Kiwi', 'ave', 'insectivoro', 'pequeno'),
  (86, 'Cisne vulgar', 'ave', 'herbivoro', 'mediano'),
  (87, 'Pato real', 'ave', 'omnivoro', 'pequeno'),
  (88, 'Gallina', 'ave', 'omnivoro', 'pequeno'),
  (89, 'Pavo real', 'ave', 'omnivoro', 'mediano'),
  (90, 'Gaviota', 'ave', 'omnivoro', 'pequeno'),
  (91, 'Cigüeña blanca', 'ave', 'carnivoro', 'pequeno'),
  (92, 'Pelícano', 'ave', 'carnivoro', 'mediano'),
  (93, 'Petirrojo', 'ave', 'insectivoro', 'pequeno'),
  (94, 'Albatros viajero', 'ave', 'carnivoro', 'mediano'),
  (95, 'Pájaro carpintero', 'ave', 'insectivoro', 'pequeno'),
  (96, 'Cuervo', 'ave', 'omnivoro', 'pequeno'),
  (97, 'Garza real', 'ave', 'carnivoro', 'pequeno'),
  (98, 'Cocodrilo del Nilo', 'reptil', 'carnivoro', 'grande'),
  (99, 'Caimán negro', 'reptil', 'carnivoro', 'grande'),
  (100, 'Aligátor americano', 'reptil', 'carnivoro', 'grande'),
  (101, 'Tortuga gigante de Galápagos', 'reptil', 'herbivoro', 'grande'),
  (102, 'Tortuga verde', 'reptil', 'herbivoro', 'grande'),
  (103, 'Tortuga mediterránea', 'reptil', 'herbivoro', 'pequeno'),
  (104, 'Iguana verde', 'reptil', 'herbivoro', 'mediano'),
  (105, 'Camaleón común', 'reptil', 'insectivoro', 'pequeno'),
  (106, 'Cobra real', 'reptil', 'carnivoro', 'mediano'),
  (107, 'Serpiente de cascabel', 'reptil', 'carnivoro', 'mediano'),
  (108, 'Pitón reticulada', 'reptil', 'carnivoro', 'mediano'),
  (109, 'Anaconda verde', 'reptil', 'carnivoro', 'mediano'),
  (110, 'Mamba negra', 'reptil', 'carnivoro', 'pequeno'),
  (111, 'Dragón de Komodo', 'reptil', 'carnivoro', 'mediano'),
  (112, 'Víbora áspid', 'reptil', 'carnivoro', 'pequeno'),
  (113, 'Monstruo de Gila', 'reptil', 'carnivoro', 'pequeno'),
  (114, 'Rana común', 'anfibio', 'insectivoro', 'pequeno'),
  (115, 'Rana dardo azul', 'anfibio', 'insectivoro', 'pequeno'),
  (116, 'Sapo común', 'anfibio', 'insectivoro', 'pequeno'),
  (117, 'Salamandra común', 'anfibio', 'insectivoro', 'pequeno'),
  (118, 'Ajolote', 'anfibio', 'carnivoro', 'pequeno'),
  (119, 'Rana toro', 'anfibio', 'carnivoro', 'pequeno'),
  (120, 'Rana de ojos rojos', 'anfibio', 'insectivoro', 'pequeno'),
  (121, 'Sapo de caña', 'anfibio', 'omnivoro', 'pequeno'),
  (122, 'Tiburón blanco', 'pez', 'carnivoro', 'grande'),
  (123, 'Tiburón ballena', 'pez', 'carnivoro', 'grande'),
  (124, 'Tiburón martillo', 'pez', 'carnivoro', 'grande'),
  (125, 'Pez payaso', 'pez', 'omnivoro', 'pequeno'),
  (126, 'Salmón del Atlántico', 'pez', 'carnivoro', 'mediano'),
  (127, 'Trucha común', 'pez', 'carnivoro', 'pequeno'),
  (128, 'Atún rojo', 'pez', 'carnivoro', 'grande'),
  (129, 'Pez globo', 'pez', 'omnivoro', 'pequeno'),
  (130, 'Caballito de mar', 'pez', 'carnivoro', 'pequeno'),
  (131, 'Raya manta', 'pez', 'carnivoro', 'grande'),
  (132, 'Piraña', 'pez', 'carnivoro', 'pequeno'),
  (133, 'Pez espada', 'pez', 'carnivoro', 'grande'),
  (134, 'Pez luna', 'pez', 'carnivoro', 'grande'),
  (135, 'Anguila europea', 'pez', 'carnivoro', 'pequeno'),
  (136, 'Carpa común', 'pez', 'omnivoro', 'pequeno'),
  (137, 'Pez león', 'pez', 'carnivoro', 'pequeno'),
  (138, 'Barracuda', 'pez', 'carnivoro', 'mediano'),
  (139, 'Pulpo común', 'invertebrado', 'carnivoro', 'pequeno'),
  (140, 'Calamar gigante', 'invertebrado', 'carnivoro', 'grande'),
  (141, 'Medusa luna', 'invertebrado', 'carnivoro', 'pequeno'),
  (142, 'Abeja melífera', 'invertebrado', 'herbivoro', 'pequeno'),
  (143, 'Mariposa monarca', 'invertebrado', 'herbivoro', 'pequeno'),
  (144, 'Mariquita', 'invertebrado', 'carnivoro', 'pequeno'),
  (145, 'Hormiga', 'invertebrado', 'omnivoro', 'pequeno'),
  (146, 'Escorpión emperador', 'invertebrado', 'carnivoro', 'pequeno'),
  (147, 'Tarántula', 'invertebrado', 'carnivoro', 'pequeno'),
  (148, 'Saltamontes', 'invertebrado', 'herbivoro', 'pequeno'),
  (149, 'Escarabajo rinoceronte', 'invertebrado', 'herbivoro', 'pequeno'),
  (150, 'Langosta europea', 'invertebrado', 'omnivoro', 'pequeno'),
  (151, 'Cangrejo ermitaño', 'invertebrado', 'omnivoro', 'pequeno'),
  (152, 'Caracol de jardín', 'invertebrado', 'herbivoro', 'pequeno'),
  (153, 'Lombriz de tierra', 'invertebrado', 'herbivoro', 'pequeno'),
  (154, 'Estrella de mar', 'invertebrado', 'carnivoro', 'pequeno'),
  (155, 'Libélula', 'invertebrado', 'carnivoro', 'pequeno'),
  (156, 'Mantis religiosa', 'invertebrado', 'carnivoro', 'pequeno');


-- ============================================================
--  DATOS: ETIQUETAS DE CADA ANIMAL
--  (animal_id, etiqueta_id). Los ids de las etiquetas estan en
--  la tabla etiquetas de mas arriba.
-- ============================================================
-- León
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (1, 3), (1, 11), (1, 10), (1, 20);
-- Tigre
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (2, 2), (2, 1), (2, 10), (2, 23);
-- Leopardo
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (3, 2), (3, 3), (3, 11), (3, 10), (3, 15), (3, 23);
-- Jaguar
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (4, 2), (4, 12), (4, 23);
-- Puma
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (5, 7), (5, 1), (5, 12);
-- Guepardo
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (6, 3), (6, 11), (6, 23);
-- Leopardo de las nieves
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (7, 7), (7, 10), (7, 23);
-- Lince ibérico
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (8, 1), (8, 9), (8, 15), (8, 23);
-- Hiena manchada
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (9, 3), (9, 11), (9, 20), (9, 15), (9, 23);
-- Lobo gris
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (10, 1), (10, 7), (10, 8), (10, 9), (10, 10), (10, 12), (10, 20);
-- Zorro rojo
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (11, 1), (11, 7), (11, 9), (11, 10), (11, 12), (11, 15);
-- Oso pardo
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (12, 1), (12, 7), (12, 9), (12, 10), (12, 12);
-- Oso polar
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (13, 8), (13, 9), (13, 10), (13, 12);
-- Panda gigante
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (14, 1), (14, 7), (14, 10), (14, 23);
-- Elefante africano
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (15, 3), (15, 2), (15, 11), (15, 20);
-- Elefante asiático
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (16, 2), (16, 1), (16, 10), (16, 20);
-- Jirafa
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (17, 3), (17, 11), (17, 19), (17, 20), (17, 23);
-- Cebra
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (18, 3), (18, 11), (18, 20), (18, 23);
-- Hipopótamo
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (19, 6), (19, 11), (19, 17), (19, 15), (19, 20);
-- Rinoceronte blanco
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (20, 3), (20, 11), (20, 19);
-- Búfalo africano
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (21, 3), (21, 11), (21, 19), (21, 20);
-- Ñu
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (22, 3), (22, 11), (22, 19), (22, 20), (22, 21);
-- Gacela de Thomson
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (23, 3), (23, 11), (23, 19), (23, 20), (23, 21);
-- Canguro rojo
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (24, 4), (24, 3), (24, 13), (24, 22), (24, 20);
-- Koala
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (25, 1), (25, 13), (25, 22), (25, 15);
-- Wombat
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (26, 1), (26, 7), (26, 13), (26, 22), (26, 15);
-- Demonio de Tasmania
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (27, 1), (27, 13), (27, 22), (27, 15);
-- Ornitorrinco
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (28, 6), (28, 13), (28, 17), (28, 18), (28, 15);
-- Zarigüeya
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (29, 1), (29, 12), (29, 22), (29, 15);
-- Dromedario
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (30, 4), (30, 11), (30, 10), (30, 25), (30, 20);
-- Llama
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (31, 7), (31, 12), (31, 25), (31, 20);
-- Alpaca
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (32, 7), (32, 12), (32, 25), (32, 20);
-- Perro
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (33, 9), (33, 10), (33, 11), (33, 12), (33, 13), (33, 25), (33, 20);
-- Gato doméstico
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (34, 9), (34, 10), (34, 11), (34, 12), (34, 13), (34, 25);
-- Caballo
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (35, 9), (35, 10), (35, 11), (35, 12), (35, 13), (35, 25), (35, 20);
-- Vaca
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (36, 9), (36, 10), (36, 11), (36, 12), (36, 13), (36, 25), (36, 19), (36, 20);
-- Oveja
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (37, 9), (37, 10), (37, 11), (37, 12), (37, 13), (37, 25), (37, 19), (37, 20);
-- Cabra
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (38, 9), (38, 10), (38, 11), (38, 12), (38, 13), (38, 25), (38, 19), (38, 20);
-- Cerdo
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (39, 9), (39, 10), (39, 11), (39, 12), (39, 13), (39, 25);
-- Conejo
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (40, 1), (40, 9);
-- Ardilla roja
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (41, 1), (41, 9), (41, 10);
-- Erizo
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (42, 1), (42, 9), (42, 15);
-- Murciélago común
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (43, 1), (43, 9), (43, 10), (43, 11), (43, 12), (43, 13), (43, 16), (43, 15), (43, 20);
-- Delfín mular
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (44, 5), (44, 9), (44, 10), (44, 11), (44, 12), (44, 13), (44, 17), (44, 20);
-- Ballena azul
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (45, 5), (45, 9), (45, 10), (45, 11), (45, 12), (45, 13), (45, 14), (45, 17), (45, 21);
-- Orca
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (46, 5), (46, 9), (46, 10), (46, 11), (46, 12), (46, 13), (46, 14), (46, 17), (46, 20), (46, 23);
-- Foca común
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (47, 5), (47, 9), (47, 10), (47, 12), (47, 17);
-- Morsa
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (48, 8), (48, 5), (48, 9), (48, 10), (48, 12), (48, 17), (48, 20);
-- Nutria europea
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (49, 6), (49, 9), (49, 10), (49, 17), (49, 15);
-- Castor
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (50, 6), (50, 9), (50, 12), (50, 17), (50, 15);
-- Mapache
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (51, 1), (51, 12), (51, 15), (51, 23);
-- Mofeta rayada
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (52, 1), (52, 12), (52, 15), (52, 23);
-- Gorila de montaña
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (53, 2), (53, 7), (53, 11), (53, 20);
-- Chimpancé
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (54, 2), (54, 11), (54, 20);
-- Orangután
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (55, 2), (55, 10);
-- Lémur de cola anillada
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (56, 1), (56, 11), (56, 20), (56, 23);
-- Perezoso de tres dedos
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (57, 2), (57, 12);
-- Armadillo de nueve bandas
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (58, 1), (58, 3), (58, 12), (58, 24), (58, 15);
-- Oso hormiguero gigante
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (59, 3), (59, 2), (59, 12);
-- Pangolín
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (60, 2), (60, 3), (60, 11), (60, 10), (60, 15);
-- Alce
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (61, 1), (61, 9), (61, 10), (61, 12), (61, 19);
-- Reno
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (62, 8), (62, 1), (62, 9), (62, 10), (62, 12), (62, 19), (62, 20), (62, 21);
-- Ciervo rojo
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (63, 1), (63, 7), (63, 9), (63, 10), (63, 19), (63, 20);
-- Jabalí
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (64, 1), (64, 9), (64, 10), (64, 11), (64, 20), (64, 15);
-- Bisonte europeo
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (65, 1), (65, 9), (65, 19), (65, 20);
-- Cabra montés
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (66, 7), (66, 9), (66, 19), (66, 20);
-- Yak
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (67, 7), (67, 10), (67, 19), (67, 20);
-- Tapir
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (68, 2), (68, 12), (68, 10), (68, 15);
-- Capibara
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (69, 6), (69, 12), (69, 17), (69, 20);
-- Suricata
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (70, 4), (70, 11), (70, 20);
-- Águila real
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (71, 7), (71, 9), (71, 10), (71, 12), (71, 11), (71, 16);
-- Águila calva
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (72, 1), (72, 6), (72, 12), (72, 16);
-- Búho real
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (73, 1), (73, 7), (73, 9), (73, 10), (73, 16), (73, 15);
-- Lechuza común
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (74, 1), (74, 9), (74, 10), (74, 11), (74, 12), (74, 13), (74, 16), (74, 15);
-- Halcón peregrino
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (75, 7), (75, 9), (75, 10), (75, 11), (75, 12), (75, 13), (75, 16), (75, 21);
-- Cóndor andino
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (76, 7), (76, 12), (76, 16);
-- Buitre leonado
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (77, 7), (77, 9), (77, 10), (77, 11), (77, 16), (77, 20);
-- Guacamayo azul y amarillo
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (78, 2), (78, 12), (78, 16), (78, 20);
-- Tucán
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (79, 2), (79, 12), (79, 16);
-- Colibrí
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (80, 2), (80, 1), (80, 12), (80, 16);
-- Flamenco común
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (81, 6), (81, 9), (81, 10), (81, 11), (81, 16), (81, 20), (81, 21);
-- Pingüino emperador
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (82, 8), (82, 5), (82, 14), (82, 17), (82, 20);
-- Avestruz
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (83, 3), (83, 4), (83, 11), (83, 20);
-- Emú
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (84, 3), (84, 13), (84, 20);
-- Kiwi
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (85, 1), (85, 13), (85, 15);
-- Cisne vulgar
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (86, 6), (86, 9), (86, 10), (86, 16), (86, 17), (86, 21);
-- Pato real
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (87, 6), (87, 9), (87, 10), (87, 11), (87, 12), (87, 16), (87, 17);
-- Gallina
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (88, 9), (88, 10), (88, 11), (88, 12), (88, 13), (88, 25), (88, 20);
-- Pavo real
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (89, 1), (89, 10), (89, 23);
-- Gaviota
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (90, 5), (90, 9), (90, 10), (90, 11), (90, 12), (90, 13), (90, 14), (90, 16), (90, 20);
-- Cigüeña blanca
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (91, 6), (91, 9), (91, 10), (91, 11), (91, 16), (91, 21);
-- Pelícano
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (92, 6), (92, 5), (92, 9), (92, 10), (92, 11), (92, 12), (92, 16), (92, 20), (92, 17);
-- Petirrojo
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (93, 1), (93, 9), (93, 16);
-- Albatros viajero
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (94, 5), (94, 11), (94, 12), (94, 13), (94, 14), (94, 16), (94, 21);
-- Pájaro carpintero
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (95, 1), (95, 9), (95, 10), (95, 12), (95, 16);
-- Cuervo
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (96, 1), (96, 7), (96, 9), (96, 10), (96, 12), (96, 16);
-- Garza real
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (97, 6), (97, 9), (97, 10), (97, 11), (97, 16);
-- Cocodrilo del Nilo
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (98, 6), (98, 11), (98, 17);
-- Caimán negro
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (99, 6), (99, 12), (99, 17), (99, 15);
-- Aligátor americano
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (100, 6), (100, 12), (100, 17);
-- Tortuga gigante de Galápagos
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (101, 7), (101, 12), (101, 24);
-- Tortuga verde
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (102, 5), (102, 9), (102, 10), (102, 11), (102, 12), (102, 13), (102, 17), (102, 24), (102, 21);
-- Tortuga mediterránea
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (103, 1), (103, 9), (103, 24);
-- Iguana verde
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (104, 2), (104, 12);
-- Camaleón común
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (105, 1), (105, 11), (105, 9);
-- Cobra real
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (106, 2), (106, 10), (106, 18);
-- Serpiente de cascabel
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (107, 4), (107, 12), (107, 18);
-- Pitón reticulada
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (108, 2), (108, 10), (108, 23);
-- Anaconda verde
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (109, 6), (109, 2), (109, 12), (109, 17), (109, 23);
-- Mamba negra
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (110, 3), (110, 11), (110, 18);
-- Dragón de Komodo
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (111, 3), (111, 10), (111, 18);
-- Víbora áspid
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (112, 1), (112, 7), (112, 9), (112, 18);
-- Monstruo de Gila
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (113, 4), (113, 12), (113, 18), (113, 23);
-- Rana común
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (114, 6), (114, 1), (114, 9), (114, 10), (114, 17);
-- Rana dardo azul
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (115, 2), (115, 12), (115, 18), (115, 23);
-- Sapo común
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (116, 1), (116, 9), (116, 10), (116, 11), (116, 15);
-- Salamandra común
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (117, 1), (117, 9), (117, 15), (117, 18), (117, 23);
-- Ajolote
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (118, 6), (118, 12), (118, 17);
-- Rana toro
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (119, 6), (119, 12), (119, 17), (119, 15);
-- Rana de ojos rojos
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (120, 2), (120, 12), (120, 15);
-- Sapo de caña
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (121, 2), (121, 1), (121, 12), (121, 13), (121, 18), (121, 15);
-- Tiburón blanco
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (122, 5), (122, 9), (122, 10), (122, 11), (122, 12), (122, 13), (122, 17);
-- Tiburón ballena
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (123, 5), (123, 10), (123, 11), (123, 12), (123, 13), (123, 17), (123, 23), (123, 21);
-- Tiburón martillo
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (124, 5), (124, 10), (124, 11), (124, 12), (124, 13), (124, 17), (124, 20);
-- Pez payaso
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (125, 5), (125, 10), (125, 13), (125, 17), (125, 23);
-- Salmón del Atlántico
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (126, 6), (126, 5), (126, 9), (126, 12), (126, 17), (126, 21);
-- Trucha común
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (127, 6), (127, 9), (127, 10), (127, 17), (127, 23);
-- Atún rojo
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (128, 5), (128, 9), (128, 11), (128, 12), (128, 17), (128, 21);
-- Pez globo
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (129, 5), (129, 10), (129, 11), (129, 12), (129, 13), (129, 17), (129, 18);
-- Caballito de mar
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (130, 5), (130, 9), (130, 10), (130, 11), (130, 12), (130, 13), (130, 17);
-- Raya manta
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (131, 5), (131, 10), (131, 11), (131, 12), (131, 13), (131, 17), (131, 21);
-- Piraña
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (132, 6), (132, 12), (132, 17), (132, 20);
-- Pez espada
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (133, 5), (133, 9), (133, 10), (133, 11), (133, 12), (133, 13), (133, 17), (133, 21);
-- Pez luna
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (134, 5), (134, 9), (134, 10), (134, 11), (134, 12), (134, 13), (134, 17);
-- Anguila europea
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (135, 6), (135, 5), (135, 9), (135, 17), (135, 21), (135, 15);
-- Carpa común
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (136, 6), (136, 9), (136, 10), (136, 17);
-- Pez león
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (137, 5), (137, 10), (137, 13), (137, 12), (137, 17), (137, 18), (137, 23);
-- Barracuda
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (138, 5), (138, 10), (138, 11), (138, 12), (138, 13), (138, 17);
-- Pulpo común
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (139, 5), (139, 9), (139, 10), (139, 11), (139, 12), (139, 13), (139, 17);
-- Calamar gigante
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (140, 5), (140, 9), (140, 10), (140, 11), (140, 12), (140, 13), (140, 14), (140, 17);
-- Medusa luna
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (141, 5), (141, 9), (141, 10), (141, 11), (141, 12), (141, 13), (141, 17), (141, 18);
-- Abeja melífera
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (142, 1), (142, 9), (142, 10), (142, 11), (142, 12), (142, 13), (142, 16), (142, 20), (142, 18);
-- Mariposa monarca
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (143, 1), (143, 12), (143, 16), (143, 21), (143, 23);
-- Mariquita
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (144, 1), (144, 9), (144, 10), (144, 12), (144, 16), (144, 23);
-- Hormiga
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (145, 1), (145, 2), (145, 9), (145, 10), (145, 11), (145, 12), (145, 13), (145, 20);
-- Escorpión emperador
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (146, 2), (146, 11), (146, 18), (146, 15);
-- Tarántula
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (147, 2), (147, 4), (147, 12), (147, 18), (147, 15);
-- Saltamontes
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (148, 3), (148, 9), (148, 10), (148, 11), (148, 12), (148, 13), (148, 16);
-- Escarabajo rinoceronte
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (149, 1), (149, 9), (149, 10), (149, 19), (149, 16);
-- Langosta europea
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (150, 5), (150, 9), (150, 17), (150, 24), (150, 15);
-- Cangrejo ermitaño
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (151, 5), (151, 9), (151, 10), (151, 11), (151, 12), (151, 13), (151, 24);
-- Caracol de jardín
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (152, 1), (152, 9), (152, 12), (152, 24), (152, 15);
-- Lombriz de tierra
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (153, 1), (153, 9), (153, 10), (153, 11), (153, 12), (153, 13);
-- Estrella de mar
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (154, 5), (154, 9), (154, 10), (154, 11), (154, 12), (154, 13), (154, 14), (154, 17);
-- Libélula
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (155, 6), (155, 9), (155, 10), (155, 11), (155, 12), (155, 13), (155, 16);
-- Mantis religiosa
INSERT INTO animal_etiqueta (animal_id, etiqueta_id) VALUES (156, 1), (156, 9), (156, 10), (156, 11);


-- ============================================================
--  DATOS: CRITERIOS (condiciones de las cabeceras)
-- ============================================================
INSERT INTO criterios (tipo, valor, texto, icono) VALUES
  ('clase', 'mamifero', 'Mamífero', '🦁'),
  ('clase', 'ave', 'Ave', '🦅'),
  ('clase', 'reptil', 'Reptil', '🦎'),
  ('clase', 'anfibio', 'Anfibio', '🐸'),
  ('clase', 'pez', 'Pez', '🐟'),
  ('clase', 'invertebrado', 'Invertebrado', '🐛'),
  ('dieta', 'carnivoro', 'Carnívoro', '🥩'),
  ('dieta', 'herbivoro', 'Herbívoro', '🌿'),
  ('dieta', 'omnivoro', 'Omnívoro', '🍽️'),
  ('dieta', 'insectivoro', 'Come insectos', '🐛'),
  ('tamano', 'pequeno', 'Pesa menos de 5 kg', '🐭'),
  ('tamano', 'mediano', 'Pesa entre 5 y 100 kg', '🐕'),
  ('tamano', 'grande', 'Pesa más de 100 kg', '🐘'),
  ('habitat', 'bosque', 'Vive en el bosque', '🌲'),
  ('habitat', 'selva', 'Vive en la selva', '🌴'),
  ('habitat', 'sabana', 'Vive en la sabana', '🌾'),
  ('habitat', 'desierto', 'Vive en el desierto', '🏜️'),
  ('habitat', 'oceano', 'Vive en el océano', '🌊'),
  ('habitat', 'agua_dulce', 'Vive en agua dulce', '💧'),
  ('habitat', 'montana', 'Vive en la montaña', '⛰️'),
  ('habitat', 'polar', 'Vive en zonas polares', '❄️'),
  ('continente', 'europa', 'Vive en Europa', '🌍'),
  ('continente', 'asia', 'Vive en Asia', '🌏'),
  ('continente', 'africa', 'Vive en África', '🌍'),
  ('continente', 'america', 'Vive en América', '🌎'),
  ('continente', 'oceania', 'Vive en Oceanía', '🌏'),
  ('continente', 'antartida', 'Vive en la Antártida', '🧊'),
  ('rasgo', 'nocturno', 'Es nocturno', '🌙'),
  ('rasgo', 'vuela', 'Puede volar', '🕊️'),
  ('rasgo', 'acuatico', 'Pasa la vida en el agua', '🏊'),
  ('rasgo', 'venenoso', 'Es venenoso', '☠️'),
  ('rasgo', 'cuernos', 'Tiene cuernos o astas', '🦌'),
  ('rasgo', 'manada', 'Vive en grupo', '👥'),
  ('rasgo', 'migratorio', 'Es migratorio', '🧭'),
  ('rasgo', 'marsupial', 'Es marsupial', '🦘'),
  ('rasgo', 'rayas_manchas', 'Tiene rayas o manchas', '🦓'),
  ('rasgo', 'caparazon', 'Tiene caparazón', '🐢'),
  ('rasgo', 'domestico', 'Es doméstico', '🏠');


-- ============================================================
--  VISTAS
-- ============================================================

-- Que animal cumple que criterio. Es la vista clave: para saber si una
-- respuesta es valida basta comprobar que el animal sale con los dos
-- criterios de la casilla.
CREATE VIEW v_animal_criterio AS
  SELECT a.id AS animal_id, c.id AS criterio_id
  FROM animales a
  JOIN criterios c ON c.tipo = 'clase' AND c.valor = a.clase
  UNION ALL
  SELECT a.id, c.id
  FROM animales a
  JOIN criterios c ON c.tipo = 'dieta' AND c.valor = a.dieta
  UNION ALL
  SELECT a.id, c.id
  FROM animales a
  JOIN criterios c ON c.tipo = 'tamano' AND c.valor = a.tamano
  UNION ALL
  SELECT ae.animal_id, c.id
  FROM animal_etiqueta ae
  JOIN etiquetas e ON e.id = ae.etiqueta_id
  JOIN criterios c ON c.tipo = e.tipo AND c.valor = e.nombre;

-- Cuantos animales cumplen cada pareja de criterios (en los dos sentidos).
-- Sirve para que el tablero nunca tenga una casilla sin respuesta.
CREATE VIEW v_parejas AS
  SELECT x.criterio_id AS criterio_a,
         y.criterio_id AS criterio_b,
         COUNT(*) AS total
  FROM v_animal_criterio x
  JOIN v_animal_criterio y
    ON y.animal_id = x.animal_id AND y.criterio_id <> x.criterio_id
  GROUP BY x.criterio_id, y.criterio_id;

-- Porcentaje de jugadores que eligio cada animal en cada casilla.
-- Cuanto mas bajo, mas raro (mas dificil de pensar) es el animal.
CREATE VIEW v_rareza AS
  SELECT r.tablero_id,
         r.celda,
         r.animal_id,
         COUNT(*) AS veces,
         t.total AS total_celda,
         ROUND(COUNT(*) * 100.0 / t.total, 1) AS porcentaje
  FROM respuestas r
  JOIN (SELECT tablero_id, celda, COUNT(*) AS total
        FROM respuestas
        GROUP BY tablero_id, celda) t
    ON t.tablero_id = r.tablero_id AND t.celda = r.celda
  GROUP BY r.tablero_id, r.celda, r.animal_id, t.total;


-- ============================================================
--  Desactivar los criterios con menos de 4 animales
--  (si anades animales, vuelve a ejecutar esto y el de abajo)
-- ============================================================
UPDATE criterios SET activo = 0
WHERE id NOT IN (
  SELECT criterio_id FROM (
    SELECT criterio_id
    FROM v_animal_criterio
    GROUP BY criterio_id
    HAVING COUNT(*) >= 4
  ) AS suficientes
);

-- Y para reactivar los que ya lleguen a 4:
-- UPDATE criterios SET activo = 1
-- WHERE id IN (SELECT criterio_id FROM (
--   SELECT criterio_id FROM v_animal_criterio
--   GROUP BY criterio_id HAVING COUNT(*) >= 4) AS suficientes);

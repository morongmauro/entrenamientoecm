-- ════════════════════════════════════════════════════════════════════════
-- VIDEOS · los ejercicios «🔬 En análisis», segunda pasada, POR ID
-- ════════════════════════════════════════════════════════════════════════
-- Dónde: Supabase del CRM → SQL Editor → pegar todo → Run.
-- Se puede correr dos veces: la segunda no cambia nada.
--
-- Hecho con la galería real (CSV del 16 oct: 543 ejercicios, 190 en uso,
-- 353 en análisis). Cada línea lleva el ID del ejercicio: cambia exactamente
-- ese y ninguno más.
--
-- Canales, en este orden de preferencia (si uno no tiene el ejercicio, el
-- siguiente; si ninguno, YouTube general):
--   Functional Bodybuilding → PureGym → OPEX Fitness → Theory Library → LiveLean
-- Videos en esta lista (274):
--   · YouTube                    207
--   · Functional Bodybuilding     49
--   · Theory Library              13
--   · LiveLean                     3
--   · PureGym                      1
--   · OPEX Fitness                 1
-- Coincidencia: 148 exacto · 67 revisar · 52 aproximado · 7 parecido.
--   exacto / equivalente = el mismo ejercicio (mismo nombre, o las mismas
--   palabras en otro orden: «DB» = «Dumbbell»); parecido = una palabra que no
--   cambia el ejercicio («Standing»); aproximado = YouTube general con el
--   mismo equipo y casi el mismo nombre; revisar = YouTube general, el primer
--   resultado corto con el mismo equipo: míralo antes de confiar.
-- Por qué entra cada uno:
--   · sin video → YouTube general                207
--   · sin video → canal                           49
--   · reemplazo por canal                         18
-- Los que ya tenían video solo cambian si el nuevo viene de uno de los cinco
-- canales y el actual no; nunca se cambia un video que ya hay por uno de
-- YouTube general. El informe completo: carga/VIDEOS-EN-ANALISIS-2.md
--
-- PROTECCIONES
--   1. «👥 Los usan ahora» NO SE TOCA: se calcula AQUÍ, al correrlo, con la
--      misma regla del CRM (ciclo vigente de cada cliente activo). Si hoy le
--      pusiste un ejercicio a alguien, ese queda fuera aunque esté en la lista.
--      Y al final se comprueba: si uno solo de esos cambiara, se cancela todo.
--   2. Los videos elegidos a mano en el CRM (video_elegido_at) no se tocan.
--   3. Antes de cambiar nada, el video que tenía cada ejercicio queda guardado
--      en `ejercicios_video_respaldo`. Para volver atrás:
--      carga/videos-en-analisis-2-deshacer.sql
--   4. Solo cambia el video y su miniatura (el cuadro del medio del video).
--      No borra nada; no toca rutinas, clientes, sesiones ni registros.
-- ════════════════════════════════════════════════════════════════════════
begin;

alter table ejercicios add column if not exists video_elegido_at timestamptz;

create table if not exists ejercicios_video_respaldo (
  id               bigserial primary key,
  ejercicio_id     uuid not null,
  video_fuente     text,
  video_ref        text,
  video_url        text,
  video_inicio_seg integer,
  video_path       text,
  poster_path      text,
  poster_url       text,
  video_elegido_at timestamptz,
  motivo           text,
  puesto_ref       text,
  guardado_at      timestamptz not null default now()
);

create temp table _v (id uuid, alias text, nombre text, ref text, canal text, coincide text, titulo text) on commit drop;
insert into _v (id, alias, nombre, ref, canal, coincide, titulo) values
  ('72c371b9-3c79-47da-a635-0ae29310b4a0', null, 'Abducción de cadera en polea', '4vrIJtUisrk', 'YouTube · Koben Moore & Hattie Boydle', 'exacto', 'Cable hip abduction'),
  ('3fdf32ff-0f5c-4b71-9d43-8d25dd40892a', null, 'Abductores en máquina', '6dBeSw1AFUw', 'YouTube · Millarfit', 'revisar', 'How to use the hip adductor and hip abductor machine'),
  ('7a511bf6-96df-49bc-91df-771ba8539378', null, 'Aducción de cadera en polea', 'DAF8tFwzJCg', 'YouTube · TITAN GYM', 'revisar', 'Aducción unilateral de cadera en polea (aductores) /TITÁN GYM/'),
  ('5ce27b9c-b676-4948-9c6a-a939a8398dc3', 'ankle rocks', 'Movilidad de tobillo en zancada', 'WBD8DJ2du8I', 'YouTube · Resilience Physical Therapy and Wellness', 'exacto', 'Ankle Rocks'),
  ('dd368beb-318f-4609-8087-50a7e29e3e64', 'arrancada KB', 'Snatch con kettlebell', 'C7r6jI7Ch48', 'YouTube · Greg Brookes', 'revisar', 'Kettlebell Snatch: The Complete Exercise Tutorial'),
  ('1f207198-4d3c-4b15-be02-6357217e513f', 'back squat', 'Sentadilla trasera con barra', 'LVu9PaIQEwo', 'Functional Bodybuilding', 'exacto', 'Back Squat'),
  ('733557b2-4a02-4988-8c1a-d61f00d061b1', null, 'Balanceo de pierna lateral', '7SF7AYh2_Yw', 'YouTube · Coury & Buehler Physical Therapy', 'revisar', 'Ejercicio de equilibrio con una sola pierna'),
  ('b36d7397-3da3-4341-a73f-daa29fa40efa', 'barbell rollout', 'Rodillo abdominal con barra', 'khKxUeu12H0', 'Theory Library', 'exacto', 'BB Rollout'),
  ('93892ff0-719f-4b9a-ac6c-d966d6215831', 'barbell row, remo pendlay', 'Remo con barra', '89AlXrrBH9c', 'YouTube · The Strength Co.', 'revisar', 'Barbell Row Basics with Starting Strength Coach Grant Broggi'),
  ('046472f0-c61d-4400-af23-6dcd5f367d7f', 'bench press', 'Press de banca con barra', 'nUbEPSYrGQw', 'Functional Bodybuilding', 'exacto', 'Bench Press'),
  ('e2b7469d-661c-4d67-ac05-c98efe03744c', 'bird dog', 'Pájaro-perro', 'Kk_CBagHNMw', 'Functional Bodybuilding', 'exacto', 'Bird Dog'),
  ('8eaa4ab0-1fb9-4fdb-bf5a-decec8e41212', 'Bodyweight Kang Squat', 'Kang squat sin peso', '_zTWEzBctNI', 'Functional Bodybuilding', 'parecido', 'Kang Squat'),
  ('e4b4fb4f-c6a4-4f12-989e-09bf42eeec99', 'box jump', 'Salto al cajón', 'YbA9F8snxrc', 'Theory Library', 'exacto', 'Box Jump'),
  ('73ef48c8-eb2b-4445-b2be-986104328f9b', 'broad jump', 'Salto largo horizontal', 'vDMbSKj9_0E', 'Functional Bodybuilding', 'exacto', 'Broad Jump'),
  ('a4f2b666-a7a8-44b9-9358-f222cd9e9750', null, 'Buenos días en Smith', '-3cv2D_mi_4', 'YouTube · SolFit Team', 'exacto', 'Buenos días en Smith'),
  ('da905ec1-f0f2-4eb1-b310-02150f2c2262', 'Burpee Broad Jump', 'Burpee con salto horizontal', '8m7kZSS46vY', 'Functional Bodybuilding', 'exacto', 'Burpee Broad Jump'),
  ('2fdde2a5-7548-40c9-b75a-057211e590cb', null, 'Burpee con salto al cajón', 'y4_mPdNnfXI', 'YouTube · Lionfit Gym', 'exacto', 'burpee con salto al cajon'),
  ('0a034c15-edf8-4cef-adcb-21bab3db529d', null, 'Burpees', '9Yim_he9TBc', 'Functional Bodybuilding', 'exacto', 'Burpee'),
  ('e4f22c68-9be5-46ad-9bc4-91e88792f549', 'butt kicks', 'Talones al glúteo corriendo', 'e4cnI7eVKRw', 'YouTube · Josh Wilson (Chief)', 'exacto', 'butt kicks exercise'),
  ('3cb56ff9-2c50-46d5-91c3-7e36d87cdb90', 'cable crossover', 'Cruces en polea alta', 'EXRMm4a5hK0', 'Theory Library', 'exacto', 'Cable Crossover'),
  ('dd19f593-d0d7-49d6-9ade-88d891a39752', 'Cable Straight Bar Tricep Pushdown', 'Extensión de tríceps con barra recta en polea', 'Rpv1iD4u7Us', 'LiveLean', 'parecido', 'How To: Standing Cable Triceps Pushdown With Straight Bar'),
  ('2739296f-57f2-4328-b68f-c18f5f2eb0c0', 'Cable V-Bar Overhead Tricep Extension', 'Cable V-Bar Overhead Tricep Extension', 'UNFzrwQq3Xo', 'YouTube · Bristowe Performance', 'exacto', 'V-Bar Cable Overhead Tricep Extensions'),
  ('0bd989e8-bb04-4c39-8877-9c31b4b75fa1', null, 'Cambio de dirección en 5-10-5', 'f8y0CHl6XYQ', 'YouTube · Parisi Speed School of Southeast Texas', 'revisar', '5-10-5 Drill'),
  ('cbc016b1-cc21-4906-b699-0a979b69818a', null, 'Carioca', 'KIuEcF8Arpk', 'YouTube · smithalim', 'exacto', 'Carioca'),
  ('231038fb-14b3-48bb-bd4b-346214cf92cb', null, 'Carrera en escalera de agilidad', '6Rku0OK6Zpk', 'YouTube · Gabriela Gamarra Fit Life', 'revisar', '13 ejercicios de coordinación en escalera'),
  ('1c23bcab-eadd-4699-91f8-8f646615f58b', null, 'Carrera en zigzag', '47WMe1e67FA', 'YouTube · entrenartevideos', 'revisar', 'entrenartevideos, (Agilidad) Desplazamientos en zig zag, entre conos'),
  ('edf3113d-b4f0-4568-99f0-7fc79e86707f', 'cat cow', 'Gato-camello', 'xkfGySGvIjQ', 'Functional Bodybuilding', 'exacto', 'Cat Cow'),
  ('de5bf1b8-4a9e-4c40-8e29-487fbd8389d8', 'chest pass', 'Lanzamiento de balón desde el pecho', 'B2qsEALGXYw', 'YouTube · Thundrbro', 'revisar', 'Plyometric: Chest pass against wall'),
  ('f85d6112-cb0e-4cd2-9e9c-7cd1648c269a', 'chest press', 'Press de pecho en máquina', '-rQlxOj1yZE', 'YouTube · TrainingPedia', 'exacto', 'CHEST PRESS'),
  ('1620e4fc-4f27-438b-be4c-548bbde725cd', 'chest supported row', 'Remo en banco inclinado con mancuernas', '0UBRfiO4zDs', 'YouTube · Renaissance Periodization', 'exacto', 'Chest Supported Row'),
  ('aae2d571-29cc-4a77-a9a1-41ebd28a856b', null, 'Círculos de hombro', 'qiyTtBPxyIs', 'YouTube · Virginia Mason Franciscan Health', 'exacto', 'Shoulder Circles'),
  ('0daf707b-c262-4a02-8602-d407940e5b3a', null, 'Círculos de tobillo', 'puH5FKS9pOI', 'YouTube · RUNFIT', 'exacto', 'Círculo de tobillos'),
  ('272a1ebe-19dd-4369-8a3e-22e38a0f5349', null, 'Clean and press con kettlebell', 'sAtZ4yAsQnI', 'YouTube · Men''s Health', 'aproximado', 'Kettlebell Clean And Press'),
  ('b212f73d-dc7c-4305-b48f-09685b81cc5e', 'close grip', 'Press de banca agarre cerrado', '2cdIRe5tcqI', 'YouTube · Atomic Athlete', 'aproximado', 'Close Grip Pushup'),
  ('61c54e30-3437-4bf7-a459-f8386fb1b8f6', 'contractor de pecho, mariposa', 'Peck deck', 'CsQgnEc5vxY', 'YouTube · UltraGym Fitness Esquipulas', 'revisar', 'PECHO   Aperturas en Contractor de Pecho - Peck Deck'),
  ('787b7c58-e081-4482-aff1-6d58ac48e493', 'cossack squat', 'Sentadilla cosaca', 'dhDjKmTX8tU', 'Functional Bodybuilding', 'exacto', 'Cossack Squat'),
  ('dd8df905-27cc-4a3b-940d-084ef08a5351', null, 'Cruces en polea baja', 'sHwfDdo26b0', 'YouTube · Nacho Alcorta', 'aproximado', 'Pectorales  -  Cruces en polea baja'),
  ('be8c7bfb-6091-4535-ba81-4b44870df6de', 'crunch arrodillado', 'Crunch en polea', 'z1fwSujYhX8', 'YouTube · Joanna Soh', 'revisar', 'How to do Standing Elbow to Knee Crunch | Joanna Soh'),
  ('8e55a63f-6dd1-4b69-9dd9-62cbc6c79db9', 'curl banco 45', 'Curl inclinado en banco', 'siFAH_vjiJE', 'YouTube · Jorge Soria Virto', 'revisar', 'B93 Curl con mancuernas en banco 45º agarre supino alterno abierto'),
  ('aef5d351-f6b1-4f34-8655-18f9fcabbeda', null, 'Curl concentrado', 'Is3JRhq37o4', 'YouTube · sportizemespain', 'exacto', 'Curl concentrado'),
  ('645e4d99-5106-4457-885e-9e90d7f8c509', 'curl crucifijo', 'Curl de bíceps en polea alta', '4k1Dkx4G6Mg', 'YouTube · Derek Noble', 'exacto', 'Crucifix Curls'),
  ('9b4ed34e-3e7e-41bc-9713-46f740e6c4bd', null, 'Curl de bíceps con barra', 'mFgTFstIfFs', 'YouTube · XperFit Wellness Club', 'aproximado', 'Biceps.- Curl con barra Z'),
  ('4cde2f69-7716-43fb-85f0-6ffb519fc3e0', null, 'Curl de bíceps con kettlebell', 'OfgQrQCLJsk', 'YouTube · LIVESTRONG', 'aproximado', 'How to Do a Bicep Curl With a Kettlebell'),
  ('f1d202a1-55aa-4d9d-a85d-796f2e5f3651', null, 'Curl de bíceps en máquina', 'eyqFaF9em-w', 'YouTube · Ammfit', 'aproximado', 'Máquina de Curl de Bíceps:'),
  ('cef259d5-870e-42a2-bc3f-1c0a58dd7fe5', null, 'Curl de muñeca con mancuernas', 'VDSbUhqvWTQ', 'YouTube · sportizemespain', 'exacto', 'Curl de muñeca con mancuerna'),
  ('bc873e70-ee66-48e8-9c6c-94f90377a0e6', 'curl EZ', 'Curl con barra Z', '-gSM-kqNlUw', 'YouTube · OPEX Fitness', 'revisar', 'EZ Bar Curl - OPEX Exercise Library'),
  ('65c36bf7-32fa-41eb-ad96-e7b724d0f8c8', null, 'Curl femoral sentado', '_gHpzHfEvro', 'YouTube · Aitor Vilariño', 'exacto', 'Curl femoral sentado'),
  ('61d0460e-2f7b-4fbf-a510-41b040ee68e4', null, 'Curl martillo con cuerda en polea', '54mQ9iCmmXQ', 'YouTube · SMARTRAINING', 'aproximado', 'CURL DE BÍCEPS MARTILLO CON CUERDA EN POLEA BAJA'),
  ('4590c14b-d8d5-4f50-833e-61e35c143f05', null, 'Curl Zottman', 'Kh7oukUJWEM', 'Functional Bodybuilding', 'exacto', 'Zottman Curls'),
  ('907ac910-7821-4763-90e5-9cd2c9e7c825', 'dead bug', 'Bicho muerto', '1EpheIILXqk', 'Functional Bodybuilding', 'exacto', 'Deadbug'),
  ('6e894dd6-1838-402d-8503-45de7f3cc33a', 'deadlift', 'Peso muerto convencional', '0GCPn0VvXLc', 'PureGym', 'exacto', 'Deadlift'),
  ('faf9c29d-9aab-4f4c-bcbe-3ee4b5b98634', 'deep squat hold', 'Sentadilla profunda sostenida', 'yV-f07dFWgM', 'YouTube · Jacobs Fitness', 'exacto', 'Deep Squat Hold Tutorial'),
  ('e1ab172f-837b-4486-b1fd-c0c9427b6fd1', 'depth jump', 'Bajada del cajón y salto', 'RquU4yJwxFw', 'Theory Library', 'exacto', 'Depth Jump'),
  ('975219df-5312-4193-9d29-5a75d6d638d0', null, 'Dominadas asistidas en máquina', 'lTZfJHTLsjQ', 'YouTube · Trainers On', 'aproximado', 'Dominada Pronada Asistida en Máquina'),
  ('9dd04e99-499d-4408-9292-e62c0c626140', 'double under', 'Doble salto con cuerda', 'IPYqKCDg5Y4', 'Functional Bodybuilding', 'exacto', 'Double Unders'),
  ('464f7333-97b3-4fa6-9147-52197a83d8f8', 'downward dog', 'Perro boca abajo', 'e3quim3xFEA', 'Functional Bodybuilding', 'exacto', 'Downward Dog'),
  ('431e3c21-0281-49e6-992e-c81f2a1d10b2', 'Dumbbell Lateral Raise', 'Elevación lateral con mancuernas', '8aUc9snLOxU', 'OPEX Fitness', 'exacto', 'Dumbbell Lateral Raise'),
  ('d13cd4de-98e9-470b-b13c-69180535dbee', 'Dumbbell Romanian Deadlift', 'Dumbbell Romanian Deadlift', 'UsOjCcxSJaI', 'Functional Bodybuilding', 'exacto', 'Dumbbell Romanian Deadlift'),
  ('c3ec098e-2c80-4c92-a1ca-3dd3adb7bd52', null, 'Elevación de talones con barra', 'vuF4B-881Ds', 'YouTube · Monse Soto', 'exacto', 'Elevación de talones con barra'),
  ('d8a07c43-619a-463f-b757-f3cc715339cc', null, 'Elevación de talones con mancuernas', 'yyoubmNCDk4', 'YouTube · Deporte y Salud ITESO', 'revisar', 'Elevación de talones en posición de pie | Accesorio: mancuernas'),
  ('e86dcc31-81f7-47ad-b87e-e193fbaa0765', null, 'Elevación de talones en máquina', 'CJDdGCWvQ-k', 'YouTube · Instituto IFIC: Cursos online, cursos a distancia', 'exacto', 'Elevación de Talones en Máquina'),
  ('cfcb15e7-a950-4407-9905-791087e1140a', null, 'Elevación de talones en Smith', 'hqpDP6O5Ph8', 'YouTube · Focus MX', 'exacto', 'Elevación de Talones en Smith'),
  ('137aca56-3e1c-4e35-8a1f-49cf7870eb40', null, 'Elevación de talones sentado', 'tn7zDiFBHFE', 'YouTube · Trainerax', 'exacto', 'Seated Calf Raise'),
  ('e5034bfd-c485-458c-8811-81ffd255a423', null, 'Elevaciones frontales en polea', 'way-L7d5NoI', 'YouTube · Fitness&Coach', 'aproximado', 'Elevaciones frontales en polea baja'),
  ('79e725e1-e2a9-4bd7-bd7c-8ce1c82c0a78', null, 'Elevaciones laterales en máquina', 'hTSAWprI-Zg', 'YouTube · PM Well Being', 'aproximado', 'Elevaciones laterales en máquina de pie'),
  ('3c06e5d7-60cc-48b1-9aeb-f39c9cae96fa', null, 'Elevaciones laterales en polea', '8TvVdwpIUA8', 'YouTube · Alexandre Coaching', 'exacto', 'Elevaciones Laterales en Polea (Bilateral)'),
  ('96f812aa-85df-434a-8b45-7183269c7971', null, 'Elevaciones laterales inclinado', 'ycgPxBrKLV8', 'YouTube · Davfer', 'exacto', 'Elevaciones laterales, inclinado'),
  ('1496bb40-c727-472e-a67e-e836bd997642', 'elevaciones posteriores, rear delt fly', 'Pájaros con mancuernas', 'J3C7yEyDGGQ', 'YouTube · Eric Williams welcome to my channel', 'aproximado', 'Rear delt fly (posterior deltoid)'),
  ('86ee548c-c04b-425a-8fb1-332da37d781d', null, 'Empuje de cadera con kettlebell', '5WRJoJlGxYE', 'YouTube · FRANK SERAPIÓN', 'aproximado', 'ELEVACION DE CADERA CON KETTLEBELL'),
  ('cb9df585-7da7-4ce0-b9ae-8db64bbffa0a', null, 'Encogimientos en máquina', 'JyyXMaMvHu8', 'YouTube · SportCityMexico', 'revisar', 'Abdomen en máquina Rutinas031300'),
  ('9fdedad9-6033-4316-82d6-81fcd7b7eb5d', null, 'Encogimientos en polea', 'wB_d8w9ld5w', 'YouTube · ABRAHAM RODRIGUEZ', 'aproximado', 'ENCOGIMIENTOS UNILATERAL EN POLEA'),
  ('ede608b6-f008-48d4-bb1d-21657fafb075', null, 'Encogimientos en Smith', '_W80DSczWO8', 'YouTube · ABRAHAM RODRIGUEZ', 'exacto', 'ENCOGIMIENTOS EN SMITH'),
  ('f5f688cc-c641-4a0d-a9c7-b60f60bc364a', null, 'Escaladores cruzados', 'vy2Cki-5r4k', 'YouTube · MYCOACH ', 'exacto', 'Escaladores Cruzados'),
  ('3ed4090b-6941-46fa-ab26-a7f0e6f4e76c', null, 'Escorpión tumbado', 'CIq-sD549tU', 'YouTube · S4S - Preparación física', 'revisar', 'Escorpiones: Tumbado prono | Sweat4Success'),
  ('a32a6d5e-f82c-4c40-9ace-2a44711ecbb9', null, 'Estiramiento de antebrazo en pared', 'ny2Zfq-p6LU', 'YouTube · OMNIFUNCTION', 'exacto', 'Wall Forearm Stretch'),
  ('d9f2d0d3-a832-4666-9770-5ee123f667f3', null, 'Estiramiento de cuádriceps de pie', 'wIwIGR9jqUA', 'YouTube · Scottish Rite for Children en español', 'exacto', 'Estiramiento de cuádriceps de pie'),
  ('9437cbd5-d5cc-48ee-a1fe-796b330654ce', null, 'Estiramiento de cuello lateral', '54y0JAT46vE', 'YouTube · Coury & Buehler Physical Therapy', 'revisar', 'Neck Side-Bend Stretch'),
  ('6f424d4f-d078-4ef5-8cfd-dab1906e724a', null, 'Estiramiento de dorsal colgado', 'quALD8pisKs', 'YouTube · YST Exercises', 'exacto', 'Hanging Lat Stretch'),
  ('cb3440ac-17a6-46e3-819e-97b64a385183', null, 'Estiramiento de gemelo en pared', 'TyZAmDcD6mM', 'YouTube · Sanitas', 'aproximado', 'Estiramiento de gemelos en la pared'),
  ('70f1ab38-4d4a-4429-afeb-4fd40a9148d1', null, 'Estiramiento de isquiotibiales de pie', '03kF6twGE4o', 'YouTube · gymvirtual', 'revisar', 'Back, glute, and hamstring stretches'),
  ('78ae63d4-d2ed-4998-b13a-87a19a452973', null, 'Estiramiento de isquiotibiales tumbado con banda', 'YE5sHkv3MVA', 'YouTube · 24Life', 'aproximado', '15. Lying Hamstring Stretch With Band'),
  ('6a28d347-5372-45dc-b073-8e51666b9131', null, 'Estiramiento de pectoral en marco de puerta', '2Z3DNkZ6V0k', 'YouTube · ENTRENA con SEBASTIÁN MOLINA', 'revisar', '𝗘𝘀𝘁𝗶𝗿𝗮𝗺𝗶𝗲𝗻𝘁𝗼 𝗣𝗲𝗰𝘁𝗼𝗿𝗮𝗹/𝗠𝗮𝗿𝗰𝗼 𝗣𝘂𝗲𝗿𝘁𝗮'),
  ('12941653-3995-4366-9586-8e1c0d4a8ea5', null, 'Estiramiento de psoas en zancada con elevación de brazo', 'dOFYeEqnUPk', 'YouTube · Argos Performance', 'revisar', 'REVERSE LUNGE WITH ARM RAISE (ZANCADA POSTERIOR CON ELEVACIÓN DE BRAZO)'),
  ('4200bc67-9359-48cd-b187-2c6575e5b031', null, 'Estiramiento de tríceps sobre la cabeza', 'zPDhpDhQufs', 'YouTube · Marcos Sacristán | Fisioterapia a tu alcance', 'revisar', 'Triceps stretch and anatomy'),
  ('077189c8-2057-440b-bc70-afd22a13eabb', null, 'Estiramiento del flexor de cadera de rodillas', '34SlL-PPCWQ', 'YouTube · MGHOrthopaedics', 'exacto', 'Kneeling Hip Flexor Stretch'),
  ('17b475b2-c96f-4ef9-9137-ef6bce89b95f', null, 'Extensión de tríceps con cuerda', 'glsfbbmW2zo', 'YouTube · Edgar Rojas Coach', 'aproximado', 'Extensión de triceps tras nuca con cuerda.'),
  ('1dc5b315-7faf-4e27-aa3d-5d3f87643a47', null, 'Extensión de tríceps con kettlebell', 'qS5q6FgddTI', 'YouTube · Kettlebell Kings', 'revisar', 'Kettlebell Kings Presents: Kettlebell Overhead Tricep Extension - Kettlebells 4 Aesthetics'),
  ('076db2f0-c662-494a-bae3-121e2a96b95a', null, 'Extensión de tríceps en máquina', 'Bx8ga1BLHLE', 'YouTube · Renaissance Periodization', 'exacto', 'Extensión de tríceps en máquina'),
  ('f93427b3-85ca-429d-ab73-f67f50aba88f', null, 'Face pull', '_XKGTRVh72A', 'Theory Library', 'exacto', 'Face Pull'),
  ('38c63378-9008-47e2-982b-9022f35755cd', 'farmer walk', 'Paseo del granjero con mancuernas', 'NH7Xv-7NQNQ', 'YouTube · Buff Dudes Workouts', 'aproximado', 'How To Perform Farmer Walks Exercise Tutorial'),
  ('8104e125-adbd-4b05-9215-517ca239f5c9', 'figure 8', 'Figura ocho con kettlebell', '0wF0WiTiC4U', 'YouTube · Waterdown Village Chiropractic & Wellness Group', 'parecido', 'Figure 8 Exercises'),
  ('10dc89a0-db29-4580-8581-5d9606c20fe9', 'Fire Hydrant Standing', 'Abducción de cadera de pie', '9O7bZy_y9bk', 'Functional Bodybuilding', 'parecido', 'Fire Hydrant'),
  ('409ecce3-e3fd-448a-8c33-550b06ee827d', null, 'Flexión con salto al cajón', 'vUFK2d1eNQw', 'YouTube · Abraham García Benitez', 'revisar', 'FLEXIONES SOBRE CAJÓN'),
  ('3a9bd0af-f4a6-421b-b5b1-34441a2b76ea', null, 'Flexiones inclinadas en Smith', 'me1PLbazNmA', 'YouTube · Fuerza Saludable', 'aproximado', 'PUSH UPS   inclinadas en smith'),
  ('3c1bb3ba-1178-4f31-bdef-f393ffa48d91', 'floor press', 'Press de suelo con mancuernas', 'Pt8PXCnNERY', 'Theory Library', 'parecido', 'Bodyweight Floor Press'),
  ('54180340-ac54-4dba-a467-3d531dcc7724', 'fly inclinado', 'Aperturas inclinadas con mancuernas', 'u1GjCGinCGE', 'YouTube · Leo Personal ', 'exacto', 'Fly inclinado'),
  ('5e8f4716-1fe4-4386-9fee-35a58c588591', 'fly plano', 'Aperturas en banco plano', '71jXbeBP30E', 'YouTube · Fitness Freaks', 'revisar', '1 minute plank timer with  music.'),
  ('e58b10f7-8993-4bb2-b3bb-6dab637480f5', null, 'Fondos de tríceps en Smith', '_bTuG8rmxkg', 'YouTube · DrVíctorLópez', 'revisar', 'SKULL CRUSHERS en Barra Fija o Máquina Smith. RUTINA TRICEPS'),
  ('235b2590-9ee0-48f8-9d5c-2988b976aeb6', 'francés a una mano', 'Extensión de tríceps sobre la cabeza', 'EUm95bHsBds', 'YouTube · XperFit Wellness Club', 'revisar', 'Triceps.- Press francés con mancuerna'),
  ('a15fb2ae-9052-4f04-b9f7-0ee0df7c1556', 'frog jump', 'Salto de rana', 'C54LoE13DUo', 'YouTube · LivestrongWoman', 'exacto', 'Frog Jumps'),
  ('5d8e7352-7b4b-4bbc-b67e-a1f1346817bd', 'front raise', 'Elevaciones frontales', 'gzDawZwDC6Y', 'YouTube · LIVESTRONG', 'aproximado', 'How to Do Front Raises'),
  ('b0e7002c-796c-41d3-850e-e7e83dacbbda', 'front squat', 'Sentadilla frontal con barra', '-iPN3LLg3Yo', 'Functional Bodybuilding', 'exacto', 'Front Squat'),
  ('a07e2c40-01db-4ff5-8cd3-7ec0a4ffb25e', 'front squat KB', 'Sentadilla frontal con kettlebell', 'SlPwjU6I9gk', 'YouTube · John Parker', 'aproximado', 'Single Kettlebell Front Squat'),
  ('f2852ef3-56f6-42dd-80d6-f4eab1823993', 'glute kickback', 'Patada de glúteo en máquina', 'BNDw4ciQoQI', 'YouTube · Nuffield Health', 'revisar', 'Glute Kickbacks | Nuffield Health'),
  ('e86e398a-3304-4848-9384-777e9969bfb4', 'goblet squat', 'Sentadilla goblet', '5ZzkcZbFyJo', 'Functional Bodybuilding', 'exacto', 'Goblet Squat'),
  ('111dbe8f-3466-484c-a2c4-ea0e52ad477b', 'good morning', 'Buenos días', 'mR1UBXNNRB4', 'Functional Bodybuilding', 'exacto', 'Good Morning'),
  ('0c5055aa-479d-4dfb-b7af-2e4df42af681', null, 'Good morning con kettlebell', '0lcPSo2gRoY', 'YouTube · Mountain Tactical Institute', 'aproximado', 'Kettlebell Good Morning'),
  ('55b175be-35cf-4883-834e-6ff020578366', null, 'Hack squat en máquina', 'kqciRGjongc', 'YouTube · JESSICAFITBEAUTY', 'revisar', 'Hack squat alternative'),
  ('d8e11db5-6f47-4a9e-8bac-8309de444f9f', null, 'Halo con kettlebell', 'LEjVh4scVy4', 'YouTube · Kettlebell Emma', 'aproximado', 'Kettlebell Halo Tutorial'),
  ('ec650c0a-9b3a-422d-9016-f7cc72a5d87a', 'hammer curl', 'Curl martillo', 'fM0TQLoesLs', 'Functional Bodybuilding', 'exacto', 'Hammer Curls'),
  ('c6727773-50c8-4d4b-9377-089d5e982871', 'high knees', 'Rodillas al pecho corriendo', 'O1HkauKyzgY', 'Theory Library', 'exacto', 'High Knees'),
  ('ce88edfd-fa6b-46a7-b9fa-f72ab9d2714e', null, 'Hip thrust en Smith', 'qWC5FC6V1ZM', 'YouTube · Puntarenas Online Training', 'exacto', 'HIP THRUST EN SMITH'),
  ('07f42777-4e18-49f8-9d0c-34ed732def1e', 'hiperextensiones', 'Extensión lumbar en banco romano', 'G6HG5VzJoNc', 'YouTube · Alexandra Yaeger', 'revisar', 'Form Tips: How to perform a back extension | Glute Bias 45° Extension Form Tips'),
  ('6c8e30f6-e6f3-4bd4-84ab-10dfda1ceddf', 'hurdle hops', 'Saltos sobre vallas', 'Of0x2u1hPF0', 'Theory Library', 'exacto', 'Hurdle Hops'),
  ('173fd7a3-d592-4e2a-adae-b2d01264df00', 'inchworm', 'Gusano caminando', 'Dh2-Ns8gEvw', 'Functional Bodybuilding', 'exacto', 'Inchworm'),
  ('bd89f146-8979-4734-a10f-fa601758e78f', null, 'Jalón al pecho agarre cerrado', 'vlWhsiHT6B8', 'YouTube · Programa DOCE', 'aproximado', 'Jalón al pecho agarre neutro cerrado'),
  ('5677e7fd-33a3-4b46-b125-6045602c03f6', null, 'Jalón al pecho agarre supino', 'cwN6QVwXTgQ', 'YouTube · Harbiz', 'exacto', 'Jalón al pecho agarre supino (Supine Grip Lat Pulldown)'),
  ('db71bda2-feed-434b-bf75-080c1163289b', null, 'Jalón al pecho en máquina', 'kxmH8MMtW-I', 'YouTube · Michael Romero', 'exacto', 'Jalon al Pecho en Maquina (Agarre Neutro Abierto)'),
  ('b08271f2-e320-40f2-b4a9-b0f8ad3b3973', null, 'Jalón tras nuca', 'HhVai57ez40', 'YouTube · Jessy Fit', 'aproximado', 'Jalón Tras Nuca Acostada'),
  ('64b7c196-2ccd-4753-ba79-700a0699ddf6', 'jump lunge', 'Zancada con salto', '-bItd3j6yjU', 'Functional Bodybuilding', 'exacto', 'Jump Lunges'),
  ('2fab04c3-a424-4a25-a1a9-29d07b98fd7b', 'jumping jacks', 'Saltos de tijera', 'FmnrehDxEB0', 'Functional Bodybuilding', 'exacto', 'Jumping Jacks'),
  ('be3a1ddf-2ea0-4851-9662-df0d0b66d9fc', 'kettlebell clean', 'Cargada con kettlebell', 'Wbo_3yQJFdA', 'Functional Bodybuilding', 'exacto', 'Kettlebell Clean'),
  ('00e529d7-6845-43f8-9b66-2c6fb7e8b5ca', 'kettlebell drag', 'Plancha con arrastre de kettlebell', 'NgxXZL4u6Ro', 'YouTube · Rafal Matuszewski', 'exacto', 'Kettlebell Drags Tutorial'),
  ('45ad8b7a-dd77-446d-b350-63a4c5f322f8', 'kettlebell swing', 'Swing ruso con kettlebell', '50WEYvzautk', 'Theory Library', 'exacto', 'KB Swings'),
  ('1125ba84-112c-43a3-bc81-0561330d9f79', 'kickback', 'Patada de tríceps', 'BNDw4ciQoQI', 'YouTube · Nuffield Health', 'revisar', 'Glute Kickbacks | Nuffield Health'),
  ('446e9cf8-6302-4d3c-9de0-7418ce9b9cc0', null, 'Lanzamiento de balón sobre la cabeza', '7kxNLhi0beI', 'YouTube · Sanitas', 'aproximado', 'Lanzamientos de balón por encima de la cabeza'),
  ('406ac208-dd40-4cff-8d94-b8d43a96600a', null, 'Lanzamiento lateral de balón', 'zukLlUNYSbA', 'YouTube · Fitness Guia', 'revisar', 'ABDOMINALES lanzamiento lateral balon medicinal'),
  ('530a3238-8f10-46c9-b2e4-71c1744ebcec', 'lat pulldown', 'Jalón al pecho en polea', '09XfezGqLis', 'Theory Library', 'exacto', 'Lat Pulldown'),
  ('be9a073d-ae7b-4b31-8609-4f6234b9af0f', 'lateral raise', 'Elevaciones laterales', 'a4lcU0WMiIY', 'YouTube · Muscle & Motion', 'exacto', 'Lateral Raise Exercise'),
  ('73dfd3d0-ace3-43f5-aaaa-feb39f39e1cf', 'leg curl', 'Curl femoral tumbado', 't9sTSr-JYSs', 'YouTube · SilverSneakers', 'revisar', 'Beginner''s Guide: Seated Leg Curl'),
  ('67dda2d8-35af-4e4f-9ea3-00d50e301f91', 'leg extension', 'Extensión de cuádriceps', 'xL6hRhgh3Ps', 'Functional Bodybuilding', 'exacto', 'Leg Extension'),
  ('6c1375bc-1828-48e3-b948-5b1f276de83b', 'leg press', 'Prensa de piernas', 'mHOmubKmFqo', 'Functional Bodybuilding', 'exacto', 'Leg Press'),
  ('dd1ac05b-57c6-4187-8734-a1b7bd4c2b2d', 'leg swings', 'Balanceo de pierna adelante y atrás', 'UZd_j5dJsaI', 'Functional Bodybuilding', 'exacto', 'Leg Swings (flexion/extension)'),
  ('60c9ae73-c7b6-4191-9fd9-535fc7106d22', 'levantada turca', 'Turkish get-up', 'SD4_Lv2Lkvk', 'YouTube · XI FIT app', 'exacto', 'Levantada turca (subida)'),
  ('b54486f4-bc63-426f-8126-540c92e4578c', 'lunge', 'Zancada con mancuernas', 'whwwIax9RRc', 'YouTube · WomansHospitalBR', 'revisar', 'Weekly Workout: Beginner Lunge'),
  ('3b9df6bd-54f9-48be-a640-c9d61d8019ec', null, 'Mariposa sentado', 'LRiaNXfJtUw', 'YouTube · Yanet Yoga', 'revisar', 'Para Practicar la Postura de la Mariposa | Yanet Yoga'),
  ('41193e38-57d8-4d04-b4f1-0ebcc1a882cf', 'monster walk', 'Caminata lateral con banda', 'ty2Kff9x7Hc', 'Functional Bodybuilding', 'exacto', 'Monster Walk'),
  ('795f7c0d-1af4-49d0-85e9-9650fc0496a6', 'mountain climbers', 'Escaladores', 'SfoBQkyrhbs', 'Functional Bodybuilding', 'exacto', 'Mountain Climbers'),
  ('baa05380-de06-471a-9f65-0816998fcb1b', null, 'Movilidad de muñeca en cuadrupedia', 'A_uUzK2svyU', 'YouTube · Jose Ramon Gutierrez Menendez', 'aproximado', 'MOVILIDAD DE MUÑECA'),
  ('9d64bf22-3e2f-4cb7-b080-6c868f9e6c8a', 'open book', 'Apertura de libro', 'MlnTwM_CSyQ', 'YouTube · Rehab My Patient', 'exacto', 'Open Book Exercise'),
  ('4c37e1f9-a117-4e27-9443-61473cba757b', 'overhead press', 'Press militar con barra', 'iZq4yvgnajM', 'YouTube · Kelly Matthews', 'revisar', 'HOW TO STRICT OVERHEAD PRESS | Coach Kelly Cues'),
  ('8adf1b77-2b22-4051-889d-7d0a73a8445c', null, 'Paseo del granjero con kettlebells', '517W14RsO5Y', 'YouTube · Krahe Fitness', 'revisar', 'paseo del granjero / farmer walk con 2 kettlebell'),
  ('87fbe981-8b56-412c-bd02-8871d9d3e6bb', null, 'Patada de glúteo en polea', 'dU1R-AHW4IM', 'YouTube · Kia Khadem', 'exacto', 'How To: Cable Glute Kickback'),
  ('e17f79f3-fbf1-406a-aa9a-74a149aea728', null, 'Peso muerto a una pierna con kettlebell', 'o4gOROOIz4Y', 'YouTube · Lucas Negro', 'aproximado', 'Peso muerto a una pierna con 2 kettlebell'),
  ('af5e3ac4-e42c-47b8-a5d6-e5d9dd14984a', null, 'Peso muerto con kettlebell', 'hinonqqzatk', 'YouTube · Well+Good', 'revisar', 'How To Do a Kettlebell Deadlift | The Right Way | Well+Good'),
  ('5f0c3731-f767-4417-b6af-9e28911dc08e', null, 'Peso muerto en máquina', 'GXSpU4mqlZw', 'YouTube · Sportandfit', 'exacto', 'Peso muerto en máquina'),
  ('78ae9ad2-813d-4700-8104-6ce9cc6ceb39', null, 'Peso muerto rumano con kettlebell', 'fgfN4D9Z52I', 'YouTube · Life Code ', 'exacto', 'Peso muerto rumano con Kettlebell'),
  ('dec6193f-1f48-4641-a183-a714c48919d1', null, 'Peso muerto rumano en Smith', '9pZEdISkS5Q', 'YouTube · Alejo Te Entrena', 'exacto', 'PESO MUERTO RUMANO - EN SMITH'),
  ('f599f895-6c3b-4311-8c27-1cca37f6c755', null, 'Peso muerto sumo con barra', 'jcTzItINY7A', 'YouTube · TITAN GYM', 'aproximado', 'Peso muerto sumo con barra (aductores) /TITÁN GYM/'),
  ('41b69a35-454e-4882-816c-ac751613f589', 'pigeon pose', 'Estiramiento de la paloma', 'HTvUB81fGJU', 'Functional Bodybuilding', 'exacto', 'Pigeon Pose'),
  ('74c4566b-c27f-408e-83ca-fa3ba61aacad', 'plank jack', 'Plancha con salto de pies', 'RatX5Bn_hFI', 'Theory Library', 'exacto', 'Plank Jacks'),
  ('5665e5e8-893b-43cf-8542-c8a6049d7c3b', 'plyo push up', 'Flexión explosiva', 'mGo11MkEfeI', 'Functional Bodybuilding', 'exacto', 'Plyo Push Ups'),
  ('6eea7b27-c81b-4f5c-8aea-bd77943dc62a', 'pogo a una pierna', 'Salto a una pierna en el sitio', 'EE2PSNtShzc', 'YouTube · Coach Ryan Patrick', 'exacto', 'Single leg pogo hops'),
  ('7a9d17b5-71e6-4ba2-8c0c-6525a86c095a', 'pogo jumps', 'Saltos pogo', 'j0nl5dWuqN4', 'YouTube · Runna', 'exacto', 'Pogo Jumps Tutorial - Proper Form and Technique'),
  ('b405b99f-6f89-413a-86d9-79b7958470ad', 'power clean', 'Cargada de potencia', 'pqPst6wmcOg', 'Functional Bodybuilding', 'exacto', 'Power Clean'),
  ('2d57669f-6901-4219-9b80-d46f124cee28', 'power snatch', 'Arrancada de potencia', 'nrkO6IWDoRE', 'Functional Bodybuilding', 'exacto', 'Power Snatch'),
  ('70a6dab4-ac1a-4254-92d5-5842e257fd91', null, 'Press Arnold', 'ZsVxV2dV5YU', 'LiveLean', 'parecido', 'How To: Standing Arnold Press'),
  ('aa905967-91f6-43c2-8616-61063c50df9b', null, 'Press banca con Barra', 'bCqiGmP3k1g', 'YouTube · Proet Ejercicio Terapéutico ', 'aproximado', '169. Press de banca con barra'),
  ('e6ade919-b5e2-4ec8-acc9-2b052c31bdd9', null, 'Press cerrado con mancuernas', 'WV_maawTlh8', 'YouTube · POWER HIIT FITNESS COACHING', 'exacto', 'PRESS CERRADO CON MANCUERNAS'),
  ('4c775af4-e51b-45df-9804-15d417ffda5f', null, 'Press de banca en Smith', '5VCjjKj5EXc', 'YouTube · Dynamik Fitness Center', 'aproximado', 'Press de banca en máquina smith'),
  ('f96ee961-0de6-48e5-a667-df536f4ec6e9', null, 'Press de hombro con kettlebell', 'mhReHlKXoW4', 'YouTube · Harbiz', 'exacto', 'Press de hombro con kettlebell (1 Arm KB Press)'),
  ('54688369-36df-42d7-9349-fb0d5e2122f4', null, 'Press de hombro en máquina', 'IyRu1XMhbIM', 'YouTube · Adrian Muria - La Vieja Escuela', 'exacto', 'PRESS DE HOMBRO EN MÁQUINA'),
  ('6c1c9056-f42d-4d43-850a-3da1d679a6eb', null, 'Press de pecho en polea', 'nmsXTGxgSzs', 'YouTube · Elite Next Level', 'aproximado', 'Press de Pecho a una mano en Polea'),
  ('85cb185d-04fe-442c-8e21-3710012fbfab', null, 'Press de suelo en Smith', '_aVQOIPgYLI', 'YouTube · Marcela Cigala', 'aproximado', 'PRESS DE PECHO EN SMITH'),
  ('87ba7cfc-da50-4f1b-9732-c8e00f97d528', null, 'Press declinado con barra', 'LfyQBUKR8SE', 'YouTube · ScottHermanFitness', 'exacto', 'How To: Barbell Decline Bench Press'),
  ('3ee916af-d76c-43e3-8eba-7e05cd508680', null, 'Press declinado con mancuernas', '2uWdrii0ZG8', 'YouTube · Campestre Aguascalientes Oficial', 'exacto', 'Press declinado con mancuerna'),
  ('427f2420-61bd-480f-9d64-9a3e250ecda9', null, 'Press declinado en Smith', '00lTCTI9ZU4', 'YouTube · Julio Massivo', 'exacto', 'PRESS DECLINADO EN SMITH'),
  ('3f2ed29e-7462-4615-93ac-3eb0d4a8e5b5', 'press hombro de pie', 'Press militar con mancuernas', 'Raemd3qWgJc', 'YouTube · Renaissance Periodization', 'exacto', 'Standing Dumbbell Shoulder Press'),
  ('8aec6573-7cf9-4dad-9d98-61279fc8ab3f', null, 'Press inclinado con barra', 'vUMtItXfO8Y', 'YouTube · Andres Vazquez Personal Trainer', 'revisar', 'INCLINED BENCH PRESS: HOW TO DO IT TO BUILD MUSCLE'),
  ('320a3c14-44e5-4809-a469-f422ca076db1', null, 'Press inclinado en máquina', 'VesHgJR14E8', 'YouTube · Max Euceda', 'revisar', 'Press de pecho inclinado | Guía de ejercicios'),
  ('e456a71a-9f82-46b7-b660-b5f399ddd8f3', null, 'Press inclinado en Smith', 'oe7N2GUzHIw', 'YouTube · MyTraining App', 'revisar', 'Smith Machine Incline Bench Press - Chest Exercise'),
  ('79ec02d8-a0be-4b87-8c44-1996ba8dcc0a', null, 'Press militar en Smith', 'CsDgHoozJEE', 'YouTube · Mr. H', 'aproximado', 'Ejercicio press militar en smith'),
  ('5144b4b8-e1d7-4171-b8f0-ae3432119ca6', 'press plano mancuernas', 'Press de banca con mancuernas', '2DUKO1rdBH4', 'YouTube · Dorian Fit', 'revisar', 'Cómo Hacer PRESS PLANO CON MANCUERNAS - Ejercicios Para Pecho'),
  ('85362dde-c53c-40e3-9810-e1e338ea7cd4', null, 'Puente de glúteo a una pierna', 'S0oUDi076k8', 'YouTube · Victor Pody', 'aproximado', 'Puente de Gluteo 1 pierna'),
  ('a28661ef-17e1-4387-84e4-b33a0225aa8c', null, 'Pull-over en máquina', 'vDHovAm5f9U', 'YouTube · INTENSIVETTT', 'exacto', 'PULL OVER EN MAQUINA.'),
  ('6fb5cb4f-587a-4b5e-aa1d-3ceb866a0e2e', null, 'Pull-over en polea alta', 'mH5ApeK3FAg', 'YouTube · AlFitness', 'aproximado', 'Serratos - Pull Over en polea alta | Guía Fitness'),
  ('2342f21c-de3d-45c0-b1f8-c81f9324800c', null, 'Pull-through en polea', 'YAfPMgKtGoE', 'YouTube · Tu Fisioterapeuta Fit', 'revisar', 'PULL THROUGH CON POLEA - NicoCastFit'),
  ('db629d35-d318-4493-9f85-4e4d2e1c1f73', null, 'Pullover con mancuerna', 'NfCTdUmWYx0', 'YouTube · Fran Osés', 'exacto', 'Pullover con mancuerna (Espalda)'),
  ('a66031fd-0bc0-46e9-9c02-0a86e3c3c2cb', 'puppy pose', 'Estiramiento del gato con brazos extendidos', 'o-H-MB7foaA', 'YouTube · FitLife Fitness, Aquatics and Physical Therapy', 'exacto', 'Puppy Pose'),
  ('fff31802-9c03-445e-b408-1b2b77335537', null, 'Push press con barra', 'gFmV302JErc', 'YouTube · Peak Strength', 'revisar', 'How To Push Press with Good Form'),
  ('826ab87f-366e-42dc-a071-dc513c9473bd', null, 'Push press con kettlebell', 'VyG8A5dQY1k', 'YouTube · FITBENCH', 'aproximado', 'Kettlebell Push Press'),
  ('e5bbfef2-332f-43cd-aeaf-0848caa0c9c2', null, 'Push press con mancuernas', 'RojJEpQEMpw', 'YouTube · Corposano', 'exacto', 'Push Press con mancuernas'),
  ('da4a8934-3fe7-448e-b15b-82a66869debc', 'pushdown', 'Extensión de tríceps en polea', 'LXkCrxn3caQ', 'YouTube · PureGym', 'revisar', 'How To Do A Tricep Pushdown'),
  ('df878e46-2007-4197-9643-5423dd3b6503', 'RDL', 'Peso muerto rumano con barra', '2G6m2hWvMWM', 'Functional Bodybuilding', 'exacto', 'Romanian Deadlift'),
  ('c3d01be2-5324-4c4d-82fb-a50c8a87917e', 'RDL', 'Peso muerto rumano con mancuernas', '2G6m2hWvMWM', 'Functional Bodybuilding', 'exacto', 'Romanian Deadlift'),
  ('7b8e74b7-e869-4977-84d3-d5a2de905395', null, 'Remo alto en polea', '11TdKa1awvQ', 'YouTube · Toro Trainer coach', 'aproximado', 'Remo alto en polea agarre cerrado'),
  ('2db036cf-e78a-440b-836e-c3066a72c973', null, 'Remo alto en Smith', 'RaOexRYGrZw', 'YouTube · MyTraining App', 'revisar', 'Smith Machine Overhead Shoulder Press - Shoulders Exercise'),
  ('88e2ce38-db77-41d1-9b00-de131948665f', null, 'Remo con barra agarre supino', 'gN8oiFu7vp4', 'YouTube · Olympia Training Channel (by Alessandro Tata)', 'exacto', 'Remo con barra agarre supino'),
  ('f9976852-2c08-4c32-b7ee-2c5996198851', null, 'Remo con barra en Smith', 'zNGwcrK8YnE', 'YouTube · Allison Ethier', 'aproximado', 'HOW TO PERFORM BENTOVER BARBELL ROWS | SMITH MACHINE'),
  ('51008393-1804-4b49-a850-a3dd379b8c77', null, 'Remo con kettlebell a una mano', 'l40Y_OWgpn8', 'YouTube · Athlo APP ', 'exacto', 'Remo a Una Mano con Kettlebell'),
  ('fdcb679d-dec4-4a2c-b692-7df2c874a31f', null, 'Remo con mancuernas a dos manos', 'A1wX8qxm0Pk', 'YouTube · FitWorld México', 'exacto', 'Remo con mancuerna a dos manos'),
  ('412bbbfb-673d-4de7-a12c-af064755e607', null, 'Remo en máquina apoyado al pecho', 'unE_jYJVgCk', 'YouTube · GET STRONG by José Ángel Sobrino', 'revisar', 'Remo máquina agarre prono con pecho apoyado'),
  ('71a25686-a533-4f2f-8c91-4a3ddaddd67a', null, 'Remo en polea a una mano', 'PiFndNAggDs', 'YouTube · Juan Rallo', 'aproximado', 'REMO A UNA MANO EN POLEA BAJA'),
  ('6d7f0f7f-356f-4b65-82d3-b2ec07c3fef4', null, 'Remo renegado con kettlebell', 'cdv7Tsa_a9I', 'YouTube · Athlo APP ', 'exacto', 'Remo Renegado con Kettlebells'),
  ('eed07a55-3d71-4a1f-8e7a-ffdafe15438e', null, 'Remo sentado en máquina', 'VWyhefUKTp4', 'YouTube · EresFitness', 'aproximado', 'Remo sentado en máquina: Tutorial en 1 minuto'),
  ('f47bd16f-61b7-47b3-b8b7-934fb0b94fa3', null, 'Remo sentado en polea baja', 'QLzPrh_8I2U', 'YouTube · Michael Romero', 'aproximado', 'Remo Sentado en Polea Baja con Barra (agarre Prono y Abierto)'),
  ('66f31dd8-8887-487a-8bee-c672b25c101d', 'remo serrucho', 'Remo con mancuerna a una mano', 'DjuvwzzBrJc', 'YouTube · Mr. Fitness. Coach', 'revisar', 'Remo serrucho con mancuerna'),
  ('266362b6-5b57-407f-a5f8-94f536c1b8ff', 'renegade row', 'Remo renegado', 'alqzqjfK9AQ', 'Functional Bodybuilding', 'exacto', 'Renegade Row'),
  ('c0b1df48-7dc3-4c2a-a95f-80832ff1a425', 'reverse lunge', 'Zancada inversa con mancuernas', 'szbcowvzghA', 'Functional Bodybuilding', 'exacto', 'Reverse Lunge'),
  ('1593d07a-55fa-459e-92b2-3000cee4afc7', 'reverse peck deck', 'Deltoide posterior en máquina', '3RLqAh8-9Pg', 'YouTube · James Harrison', 'exacto', 'Reverse Pec Deck - Exercise Tutorial'),
  ('7329aada-1e9a-492b-8920-a4f9c8c3d8fc', 'rock back', 'Deslizamiento de cadera en cuadrupedia', 'ZoRbrNbb2Bk', 'YouTube · Chicago Chiropractic & Sports Medicine', 'exacto', 'Quadruped Rock Backs'),
  ('5d03cee6-daac-4594-a821-8618a25f580d', null, 'Rodilla al pecho caminando', 'pvlpCSwsvBM', 'YouTube · Dr. Michael Maxwell', 'exacto', 'Walking Knee to Chest'),
  ('f03e787c-4699-49b6-a75b-e3581169c940', null, 'Rotación de columna tumbado', 'uxAXs2Vyc7k', 'YouTube · Sanitas', 'revisar', 'Estiramiento en rotación lumbar'),
  ('02085855-ea05-4613-b517-dc67174dbb65', null, 'Rotación de torso en máquina', 'qcxkFjQfA7Y', 'YouTube · Olimpo Gym La Paz', 'exacto', 'Rotacion de torso en Máquina'),
  ('7643d743-868c-4cf0-8fc7-a6998e6b3e57', null, 'Rotación externa de hombro con banda', '5xZkaSZlp8E', 'YouTube · Proet Ejercicio Terapéutico ', 'aproximado', '755. Rotación externa de hombros con banda elástica'),
  ('db872dc4-1e9a-4ee1-9922-8ad2b929780b', null, 'Rotación torácica sentado sobre talones', 'XAIvHO78HXg', 'YouTube · Reactívate Bilbao', 'revisar', 'Sentado sobre talones - rotacion de columna brazo estirado'),
  ('3fb02411-12cf-4970-a813-4df44eb2c224', 'russian twist', 'Giro ruso con mancuerna', 'vsEk9-OrROs', 'Functional Bodybuilding', 'exacto', 'Russian Twist'),
  ('c91e5db1-a8db-40b1-9f34-d2b088e98cdc', null, 'Salto al cajón a una pierna', 'W6bm5yaWuTM', 'YouTube · FATE', 'aproximado', 'Saltos al cajón a 1 pierna'),
  ('0b99a0ed-3efe-4a94-90ad-5f4b89c377c2', null, 'Salto al cajón con contramovimiento', 'SQy8Xyh5fA8', 'YouTube · Dani Blanco Lift4run', 'aproximado', 'SALTO CONTRAMOVIMIENTO a Cajón'),
  ('a8bd9097-85b5-4076-b31a-e8c8b9a56091', null, 'Salto con banda de resistencia', 'iywQRWs7zmU', 'YouTube · Entrenador Personal - Malagaentrena', 'revisar', '🔴 Los 10 mejores EJERCICIOS FUNCIONALES - BANDAS ELÁSTICAS'),
  ('76f4b502-2e59-4d32-85ac-8a4484554e19', null, 'Salto con giro de 180', 'G-WB5et-D_s', 'YouTube · Coach Marlon', 'aproximado', 'Salto Hacía Atrás con giro de 180°'),
  ('acba3767-b7b4-4992-8a75-dc97e3da9e45', null, 'Salto vertical', 'QRN1Yzo0hjU', 'YouTube · The Lost Breed', 'revisar', '3 Exercises To INCREASE YOUR VERTICAL Pt.2 | JUMP HIGHER | The Lost Breed'),
  ('ecb3e572-3ddc-4fa6-8e3b-62223436f64b', null, 'Saltos con cuerda', 'QNqJXxUb_0Y', 'YouTube · Jump and Roll', 'revisar', 'SALTAR CUERDA con MUSICA  en 3 MINUTOS 🔥 CARDIO CON CUERDA-  [ ♪♪ BLINDING LIGHTS ♪♪]'),
  ('41a70c69-619e-4998-8bee-a0810971c4ca', null, 'Saltos en escalera de agilidad', '6Rku0OK6Zpk', 'YouTube · Gabriela Gamarra Fit Life', 'revisar', '13 ejercicios de coordinación en escalera'),
  ('9ed2da74-4643-4e28-8db3-4c44aadf1576', null, 'Saltos laterales al cajón', 'Q254a0Z5-_M', 'YouTube · FATE', 'exacto', 'Saltos laterales al cajón.'),
  ('fd7b02b5-b713-4db5-b1fc-5312622c2b77', null, 'Saltos laterales sobre línea', '5z_SGopNdco', 'YouTube · The Strength Code ', 'exacto', 'Lateral Line Hops'),
  ('7b19cb30-7388-4fba-a3e3-3e1ae5af7026', 'Seated Single Arm Chest Press', 'Seated Single Arm Chest Press', 'jSuDZxWtDrI', 'YouTube · Bilt Wellness', 'revisar', 'Metropolitan: Chest Press Machine (One arm)'),
  ('e6c4bc09-8b1c-4e28-8bc2-776ee78c22c3', null, 'Sentadilla búlgara con barra', '3DOfzaoavn8', 'YouTube · Abdias Sadrac', 'exacto', 'sentadilla búlgara con barra'),
  ('b966cf31-b68a-4f18-a715-6545ad2e0931', null, 'Sentadilla búlgara con kettlebell', '5hCO80C_7_M', 'YouTube · Gerardo Quintana', 'exacto', 'Sentadilla búlgara con KB'),
  ('e68799a3-859f-42f1-b7b2-9bb21bfe31e4', null, 'Sentadilla búlgara en Smith', 'iaUR1wQL87c', 'YouTube · Mabelgofit', 'exacto', 'Sentadilla búlgara en Smith'),
  ('cbba1cd5-8cd9-4872-9298-94c54859d1ef', null, 'Sentadilla con mancuernas', 'tV3GIr2aLW4', 'YouTube · Real Federación Española de Balonmano', 'aproximado', '3 SENTADILLA CON MANCUERNAS'),
  ('6800fe44-f6ca-43e1-94ba-497632ca2bc4', null, 'Sentadilla con salto y bajada al cajón', '71T6qW8mnsw', 'YouTube · Garita Nutrition', 'revisar', 'Sentadilla con salto de cajón / GN'),
  ('a931009d-33aa-43d6-8bf5-e0556f5b0f20', null, 'Sentadilla con salto y balón', 'ux7Ye6uoKs4', 'YouTube · Enzo Parmisano Entrenador', 'revisar', 'Sentadilla con pelota medicinal'),
  ('2f5a882d-0305-46df-8170-f3901aa1594f', null, 'Sentadilla en polea', 'geoV48LB6dg', 'YouTube · Avid Fitness', 'exacto', 'Cable Squats'),
  ('52efe5ff-7245-47fc-bf26-d13250664015', null, 'Sentadilla en Smith', 'AHnX-aimA4E', 'YouTube · ScottHermanFitness', 'exacto', 'How To: Smith Machine- Squat'),
  ('ea8a45bb-b503-4b0f-84ad-975ca5dfdeb0', null, 'Sentadilla frontal en Smith', 'KqL9pPaPTgk', 'YouTube · ABRAHAM RODRIGUEZ', 'exacto', 'SENTADILLA FRONTAL EN SMITH'),
  ('b6e5b86e-6f60-452e-bdc3-4c97fe4bee83', null, 'Sentadilla goblet con kettlebell', 'bkuQd3HEOcU', 'YouTube · Centro Equilibrium', 'exacto', 'Sentadilla goblet con Kettlebell'),
  ('64a63a46-99be-4437-946e-2e08b01d3b92', null, 'Sentadilla overhead con kettlebell', 'Kti2IUdEk7k', 'YouTube · Joe Daniels Kettlebell Muscle Gain ', 'revisar', 'Lets Build Your Overhead Kettlebell Squat !'),
  ('3a488ba3-c8ac-41a9-bbac-c9992264f265', null, 'Sentadilla sumo con barra', 'YV-7X9e0OgA', 'YouTube · Campestre Aguascalientes Oficial', 'aproximado', 'Sentadilla sumo con barra olímpica'),
  ('7c69e002-e4df-46ef-b95f-ece835202d31', null, 'Sentadilla sumo con mancuerna', 'Bd2qYJLfOQQ', 'YouTube · Ruben Andres Blanco Valbuena', 'aproximado', 'Sentadilla Sumo con Mancuerna con Step( superficie alta cajones o discos)'),
  ('05867062-3f00-44b3-a7a2-1ef8d0a44278', null, 'Sentadilla sumo en Smith', 'pPnEglxTDVw', 'YouTube · EmilioFabila Fitness', 'exacto', 'SENTADILLA SUMO EN SMITH'),
  ('2c7a208a-38f0-412f-9de9-4dcdd3a6936f', 'shrugs', 'Encogimientos de hombros con mancuernas', 'sZQQK2eqNpE', 'YouTube · Husky Orthopaedics', 'revisar', 'Shoulder Shrug Exercise'),
  ('e1ae4787-b3fd-4df7-bcee-bed7a62df858', 'shrugs', 'Encogimientos con barra', 'sZQQK2eqNpE', 'YouTube · Husky Orthopaedics', 'revisar', 'Shoulder Shrug Exercise'),
  ('17a8c2b7-9f44-41c8-af9c-c5807d71583e', 'shuffle', 'Desplazamiento lateral defensivo', 'iBmvPEWt5og', 'YouTube · MedStar Health', 'revisar', 'Agility Exercise for ACL: Lateral Shuffle'),
  ('59cb8b5e-9516-42ad-b1dc-5fbe6357e458', 'single leg RDL', 'Peso muerto a una pierna con mancuerna', 'uAaWkZd-bG0', 'LiveLean', 'exacto', 'How To: Single Leg Romanian Deadlift'),
  ('f95e9313-14a6-481e-986b-38817e6969a0', 'skater jump', 'Patinador', 'CaN4zfIPyXU', 'Functional Bodybuilding', 'exacto', 'Skater Jumps'),
  ('03b387d8-5832-4e6b-8e19-bdee0589f96c', null, 'Skipping', 'TpzB4fDkuZ0', 'YouTube · St. Augustine High School Athletics', 'revisar', 'Plyo Skips'),
  ('bed179db-bb81-4777-9de9-1ae253178962', 'skull crusher', 'Press francés con barra', 'd_KZxkY_0cM', 'YouTube · ScottHermanFitness', 'exacto', 'How To: Skull Crushers'),
  ('1408c99f-8e0e-4c4a-92b5-fcbff0efcab4', 'skull crusher', 'Press francés con mancuernas', 'd_KZxkY_0cM', 'YouTube · ScottHermanFitness', 'exacto', 'How To: Skull Crushers'),
  ('43a21b13-dbba-4447-b0e4-fa866928e667', 'slam ball', 'Lanzamiento de balón al suelo', 'iW8G3rDF1kE', 'Functional Bodybuilding', 'exacto', 'Slam Ball'),
  ('6718972e-388b-4d11-8fbf-98b51e14af16', 'sled push', 'Empuje de trineo', 'qddxdN-z-Bk', 'Functional Bodybuilding', 'exacto', 'Sled Push'),
  ('3dcea8d4-8784-41c6-9b2f-0ec0fa5b6c12', 'soldier walk, toy soldier', 'Soldadito', 'uSay0qdfFbQ', 'YouTube · Anthony Tomeo', 'exacto', 'Toy Soldier Walk'),
  ('5bedb966-c87b-46d7-bf87-f9f60455acfa', 'Spiderman Push Up', 'Flexión spiderman', 'yZm539PV_cU', 'Theory Library', 'exacto', 'Spiderman Push-Up'),
  ('b88dcf9a-6fe6-4146-b6fb-9099aa98362c', 'split jump', 'Zancada con salto alternada', 'nccJ_jrhDNQ', 'Functional Bodybuilding', 'exacto', 'Split Jumps'),
  ('d599e135-f994-40f5-9fa4-ef3531a49748', null, 'Sprint corto', 'DIQ6JMsyEAs', 'YouTube · Julio Massivo', 'exacto', 'Sprints Cortos'),
  ('72c36e54-2a78-4048-b9b1-326cfba3901c', 'squat jump', 'Salto en sentadilla', '-95X7sYHNDI', 'Functional Bodybuilding', 'exacto', 'Jump Squat'),
  ('9637fd57-c2ce-4c7a-886b-90543ed69464', 'star jump', 'Salto estrella', '4O-LejzLmDs', 'YouTube · Runna', 'parecido', 'Full Star Jumps Tutorial - Proper Form and Technique'),
  ('c7afa6ee-469e-4373-8190-763a9f5badfe', null, 'Step-up en Smith', 'qYFlvmFu2wE', 'YouTube · Steam Training Fitness', 'exacto', 'Smith Machine Step Up'),
  ('e5adfcae-d8f9-4563-ac3f-16820614c8e4', null, 'Step-up explosivo al cajón', 'lELNPUbejo0', 'YouTube · STAT Wellness', 'exacto', 'EXPLOSIVE BOX STEP UPS'),
  ('7aa8fb0a-d925-468c-b22c-7e8e8f2df384', 'subida al cajón', 'Step-up al cajón con mancuernas', 'hsqotlvBdcQ', 'YouTube · Harbiz', 'aproximado', 'Subida al cajón goblet (Step up Goblet)'),
  ('e0de6190-d46e-4222-af19-8c280bed49a8', 'suitcase carry', 'Paseo del maletero', 'd4dd9nXcWDU', 'Theory Library', 'exacto', 'Suitcase Carry'),
  ('d14e7fc7-e4ac-4f7f-85a4-19bea01193c6', 'Superband Pull Apart', 'Apertura con superbanda', '-I4FsmMUKeU', 'Functional Bodybuilding', 'exacto', 'Band Pull Apart'),
  ('f3559969-6217-406a-be2c-4ba5126729f3', null, 'Swing a una mano', 'ijPktvM7ouY', 'YouTube · Jeronimo Milo', 'aproximado', 'How to do One-arm Kettlebell Swing. 🟥 Kettlebell Swing 🟥.'),
  ('4dc20eee-168b-4197-b96c-4b0722a2b8ef', null, 'Swing americano con kettlebell', 'd94xX-AQZ0A', 'YouTube · Onnit', 'revisar', 'The American Kettlebell Swing | Exercise Tutorial'),
  ('9544dfe1-18d4-422e-b475-ed09d7dc636e', null, 'Swing con mancuerna', 'JuDNmXKkbAk', 'YouTube · Juan Rallo', 'exacto', 'SWING CON MANCUERNAS'),
  ('74e41972-56f5-409c-a7c8-bf21354e88ab', 'T-bar row', 'Remo en T', '-4DgImN_G7o', 'Functional Bodybuilding', 'exacto', 'T Bar Row'),
  ('17bfd077-69d5-4949-a4e0-0ea90e043359', null, 'Talón al glúteo caminando', 'qQA2ZDBY7Os', 'YouTube · SIKANA Español', 'revisar', 'Ejercicio de equilibrio: talón-glúteo | Gimnasia para personas mayores'),
  ('f7b3360e-e81d-450e-a321-0e6c37e149a9', 'thread the needle', 'Rotación torácica cuadrupedia', 'NSAnVkmaRH4', 'Functional Bodybuilding', 'exacto', 'Thread the Needle'),
  ('318f5e56-29c6-419c-96c7-8138fd56fe9d', null, 'Thruster con barra', 'L219ltL15zk', 'YouTube · CrossFit', 'revisar', 'The Thruster'),
  ('96ae51fc-4a3c-4273-abf3-b9409027c20e', null, 'Thruster con mancuernas', 'Lk1F7UV7aw8', 'YouTube · Carlos Rodríguez Parejo', 'exacto', 'Thruster con mancuernas'),
  ('ba4383ac-f88c-4f42-99a7-6f40467f75a8', 'tuck jump', 'Salto en tuck', 'jgPfJjRf9Ck', 'Functional Bodybuilding', 'exacto', 'Tuck Jump'),
  ('b2729534-921b-460a-9858-5b2bf0760d1b', 'upright row', 'Remo alto con mancuernas', 'pT4njrC59fk', 'YouTube · Muscle & Motion', 'revisar', 'Upright Row - Good or Bad?'),
  ('28c7839e-3eaa-4087-825c-85305138f00a', 'upright row', 'Remo alto con barra', 'pT4njrC59fk', 'YouTube · Muscle & Motion', 'revisar', 'Upright Row - Good or Bad?'),
  ('ec2d5485-7bb7-433f-af8b-d8407898459f', 'waiter walk, overhead carry', 'Paseo del camarero', 'rcQwcv831wc', 'YouTube · CrossFit Linchpin', 'aproximado', 'Overhead Carry and Waiter''s Walk.'),
  ('5c9b9b77-2298-448a-ac0b-c692918bed37', 'walking lunge', 'Zancada caminando con mancuernas', 'adn4iQE7psM', 'Functional Bodybuilding', 'exacto', 'Walking Lunges'),
  ('e379ae96-1ba1-4027-8bc0-e63ae9e22e04', 'wall ball', 'Lanzamiento de balón a la pared', 'xMO8WZrZk-U', 'Functional Bodybuilding', 'exacto', 'Wall Balls'),
  ('bde1ed18-9493-4fd8-ba7d-da5d1ffa4a87', 'wall slides', 'Deslizamiento en pared', 'GLty-L_JxXk', 'YouTube · Baptist Health', 'exacto', 'Wall Slides'),
  ('0afd0f2e-6644-4d5d-8e3d-1e937e07e984', 'woodchopper', 'Leñador en polea', 'FA3S8CrSOTw', 'YouTube · 3v', 'revisar', '2. Wood Choppers - Core Workout - Fully Fit by Runner''s World'),
  ('8e84c078-eabc-4094-a4ff-9914ebb77988', 'world''s greatest stretch', 'Zancada con rotación torácica', '9NAGIQFLgb0', 'YouTube · Coury & Buehler Physical Therapy', 'exacto', 'World''s Greatest Stretch'),
  ('5677c81b-d4fd-4590-8fa0-6cb322482fbd', null, 'Zancada con barra', 'VQ1aMlRMrjE', 'YouTube · Ale Asesorías Fit', 'exacto', 'Zancadas con barra'),
  ('d61e63e8-6a62-414b-bad6-1bc0834cb22c', null, 'Zancada con kettlebell', 'KyIvjiS_PjQ', 'YouTube · SportForever Xativa', 'exacto', 'ZANCADA CON KETTLEBELL'),
  ('6b34a52f-379a-46f4-a694-9a0e1ee60e18', null, 'Zancada en Smith', 'eRSXZu-3YcQ', 'YouTube · Angel Velasco Coach', 'aproximado', 'Zancada en maquina Smith'),
  ('04d8e658-fe09-4c9e-a0fe-92be2aabe02a', null, 'Zancada lateral', 'c9ntDZvxQKM', 'YouTube · Michael Romero', 'exacto', 'Zancada Lateral'),
  ('3f53c206-38e8-4e44-b52d-244332510a9e', 'zercher squat', 'Sentadilla Zercher', '5jquNyvF43Y', 'Functional Bodybuilding', 'exacto', 'Zercher Squat');

-- 1. Los que usan hoy tus clientes (misma regla que «👥 1 · Los usan ahora»).
create temp table _hoy on commit drop as
with hoy as (select (now() at time zone 'America/Bogota')::date as d),
activos as (
  select id from clientes where lower(coalesce(estado, 'activo')) = 'activo'
),
fs as (
  select f.* from fases f join activos a on a.id = f.cliente_id
   where coalesce(f.estado, '') <> 'archivada'
),
vigentes as (
  select fs.id, fs.cliente_id from fs, hoy
   where fs.estado = 'activa' or fs.visible_cliente is true
      or (fs.fecha_inicio is not null and fs.fecha_inicio <= hoy.d
          and fs.fecha_inicio + (coalesce(fs.semanas, 4) * 7 - 1) >= hoy.d)
),
ultima as (
  select distinct on (fs.cliente_id) fs.id, fs.cliente_id from fs
   where fs.cliente_id not in (select cliente_id from vigentes)
   order by fs.cliente_id, fs.fecha_inicio desc nulls last, fs.orden desc nulls last, fs.created_at desc nulls last
),
fases_hoy as (select id from vigentes union select id from ultima)
select distinct re.ejercicio_id
  from rutina_ejercicios re
  join rutinas r on r.id = re.rutina_id
 where r.fase_id in (select id from fases_hoy)
   and coalesce(r.archivada, false) = false;

-- 2. Qué cambia: por ID, sin los que usan hoy, sin los elegidos a mano, y
--    solo si el video es distinto del que tiene.
create temp table _cambio on commit drop as
select e.id, v.ref, v.canal, v.coincide, v.titulo
  from _v v
  join ejercicios e on e.id = v.id
 where e.id not in (select ejercicio_id from _hoy where ejercicio_id is not null)
   and e.video_elegido_at is null
   and (coalesce(e.video_fuente, 'ninguno') <> 'youtube' or e.video_ref is distinct from v.ref);

-- Foto de cómo están HOY los videos de los que usan tus clientes, para
-- comprobar al final que ninguno cambió.
create temp table _hoy_foto on commit drop as
select id, video_fuente, video_ref, video_url, video_inicio_seg, video_path, poster_path, poster_url
  from ejercicios where id in (select ejercicio_id from _hoy);

-- Cuántos ya tenían ese mismo video (se cuenta antes de cambiar nada).
create temp table _iguales on commit drop as
select count(*) as n from _v v join ejercicios e on e.id = v.id
 where e.video_fuente = 'youtube' and e.video_ref = v.ref;

-- 3. Respaldo del video que tenían.
insert into ejercicios_video_respaldo
  (ejercicio_id, video_fuente, video_ref, video_url, video_inicio_seg, video_path, poster_path, poster_url, video_elegido_at, motivo, puesto_ref)
select e.id, e.video_fuente, e.video_ref, e.video_url, e.video_inicio_seg, e.video_path, e.poster_path, e.poster_url, e.video_elegido_at, 'en-analisis-2026-10-16', c.ref
  from ejercicios e join _cambio c on c.id = e.id;

-- 4. El video nuevo, con la miniatura del cuadro del medio.
update ejercicios e
   set video_fuente     = 'youtube',
       video_ref        = c.ref,
       video_url        = 'https://www.youtube.com/watch?v=' || c.ref,
       video_inicio_seg = null,
       video_path       = null,
       poster_path      = null,
       poster_url       = 'https://i.ytimg.com/vi/' || c.ref || '/mq2.jpg',
       updated_at       = now()
  from _cambio c
 where e.id = c.id;

-- 5. Comprobación final: si UNO SOLO de los que usan hoy tus clientes quedó
--    distinto, se cancela TODO y no se guarda ningún cambio.
do $$
declare n integer;
begin
  select count(*) into n
    from _hoy_foto f join ejercicios e on e.id = f.id
   where (e.video_fuente, e.video_ref, e.video_url, e.video_inicio_seg, e.video_path, e.poster_path, e.poster_url)
         is distinct from
         (f.video_fuente, f.video_ref, f.video_url, f.video_inicio_seg, f.video_path, f.poster_path, f.poster_url);
  if n > 0 then
    raise exception 'Cancelado: % ejercicio(s) que usan hoy tus clientes iban a cambiar. No se guardó nada.', n;
  end if;
end $$;

-- Resumen: cuántos cambiaron por canal, y cuántos se saltaron y por qué.
select 'Cambiados' as que, split_part(c.canal, ' · ', 1) as detalle, count(*) as ejercicios from _cambio c group by 2
union all
select 'Saltados: los usan hoy tus clientes', null, count(*) from _v v where v.id in (select ejercicio_id from _hoy)
union all
select 'Saltados: elegidos a mano en el CRM', null, count(*) from _v v join ejercicios e on e.id = v.id
 where e.video_elegido_at is not null and e.id not in (select ejercicio_id from _hoy where ejercicio_id is not null)
union all
select 'Saltados: ya tenían ese video', null, n from _iguales
order by 1, 3 desc;

commit;

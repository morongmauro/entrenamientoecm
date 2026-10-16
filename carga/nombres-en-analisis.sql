-- ════════════════════════════════════════════════════════════════════════
-- NOMBRES Y DUPLICADOS · solo los ejercicios «🔬 En análisis»
-- ════════════════════════════════════════════════════════════════════════
-- Dónde: Supabase del CRM → SQL Editor → pegar todo → Run.
-- Se puede correr dos veces: la segunda no cambia nada.
--
-- Los que usan hoy tus clientes NO SE TOCAN (se calcula al correrlo).
--
-- 1. NOMBRES (115). La regla de siempre: alias = el nombre en inglés de
--    Trainerize (se ve grande), nombre = el español (debajo). Ningún nombre
--    es inventado: cada uno sale del export de Trainerize de tus clientes o
--    de la librería de Trainerize (galeria-ejercicios.sql).
--      ·  58 que solo tenían español: se les pone el inglés de Trainerize.
--      ·  43 con un apodo en el campo de inglés («RDL», «arrancada KB»…):
--            se cambia por el de Trainerize; el apodo queda en las palabras
--            de búsqueda, así el buscador lo sigue encontrando.
--      ·  14 con el inglés repetido en el campo de español: se pone el español.
--    120 no aparecen en ningún dato de Trainerize: no se tocan. Están en
--    carga/NOMBRES-EN-ANALISIS.md.
--
-- 2. DUPLICADOS (40). Fichas en análisis que son el mismo ejercicio que
--    otra (casi siempre una que tus clientes usan hoy). No se archiva ni se
--    borra nada: quedan marcadas y en el CRM salen en la categoría
--    «🔁 Duplicados», con dos botones: «Archivar este» o «No es duplicado».
--
-- No borra nada; no toca videos, rutinas, clientes ni registros. Antes de
-- cambiar un nombre guarda el que tenía. Para volver atrás:
-- carga/nombres-en-analisis-deshacer.sql
-- ════════════════════════════════════════════════════════════════════════
begin;

alter table ejercicios add column if not exists busqueda text;
alter table ejercicios add column if not exists duplicado_de uuid;

create table if not exists ejercicios_nombre_respaldo (
  id            bigserial primary key,
  ejercicio_id  uuid not null,
  alias         text,
  nombre        text,
  busqueda      text,
  duplicado_de  uuid,
  motivo        text,
  puesto_alias  text,
  puesto_nombre text,
  guardado_at   timestamptz not null default now()
);

create or replace function pg_temp.ecm_norm(t text) returns text language sql immutable as $fn$
  select btrim(regexp_replace(
           lower(translate(coalesce(t,''),
                 'áàäâãéèëêíìïîóòöôõúùüûñçÁÀÄÂÃÉÈËÊÍÌÏÎÓÒÖÔÕÚÙÜÛÑÇ',
                 'aaaaaeeeeiiiiooooouuuuncAAAAAEEEEIIIIOOOOOUUUUNC')),
           '[^a-z0-9]+', ' ', 'g'));
$fn$;

create temp table _hoy on commit drop as
with hoy as (select (now() at time zone 'America/Bogota')::date as d),
activos as (select id from clientes where lower(coalesce(estado, 'activo')) = 'activo'),
fs as (select f.* from fases f join activos a on a.id = f.cliente_id where coalesce(f.estado, '') <> 'archivada'),
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
  from rutina_ejercicios re join rutinas r on r.id = re.rutina_id
 where r.fase_id in (select id from fases_hoy) and coalesce(r.archivada, false) = false;

-- ── 1. Nombres ──
create temp table _n (id uuid, caso text, alias_antes text, nombre_antes text, alias_nuevo text, nombre_nuevo text) on commit drop;
insert into _n values
  ('72c371b9-3c79-47da-a635-0ae29310b4a0', 'A', null, 'Abducción de cadera en polea', 'Cable Hip Abduction', 'Abducción de cadera en polea'),
  ('3fdf32ff-0f5c-4b71-9d43-8d25dd40892a', 'A', null, 'Abductores en máquina', 'Machine Seated Abduction', 'Abductores en máquina'),
  ('dd368beb-318f-4609-8087-50a7e29e3e64', 'C', 'arrancada KB', 'Snatch con kettlebell', 'Kettlebell Snatch', 'Snatch con kettlebell'),
  ('1f207198-4d3c-4b15-be02-6357217e513f', 'C', 'back squat', 'Sentadilla trasera con barra', 'Barbell Back Squat', 'Sentadilla trasera con barra'),
  ('733557b2-4a02-4988-8c1a-d61f00d061b1', 'A', null, 'Balanceo de pierna lateral', 'Lateral Leg Swing', 'Balanceo de pierna lateral'),
  ('9329265b-87ef-4260-9ab6-05afbd6711e8', 'B', 'Band Anchored High-Low Woodchop', 'Band Anchored High-Low Woodchop', 'Band Anchored High-Low Woodchop', 'Leñador de alto a bajo con banda anclada'),
  ('a9da1c17-4004-47a0-b896-6c81ba8769d3', 'B', 'Barbell Romanian Deadlift', 'Barbell Romanian Deadlift', 'Barbell Romanian Deadlift', 'Peso muerto rumano con barra'),
  ('93892ff0-719f-4b9a-ac6c-d966d6215831', 'C', 'barbell row, remo pendlay', 'Remo con barra', 'Barbell Bent Over Row', 'Remo con barra'),
  ('326cb0c5-6401-4349-911b-2fff186c1cc7', 'B', 'Bench Knee Tuck to V Up', 'Bench Knee Tuck to V Up', 'Bench Knee Tuck to V Up', 'Rodillas al pecho a V-up en banco'),
  ('046472f0-c61d-4400-af23-6dcd5f367d7f', 'C', 'bench press', 'Press de banca con barra', 'Barbell Bench Press', 'Press de banca con barra'),
  ('c1e15169-6b44-4ef9-a82c-1204094cc952', 'B', 'Bodyweight Single Leg Calf Raise', 'Bodyweight Single Leg Calf Raise', 'Bodyweight Single Leg Calf Raise', 'Elevación de talón a una pierna sin peso'),
  ('3cb56ff9-2c50-46d5-91c3-7e36d87cdb90', 'C', 'cable crossover', 'Cruces en polea alta', 'Cable Upper Crossover', 'Cruces en polea alta'),
  ('b4c64f2e-964c-4a38-93b8-0365003d632d', 'B', 'Cable Reverse Grip Tricep Pulldown', 'Cable Reverse Grip Tricep Pulldown', 'Cable Reverse Grip Tricep Pulldown', 'Extensión de tríceps en polea agarre supino'),
  ('2739296f-57f2-4328-b68f-c18f5f2eb0c0', 'B', 'Cable V-Bar Overhead Tricep Extension', 'Cable V-Bar Overhead Tricep Extension', 'Cable V-Bar Overhead Tricep Extension', 'Extensión de tríceps sobre la cabeza en polea con barra V'),
  ('edf3113d-b4f0-4568-99f0-7fc79e86707f', 'C', 'cat cow', 'Gato-camello', 'Cat to Cow', 'Gato-camello'),
  ('1620e4fc-4f27-438b-be4c-548bbde725cd', 'C', 'chest supported row', 'Remo en banco inclinado con mancuernas', 'Dumbbell Incline Bench Row', 'Remo en banco inclinado con mancuernas'),
  ('45d1cdfb-dd5a-42d8-9985-c71c5720226a', 'C', 'clamshell', 'Almeja con banda', 'Mini Band Clamshell', 'Almeja con banda'),
  ('272a1ebe-19dd-4369-8a3e-22e38a0f5349', 'A', null, 'Clean and press con kettlebell', 'Kettlebell Clean and Press', 'Clean and press con kettlebell'),
  ('b212f73d-dc7c-4305-b48f-09685b81cc5e', 'C', 'close grip', 'Press de banca agarre cerrado', 'Barbell Close Grip Bench Press', 'Press de banca agarre cerrado'),
  ('be8c7bfb-6091-4535-ba81-4b44870df6de', 'C', 'crunch arrodillado', 'Crunch en polea', 'Cable Kneeling Crunch', 'Crunch en polea'),
  ('aef5d351-f6b1-4f34-8655-18f9fcabbeda', 'A', null, 'Curl concentrado', 'Dumbbell Concentration Curl', 'Curl concentrado'),
  ('645e4d99-5106-4457-885e-9e90d7f8c509', 'C', 'curl crucifijo', 'Curl de bíceps en polea alta', 'Cable High Bicep Curl', 'Curl de bíceps en polea alta'),
  ('9b4ed34e-3e7e-41bc-9713-46f740e6c4bd', 'A', null, 'Curl de bíceps con barra', 'Barbell Bicep Curl', 'Curl de bíceps con barra'),
  ('ac2ef511-f2dd-48ab-8c32-db4561e5dee9', 'A', null, 'Curl de bíceps con mancuernas', 'Dumbbell Bicep Curl', 'Curl de bíceps con mancuernas'),
  ('f1d202a1-55aa-4d9d-a85d-796f2e5f3651', 'A', null, 'Curl de bíceps en máquina', 'Machine Bicep Curl', 'Curl de bíceps en máquina'),
  ('61d0460e-2f7b-4fbf-a510-41b040ee68e4', 'A', null, 'Curl martillo con cuerda en polea', 'Cable Rope Hammer Curl', 'Curl martillo con cuerda en polea'),
  ('4590c14b-d8d5-4f50-833e-61e35c143f05', 'A', null, 'Curl Zottman', 'Zottman Curl', 'Curl Zottman'),
  ('6e894dd6-1838-402d-8503-45de7f3cc33a', 'C', 'deadlift', 'Peso muerto convencional', 'Barbell Deadlift', 'Peso muerto convencional'),
  ('39e4f086-8d41-42c8-8318-035929757c12', 'B', 'Dumbbell Bent Over Row', 'Dumbbell Bent Over Row', 'Dumbbell Bent Over Row', 'Remo inclinado con mancuernas'),
  ('831ee70d-7668-4c18-a55b-152a40489a50', 'B', 'Dumbbell Front Squat', 'Dumbbell Front Squat', 'Dumbbell Front Squat', 'Sentadilla frontal con mancuernas'),
  ('d13cd4de-98e9-470b-b13c-69180535dbee', 'B', 'Dumbbell Romanian Deadlift', 'Dumbbell Romanian Deadlift', 'Dumbbell Romanian Deadlift', 'Peso muerto rumano con mancuernas'),
  ('400cff2d-ed38-44b7-900b-88af598548b4', 'B', 'Dumbbell Seated Shoulder Press', 'Dumbbell Seated Shoulder Press', 'Dumbbell Seated Shoulder Press', 'Press de hombro sentado con mancuernas'),
  ('cfcb15e7-a950-4407-9905-791087e1140a', 'A', null, 'Elevación de talones en Smith', 'Smith Machine Calf Raise', 'Elevación de talones en Smith'),
  ('e5034bfd-c485-458c-8811-81ffd255a423', 'A', null, 'Elevaciones frontales en polea', 'Cable Front Raise', 'Elevaciones frontales en polea'),
  ('3ed4090b-6941-46fa-ab26-a7f0e6f4e76c', 'A', null, 'Escorpión tumbado', 'Prone Scorpion', 'Escorpión tumbado'),
  ('9437cbd5-d5cc-48ee-a1fe-796b330654ce', 'A', null, 'Estiramiento de cuello lateral', 'Static Lateral Neck Stretch', 'Estiramiento de cuello lateral'),
  ('17b475b2-c96f-4ef9-9137-ef6bce89b95f', 'A', null, 'Extensión de tríceps con cuerda', 'Cable Rope Tricep Extension', 'Extensión de tríceps con cuerda'),
  ('076db2f0-c662-494a-bae3-121e2a96b95a', 'A', null, 'Extensión de tríceps en máquina', 'Machine Tricep Pushdowns', 'Extensión de tríceps en máquina'),
  ('8104e125-adbd-4b05-9215-517ca239f5c9', 'C', 'figure 8', 'Figura ocho con kettlebell', 'Kettlebell Figure 8', 'Figura ocho con kettlebell'),
  ('3a9bd0af-f4a6-421b-b5b1-34441a2b76ea', 'A', null, 'Flexiones inclinadas en Smith', 'Smith Machine Incline Push-Up', 'Flexiones inclinadas en Smith'),
  ('54180340-ac54-4dba-a467-3d531dcc7724', 'C', 'fly inclinado', 'Aperturas inclinadas con mancuernas', 'Dumbbell Incline Bench Chest Fly', 'Aperturas inclinadas con mancuernas'),
  ('e58b10f7-8993-4bb2-b3bb-6dab637480f5', 'A', null, 'Fondos de tríceps en Smith', 'Smith Machine Tricep Dip', 'Fondos de tríceps en Smith'),
  ('235b2590-9ee0-48f8-9d5c-2988b976aeb6', 'C', 'francés a una mano', 'Extensión de tríceps sobre la cabeza', 'Dumbbell Single Arm Overhead Tricep Extension', 'Extensión de tríceps sobre la cabeza'),
  ('5d8e7352-7b4b-4bbc-b67e-a1f1346817bd', 'C', 'front raise', 'Elevaciones frontales', 'Dumbbell Front Raise', 'Elevaciones frontales'),
  ('b0e7002c-796c-41d3-850e-e7e83dacbbda', 'C', 'front squat', 'Sentadilla frontal con barra', 'Barbell Front Squat', 'Sentadilla frontal con barra'),
  ('f2852ef3-56f6-42dd-80d6-f4eab1823993', 'C', 'glute kickback', 'Patada de glúteo en máquina', 'Machine Glute Kickback', 'Patada de glúteo en máquina'),
  ('e86e398a-3304-4848-9384-777e9969bfb4', 'C', 'goblet squat', 'Sentadilla goblet', 'Dumbbell Goblet Squat', 'Sentadilla goblet'),
  ('111dbe8f-3466-484c-a2c4-ea0e52ad477b', 'C', 'good morning', 'Buenos días', 'Barbell Good Morning', 'Buenos días'),
  ('173fd7a3-d592-4e2a-adae-b2d01264df00', 'C', 'inchworm', 'Gusano caminando', 'Inchworm Walk', 'Gusano caminando'),
  ('5677e7fd-33a3-4b46-b125-6045602c03f6', 'A', null, 'Jalón al pecho agarre supino', 'Underhand Grip Lat Pulldown', 'Jalón al pecho agarre supino'),
  ('64b7c196-2ccd-4753-ba79-700a0699ddf6', 'C', 'jump lunge', 'Zancada con salto', 'Alternating Jump Lunge', 'Zancada con salto'),
  ('2fab04c3-a424-4a25-a1a9-29d07b98fd7b', 'C', 'jumping jacks', 'Saltos de tijera', 'Jumping Jack', 'Saltos de tijera'),
  ('b9e4d387-f7d7-4f38-bc98-4381d839bde5', 'B', 'Kettlebell Alternating Halo', 'Kettlebell Alternating Halo', 'Kettlebell Alternating Halo', 'Halo alterno con kettlebell'),
  ('dd1ac05b-57c6-4187-8734-a1b7bd4c2b2d', 'C', 'leg swings', 'Balanceo de pierna adelante y atrás', 'Forward Leg Swing', 'Balanceo de pierna adelante y atrás'),
  ('60c9ae73-c7b6-4191-9fd9-535fc7106d22', 'C', 'levantada turca', 'Turkish get-up', 'Kettlebell Turkish Get Up', 'Turkish get-up'),
  ('b54486f4-bc63-426f-8126-540c92e4578c', 'C', 'lunge', 'Zancada con mancuernas', 'Dumbbell Forward Lunge', 'Zancada con mancuernas'),
  ('3ae7d4c3-59d9-4fca-8e81-2780bd731dac', 'B', 'Medicine Ball Lunge Twist to Overhead Press', 'Medicine Ball Lunge Twist to Overhead Press', 'Medicine Ball Lunge Twist to Overhead Press', 'Zancada con giro y press sobre la cabeza con balón medicinal'),
  ('4c37e1f9-a117-4e27-9443-61473cba757b', 'C', 'overhead press', 'Press militar con barra', 'Barbell Overhead Press', 'Press militar con barra'),
  ('e17f79f3-fbf1-406a-aa9a-74a149aea728', 'A', null, 'Peso muerto a una pierna con kettlebell', 'Kettlebell Single Leg Deadlift', 'Peso muerto a una pierna con kettlebell'),
  ('f599f895-6c3b-4311-8c27-1cca37f6c755', 'A', null, 'Peso muerto sumo con barra', 'Barbell Sumo Deadlift', 'Peso muerto sumo con barra'),
  ('41b69a35-454e-4882-816c-ac751613f589', 'C', 'pigeon pose', 'Estiramiento de la paloma', 'Yoga - Pigeon Pose (Kapotasana)', 'Estiramiento de la paloma'),
  ('74c4566b-c27f-408e-83ca-fa3ba61aacad', 'C', 'plank jack', 'Plancha con salto de pies', 'Low plank Jacks', 'Plancha con salto de pies'),
  ('7a9d17b5-71e6-4ba2-8c0c-6525a86c095a', 'C', 'pogo jumps', 'Saltos pogo', 'Pogo Hops', 'Saltos pogo'),
  ('2d57669f-6901-4219-9b80-d46f124cee28', 'C', 'power snatch', 'Arrancada de potencia', 'Barbell Power Snatch', 'Arrancada de potencia'),
  ('f96ee961-0de6-48e5-a667-df536f4ec6e9', 'A', null, 'Press de hombro con kettlebell', 'Kettlebell Single Arm Shoulder Press', 'Press de hombro con kettlebell'),
  ('87ba7cfc-da50-4f1b-9732-c8e00f97d528', 'A', null, 'Press declinado con barra', 'Barbell Decline Bench Press', 'Press declinado con barra'),
  ('3ee916af-d76c-43e3-8eba-7e05cd508680', 'A', null, 'Press declinado con mancuernas', 'Dumbbell Decline Bench Press', 'Press declinado con mancuernas'),
  ('427f2420-61bd-480f-9d64-9a3e250ecda9', 'A', null, 'Press declinado en Smith', 'Smith Machine Decline Bench Press', 'Press declinado en Smith'),
  ('3f2ed29e-7462-4615-93ac-3eb0d4a8e5b5', 'C', 'press hombro de pie', 'Press militar con mancuernas', 'Dumbbell Standing Shoulder Press', 'Press militar con mancuernas'),
  ('8aec6573-7cf9-4dad-9d98-61279fc8ab3f', 'A', null, 'Press inclinado con barra', 'Barbell Incline Bench Press', 'Press inclinado con barra'),
  ('320a3c14-44e5-4809-a469-f422ca076db1', 'A', null, 'Press inclinado en máquina', 'Machine Incline Chest Press', 'Press inclinado en máquina'),
  ('85362dde-c53c-40e3-9810-e1e338ea7cd4', 'A', null, 'Puente de glúteo a una pierna', 'Single Leg Glute Bridge', 'Puente de glúteo a una pierna'),
  ('6fb5cb4f-587a-4b5e-aa1d-3ceb866a0e2e', 'A', null, 'Pull-over en polea alta', 'Cable Pullover', 'Pull-over en polea alta'),
  ('2342f21c-de3d-45c0-b1f8-c81f9324800c', 'A', null, 'Pull-through en polea', 'Cable Pull Through', 'Pull-through en polea'),
  ('db629d35-d318-4493-9f85-4e4d2e1c1f73', 'A', null, 'Pullover con mancuerna', 'Dumbbell Pullover', 'Pullover con mancuerna'),
  ('a66031fd-0bc0-46e9-9c02-0a86e3c3c2cb', 'C', 'puppy pose', 'Estiramiento del gato con brazos extendidos', 'Yoga - Puppy Pose (Anahatasana)', 'Estiramiento del gato con brazos extendidos'),
  ('fff31802-9c03-445e-b408-1b2b77335537', 'A', null, 'Push press con barra', 'Barbell Overhead Push Press', 'Push press con barra'),
  ('e5bbfef2-332f-43cd-aeaf-0848caa0c9c2', 'A', null, 'Push press con mancuernas', 'Dumbbell Push Press', 'Push press con mancuernas'),
  ('7b8e74b7-e869-4977-84d3-d5a2de905395', 'A', null, 'Remo alto en polea', 'Cable Upright Row', 'Remo alto en polea'),
  ('2db036cf-e78a-440b-836e-c3066a72c973', 'A', null, 'Remo alto en Smith', 'Smith Machine Upright Row', 'Remo alto en Smith'),
  ('f9976852-2c08-4c32-b7ee-2c5996198851', 'A', null, 'Remo con barra en Smith', 'Smith Machine Bent Over Row', 'Remo con barra en Smith'),
  ('51008393-1804-4b49-a850-a3dd379b8c77', 'A', null, 'Remo con kettlebell a una mano', 'Kettlebell Single Arm Row', 'Remo con kettlebell a una mano'),
  ('71a25686-a533-4f2f-8c91-4a3ddaddd67a', 'A', null, 'Remo en polea a una mano', 'Single Arm Cable Row', 'Remo en polea a una mano'),
  ('6d7f0f7f-356f-4b65-82d3-b2ec07c3fef4', 'A', null, 'Remo renegado con kettlebell', 'Kettlebell Renegade Row', 'Remo renegado con kettlebell'),
  ('eed07a55-3d71-4a1f-8e7a-ffdafe15438e', 'A', null, 'Remo sentado en máquina', 'Machine Seated Neutral Grip Row', 'Remo sentado en máquina'),
  ('f47bd16f-61b7-47b3-b8b7-934fb0b94fa3', 'A', null, 'Remo sentado en polea baja', 'Cable Seated Row', 'Remo sentado en polea baja'),
  ('266362b6-5b57-407f-a5f8-94f536c1b8ff', 'C', 'renegade row', 'Remo renegado', 'Dumbbell Renegade Row', 'Remo renegado'),
  ('5d03cee6-daac-4594-a821-8618a25f580d', 'A', null, 'Rodilla al pecho caminando', 'Alternating Knee Hug', 'Rodilla al pecho caminando'),
  ('f03e787c-4699-49b6-a75b-e3581169c940', 'A', null, 'Rotación de columna tumbado', 'Yoga - Supine Twist (Jathara Parivartanasana)', 'Rotación de columna tumbado'),
  ('7643d743-868c-4cf0-8fc7-a6998e6b3e57', 'A', null, 'Rotación externa de hombro con banda', 'Band External Shoulder Rotation', 'Rotación externa de hombro con banda'),
  ('ecb3e572-3ddc-4fa6-8e3b-62223436f64b', 'A', null, 'Saltos con cuerda', 'Jump Rope', 'Saltos con cuerda'),
  ('156649b4-8794-4e83-959c-b777fb05188b', 'B', 'Seated Dumbbell Hammer Curl to Neutral Press', 'Seated Dumbbell Hammer Curl to Neutral Press', 'Seated Dumbbell Hammer Curl to Neutral Press', 'Curl martillo sentado con press neutro'),
  ('7b19cb30-7388-4fba-a3e3-3e1ae5af7026', 'B', 'Seated Single Arm Chest Press', 'Seated Single Arm Chest Press', 'Seated Single Arm Chest Press', 'Press de pecho sentado a una mano'),
  ('e6c4bc09-8b1c-4e28-8bc2-776ee78c22c3', 'A', null, 'Sentadilla búlgara con barra', 'Barbell Bulgarian Split Squat', 'Sentadilla búlgara con barra'),
  ('e68799a3-859f-42f1-b7b2-9bb21bfe31e4', 'A', null, 'Sentadilla búlgara en Smith', 'Smith Machine Bulgarian Split Squats', 'Sentadilla búlgara en Smith'),
  ('cbba1cd5-8cd9-4872-9298-94c54859d1ef', 'A', null, 'Sentadilla con mancuernas', 'Dumbbell Squat', 'Sentadilla con mancuernas'),
  ('ea8a45bb-b503-4b0f-84ad-975ca5dfdeb0', 'A', null, 'Sentadilla frontal en Smith', 'Smith Machine Front Squat', 'Sentadilla frontal en Smith'),
  ('b6e5b86e-6f60-452e-bdc3-4c97fe4bee83', 'A', null, 'Sentadilla goblet con kettlebell', 'Kettlebell Goblet Squat', 'Sentadilla goblet con kettlebell'),
  ('7c69e002-e4df-46ef-b95f-ece835202d31', 'A', null, 'Sentadilla sumo con mancuerna', 'Dumbbell Sumo Squat', 'Sentadilla sumo con mancuerna'),
  ('e1ae4787-b3fd-4df7-bcee-bed7a62df858', 'C', 'shrugs', 'Encogimientos con barra', 'Barbell Shrug', 'Encogimientos con barra'),
  ('59cb8b5e-9516-42ad-b1dc-5fbe6357e458', 'C', 'single leg RDL', 'Peso muerto a una pierna con mancuerna', 'Dumbbell Single Leg Deadlift', 'Peso muerto a una pierna con mancuerna'),
  ('f95e9313-14a6-481e-986b-38817e6969a0', 'C', 'skater jump', 'Patinador', 'Skater', 'Patinador'),
  ('03b387d8-5832-4e6b-8e19-bdee0589f96c', 'A', null, 'Skipping', 'Bodyweight A-skip', 'Skipping'),
  ('bed179db-bb81-4777-9de9-1ae253178962', 'C', 'skull crusher', 'Press francés con barra', 'Barbell Skullcrusher', 'Press francés con barra'),
  ('43a21b13-dbba-4447-b0e4-fa866928e667', 'C', 'slam ball', 'Lanzamiento de balón al suelo', 'Medicine Ball Slam', 'Lanzamiento de balón al suelo'),
  ('d599e135-f994-40f5-9fa4-ef3531a49748', 'A', null, 'Sprint corto', 'Sprint', 'Sprint corto'),
  ('7aa8fb0a-d925-468c-b22c-7e8e8f2df384', 'C', 'subida al cajón', 'Step-up al cajón con mancuernas', 'Dumbbell Step Up', 'Step-up al cajón con mancuernas'),
  ('f3559969-6217-406a-be2c-4ba5126729f3', 'A', null, 'Swing a una mano', 'Kettlebell Single Arm Swing', 'Swing a una mano'),
  ('4dc20eee-168b-4197-b96c-4b0722a2b8ef', 'A', null, 'Swing americano con kettlebell', 'American Kettlebell Swing', 'Swing americano con kettlebell'),
  ('318f5e56-29c6-419c-96c7-8138fd56fe9d', 'A', null, 'Thruster con barra', 'Barbell Thruster', 'Thruster con barra'),
  ('96ae51fc-4a3c-4273-abf3-b9409027c20e', 'A', null, 'Thruster con mancuernas', 'Dumbbell Thruster', 'Thruster con mancuernas'),
  ('b2729534-921b-460a-9858-5b2bf0760d1b', 'C', 'upright row', 'Remo alto con mancuernas', 'Dumbbell Upright Row', 'Remo alto con mancuernas'),
  ('28c7839e-3eaa-4087-825c-85305138f00a', 'C', 'upright row', 'Remo alto con barra', 'Barbell Upright Row', 'Remo alto con barra'),
  ('5c9b9b77-2298-448a-ac0b-c692918bed37', 'C', 'walking lunge', 'Zancada caminando con mancuernas', 'Dumbbell Walking Lunge', 'Zancada caminando con mancuernas'),
  ('04d8e658-fe09-4c9e-a0fe-92be2aabe02a', 'A', null, 'Zancada lateral', 'Side Lunge', 'Zancada lateral');

-- Solo si no la usan hoy, si sigue como estaba el 16 oct y si ninguna otra
-- ficha ya tiene ese nombre en inglés.
create temp table _cambio on commit drop as
select n.* from _n n join ejercicios e on e.id = n.id
 where n.id not in (select ejercicio_id from _hoy where ejercicio_id is not null)
   and e.alias is not distinct from n.alias_antes
   and e.nombre = n.nombre_antes
   and (n.caso = 'B' or not exists (
         select 1 from ejercicios o
          where o.id <> n.id and not coalesce(o.archivado, false)
            and pg_temp.ecm_norm(o.alias) = pg_temp.ecm_norm(n.alias_nuevo)));

insert into ejercicios_nombre_respaldo (ejercicio_id, alias, nombre, busqueda, duplicado_de, motivo, puesto_alias, puesto_nombre)
select e.id, e.alias, e.nombre, e.busqueda, e.duplicado_de, 'nombres-analisis-2026-10-16', c.alias_nuevo, c.nombre_nuevo
  from ejercicios e join _cambio c on c.id = e.id;

update ejercicios e
   set alias      = c.alias_nuevo,
       nombre     = c.nombre_nuevo,
       busqueda   = case when c.caso = 'C' and position(pg_temp.ecm_norm(c.alias_antes) in pg_temp.ecm_norm(coalesce(e.busqueda, ''))) = 0
                         then btrim(coalesce(e.busqueda, '') || ' ' || c.alias_antes)
                         else e.busqueda end,
       updated_at = now()
  from _cambio c
 where e.id = c.id;

-- ── 2. Duplicados ──
create temp table _d (id uuid, de uuid) on commit drop;
insert into _d values
  ('73ef48c8-eb2b-4445-b2be-986104328f9b', '4eb77905-2b41-4cfb-9aaf-fdb44bd1c7ad'),
  ('0a034c15-edf8-4cef-adcb-21bab3db529d', '3ea585d8-2a3a-425d-9a80-c5cf1bc5e140'),
  ('787b7c58-e081-4482-aff1-6d58ac48e493', '57d2ad01-1111-4296-a3d3-28be6a58898b'),
  ('8e55a63f-6dd1-4b69-9dd9-62cbc6c79db9', '9e8302c4-0a04-400d-bb54-6deed143dc30'),
  ('65c36bf7-32fa-41eb-ad96-e7b724d0f8c8', '7cde1733-e5ba-4b61-a2f4-e10e9cf568bf'),
  ('907ac910-7821-4763-90e5-9cd2c9e7c825', 'e0144923-8530-4a31-9ed0-5e575b9ae23b'),
  ('d8a07c43-619a-463f-b757-f3cc715339cc', '1f5c688e-6f0c-43c5-94aa-c1d6a08cbc90'),
  ('e86dcc31-81f7-47ad-b87e-e193fbaa0765', 'f7702673-fba2-46f0-8e21-1568b888c5cf'),
  ('137aca56-3e1c-4e35-8a1f-49cf7870eb40', 'fc4a8659-8191-4f64-92c8-9b3d56b7a9fd'),
  ('79e725e1-e2a9-4bd7-bd7c-8ce1c82c0a78', '33c8297e-82d5-4b30-9918-4adbe695c6cb'),
  ('3c06e5d7-60cc-48b1-9aeb-f39c9cae96fa', 'efc0beef-ce34-430d-b555-f4fb2935a063'),
  ('9fdedad9-6033-4316-82d6-81fcd7b7eb5d', '970195ad-44a2-4d48-abf3-e5110a1b5d89'),
  ('ede608b6-f008-48d4-bb1d-21657fafb075', 'c036be29-1d08-43a9-b9bf-0a1cb6520c39'),
  ('f5f688cc-c641-4a0d-a9c7-b60f60bc364a', '5a7f41c8-e2af-4b29-ab8d-1ad4a319280e'),
  ('3c1bb3ba-1178-4f31-bdef-f393ffa48d91', '2f4df0d9-d053-4765-a6da-249180691e44'),
  ('d2b251af-0423-428d-a981-8ad826550a79', '8f54ff73-739c-4169-bbc4-9c5e6798ba77'),
  ('d8e11db5-6f47-4a9e-8bac-8309de444f9f', 'c3c1b42f-56b8-4ba1-a3a0-981d63d71cf2'),
  ('ec650c0a-9b3a-422d-9016-f7cc72a5d87a', 'bb66864d-8bc7-43dc-812d-0991f426a1a1'),
  ('be9a073d-ae7b-4b31-8609-4f6234b9af0f', '431e3c21-0281-49e6-992e-c81f2a1d10b2'),
  ('73dfd3d0-ace3-43f5-aaaa-feb39f39e1cf', '3ef001d1-7110-41bd-9143-053312113fb7'),
  ('67dda2d8-35af-4e4f-9ea3-00d50e301f91', '13f1b0fb-2fe7-4eb3-99d4-79c0bbfb819c'),
  ('6c1375bc-1828-48e3-b948-5b1f276de83b', '6e43639f-a044-4896-99e3-20ec2b68d715'),
  ('795f7c0d-1af4-49d0-85e9-9650fc0496a6', 'f7b9376d-58f8-4d1f-b35b-eed6aeef25ff'),
  ('87fbe981-8b56-412c-bd02-8871d9d3e6bb', 'c5541873-d078-491d-9548-2d2e0fdf2e28'),
  ('29ee1a08-c342-4da9-b16f-13089202dcb0', 'b9a2ee75-f825-41cc-8e32-8be6905b07e4'),
  ('70a6dab4-ac1a-4254-92d5-5842e257fd91', '1642e919-cfae-40aa-be08-aad31d646206'),
  ('aa905967-91f6-43c2-8616-61063c50df9b', '046472f0-c61d-4400-af23-6dcd5f367d7f'),
  ('4c775af4-e51b-45df-9804-15d417ffda5f', '4cd55f9d-d5ba-4e44-8797-0bcbfad0710d'),
  ('54688369-36df-42d7-9349-fb0d5e2122f4', '1781708b-a6cc-4a10-b28c-e1addd398e5f'),
  ('c49e933e-67e8-4a79-8afb-492e01948ed1', '400cff2d-ed38-44b7-900b-88af598548b4'),
  ('e456a71a-9f82-46b7-b660-b5f399ddd8f3', 'a3994f79-8869-4637-a86c-b428d1b87165'),
  ('5144b4b8-e1d7-4171-b8f0-ae3432119ca6', '7ec360ca-f5a2-4bab-9c13-72702a7f3ceb'),
  ('df878e46-2007-4197-9643-5423dd3b6503', 'a9da1c17-4004-47a0-b896-6c81ba8769d3'),
  ('c3d01be2-5324-4c4d-82fb-a50c8a87917e', '571fcdb4-35df-42d0-b675-2eaab90a270b'),
  ('fdcb679d-dec4-4a2c-b692-7df2c874a31f', '39e4f086-8d41-42c8-8318-035929757c12'),
  ('66f31dd8-8887-487a-8bee-c672b25c101d', '17bddff4-18da-4fe6-b5e8-a7928c28440e'),
  ('c0b1df48-7dc3-4c2a-a95f-80832ff1a425', '4d131ad8-1c60-462e-8f0b-8cd81cddf0c5'),
  ('52efe5ff-7245-47fc-bf26-d13250664015', '63a9233a-9302-4122-b0d2-a74a32c76e0a'),
  ('2c7a208a-38f0-412f-9de9-4dcdd3a6936f', '4f5b6902-5e62-4e56-9de4-eac605e3009b'),
  ('72c36e54-2a78-4048-b9b1-326cfba3901c', 'cfd70be8-e833-48d4-b848-c8a1e30f5c44');

create temp table _marca on commit drop as
select d.* from _d d
  join ejercicios e on e.id = d.id
  join ejercicios o on o.id = d.de
 where d.id not in (select ejercicio_id from _hoy where ejercicio_id is not null)
   and e.duplicado_de is null
   and not coalesce(e.archivado, false);

insert into ejercicios_nombre_respaldo (ejercicio_id, alias, nombre, busqueda, duplicado_de, motivo, puesto_alias, puesto_nombre)
select e.id, e.alias, e.nombre, e.busqueda, e.duplicado_de, 'nombres-analisis-2026-10-16-duplicado', e.alias, e.nombre
  from ejercicios e join _marca m on m.id = e.id;

update ejercicios e set duplicado_de = m.de, updated_at = now()
  from _marca m where e.id = m.id;

-- Resumen.
select 'Nombres' as que,
       case caso when 'A' then 'se puso el inglés de Trainerize' when 'C' then 'apodo → inglés de Trainerize' else 'se puso el español' end as detalle,
       count(*) as ejercicios
  from _cambio group by caso
union all
select 'Duplicados marcados', 'salen en «🔁 Duplicados» del CRM', count(*) from _marca
union all
select 'Saltados', 'ya estaban hechos, los usan hoy tus clientes o los editaste desde el 16 oct',
       (select count(*) from _n where id not in (select id from _cambio)) + (select count(*) from _d where id not in (select id from _marca))
order by 1, 3 desc;

commit;

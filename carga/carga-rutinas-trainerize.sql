-- ═══════════════════════════════════════════════════════════════════════
-- CARGA DE RUTINAS · 5 clientes · exportadas de Trainerize (19 sep 2026)
-- ═══════════════════════════════════════════════════════════════════════
--
-- Qué hace, en orden:
--   1. Crea (si no existen) las fichas de los 112 ejercicios que usan estas
--      rutinas, en TU galería. El nombre va en español y el original de
--      Trainerize queda en `alias`, que es por donde se cruzan.
--   2. Crea una FASE por cliente con sus semanas y fechas reales.
--   3. Crea sus RUTINAS con circuitos, series, reps y descansos.
--   4. Carga el HISTORIAL de "Previous Stats": una sesión por fecha y una
--      fila de series_log por cada serie con reps y peso.
--
-- NO se le muestra nada al cliente: las fases entran como `borrador` y con
-- visible_cliente = false. Para publicarlas está el botón "Enviar al
-- cliente" del CRM (o la función publicar_fase()).
--
-- ANTES DE CORRER: pasa primero `migracion-visibilidad.sql`.
--
-- SE PUEDE CORRER DOS VECES: si un cliente ya tiene su fase cargada, esa
-- parte se salta sola y te avisa. No duplica nada.
--
-- SI ALGO SALE MAL: al final del archivo está el bloque para deshacerlo.
--
-- OJO con los nombres: cada cliente se busca en `clientes` por nombre. Si
-- alguno está escrito distinto en el CRM, ese cliente se salta con un aviso
-- y basta con corregir el patrón de búsqueda y volver a correr.
-- ═══════════════════════════════════════════════════════════════════════

begin;

-- ── Busca o crea la ficha de un ejercicio en tu galería ──────────────────
-- Cruza primero por alias (el nombre de Trainerize) y luego por nombre, así
-- que si ya tienes el ejercicio creado lo REUSA en vez de duplicarlo.
create or replace function ecm_ej(
  p_coach uuid, p_alias text, p_nombre text, p_tipo text, p_segmento text,
  p_patron text, p_equipo text[], p_unilateral boolean
) returns uuid language plpgsql as $fn$
declare v_id uuid;
begin
  select id into v_id from ejercicios
   where user_id = p_coach
     and (alias = p_alias or lower(nombre) = lower(p_nombre) or lower(nombre) = lower(p_alias))
   limit 1;
  if v_id is not null then return v_id; end if;
  insert into ejercicios (user_id, nombre, alias, tipo, segmento, patron, equipo,
                          unilateral, nivel, tags)
  values (p_coach, p_nombre, p_alias, p_tipo, p_segmento, p_patron, p_equipo,
          p_unilateral, 'intermedio', array['importado-trainerize'])
  returning id into v_id;
  return v_id;
end $fn$;

-- Tabla puente alias → id, para no repetir la ficha en cada uso.
create temp table if not exists _ecm_ej (alias text primary key, id uuid) on commit drop;


do $cat$
declare v_coach uuid;
begin
  select user_id into v_coach from clientes order by created_at limit 1;
  if v_coach is null then raise exception 'No hay clientes en la tabla `clientes`: no sé de qué coach es esto.'; end if;
  delete from _ecm_ej;
  insert into _ecm_ej values ('90-90 Hip Switch', ecm_ej(v_coach, '90-90 Hip Switch', 'Cambio de cadera 90-90', 'movilidad', 'core', null, array['peso_corporal']::text[], false));
  insert into _ecm_ej values ('Bodyweight Alternating Cossack Squat', ecm_ej(v_coach, 'Bodyweight Alternating Cossack Squat', 'Sentadilla cosaco alterna', 'movilidad', 'tren_inferior', 'rodilla', array['peso_corporal']::text[], true));
  insert into _ecm_ej values ('Bodyweight Squat To Hinge', ecm_ej(v_coach, 'Bodyweight Squat To Hinge', 'De sentadilla a bisagra', 'movilidad', 'tren_inferior', 'cadera', array['peso_corporal']::text[], false));
  insert into _ecm_ej values ('Bodyweight Spiderman Lunge To Rotation', ecm_ej(v_coach, 'Bodyweight Spiderman Lunge To Rotation', 'Zancada spiderman con rotación', 'movilidad', 'full_body', null, array['peso_corporal']::text[], true));
  insert into _ecm_ej values ('Dynamic Hip Opening Flow', ecm_ej(v_coach, 'Dynamic Hip Opening Flow', 'Flujo dinámico de apertura de cadera', 'movilidad', 'tren_inferior', null, array['peso_corporal']::text[], true));
  insert into _ecm_ej values ('Mini Band Wall Slides', ecm_ej(v_coach, 'Mini Band Wall Slides', 'Deslizamientos en pared con banda', 'movilidad', 'tren_superior', null, array['banda']::text[], false));
  insert into _ecm_ej values ('Mini Band Standing I''s', ecm_ej(v_coach, 'Mini Band Standing I''s', 'I''s de pie con banda', 'movilidad', 'tren_superior', 'pull', array['banda']::text[], false));
  insert into _ecm_ej values ('Lateral Lunge to T-Rotation', ecm_ej(v_coach, 'Lateral Lunge to T-Rotation', 'Zancada lateral con rotación en T', 'movilidad', 'full_body', null, array['peso_corporal']::text[], true));
  insert into _ecm_ej values ('Glute Side Circle', ecm_ej(v_coach, 'Glute Side Circle', 'Círculos de glúteo en cuadrupedia', 'movilidad', 'tren_inferior', 'cadera', array['peso_corporal']::text[], true));
  insert into _ecm_ej values ('Alternating Spiderman lunge to hip lift', ecm_ej(v_coach, 'Alternating Spiderman lunge to hip lift', 'Zancada spiderman con elevación de cadera', 'movilidad', 'full_body', null, array['peso_corporal']::text[], true));
  insert into _ecm_ej values ('Downward Dog to Scorpion', ecm_ej(v_coach, 'Downward Dog to Scorpion', 'Perro boca abajo a escorpión', 'movilidad', 'full_body', null, array['peso_corporal']::text[], true));
  insert into _ecm_ej values ('Cossack Squat to T-Spine Reach', ecm_ej(v_coach, 'Cossack Squat to T-Spine Reach', 'Sentadilla cosaco con alcance torácico', 'movilidad', 'full_body', null, array['peso_corporal']::text[], true));
  insert into _ecm_ej values ('Cat to Cow', ecm_ej(v_coach, 'Cat to Cow', 'Gato-camello', 'movilidad', 'core', null, array['peso_corporal']::text[], false));
  insert into _ecm_ej values ('Cobra', ecm_ej(v_coach, 'Cobra', 'Cobra', 'movilidad', 'core', null, array['peso_corporal']::text[], false));
  insert into _ecm_ej values ('Table Top Half Arm Thoracic Rotation', ecm_ej(v_coach, 'Table Top Half Arm Thoracic Rotation', 'Rotación torácica en cuadrupedia', 'movilidad', 'core', null, array['peso_corporal']::text[], true));
  insert into _ecm_ej values ('SuperBand Dislocates', ecm_ej(v_coach, 'SuperBand Dislocates', 'Dislocaciones de hombro con banda', 'movilidad', 'tren_superior', null, array['banda']::text[], false));
  insert into _ecm_ej values ('Dumbbell Standing Shoulder External Rotations', ecm_ej(v_coach, 'Dumbbell Standing Shoulder External Rotations', 'Rotación externa de hombro de pie', 'movilidad', 'tren_superior', null, array['mancuerna']::text[], false));
  insert into _ecm_ej values ('Dumbbell External Rotation on Side', ecm_ej(v_coach, 'Dumbbell External Rotation on Side', 'Rotación externa tumbado de lado', 'movilidad', 'tren_superior', null, array['mancuerna']::text[], true));
  insert into _ecm_ej values ('Lateral Shuttle Run', ecm_ej(v_coach, 'Lateral Shuttle Run', 'Desplazamiento lateral', 'agilidad', 'full_body', 'locomocion', array['peso_corporal']::text[], false));
  insert into _ecm_ej values ('Shuttle Run', ecm_ej(v_coach, 'Shuttle Run', 'Ida y vuelta corta', 'agilidad', 'full_body', 'locomocion', array['peso_corporal']::text[], false));
  insert into _ecm_ej values ('Jump Squat to Reverse Lunge', ecm_ej(v_coach, 'Jump Squat to Reverse Lunge', 'Sentadilla con salto a zancada atrás', 'pliometrico', 'tren_inferior', 'rodilla', array['peso_corporal']::text[], true));
  insert into _ecm_ej values ('1/2 Kneel to Lateral Bound', ecm_ej(v_coach, '1/2 Kneel to Lateral Bound', 'Salto lateral desde media rodilla', 'pliometrico', 'tren_inferior', null, array['peso_corporal']::text[], true));
  insert into _ecm_ej values ('Bosu Lateral Bounce to Squat Jump', ecm_ej(v_coach, 'Bosu Lateral Bounce to Squat Jump', 'Rebote lateral en BOSU a salto', 'pliometrico', 'tren_inferior', 'rodilla', array['bosu']::text[], true));
  insert into _ecm_ej values ('Broad Jump', ecm_ej(v_coach, 'Broad Jump', 'Salto horizontal', 'pliometrico', 'tren_inferior', 'cadera', array['peso_corporal']::text[], false));
  insert into _ecm_ej values ('Squat Jump', ecm_ej(v_coach, 'Squat Jump', 'Sentadilla con salto', 'pliometrico', 'tren_inferior', 'rodilla', array['peso_corporal']::text[], false));
  insert into _ecm_ej values ('BOSU Alternating Lateral Squat Shuffle', ecm_ej(v_coach, 'BOSU Alternating Lateral Squat Shuffle', 'Desplazamiento lateral en BOSU', 'agilidad', 'tren_inferior', null, array['bosu']::text[], true));
  insert into _ecm_ej values ('Running', ecm_ej(v_coach, 'Running', 'Carrera continua', 'cardio', 'full_body', 'locomocion', array['peso_corporal']::text[], false));
  insert into _ecm_ej values ('Half Burpee with Dumbbell', ecm_ej(v_coach, 'Half Burpee with Dumbbell', 'Medio burpee con mancuernas', 'pliometrico', 'full_body', null, array['mancuerna']::text[], false));
  insert into _ecm_ej values ('Dumbbell Burpee Clean to Press', ecm_ej(v_coach, 'Dumbbell Burpee Clean to Press', 'Burpee con cargada y press', 'pliometrico', 'full_body', null, array['mancuerna']::text[], false));
  insert into _ecm_ej values ('Dumbbell Front Squat', ecm_ej(v_coach, 'Dumbbell Front Squat', 'Sentadilla frontal con mancuernas', 'fuerza', 'tren_inferior', 'rodilla', array['mancuerna']::text[], false));
  insert into _ecm_ej values ('Dumbbell Straight Leg Deadlift', ecm_ej(v_coach, 'Dumbbell Straight Leg Deadlift', 'Peso muerto piernas rectas con mancuernas', 'fuerza', 'tren_inferior', 'cadera', array['mancuerna']::text[], false));
  insert into _ecm_ej values ('Plate Hip Thrust', ecm_ej(v_coach, 'Plate Hip Thrust', 'Hip thrust con disco', 'fuerza', 'tren_inferior', 'cadera', array['disco','banco']::text[], false));
  insert into _ecm_ej values ('Mini Band Wall Sit with Abductions', ecm_ej(v_coach, 'Mini Band Wall Sit with Abductions', 'Sentadilla isométrica en pared con abducción', 'fuerza', 'tren_inferior', null, array['banda']::text[], false));
  insert into _ecm_ej values ('Mini Band Side Lying Hip Abduction', ecm_ej(v_coach, 'Mini Band Side Lying Hip Abduction', 'Abducción de cadera tumbado con banda', 'fuerza', 'tren_inferior', 'cadera', array['banda']::text[], true));
  insert into _ecm_ej values ('Dumbbell Single Leg Calf Raise', ecm_ej(v_coach, 'Dumbbell Single Leg Calf Raise', 'Elevación de talón a una pierna con mancuerna', 'fuerza', 'tren_inferior', null, array['mancuerna']::text[], true));
  insert into _ecm_ej values ('Angled Machine Leg Press', ecm_ej(v_coach, 'Angled Machine Leg Press', 'Prensa inclinada', 'fuerza', 'tren_inferior', 'rodilla', array['maquina']::text[], false));
  insert into _ecm_ej values ('Machine Seated Leg Extension', ecm_ej(v_coach, 'Machine Seated Leg Extension', 'Extensión de cuádriceps en máquina', 'fuerza', 'tren_inferior', 'rodilla', array['maquina']::text[], false));
  insert into _ecm_ej values ('Machine Seated Leg Curl', ecm_ej(v_coach, 'Machine Seated Leg Curl', 'Curl femoral sentado en máquina', 'fuerza', 'tren_inferior', 'cadera', array['maquina']::text[], false));
  insert into _ecm_ej values ('Machine Seated Hip Adduction', ecm_ej(v_coach, 'Machine Seated Hip Adduction', 'Aductores en máquina', 'fuerza', 'tren_inferior', null, array['maquina']::text[], false));
  insert into _ecm_ej values ('Machine Seated Calf Raise', ecm_ej(v_coach, 'Machine Seated Calf Raise', 'Gemelo sentado en máquina', 'fuerza', 'tren_inferior', null, array['maquina']::text[], false));
  insert into _ecm_ej values ('Hip Thrust Machine', ecm_ej(v_coach, 'Hip Thrust Machine', 'Hip thrust en máquina', 'fuerza', 'tren_inferior', 'cadera', array['maquina']::text[], false));
  insert into _ecm_ej values ('Smith Machine Deadlift', ecm_ej(v_coach, 'Smith Machine Deadlift', 'Peso muerto en multipower', 'fuerza', 'tren_inferior', 'cadera', array['maquina']::text[], false));
  insert into _ecm_ej values ('Smith Machine Sumo Deadlift', ecm_ej(v_coach, 'Smith Machine Sumo Deadlift', 'Peso muerto sumo en multipower', 'fuerza', 'tren_inferior', 'cadera', array['maquina']::text[], false));
  insert into _ecm_ej values ('Smith Machine Back Squat', ecm_ej(v_coach, 'Smith Machine Back Squat', 'Sentadilla trasera en multipower', 'fuerza', 'tren_inferior', 'rodilla', array['maquina']::text[], false));
  insert into _ecm_ej values ('Landmine RDL', ecm_ej(v_coach, 'Landmine RDL', 'Peso muerto rumano con landmine', 'fuerza', 'tren_inferior', 'cadera', array['barra']::text[], false));
  insert into _ecm_ej values ('Dumbbell Bulgarian Split Squat', ecm_ej(v_coach, 'Dumbbell Bulgarian Split Squat', 'Sentadilla búlgara con mancuernas', 'fuerza', 'tren_inferior', 'rodilla', array['mancuerna','banco']::text[], true));
  insert into _ecm_ej values ('Cable Glute Crossover Kickback', ecm_ej(v_coach, 'Cable Glute Crossover Kickback', 'Patada de glúteo cruzada en polea', 'fuerza', 'tren_inferior', 'cadera', array['polea']::text[], true));
  insert into _ecm_ej values ('Dumbbell Hip Thrust', ecm_ej(v_coach, 'Dumbbell Hip Thrust', 'Hip thrust con mancuerna', 'fuerza', 'tren_inferior', 'cadera', array['mancuerna','banco']::text[], false));
  insert into _ecm_ej values ('Dumbbell Reverse Lunge', ecm_ej(v_coach, 'Dumbbell Reverse Lunge', 'Zancada atrás con mancuernas', 'fuerza', 'tren_inferior', 'rodilla', array['mancuerna']::text[], true));
  insert into _ecm_ej values ('Dumbbell Sumo Deadlift', ecm_ej(v_coach, 'Dumbbell Sumo Deadlift', 'Peso muerto sumo con mancuerna', 'fuerza', 'tren_inferior', 'cadera', array['mancuerna']::text[], false));
  insert into _ecm_ej values ('Dumbbell Glute Bridge', ecm_ej(v_coach, 'Dumbbell Glute Bridge', 'Puente de glúteo con mancuerna', 'fuerza', 'tren_inferior', 'cadera', array['mancuerna']::text[], false));
  insert into _ecm_ej values ('Bench Plank Single Arm Row', ecm_ej(v_coach, 'Bench Plank Single Arm Row', 'Remo a una mano en plancha sobre banco', 'fuerza', 'tren_superior', 'pull', array['mancuerna','banco']::text[], true));
  insert into _ecm_ej values ('Dumbbell Bench Press', ecm_ej(v_coach, 'Dumbbell Bench Press', 'Press banca con mancuernas', 'fuerza', 'tren_superior', 'push', array['mancuerna','banco']::text[], false));
  insert into _ecm_ej values ('Dumbbell Incline Bench Press', ecm_ej(v_coach, 'Dumbbell Incline Bench Press', 'Press inclinado con mancuernas', 'fuerza', 'tren_superior', 'push', array['mancuerna','banco']::text[], false));
  insert into _ecm_ej values ('Cable Lateral Raise', ecm_ej(v_coach, 'Cable Lateral Raise', 'Elevación lateral en polea', 'fuerza', 'tren_superior', 'push', array['polea']::text[], true));
  insert into _ecm_ej values ('Cable Bicep Curl', ecm_ej(v_coach, 'Cable Bicep Curl', 'Curl de bíceps en polea', 'fuerza', 'tren_superior', 'pull', array['polea']::text[], false));
  insert into _ecm_ej values ('Dumbbell Hammer Curl', ecm_ej(v_coach, 'Dumbbell Hammer Curl', 'Curl martillo con mancuernas', 'fuerza', 'tren_superior', 'pull', array['mancuerna']::text[], false));
  insert into _ecm_ej values ('Dumbbell Alternating Hammer Curl', ecm_ej(v_coach, 'Dumbbell Alternating Hammer Curl', 'Curl martillo alterno', 'fuerza', 'tren_superior', 'pull', array['mancuerna']::text[], true));
  insert into _ecm_ej values ('Cable V-Bar Overhead Tricep Extension', ecm_ej(v_coach, 'Cable V-Bar Overhead Tricep Extension', 'Extensión de tríceps sobre la cabeza en polea', 'fuerza', 'tren_superior', 'push', array['polea']::text[], false));
  insert into _ecm_ej values ('Cable V Bar Tricep Pushdown', ecm_ej(v_coach, 'Cable V Bar Tricep Pushdown', 'Extensión de tríceps en polea alta', 'fuerza', 'tren_superior', 'push', array['polea']::text[], false));
  insert into _ecm_ej values ('Machine Assisted Wide Grip Pull Up', ecm_ej(v_coach, 'Machine Assisted Wide Grip Pull Up', 'Dominada asistida agarre ancho', 'fuerza', 'tren_superior', 'pull', array['maquina']::text[], false));
  insert into _ecm_ej values ('Machine Seated Shoulder Press', ecm_ej(v_coach, 'Machine Seated Shoulder Press', 'Press de hombro sentado en máquina', 'fuerza', 'tren_superior', 'push', array['maquina']::text[], false));
  insert into _ecm_ej values ('Cable Seated Wide Grip Row', ecm_ej(v_coach, 'Cable Seated Wide Grip Row', 'Remo sentado agarre ancho en polea', 'fuerza', 'tren_superior', 'pull', array['polea']::text[], false));
  insert into _ecm_ej values ('Cable Seated Close Row', ecm_ej(v_coach, 'Cable Seated Close Row', 'Remo sentado agarre estrecho en polea', 'fuerza', 'tren_superior', 'pull', array['polea']::text[], false));
  insert into _ecm_ej values ('Cable Seated Close Grip Row', ecm_ej(v_coach, 'Cable Seated Close Grip Row', 'Remo sentado agarre cerrado en polea', 'fuerza', 'tren_superior', 'pull', array['polea']::text[], false));
  insert into _ecm_ej values ('Cable Standing Crossover Chest Fly', ecm_ej(v_coach, 'Cable Standing Crossover Chest Fly', 'Cruce de poleas de pie', 'fuerza', 'tren_superior', 'push', array['polea']::text[], false));
  insert into _ecm_ej values ('Machine Lateral Raise', ecm_ej(v_coach, 'Machine Lateral Raise', 'Elevación lateral en máquina', 'fuerza', 'tren_superior', 'push', array['maquina']::text[], false));
  insert into _ecm_ej values ('Barbell Preacher Curl', ecm_ej(v_coach, 'Barbell Preacher Curl', 'Curl predicador con barra', 'fuerza', 'tren_superior', 'pull', array['barra']::text[], false));
  insert into _ecm_ej values ('Machine Preacher Curl', ecm_ej(v_coach, 'Machine Preacher Curl', 'Curl predicador en máquina', 'fuerza', 'tren_superior', 'pull', array['maquina']::text[], false));
  insert into _ecm_ej values ('Bar Hang', ecm_ej(v_coach, 'Bar Hang', 'Colgarse de la barra', 'fuerza', 'tren_superior', 'pull', array['pull_up_bar']::text[], false));
  insert into _ecm_ej values ('Plate Weighted Wide Grip Pull Up', ecm_ej(v_coach, 'Plate Weighted Wide Grip Pull Up', 'Dominada lastrada agarre ancho', 'fuerza', 'tren_superior', 'pull', array['pull_up_bar','disco']::text[], false));
  insert into _ecm_ej values ('Wide Grip Pull Up', ecm_ej(v_coach, 'Wide Grip Pull Up', 'Dominada agarre ancho', 'fuerza', 'tren_superior', 'pull', array['pull_up_bar']::text[], false));
  insert into _ecm_ej values ('Machine Seated Reverse Fly', ecm_ej(v_coach, 'Machine Seated Reverse Fly', 'Pájaro en máquina', 'fuerza', 'tren_superior', 'pull', array['maquina']::text[], false));
  insert into _ecm_ej values ('Cable Shrug', ecm_ej(v_coach, 'Cable Shrug', 'Encogimiento de trapecio en polea', 'fuerza', 'tren_superior', 'pull', array['polea']::text[], false));
  insert into _ecm_ej values ('Machine Seated Single Arm Neutral Grip Row', ecm_ej(v_coach, 'Machine Seated Single Arm Neutral Grip Row', 'Remo a una mano en máquina agarre neutro', 'fuerza', 'tren_superior', 'pull', array['maquina']::text[], true));
  insert into _ecm_ej values ('Push Up', ecm_ej(v_coach, 'Push Up', 'Flexión de brazos', 'fuerza', 'tren_superior', 'push', array['peso_corporal']::text[], false));
  insert into _ecm_ej values ('Smith Machine Incline Bench Press', ecm_ej(v_coach, 'Smith Machine Incline Bench Press', 'Press inclinado en multipower', 'fuerza', 'tren_superior', 'push', array['maquina']::text[], false));
  insert into _ecm_ej values ('Smith Machine Bench Press', ecm_ej(v_coach, 'Smith Machine Bench Press', 'Press banca en multipower', 'fuerza', 'tren_superior', 'push', array['maquina']::text[], false));
  insert into _ecm_ej values ('Smith Machine Seated Shoulder Press', ecm_ej(v_coach, 'Smith Machine Seated Shoulder Press', 'Press de hombro sentado en multipower', 'fuerza', 'tren_superior', 'push', array['maquina']::text[], false));
  insert into _ecm_ej values ('Machine Seated Chest Fly', ecm_ej(v_coach, 'Machine Seated Chest Fly', 'Aperturas en máquina', 'fuerza', 'tren_superior', 'push', array['maquina']::text[], false));
  insert into _ecm_ej values ('Machine Seated Chest Press', ecm_ej(v_coach, 'Machine Seated Chest Press', 'Press de pecho sentado en máquina', 'fuerza', 'tren_superior', 'push', array['maquina']::text[], false));
  insert into _ecm_ej values ('Dip', ecm_ej(v_coach, 'Dip', 'Fondos en paralelas', 'fuerza', 'tren_superior', 'push', array['peso_corporal']::text[], false));
  insert into _ecm_ej values ('Kettlebell Single Arm Clean and Press', ecm_ej(v_coach, 'Kettlebell Single Arm Clean and Press', 'Cargada y press a una mano con kettlebell', 'potencia', 'full_body', 'push', array['kettlebell']::text[], true));
  insert into _ecm_ej values ('Dumbbell Alternating Lateral Raise to Front Raise', ecm_ej(v_coach, 'Dumbbell Alternating Lateral Raise to Front Raise', 'Elevación lateral a frontal alterna', 'fuerza', 'tren_superior', 'push', array['mancuerna']::text[], true));
  insert into _ecm_ej values ('Cable Single Arm Standing Overhead Tricep Extension', ecm_ej(v_coach, 'Cable Single Arm Standing Overhead Tricep Extension', 'Extensión de tríceps a una mano en polea', 'fuerza', 'tren_superior', 'push', array['polea']::text[], true));
  insert into _ecm_ej values ('Wide Grip Lat Pulldown', ecm_ej(v_coach, 'Wide Grip Lat Pulldown', 'Jalón al pecho agarre ancho', 'fuerza', 'tren_superior', 'pull', array['polea']::text[], false));
  insert into _ecm_ej values ('Dumbbell Glute Bridge Chest Press', ecm_ej(v_coach, 'Dumbbell Glute Bridge Chest Press', 'Press de pecho en puente de glúteo', 'fuerza', 'full_body', 'push', array['mancuerna']::text[], false));
  insert into _ecm_ej values ('Seated Dumbbell Front Raise to Lateral Raise', ecm_ej(v_coach, 'Seated Dumbbell Front Raise to Lateral Raise', 'Elevación frontal a lateral sentado', 'fuerza', 'tren_superior', 'push', array['mancuerna','banco']::text[], false));
  insert into _ecm_ej values ('Dumbbell Incline Alternating Curl', ecm_ej(v_coach, 'Dumbbell Incline Alternating Curl', 'Curl inclinado alterno', 'fuerza', 'tren_superior', 'pull', array['mancuerna','banco']::text[], true));
  insert into _ecm_ej values ('Cable Straight Bar Tricep Pushdown', ecm_ej(v_coach, 'Cable Straight Bar Tricep Pushdown', 'Extensión de tríceps con barra recta en polea', 'fuerza', 'tren_superior', 'push', array['polea']::text[], false));
  insert into _ecm_ej values ('Cable Rope Face Pull', ecm_ej(v_coach, 'Cable Rope Face Pull', 'Face pull con cuerda', 'fuerza', 'tren_superior', 'pull', array['polea']::text[], false));
  insert into _ecm_ej values ('Dumbbell Floor Press', ecm_ej(v_coach, 'Dumbbell Floor Press', 'Press de pecho en suelo', 'fuerza', 'tren_superior', 'push', array['mancuerna']::text[], false));
  insert into _ecm_ej values ('Dumbbell Single Arm Row', ecm_ej(v_coach, 'Dumbbell Single Arm Row', 'Remo a una mano con mancuerna', 'fuerza', 'tren_superior', 'pull', array['mancuerna','banco']::text[], true));
  insert into _ecm_ej values ('Dumbbell Alternating Bicep Curl', ecm_ej(v_coach, 'Dumbbell Alternating Bicep Curl', 'Curl de bíceps alterno', 'fuerza', 'tren_superior', 'pull', array['mancuerna']::text[], true));
  insert into _ecm_ej values ('Band Anchored Single Arm Tricep Kickback', ecm_ej(v_coach, 'Band Anchored Single Arm Tricep Kickback', 'Patada de tríceps a una mano con banda', 'fuerza', 'tren_superior', 'push', array['banda']::text[], true));
  insert into _ecm_ej values ('SuperBand Single Arm Row', ecm_ej(v_coach, 'SuperBand Single Arm Row', 'Remo a una mano con banda', 'fuerza', 'tren_superior', 'pull', array['banda']::text[], true));
  insert into _ecm_ej values ('Dumbbell Seated Front Raise', ecm_ej(v_coach, 'Dumbbell Seated Front Raise', 'Elevación frontal sentado', 'fuerza', 'tren_superior', 'push', array['mancuerna','banco']::text[], false));
  insert into _ecm_ej values ('Bench Knee Tuck to V Up', ecm_ej(v_coach, 'Bench Knee Tuck to V Up', 'Rodillas al pecho a V-up en banco', 'core', 'core', 'core', array['banco']::text[], false));
  insert into _ecm_ej values ('Bicycle Crunch', ecm_ej(v_coach, 'Bicycle Crunch', 'Bicicleta abdominal', 'core', 'core', 'core', array['peso_corporal']::text[], false));
  insert into _ecm_ej values ('High Plank Jacks', ecm_ej(v_coach, 'High Plank Jacks', 'Plancha alta con saltos', 'core', 'core', 'core', array['peso_corporal']::text[], false));
  insert into _ecm_ej values ('Pallof Press', ecm_ej(v_coach, 'Pallof Press', 'Press Pallof', 'core', 'core', 'core', array['polea']::text[], true));
  insert into _ecm_ej values ('Dip Machine Bent Leg Raise', ecm_ej(v_coach, 'Dip Machine Bent Leg Raise', 'Elevación de rodillas en paralelas', 'core', 'core', 'core', array['maquina']::text[], false));
  insert into _ecm_ej values ('Dip Machine Straight Leg Raise', ecm_ej(v_coach, 'Dip Machine Straight Leg Raise', 'Elevación de piernas rectas en paralelas', 'core', 'core', 'core', array['maquina']::text[], false));
  insert into _ecm_ej values ('Ab Roller Wheel Abdominal Roll Out', ecm_ej(v_coach, 'Ab Roller Wheel Abdominal Roll Out', 'Rueda abdominal', 'core', 'core', 'core', array['rueda_ab']::text[], false));
  insert into _ecm_ej values ('Seated Machine Ab Crunch', ecm_ej(v_coach, 'Seated Machine Ab Crunch', 'Crunch abdominal en máquina', 'core', 'core', 'core', array['maquina']::text[], false));
  insert into _ecm_ej values ('Cross Body Mountain Climber', ecm_ej(v_coach, 'Cross Body Mountain Climber', 'Escalador cruzado', 'core', 'core', 'core', array['peso_corporal']::text[], false));
  insert into _ecm_ej values ('Knee to Elbow Crunch', ecm_ej(v_coach, 'Knee to Elbow Crunch', 'Crunch rodilla al codo', 'core', 'core', 'core', array['peso_corporal']::text[], false));
  insert into _ecm_ej values ('Bench V Sit Leg Raise', ecm_ej(v_coach, 'Bench V Sit Leg Raise', 'Elevación de piernas en V sobre banco', 'core', 'core', 'core', array['banco']::text[], false));
  insert into _ecm_ej values ('Plank To Push Up', ecm_ej(v_coach, 'Plank To Push Up', 'De plancha a flexión', 'core', 'core', 'core', array['peso_corporal']::text[], false));
  insert into _ecm_ej values ('Static Pigeon Stretch', ecm_ej(v_coach, 'Static Pigeon Stretch', 'Estiramiento de paloma', 'estiramiento_pasivo', 'tren_inferior', null, array['peso_corporal']::text[], true));
  insert into _ecm_ej values ('Child''s Pose', ecm_ej(v_coach, 'Child''s Pose', 'Postura del niño', 'estiramiento_pasivo', 'core', null, array['peso_corporal']::text[], false));
  insert into _ecm_ej values ('Suspension Low Back Stretch', ecm_ej(v_coach, 'Suspension Low Back Stretch', 'Estiramiento lumbar en suspensión', 'estiramiento_pasivo', 'core', null, array['trx']::text[], false));
  insert into _ecm_ej values ('Quadruped Hip Circles', ecm_ej(v_coach, 'Quadruped Hip Circles', 'Círculos de cadera en cuadrupedia', 'movilidad', 'tren_inferior', 'cadera', array['peso_corporal']::text[], true));
  insert into _ecm_ej values ('Bodyweight Cossack Squat', ecm_ej(v_coach, 'Bodyweight Cossack Squat', 'Sentadilla cosaco', 'movilidad', 'tren_inferior', 'rodilla', array['peso_corporal']::text[], true));
  insert into _ecm_ej values ('Squat to Hinge', ecm_ej(v_coach, 'Squat to Hinge', 'De sentadilla a bisagra', 'movilidad', 'tren_inferior', 'cadera', array['peso_corporal']::text[], false));
  insert into _ecm_ej values ('1/2 Kneel to High Knee Hop', ecm_ej(v_coach, '1/2 Kneel to High Knee Hop', 'Salto de rodilla alta desde media rodilla', 'pliometrico', 'tren_inferior', null, array['peso_corporal']::text[], true));
  insert into _ecm_ej values ('Bear Squat to Spinal Wave', ecm_ej(v_coach, 'Bear Squat to Spinal Wave', 'Sentadilla de oso con onda espinal', 'movilidad', 'full_body', null, array['peso_corporal']::text[], false));
  insert into _ecm_ej values ('Bear to Step Through', ecm_ej(v_coach, 'Bear to Step Through', 'Posición de oso con paso cruzado', 'movilidad', 'full_body', null, array['peso_corporal']::text[], true));
  insert into _ecm_ej values ('Clapping Push Up', ecm_ej(v_coach, 'Clapping Push Up', 'Flexión con palmada', 'pliometrico', 'tren_superior', 'push', array['peso_corporal']::text[], false));
  insert into _ecm_ej values ('Bench Plyo Push Ups', ecm_ej(v_coach, 'Bench Plyo Push Ups', 'Flexiones pliométricas en banco', 'pliometrico', 'tren_superior', 'push', array['banco']::text[], false));
  insert into _ecm_ej values ('Pull Up', ecm_ej(v_coach, 'Pull Up', 'Dominada', 'fuerza', 'tren_superior', 'pull', array['pull_up_bar']::text[], false));
  insert into _ecm_ej values ('Machine Assisted Parallel Grip Pull Up', ecm_ej(v_coach, 'Machine Assisted Parallel Grip Pull Up', 'Dominada asistida agarre paralelo', 'fuerza', 'tren_superior', 'pull', array['maquina']::text[], false));
  insert into _ecm_ej values ('Machine Seated Parallel Grip Shoulder Press', ecm_ej(v_coach, 'Machine Seated Parallel Grip Shoulder Press', 'Press de hombro agarre paralelo en máquina', 'fuerza', 'tren_superior', 'push', array['maquina']::text[], false));
  insert into _ecm_ej values ('Dumbbell Seated Shoulder Press', ecm_ej(v_coach, 'Dumbbell Seated Shoulder Press', 'Press de hombro sentado con mancuernas', 'fuerza', 'tren_superior', 'push', array['mancuerna','banco']::text[], false));
  insert into _ecm_ej values ('Dumbbell Seated Arnold Press', ecm_ej(v_coach, 'Dumbbell Seated Arnold Press', 'Press Arnold sentado', 'fuerza', 'tren_superior', 'push', array['mancuerna','banco']::text[], false));
  insert into _ecm_ej values ('Smith Machine Shrug', ecm_ej(v_coach, 'Smith Machine Shrug', 'Encogimiento de trapecio en multipower', 'fuerza', 'tren_superior', 'pull', array['maquina']::text[], false));
  insert into _ecm_ej values ('Dumbbell Shrug', ecm_ej(v_coach, 'Dumbbell Shrug', 'Encogimiento de trapecio con mancuernas', 'fuerza', 'tren_superior', 'pull', array['mancuerna']::text[], false));
  insert into _ecm_ej values ('Band Internal Shoulder Rotation (90 degrees)', ecm_ej(v_coach, 'Band Internal Shoulder Rotation (90 degrees)', 'Rotación interna de hombro con banda (90°)', 'movilidad', 'tren_superior', null, array['banda']::text[], true));
  insert into _ecm_ej values ('Cable External Rotation', ecm_ej(v_coach, 'Cable External Rotation', 'Rotación externa en polea', 'movilidad', 'tren_superior', null, array['polea']::text[], true));
  insert into _ecm_ej values ('Kettlebell Alternating Press', ecm_ej(v_coach, 'Kettlebell Alternating Press', 'Press alterno con kettlebell', 'fuerza', 'tren_superior', 'push', array['kettlebell']::text[], true));
  insert into _ecm_ej values ('Kettlebell Alternating Halo', ecm_ej(v_coach, 'Kettlebell Alternating Halo', 'Halo alterno con kettlebell', 'movilidad', 'tren_superior', null, array['kettlebell']::text[], true));
  insert into _ecm_ej values ('Kettlebell Alternating Bent Over Row', ecm_ej(v_coach, 'Kettlebell Alternating Bent Over Row', 'Remo inclinado alterno con kettlebell', 'fuerza', 'tren_superior', 'pull', array['kettlebell']::text[], true));
  insert into _ecm_ej values ('Kettlebell High Pull', ecm_ej(v_coach, 'Kettlebell High Pull', 'Cargada alta con kettlebell', 'potencia', 'full_body', 'pull', array['kettlebell']::text[], false));
  insert into _ecm_ej values ('Dumbbell Incline Bench High Row', ecm_ej(v_coach, 'Dumbbell Incline Bench High Row', 'Remo alto en banco inclinado', 'fuerza', 'tren_superior', 'pull', array['mancuerna','banco']::text[], false));
  insert into _ecm_ej values ('Dumbbell Stationary Lunge', ecm_ej(v_coach, 'Dumbbell Stationary Lunge', 'Zancada estática con mancuernas', 'fuerza', 'tren_inferior', 'rodilla', array['mancuerna']::text[], true));
  insert into _ecm_ej values ('Bench Hip Thrust', ecm_ej(v_coach, 'Bench Hip Thrust', 'Hip thrust en banco', 'fuerza', 'tren_inferior', 'cadera', array['banco']::text[], false));
  insert into _ecm_ej values ('Bodyweight Deadlift', ecm_ej(v_coach, 'Bodyweight Deadlift', 'Peso muerto sin carga', 'fuerza', 'tren_inferior', 'cadera', array['peso_corporal']::text[], false));
  insert into _ecm_ej values ('Body Weight Calf Raise', ecm_ej(v_coach, 'Body Weight Calf Raise', 'Elevación de talones sin carga', 'fuerza', 'tren_inferior', null, array['peso_corporal']::text[], false));
  insert into _ecm_ej values ('Dumbbell Deadlift', ecm_ej(v_coach, 'Dumbbell Deadlift', 'Peso muerto con mancuernas', 'fuerza', 'tren_inferior', 'cadera', array['mancuerna']::text[], false));
  insert into _ecm_ej values ('Seated Leg Press', ecm_ej(v_coach, 'Seated Leg Press', 'Prensa sentado', 'fuerza', 'tren_inferior', 'rodilla', array['maquina']::text[], false));
  insert into _ecm_ej values ('Machine Lying Leg Curl', ecm_ej(v_coach, 'Machine Lying Leg Curl', 'Curl femoral tumbado en máquina', 'fuerza', 'tren_inferior', 'cadera', array['maquina']::text[], false));
  insert into _ecm_ej values ('Leg Press Machine Calf Raise', ecm_ej(v_coach, 'Leg Press Machine Calf Raise', 'Gemelo en prensa', 'fuerza', 'tren_inferior', null, array['maquina']::text[], false));
  insert into _ecm_ej values ('Machine Standing Calf Raise', ecm_ej(v_coach, 'Machine Standing Calf Raise', 'Gemelo de pie en máquina', 'fuerza', 'tren_inferior', null, array['maquina']::text[], false));
  insert into _ecm_ej values ('Barbell Romanian Deadlift', ecm_ej(v_coach, 'Barbell Romanian Deadlift', 'Peso muerto rumano con barra', 'fuerza', 'tren_inferior', 'cadera', array['barra']::text[], false));
  insert into _ecm_ej values ('90-90 to Hip Raise', ecm_ej(v_coach, '90-90 to Hip Raise', '90-90 con elevación de cadera', 'movilidad', 'tren_inferior', 'cadera', array['peso_corporal']::text[], true));
  insert into _ecm_ej values ('Alternating Lunge Hops', ecm_ej(v_coach, 'Alternating Lunge Hops', 'Saltos de zancada alternos', 'pliometrico', 'tren_inferior', 'rodilla', array['peso_corporal']::text[], true));
  insert into _ecm_ej values ('Mountain Climber', ecm_ej(v_coach, 'Mountain Climber', 'Escalador', 'core', 'core', 'core', array['peso_corporal']::text[], false));
  insert into _ecm_ej values ('Bodyweight Deadbug', ecm_ej(v_coach, 'Bodyweight Deadbug', 'Dead bug', 'core', 'core', 'core', array['peso_corporal']::text[], false));
  insert into _ecm_ej values ('Seated Hip Twist', ecm_ej(v_coach, 'Seated Hip Twist', 'Giro de cadera sentado', 'core', 'core', 'core', array['peso_corporal']::text[], true));
  insert into _ecm_ej values ('Plate Russian Twist', ecm_ej(v_coach, 'Plate Russian Twist', 'Giro ruso con disco', 'core', 'core', 'core', array['disco']::text[], true));
  insert into _ecm_ej values ('Hinge to T-Rotation', ecm_ej(v_coach, 'Hinge to T-Rotation', 'Bisagra con rotación en T', 'movilidad', 'full_body', null, array['peso_corporal']::text[], true));
  insert into _ecm_ej values ('Quadruped Scapular Push Up', ecm_ej(v_coach, 'Quadruped Scapular Push Up', 'Flexión escapular en cuadrupedia', 'movilidad', 'tren_superior', 'push', array['peso_corporal']::text[], false));
  insert into _ecm_ej values ('Trunk Rotation', ecm_ej(v_coach, 'Trunk Rotation', 'Rotación de tronco', 'movilidad', 'core', null, array['peso_corporal']::text[], true));
  insert into _ecm_ej values ('Dumbbell Clean to Press', ecm_ej(v_coach, 'Dumbbell Clean to Press', 'Cargada y press con mancuernas', 'potencia', 'full_body', 'push', array['mancuerna']::text[], false));
  insert into _ecm_ej values ('Dumbbell Burpee with Curl to Press', ecm_ej(v_coach, 'Dumbbell Burpee with Curl to Press', 'Burpee con curl y press', 'pliometrico', 'full_body', null, array['mancuerna']::text[], false));
  insert into _ecm_ej values ('SuperBand Anchored Tricep Pushdown', ecm_ej(v_coach, 'SuperBand Anchored Tricep Pushdown', 'Extensión de tríceps con banda anclada', 'fuerza', 'tren_superior', 'push', array['banda']::text[], false));
  insert into _ecm_ej values ('EZ Bar Preacher Curl', ecm_ej(v_coach, 'EZ Bar Preacher Curl', 'Curl predicador con barra Z', 'fuerza', 'tren_superior', 'pull', array['barra']::text[], false));
  insert into _ecm_ej values ('Plate Weighted Dip', ecm_ej(v_coach, 'Plate Weighted Dip', 'Fondos lastrados', 'fuerza', 'tren_superior', 'push', array['peso_corporal','disco']::text[], false));
  insert into _ecm_ej values ('Dumbbell Seated Overhead Tricep Extension', ecm_ej(v_coach, 'Dumbbell Seated Overhead Tricep Extension', 'Extensión de tríceps sobre la cabeza sentado', 'fuerza', 'tren_superior', 'push', array['mancuerna','banco']::text[], false));
  insert into _ecm_ej values ('Half Lord of the Fishes', ecm_ej(v_coach, 'Half Lord of the Fishes', 'Torsión sentada (media torsión espinal)', 'estiramiento_pasivo', 'core', null, array['peso_corporal']::text[], true));
  raise notice 'Catálogo listo: % ejercicios disponibles.', (select count(*) from _ecm_ej);
end $cat$;

-- ─────────────────────────────────────────────────────────────────────
-- ANDREA ANGULO · Cycle 8 · 5 semanas (2026-08-24 → 2026-09-27)
-- ─────────────────────────────────────────────────────────────────────
do $cli$
declare v_coach uuid; v_cli uuid; v_fase uuid; v_rut uuid; v_blo uuid; v_ses uuid; v_n int;
begin
  select id, user_id into v_cli, v_coach from clientes where nombre ilike '%andrea%angulo%' limit 1;
  if v_cli is null then
    raise warning 'SALTADO: no encuentro a «Andrea Angulo» en `clientes` (patrón %%andrea%%angulo%%). Corrige el nombre y vuelve a correr.';
    return;
  end if;
  if exists (select 1 from fases where cliente_id = v_cli and nombre = 'Cycle 8') then
    raise notice 'SALTADO: «Andrea Angulo» ya tiene la fase Cycle 8 cargada.';
    return;
  end if;

  insert into fases (user_id, cliente_id, nombre, objetivo, notas_coach, semanas,
                     fecha_inicio, orden, estado)
  values (v_coach, v_cli, 'Cycle 8',
          'Bloque importado de Trainerize — la rutina que ya venía haciendo.',
          'Importado el 2026-09-20 desde el PDF de Trainerize (Cycle 8, 2026-08-24 a 2026-09-27). Revisar antes de enviar al cliente.',
          5, date '2026-08-24',
          coalesce((select max(orden)+1 from fases where cliente_id = v_cli), 1), 'borrador')
  returning id into v_fase;

  -- Rutina 1: Lower Body + Core Training
  insert into rutinas (user_id, cliente_id, fase_id, nombre, dia_orden,
                       duracion_estimada_min, tipo_sesion)
  values (v_coach, v_cli, v_fase, 'Lower Body + Core Training', 1, 62, 'fuerza')
  returning id into v_rut;
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'A', 'circuito', 2, 30, 1)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Bodyweight Alternating Cossack Squat'), 1, 1, '5 por lado', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='90-90 Hip Switch'), 2, 1, '5 por lado', 30);
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'B', 'superserie', 1, 35, 2)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Lateral Shuttle Run'), 3, 1, '60 s', 35);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Jump Squat to Reverse Lunge'), 4, 1, '6-8', 35);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Dumbbell Front Squat'), 5, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Mini Band Wall Sit with Abductions'), 6, 3, '5-30 s', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Dumbbell Straight Leg Deadlift'), 7, 4, '6-12', 45);
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'C', 'superserie', 1, 35, 3)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Lateral Shuttle Run'), 8, 1, '60 s', 35);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Jump Squat to Reverse Lunge'), 9, 1, '6-8', 35);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Plate Hip Thrust'), 10, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Mini Band Side Lying Hip Abduction'), 11, 3, '6-12 por lado', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Dumbbell Single Leg Calf Raise'), 12, 3, '6-8 por lado', 45);
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'D', 'circuito', 3, 30, 4)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Bench Knee Tuck to V Up'), 13, 1, '15', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Bicycle Crunch'), 14, 1, '15', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='High Plank Jacks'), 15, 1, '15', 30);
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'E', 'superserie', 1, 35, 5)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Lateral Shuttle Run'), 16, 1, '60 s', 35);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Jump Squat to Reverse Lunge'), 17, 1, '6-8', 35);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Static Pigeon Stretch'), 18, 1, '30 s por lado', null);
  -- historial 2026-09-15
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-15', 4,
          '2026-W38', 'completada', '2026-09-15 12:00:00+00'::timestamptz, true)
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Front Squat') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Front Squat'), 1, 12, 7, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Front Squat') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Front Squat'), 2, 12, 7, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Front Squat') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Front Squat'), 3, 12, 7, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Front Squat') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Front Squat'), 4, 12, 7, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Wall Sit with Abductions') limit 1),
            (select id from _ecm_ej where alias='Mini Band Wall Sit with Abductions'), 1, 20, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Wall Sit with Abductions') limit 1),
            (select id from _ecm_ej where alias='Mini Band Wall Sit with Abductions'), 2, 20, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Wall Sit with Abductions') limit 1),
            (select id from _ecm_ej where alias='Mini Band Wall Sit with Abductions'), 3, 20, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Straight Leg Deadlift') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Straight Leg Deadlift'), 1, 15, 9, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Straight Leg Deadlift') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Straight Leg Deadlift'), 2, 15, 9, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Straight Leg Deadlift') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Straight Leg Deadlift'), 3, 15, 9, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Straight Leg Deadlift') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Straight Leg Deadlift'), 4, 15, 9, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Hip Thrust') limit 1),
            (select id from _ecm_ej where alias='Plate Hip Thrust'), 1, 15, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Hip Thrust') limit 1),
            (select id from _ecm_ej where alias='Plate Hip Thrust'), 2, 15, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Hip Thrust') limit 1),
            (select id from _ecm_ej where alias='Plate Hip Thrust'), 3, 15, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Hip Thrust') limit 1),
            (select id from _ecm_ej where alias='Plate Hip Thrust'), 4, 15, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Side Lying Hip Abduction') limit 1),
            (select id from _ecm_ej where alias='Mini Band Side Lying Hip Abduction'), 1, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Side Lying Hip Abduction') limit 1),
            (select id from _ecm_ej where alias='Mini Band Side Lying Hip Abduction'), 2, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Side Lying Hip Abduction') limit 1),
            (select id from _ecm_ej where alias='Mini Band Side Lying Hip Abduction'), 3, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Single Leg Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Single Leg Calf Raise'), 1, 12, 2, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Single Leg Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Single Leg Calf Raise'), 2, 12, 2, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Single Leg Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Single Leg Calf Raise'), 3, 12, 2, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Bicycle Crunch') limit 1),
            (select id from _ecm_ej where alias='Bicycle Crunch'), 1, 40, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Bicycle Crunch') limit 1),
            (select id from _ecm_ej where alias='Bicycle Crunch'), 2, 40, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Bicycle Crunch') limit 1),
            (select id from _ecm_ej where alias='Bicycle Crunch'), 3, 40, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='High Plank Jacks') limit 1),
            (select id from _ecm_ej where alias='High Plank Jacks'), 1, 30, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='High Plank Jacks') limit 1),
            (select id from _ecm_ej where alias='High Plank Jacks'), 2, 30, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='High Plank Jacks') limit 1),
            (select id from _ecm_ej where alias='High Plank Jacks'), 3, 30, null, 'kg');
  end if;
  -- historial 2026-09-10
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-10', 3,
          '2026-W37', 'completada', '2026-09-10 12:00:00+00'::timestamptz, true)
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Front Squat') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Front Squat'), 1, 12, 7, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Front Squat') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Front Squat'), 2, 12, 7, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Front Squat') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Front Squat'), 3, 12, 7, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Front Squat') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Front Squat'), 4, 12, 7, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Wall Sit with Abductions') limit 1),
            (select id from _ecm_ej where alias='Mini Band Wall Sit with Abductions'), 1, 20, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Wall Sit with Abductions') limit 1),
            (select id from _ecm_ej where alias='Mini Band Wall Sit with Abductions'), 2, 20, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Wall Sit with Abductions') limit 1),
            (select id from _ecm_ej where alias='Mini Band Wall Sit with Abductions'), 3, 20, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Straight Leg Deadlift') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Straight Leg Deadlift'), 1, 15, 9, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Straight Leg Deadlift') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Straight Leg Deadlift'), 2, 15, 9, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Straight Leg Deadlift') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Straight Leg Deadlift'), 3, 15, 9, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Straight Leg Deadlift') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Straight Leg Deadlift'), 4, 15, 9, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Hip Thrust') limit 1),
            (select id from _ecm_ej where alias='Plate Hip Thrust'), 1, 15, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Hip Thrust') limit 1),
            (select id from _ecm_ej where alias='Plate Hip Thrust'), 2, 15, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Hip Thrust') limit 1),
            (select id from _ecm_ej where alias='Plate Hip Thrust'), 3, 15, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Hip Thrust') limit 1),
            (select id from _ecm_ej where alias='Plate Hip Thrust'), 4, 15, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Side Lying Hip Abduction') limit 1),
            (select id from _ecm_ej where alias='Mini Band Side Lying Hip Abduction'), 1, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Side Lying Hip Abduction') limit 1),
            (select id from _ecm_ej where alias='Mini Band Side Lying Hip Abduction'), 2, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Side Lying Hip Abduction') limit 1),
            (select id from _ecm_ej where alias='Mini Band Side Lying Hip Abduction'), 3, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Single Leg Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Single Leg Calf Raise'), 1, 12, 2, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Single Leg Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Single Leg Calf Raise'), 2, 12, 2, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Single Leg Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Single Leg Calf Raise'), 3, 12, 2, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Bicycle Crunch') limit 1),
            (select id from _ecm_ej where alias='Bicycle Crunch'), 1, 40, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Bicycle Crunch') limit 1),
            (select id from _ecm_ej where alias='Bicycle Crunch'), 2, 40, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Bicycle Crunch') limit 1),
            (select id from _ecm_ej where alias='Bicycle Crunch'), 3, 40, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='High Plank Jacks') limit 1),
            (select id from _ecm_ej where alias='High Plank Jacks'), 1, 30, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='High Plank Jacks') limit 1),
            (select id from _ecm_ej where alias='High Plank Jacks'), 2, 30, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='High Plank Jacks') limit 1),
            (select id from _ecm_ej where alias='High Plank Jacks'), 3, 30, null, 'kg');
  end if;
  -- historial 2026-09-08
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-08', 3,
          '2026-W37', 'completada', '2026-09-08 12:00:00+00'::timestamptz, true)
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Front Squat') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Front Squat'), 1, 12, 7, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Front Squat') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Front Squat'), 2, 12, 7, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Front Squat') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Front Squat'), 3, 12, 7, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Front Squat') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Front Squat'), 4, 12, 7, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Wall Sit with Abductions') limit 1),
            (select id from _ecm_ej where alias='Mini Band Wall Sit with Abductions'), 1, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Wall Sit with Abductions') limit 1),
            (select id from _ecm_ej where alias='Mini Band Wall Sit with Abductions'), 2, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Wall Sit with Abductions') limit 1),
            (select id from _ecm_ej where alias='Mini Band Wall Sit with Abductions'), 3, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Straight Leg Deadlift') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Straight Leg Deadlift'), 1, 15, 9, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Straight Leg Deadlift') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Straight Leg Deadlift'), 2, 15, 9, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Straight Leg Deadlift') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Straight Leg Deadlift'), 3, 15, 9, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Straight Leg Deadlift') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Straight Leg Deadlift'), 4, 15, 9, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Hip Thrust') limit 1),
            (select id from _ecm_ej where alias='Plate Hip Thrust'), 1, 15, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Hip Thrust') limit 1),
            (select id from _ecm_ej where alias='Plate Hip Thrust'), 2, 15, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Hip Thrust') limit 1),
            (select id from _ecm_ej where alias='Plate Hip Thrust'), 3, 15, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Hip Thrust') limit 1),
            (select id from _ecm_ej where alias='Plate Hip Thrust'), 4, 15, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Side Lying Hip Abduction') limit 1),
            (select id from _ecm_ej where alias='Mini Band Side Lying Hip Abduction'), 1, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Side Lying Hip Abduction') limit 1),
            (select id from _ecm_ej where alias='Mini Band Side Lying Hip Abduction'), 2, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Side Lying Hip Abduction') limit 1),
            (select id from _ecm_ej where alias='Mini Band Side Lying Hip Abduction'), 3, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Single Leg Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Single Leg Calf Raise'), 1, 12, 2, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Single Leg Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Single Leg Calf Raise'), 2, 12, 2, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Single Leg Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Single Leg Calf Raise'), 3, 12, 2, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Bicycle Crunch') limit 1),
            (select id from _ecm_ej where alias='Bicycle Crunch'), 1, 40, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Bicycle Crunch') limit 1),
            (select id from _ecm_ej where alias='Bicycle Crunch'), 2, 40, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Bicycle Crunch') limit 1),
            (select id from _ecm_ej where alias='Bicycle Crunch'), 3, 40, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='High Plank Jacks') limit 1),
            (select id from _ecm_ej where alias='High Plank Jacks'), 1, 30, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='High Plank Jacks') limit 1),
            (select id from _ecm_ej where alias='High Plank Jacks'), 2, 30, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='High Plank Jacks') limit 1),
            (select id from _ecm_ej where alias='High Plank Jacks'), 3, 30, null, 'kg');
  end if;
  -- historial 2026-09-03
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-03', 2,
          '2026-W36', 'completada', '2026-09-03 12:00:00+00'::timestamptz, true)
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Front Squat') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Front Squat'), 1, 12, 7, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Front Squat') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Front Squat'), 2, 12, 7, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Front Squat') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Front Squat'), 3, 12, 7, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Front Squat') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Front Squat'), 4, 12, 7, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Wall Sit with Abductions') limit 1),
            (select id from _ecm_ej where alias='Mini Band Wall Sit with Abductions'), 1, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Wall Sit with Abductions') limit 1),
            (select id from _ecm_ej where alias='Mini Band Wall Sit with Abductions'), 2, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Wall Sit with Abductions') limit 1),
            (select id from _ecm_ej where alias='Mini Band Wall Sit with Abductions'), 3, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Straight Leg Deadlift') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Straight Leg Deadlift'), 1, 15, 9, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Straight Leg Deadlift') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Straight Leg Deadlift'), 2, 15, 9, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Straight Leg Deadlift') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Straight Leg Deadlift'), 3, 15, 9, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Straight Leg Deadlift') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Straight Leg Deadlift'), 4, 15, 9, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Hip Thrust') limit 1),
            (select id from _ecm_ej where alias='Plate Hip Thrust'), 1, 15, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Hip Thrust') limit 1),
            (select id from _ecm_ej where alias='Plate Hip Thrust'), 2, 15, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Hip Thrust') limit 1),
            (select id from _ecm_ej where alias='Plate Hip Thrust'), 3, 15, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Hip Thrust') limit 1),
            (select id from _ecm_ej where alias='Plate Hip Thrust'), 4, 15, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Side Lying Hip Abduction') limit 1),
            (select id from _ecm_ej where alias='Mini Band Side Lying Hip Abduction'), 1, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Side Lying Hip Abduction') limit 1),
            (select id from _ecm_ej where alias='Mini Band Side Lying Hip Abduction'), 2, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Side Lying Hip Abduction') limit 1),
            (select id from _ecm_ej where alias='Mini Band Side Lying Hip Abduction'), 3, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Single Leg Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Single Leg Calf Raise'), 1, 12, 2, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Single Leg Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Single Leg Calf Raise'), 2, 12, 2, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Single Leg Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Single Leg Calf Raise'), 3, 12, 2, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Bicycle Crunch') limit 1),
            (select id from _ecm_ej where alias='Bicycle Crunch'), 1, 40, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Bicycle Crunch') limit 1),
            (select id from _ecm_ej where alias='Bicycle Crunch'), 2, 40, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Bicycle Crunch') limit 1),
            (select id from _ecm_ej where alias='Bicycle Crunch'), 3, 40, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='High Plank Jacks') limit 1),
            (select id from _ecm_ej where alias='High Plank Jacks'), 1, 30, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='High Plank Jacks') limit 1),
            (select id from _ecm_ej where alias='High Plank Jacks'), 2, 30, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='High Plank Jacks') limit 1),
            (select id from _ecm_ej where alias='High Plank Jacks'), 3, 30, null, 'kg');
  end if;
  -- historial 2026-09-01
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-01', 2,
          '2026-W36', 'completada', '2026-09-01 12:00:00+00'::timestamptz, true)
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Front Squat') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Front Squat'), 1, 12, 7, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Front Squat') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Front Squat'), 2, 12, 7, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Front Squat') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Front Squat'), 3, 12, 7, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Front Squat') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Front Squat'), 4, 12, 7, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Wall Sit with Abductions') limit 1),
            (select id from _ecm_ej where alias='Mini Band Wall Sit with Abductions'), 1, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Wall Sit with Abductions') limit 1),
            (select id from _ecm_ej where alias='Mini Band Wall Sit with Abductions'), 2, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Wall Sit with Abductions') limit 1),
            (select id from _ecm_ej where alias='Mini Band Wall Sit with Abductions'), 3, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Straight Leg Deadlift') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Straight Leg Deadlift'), 1, 15, 9, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Straight Leg Deadlift') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Straight Leg Deadlift'), 2, 15, 9, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Straight Leg Deadlift') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Straight Leg Deadlift'), 3, 15, 9, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Straight Leg Deadlift') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Straight Leg Deadlift'), 4, 15, 9, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Hip Thrust') limit 1),
            (select id from _ecm_ej where alias='Plate Hip Thrust'), 1, 15, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Hip Thrust') limit 1),
            (select id from _ecm_ej where alias='Plate Hip Thrust'), 2, 15, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Hip Thrust') limit 1),
            (select id from _ecm_ej where alias='Plate Hip Thrust'), 3, 15, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Hip Thrust') limit 1),
            (select id from _ecm_ej where alias='Plate Hip Thrust'), 4, 15, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Side Lying Hip Abduction') limit 1),
            (select id from _ecm_ej where alias='Mini Band Side Lying Hip Abduction'), 1, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Side Lying Hip Abduction') limit 1),
            (select id from _ecm_ej where alias='Mini Band Side Lying Hip Abduction'), 2, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Side Lying Hip Abduction') limit 1),
            (select id from _ecm_ej where alias='Mini Band Side Lying Hip Abduction'), 3, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Single Leg Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Single Leg Calf Raise'), 1, 12, 2, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Single Leg Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Single Leg Calf Raise'), 2, 12, 2, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Single Leg Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Single Leg Calf Raise'), 3, 12, 2, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Bicycle Crunch') limit 1),
            (select id from _ecm_ej where alias='Bicycle Crunch'), 1, 40, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Bicycle Crunch') limit 1),
            (select id from _ecm_ej where alias='Bicycle Crunch'), 2, 40, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Bicycle Crunch') limit 1),
            (select id from _ecm_ej where alias='Bicycle Crunch'), 3, 40, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='High Plank Jacks') limit 1),
            (select id from _ecm_ej where alias='High Plank Jacks'), 1, 30, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='High Plank Jacks') limit 1),
            (select id from _ecm_ej where alias='High Plank Jacks'), 2, 30, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='High Plank Jacks') limit 1),
            (select id from _ecm_ej where alias='High Plank Jacks'), 3, 30, null, 'kg');
  end if;

  -- Rutina 2: Upper Body Training
  insert into rutinas (user_id, cliente_id, fase_id, nombre, dia_orden,
                       duracion_estimada_min, tipo_sesion)
  values (v_coach, v_cli, v_fase, 'Upper Body Training', 2, 47, 'fuerza')
  returning id into v_rut;
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'A', 'circuito', 2, 35, 1)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Bodyweight Spiderman Lunge To Rotation'), 1, 1, '5 por lado', 35);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Mini Band Standing I''s'), 2, 1, '6-8', 35);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Dumbbell Standing Shoulder External Rotations'), 3, 1, '5', 35);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Bench Plank Single Arm Row'), 4, 4, '6-12 por lado', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Dumbbell Bench Press'), 5, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Cable Lateral Raise'), 6, 4, '6-12 por lado', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Cable Bicep Curl'), 7, 3, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 8, 3, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Child''s Pose'), 9, 1, '30 s', null);
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'B', 'superserie', 1, 35, 2)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Dumbbell Burpee Clean to Press'), 10, 1, '8-15', 35);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Lateral Shuttle Run'), 11, 1, '60 s', 35);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Cable V-Bar Overhead Tricep Extension'), 12, 3, '6-12', 45);
  -- historial 2026-09-16
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-16', 4,
          '2026-W38', 'completada', '2026-09-16 12:00:00+00'::timestamptz, true)
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Standing I''s') limit 1),
            (select id from _ecm_ej where alias='Mini Band Standing I''s'), 1, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Standing I''s') limit 1),
            (select id from _ecm_ej where alias='Mini Band Standing I''s'), 2, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Standing Shoulder External Rotations') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Standing Shoulder External Rotations'), 1, 20, 2, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Standing Shoulder External Rotations') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Standing Shoulder External Rotations'), 2, 20, 2, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Bench Plank Single Arm Row') limit 1),
            (select id from _ecm_ej where alias='Bench Plank Single Arm Row'), 1, 12, 7, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Bench Plank Single Arm Row') limit 1),
            (select id from _ecm_ej where alias='Bench Plank Single Arm Row'), 2, 12, 7, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Bench Plank Single Arm Row') limit 1),
            (select id from _ecm_ej where alias='Bench Plank Single Arm Row'), 3, 12, 7, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Bench Plank Single Arm Row') limit 1),
            (select id from _ecm_ej where alias='Bench Plank Single Arm Row'), 4, 12, 7, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Bench Press'), 1, 15, 7, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Bench Press'), 2, 15, 7, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Bench Press'), 3, 15, 7, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Bench Press'), 4, 15, 7, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Lateral Raise') limit 1),
            (select id from _ecm_ej where alias='Cable Lateral Raise'), 1, 12, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Lateral Raise') limit 1),
            (select id from _ecm_ej where alias='Cable Lateral Raise'), 2, 12, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Lateral Raise') limit 1),
            (select id from _ecm_ej where alias='Cable Lateral Raise'), 3, 12, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Lateral Raise') limit 1),
            (select id from _ecm_ej where alias='Cable Lateral Raise'), 4, 12, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Bicep Curl') limit 1),
            (select id from _ecm_ej where alias='Cable Bicep Curl'), 1, 12, 6, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Bicep Curl') limit 1),
            (select id from _ecm_ej where alias='Cable Bicep Curl'), 2, 12, 6, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Bicep Curl') limit 1),
            (select id from _ecm_ej where alias='Cable Bicep Curl'), 3, 12, 6, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 1, 12, 6, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 2, 12, 6, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 3, 12, 6, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Burpee Clean to Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Burpee Clean to Press'), 1, 12, 6, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V-Bar Overhead Tricep Extension') limit 1),
            (select id from _ecm_ej where alias='Cable V-Bar Overhead Tricep Extension'), 1, 15, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V-Bar Overhead Tricep Extension') limit 1),
            (select id from _ecm_ej where alias='Cable V-Bar Overhead Tricep Extension'), 2, 15, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V-Bar Overhead Tricep Extension') limit 1),
            (select id from _ecm_ej where alias='Cable V-Bar Overhead Tricep Extension'), 3, 15, 15, 'kg');
  end if;
  -- historial 2026-09-14
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-14', 4,
          '2026-W38', 'completada', '2026-09-14 12:00:00+00'::timestamptz, true)
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Standing I''s') limit 1),
            (select id from _ecm_ej where alias='Mini Band Standing I''s'), 1, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Standing I''s') limit 1),
            (select id from _ecm_ej where alias='Mini Band Standing I''s'), 2, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Standing Shoulder External Rotations') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Standing Shoulder External Rotations'), 1, 20, 2, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Standing Shoulder External Rotations') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Standing Shoulder External Rotations'), 2, 20, 2, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Bench Plank Single Arm Row') limit 1),
            (select id from _ecm_ej where alias='Bench Plank Single Arm Row'), 1, 12, 7, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Bench Plank Single Arm Row') limit 1),
            (select id from _ecm_ej where alias='Bench Plank Single Arm Row'), 2, 12, 7, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Bench Plank Single Arm Row') limit 1),
            (select id from _ecm_ej where alias='Bench Plank Single Arm Row'), 3, 12, 7, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Bench Plank Single Arm Row') limit 1),
            (select id from _ecm_ej where alias='Bench Plank Single Arm Row'), 4, 12, 7, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Bench Press'), 1, 15, 7, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Bench Press'), 2, 15, 7, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Bench Press'), 3, 15, 7, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Bench Press'), 4, 15, 7, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Lateral Raise') limit 1),
            (select id from _ecm_ej where alias='Cable Lateral Raise'), 1, 12, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Lateral Raise') limit 1),
            (select id from _ecm_ej where alias='Cable Lateral Raise'), 2, 12, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Lateral Raise') limit 1),
            (select id from _ecm_ej where alias='Cable Lateral Raise'), 3, 12, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Lateral Raise') limit 1),
            (select id from _ecm_ej where alias='Cable Lateral Raise'), 4, 12, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Bicep Curl') limit 1),
            (select id from _ecm_ej where alias='Cable Bicep Curl'), 1, 12, 6, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Bicep Curl') limit 1),
            (select id from _ecm_ej where alias='Cable Bicep Curl'), 2, 12, 6, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Bicep Curl') limit 1),
            (select id from _ecm_ej where alias='Cable Bicep Curl'), 3, 12, 6, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 1, 12, 6, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 2, 12, 6, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 3, 12, 6, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Burpee Clean to Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Burpee Clean to Press'), 1, 12, 6, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V-Bar Overhead Tricep Extension') limit 1),
            (select id from _ecm_ej where alias='Cable V-Bar Overhead Tricep Extension'), 1, 15, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V-Bar Overhead Tricep Extension') limit 1),
            (select id from _ecm_ej where alias='Cable V-Bar Overhead Tricep Extension'), 2, 15, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V-Bar Overhead Tricep Extension') limit 1),
            (select id from _ecm_ej where alias='Cable V-Bar Overhead Tricep Extension'), 3, 15, 15, 'kg');
  end if;
  -- historial 2026-09-09
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-09', 3,
          '2026-W37', 'completada', '2026-09-09 12:00:00+00'::timestamptz, true)
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Standing I''s') limit 1),
            (select id from _ecm_ej where alias='Mini Band Standing I''s'), 1, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Standing I''s') limit 1),
            (select id from _ecm_ej where alias='Mini Band Standing I''s'), 2, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Standing Shoulder External Rotations') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Standing Shoulder External Rotations'), 1, 20, 2, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Standing Shoulder External Rotations') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Standing Shoulder External Rotations'), 2, 20, 2, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Bench Plank Single Arm Row') limit 1),
            (select id from _ecm_ej where alias='Bench Plank Single Arm Row'), 1, 12, 7, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Bench Plank Single Arm Row') limit 1),
            (select id from _ecm_ej where alias='Bench Plank Single Arm Row'), 2, 12, 7, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Bench Plank Single Arm Row') limit 1),
            (select id from _ecm_ej where alias='Bench Plank Single Arm Row'), 3, 12, 7, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Bench Plank Single Arm Row') limit 1),
            (select id from _ecm_ej where alias='Bench Plank Single Arm Row'), 4, 12, 7, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Bench Press'), 1, 15, 7, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Bench Press'), 2, 15, 7, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Bench Press'), 3, 15, 7, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Bench Press'), 4, 15, 7, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Lateral Raise') limit 1),
            (select id from _ecm_ej where alias='Cable Lateral Raise'), 1, 12, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Lateral Raise') limit 1),
            (select id from _ecm_ej where alias='Cable Lateral Raise'), 2, 12, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Lateral Raise') limit 1),
            (select id from _ecm_ej where alias='Cable Lateral Raise'), 3, 12, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Lateral Raise') limit 1),
            (select id from _ecm_ej where alias='Cable Lateral Raise'), 4, 12, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Bicep Curl') limit 1),
            (select id from _ecm_ej where alias='Cable Bicep Curl'), 1, 12, 6, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Bicep Curl') limit 1),
            (select id from _ecm_ej where alias='Cable Bicep Curl'), 2, 12, 6, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Bicep Curl') limit 1),
            (select id from _ecm_ej where alias='Cable Bicep Curl'), 3, 12, 6, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 1, 12, 6, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 2, 12, 6, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 3, 12, 6, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Burpee Clean to Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Burpee Clean to Press'), 1, 12, 6, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V-Bar Overhead Tricep Extension') limit 1),
            (select id from _ecm_ej where alias='Cable V-Bar Overhead Tricep Extension'), 1, 15, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V-Bar Overhead Tricep Extension') limit 1),
            (select id from _ecm_ej where alias='Cable V-Bar Overhead Tricep Extension'), 2, 15, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V-Bar Overhead Tricep Extension') limit 1),
            (select id from _ecm_ej where alias='Cable V-Bar Overhead Tricep Extension'), 3, 15, 15, 'kg');
  end if;
  -- historial 2026-09-07
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-07', 3,
          '2026-W37', 'completada', '2026-09-07 12:00:00+00'::timestamptz, true)
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Standing I''s') limit 1),
            (select id from _ecm_ej where alias='Mini Band Standing I''s'), 1, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Standing I''s') limit 1),
            (select id from _ecm_ej where alias='Mini Band Standing I''s'), 2, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Standing Shoulder External Rotations') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Standing Shoulder External Rotations'), 1, 20, 2, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Standing Shoulder External Rotations') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Standing Shoulder External Rotations'), 2, 20, 2, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Bench Plank Single Arm Row') limit 1),
            (select id from _ecm_ej where alias='Bench Plank Single Arm Row'), 1, 12, 7, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Bench Plank Single Arm Row') limit 1),
            (select id from _ecm_ej where alias='Bench Plank Single Arm Row'), 2, 12, 7, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Bench Plank Single Arm Row') limit 1),
            (select id from _ecm_ej where alias='Bench Plank Single Arm Row'), 3, 12, 7, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Bench Plank Single Arm Row') limit 1),
            (select id from _ecm_ej where alias='Bench Plank Single Arm Row'), 4, 12, 7, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Bench Press'), 1, 15, 7, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Bench Press'), 2, 15, 7, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Bench Press'), 3, 15, 7, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Bench Press'), 4, 15, 7, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Lateral Raise') limit 1),
            (select id from _ecm_ej where alias='Cable Lateral Raise'), 1, 12, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Lateral Raise') limit 1),
            (select id from _ecm_ej where alias='Cable Lateral Raise'), 2, 12, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Lateral Raise') limit 1),
            (select id from _ecm_ej where alias='Cable Lateral Raise'), 3, 12, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Lateral Raise') limit 1),
            (select id from _ecm_ej where alias='Cable Lateral Raise'), 4, 12, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Bicep Curl') limit 1),
            (select id from _ecm_ej where alias='Cable Bicep Curl'), 1, 12, 6, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Bicep Curl') limit 1),
            (select id from _ecm_ej where alias='Cable Bicep Curl'), 2, 12, 6, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Bicep Curl') limit 1),
            (select id from _ecm_ej where alias='Cable Bicep Curl'), 3, 12, 6, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 1, 12, 6, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 2, 12, 6, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 3, 12, 6, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Burpee Clean to Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Burpee Clean to Press'), 1, 12, 6, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V-Bar Overhead Tricep Extension') limit 1),
            (select id from _ecm_ej where alias='Cable V-Bar Overhead Tricep Extension'), 1, 12, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V-Bar Overhead Tricep Extension') limit 1),
            (select id from _ecm_ej where alias='Cable V-Bar Overhead Tricep Extension'), 2, 12, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V-Bar Overhead Tricep Extension') limit 1),
            (select id from _ecm_ej where alias='Cable V-Bar Overhead Tricep Extension'), 3, 12, 5, 'kg');
  end if;
  -- historial 2026-08-31
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-08-31', 2,
          '2026-W36', 'completada', '2026-08-31 12:00:00+00'::timestamptz, true)
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Standing I''s') limit 1),
            (select id from _ecm_ej where alias='Mini Band Standing I''s'), 1, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Standing I''s') limit 1),
            (select id from _ecm_ej where alias='Mini Band Standing I''s'), 2, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Standing Shoulder External Rotations') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Standing Shoulder External Rotations'), 1, 20, 2, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Standing Shoulder External Rotations') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Standing Shoulder External Rotations'), 2, 20, 2, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Bench Plank Single Arm Row') limit 1),
            (select id from _ecm_ej where alias='Bench Plank Single Arm Row'), 1, 12, 7, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Bench Plank Single Arm Row') limit 1),
            (select id from _ecm_ej where alias='Bench Plank Single Arm Row'), 2, 12, 7, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Bench Plank Single Arm Row') limit 1),
            (select id from _ecm_ej where alias='Bench Plank Single Arm Row'), 3, 12, 7, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Bench Plank Single Arm Row') limit 1),
            (select id from _ecm_ej where alias='Bench Plank Single Arm Row'), 4, 12, 7, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Bench Press'), 1, 15, 6, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Bench Press'), 2, 15, 6, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Bench Press'), 3, 15, 6, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Bench Press'), 4, 15, 6, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Lateral Raise') limit 1),
            (select id from _ecm_ej where alias='Cable Lateral Raise'), 1, 12, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Lateral Raise') limit 1),
            (select id from _ecm_ej where alias='Cable Lateral Raise'), 2, 12, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Lateral Raise') limit 1),
            (select id from _ecm_ej where alias='Cable Lateral Raise'), 3, 12, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Lateral Raise') limit 1),
            (select id from _ecm_ej where alias='Cable Lateral Raise'), 4, 12, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Bicep Curl') limit 1),
            (select id from _ecm_ej where alias='Cable Bicep Curl'), 1, 12, 6, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Bicep Curl') limit 1),
            (select id from _ecm_ej where alias='Cable Bicep Curl'), 2, 12, 6, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Bicep Curl') limit 1),
            (select id from _ecm_ej where alias='Cable Bicep Curl'), 3, 12, 6, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 1, 12, 6, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 2, 12, 6, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 3, 12, 6, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Burpee Clean to Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Burpee Clean to Press'), 1, 12, 6, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V-Bar Overhead Tricep Extension') limit 1),
            (select id from _ecm_ej where alias='Cable V-Bar Overhead Tricep Extension'), 1, 12, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V-Bar Overhead Tricep Extension') limit 1),
            (select id from _ecm_ej where alias='Cable V-Bar Overhead Tricep Extension'), 2, 12, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V-Bar Overhead Tricep Extension') limit 1),
            (select id from _ecm_ej where alias='Cable V-Bar Overhead Tricep Extension'), 3, 12, 15, 'kg');
  end if;

  select count(*) into v_n from rutinas where fase_id = v_fase;
  raise notice 'OK · Andrea Angulo: fase Cycle 8 con % rutinas y % series de historial.', v_n,
        (select count(*) from series_log sl join sesiones s on s.id = sl.sesion_id where s.fase_id = v_fase);
end $cli$;

-- ─────────────────────────────────────────────────────────────────────
-- AMAURI BARBOSA · Cycle 6 · 5 semanas (2026-09-14 → 2026-10-18)
-- ─────────────────────────────────────────────────────────────────────
do $cli$
declare v_coach uuid; v_cli uuid; v_fase uuid; v_rut uuid; v_blo uuid; v_ses uuid; v_n int;
begin
  select id, user_id into v_cli, v_coach from clientes where nombre ilike '%amauri%barbosa%' limit 1;
  if v_cli is null then
    raise warning 'SALTADO: no encuentro a «Amauri Barbosa» en `clientes` (patrón %%amauri%%barbosa%%). Corrige el nombre y vuelve a correr.';
    return;
  end if;
  if exists (select 1 from fases where cliente_id = v_cli and nombre = 'Cycle 6') then
    raise notice 'SALTADO: «Amauri Barbosa» ya tiene la fase Cycle 6 cargada.';
    return;
  end if;

  insert into fases (user_id, cliente_id, nombre, objetivo, notas_coach, semanas,
                     fecha_inicio, orden, estado)
  values (v_coach, v_cli, 'Cycle 6',
          'Bloque importado de Trainerize — la rutina que ya venía haciendo.',
          'Importado el 2026-09-20 desde el PDF de Trainerize (Cycle 6, 2026-09-14 a 2026-10-18). Revisar antes de enviar al cliente.',
          5, date '2026-09-14',
          coalesce((select max(orden)+1 from fases where cliente_id = v_cli), 1), 'borrador')
  returning id into v_fase;

  -- Rutina 1: Lower Body + Core Training
  insert into rutinas (user_id, cliente_id, fase_id, nombre, dia_orden,
                       duracion_estimada_min, tipo_sesion)
  values (v_coach, v_cli, v_fase, 'Lower Body + Core Training', 1, 62, 'fuerza')
  returning id into v_rut;
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'A', 'superserie', 1, 25, 1)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Bodyweight Squat To Hinge'), 1, 1, '5', 25);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Bodyweight Alternating Cossack Squat'), 2, 1, '5 por lado', 25);
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'B', 'circuito', 2, 35, 2)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='1/2 Kneel to Lateral Bound'), 3, 1, '10', 35);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Lateral Shuttle Run'), 4, 1, '60 s', 35);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Angled Machine Leg Press'), 5, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Machine Seated Leg Extension'), 6, 3, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Hip Thrust Machine'), 7, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Smith Machine Deadlift'), 8, 3, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Machine Seated Hip Adduction'), 9, 3, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Machine Seated Leg Curl'), 10, 3, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Machine Seated Calf Raise'), 11, 3, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Dip Machine Bent Leg Raise'), 12, 3, '8-15', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Ab Roller Wheel Abdominal Roll Out'), 13, 3, '8-15', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Pallof Press'), 14, 3, '6-12 por lado', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Static Pigeon Stretch'), 15, 1, '30 s por lado', null);
  -- historial 2026-09-17
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-17', 1,
          '2026-W38', 'completada', '2026-09-17 12:00:00+00'::timestamptz, true)
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Angled Machine Leg Press') limit 1),
            (select id from _ecm_ej where alias='Angled Machine Leg Press'), 1, 12, 90, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Angled Machine Leg Press') limit 1),
            (select id from _ecm_ej where alias='Angled Machine Leg Press'), 2, 12, 90, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Angled Machine Leg Press') limit 1),
            (select id from _ecm_ej where alias='Angled Machine Leg Press'), 3, 12, 90, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Angled Machine Leg Press') limit 1),
            (select id from _ecm_ej where alias='Angled Machine Leg Press'), 4, 12, 90, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Leg Extension') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Leg Extension'), 1, 10, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Leg Extension') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Leg Extension'), 2, 10, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Leg Extension') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Leg Extension'), 3, 10, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Hip Adduction') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Hip Adduction'), 1, 12, 70, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Hip Adduction') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Hip Adduction'), 2, 12, 70, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Hip Adduction') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Hip Adduction'), 3, 12, 70, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Calf Raise'), 1, 10, 57, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Calf Raise'), 2, 10, 57, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Calf Raise'), 3, 10, 57, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dip Machine Bent Leg Raise') limit 1),
            (select id from _ecm_ej where alias='Dip Machine Bent Leg Raise'), 1, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dip Machine Bent Leg Raise') limit 1),
            (select id from _ecm_ej where alias='Dip Machine Bent Leg Raise'), 2, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dip Machine Bent Leg Raise') limit 1),
            (select id from _ecm_ej where alias='Dip Machine Bent Leg Raise'), 3, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Ab Roller Wheel Abdominal Roll Out') limit 1),
            (select id from _ecm_ej where alias='Ab Roller Wheel Abdominal Roll Out'), 1, 10, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Ab Roller Wheel Abdominal Roll Out') limit 1),
            (select id from _ecm_ej where alias='Ab Roller Wheel Abdominal Roll Out'), 2, 10, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Ab Roller Wheel Abdominal Roll Out') limit 1),
            (select id from _ecm_ej where alias='Ab Roller Wheel Abdominal Roll Out'), 3, 10, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Pallof Press') limit 1),
            (select id from _ecm_ej where alias='Pallof Press'), 1, 10, 60, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Pallof Press') limit 1),
            (select id from _ecm_ej where alias='Pallof Press'), 2, 10, 60, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Pallof Press') limit 1),
            (select id from _ecm_ej where alias='Pallof Press'), 3, 10, 60, 'kg');
  end if;
  -- historial 2026-09-15
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-15', 1,
          '2026-W38', 'completada', '2026-09-15 12:00:00+00'::timestamptz, true)
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Hip Adduction') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Hip Adduction'), 1, 12, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Hip Adduction') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Hip Adduction'), 2, 12, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Hip Adduction') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Hip Adduction'), 3, 12, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Hip Adduction') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Hip Adduction'), 4, 12, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Calf Raise'), 1, 12, 57, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Calf Raise'), 2, 12, 57, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Calf Raise'), 3, 12, 57, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Calf Raise'), 4, 12, 57, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dip Machine Bent Leg Raise') limit 1),
            (select id from _ecm_ej where alias='Dip Machine Bent Leg Raise'), 1, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dip Machine Bent Leg Raise') limit 1),
            (select id from _ecm_ej where alias='Dip Machine Bent Leg Raise'), 2, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dip Machine Bent Leg Raise') limit 1),
            (select id from _ecm_ej where alias='Dip Machine Bent Leg Raise'), 3, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Squat Jump') limit 1),
            (select id from _ecm_ej where alias='Squat Jump'), 1, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Smith Machine Back Squat') limit 1),
            (select id from _ecm_ej where alias='Smith Machine Back Squat'), 1, 10, 35, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Smith Machine Back Squat') limit 1),
            (select id from _ecm_ej where alias='Smith Machine Back Squat'), 2, 10, 35, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Smith Machine Back Squat') limit 1),
            (select id from _ecm_ej where alias='Smith Machine Back Squat'), 3, 10, 35, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Smith Machine Back Squat') limit 1),
            (select id from _ecm_ej where alias='Smith Machine Back Squat'), 4, 10, 35, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Landmine RDL') limit 1),
            (select id from _ecm_ej where alias='Landmine RDL'), 1, 10, 35, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Landmine RDL') limit 1),
            (select id from _ecm_ej where alias='Landmine RDL'), 2, 10, 45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Landmine RDL') limit 1),
            (select id from _ecm_ej where alias='Landmine RDL'), 3, 10, 45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Landmine RDL') limit 1),
            (select id from _ecm_ej where alias='Landmine RDL'), 4, 10, 45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Bicycle Crunch') limit 1),
            (select id from _ecm_ej where alias='Bicycle Crunch'), 1, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Bicycle Crunch') limit 1),
            (select id from _ecm_ej where alias='Bicycle Crunch'), 2, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Bicycle Crunch') limit 1),
            (select id from _ecm_ej where alias='Bicycle Crunch'), 3, 15, null, 'kg');
  end if;

  -- Rutina 2: Upper Body Training
  insert into rutinas (user_id, cliente_id, fase_id, nombre, dia_orden,
                       duracion_estimada_min, tipo_sesion)
  values (v_coach, v_cli, v_fase, 'Upper Body Training', 2, 67, 'fuerza')
  returning id into v_rut;
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'A', 'superserie', 1, 30, 1)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Bodyweight Spiderman Lunge To Rotation'), 1, 1, '5 por lado', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Dumbbell External Rotation on Side'), 2, 1, '5 por lado', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Bar Hang'), 3, 1, '40 s', 30);
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'B', 'circuito', 2, 30, 2)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Shuttle Run'), 4, 1, '60 s', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Dumbbell Burpee Clean to Press'), 5, 1, '8-15', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 6, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Machine Assisted Wide Grip Pull Up'), 7, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Machine Seated Shoulder Press'), 8, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Cable Seated Wide Grip Row'), 9, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Cable Standing Crossover Chest Fly'), 10, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Machine Lateral Raise'), 11, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Barbell Preacher Curl'), 12, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 13, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown'), 14, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Child''s Pose'), 15, 1, '30 s', null);
  -- historial 2026-09-16
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-16', 1,
          '2026-W38', 'completada', '2026-09-16 12:00:00+00'::timestamptz, true)
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell External Rotation on Side') limit 1),
            (select id from _ecm_ej where alias='Dumbbell External Rotation on Side'), 1, 10, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Bar Hang') limit 1),
            (select id from _ecm_ej where alias='Bar Hang'), 1, 1200, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Burpee Clean to Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Burpee Clean to Press'), 1, 10, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 1, 10, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 2, 10, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 3, 10, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 4, 10, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Shoulder Press') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Shoulder Press'), 1, 10, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Shoulder Press') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Shoulder Press'), 2, 10, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Shoulder Press') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Shoulder Press'), 3, 10, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Seated Wide Grip Row') limit 1),
            (select id from _ecm_ej where alias='Cable Seated Wide Grip Row'), 1, 10, 70, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Seated Wide Grip Row') limit 1),
            (select id from _ecm_ej where alias='Cable Seated Wide Grip Row'), 2, 10, 70, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Seated Wide Grip Row') limit 1),
            (select id from _ecm_ej where alias='Cable Seated Wide Grip Row'), 3, 10, 70, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Barbell Preacher Curl') limit 1),
            (select id from _ecm_ej where alias='Barbell Preacher Curl'), 1, 10, 35, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Barbell Preacher Curl') limit 1),
            (select id from _ecm_ej where alias='Barbell Preacher Curl'), 2, 10, 35, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Barbell Preacher Curl') limit 1),
            (select id from _ecm_ej where alias='Barbell Preacher Curl'), 3, 10, 35, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 1, 10, 17.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 2, 10, 17.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 3, 10, 17.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown'), 1, 10, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown'), 2, 10, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown'), 3, 10, 40, 'kg');
  end if;
  -- historial 2026-09-14
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-14', 1,
          '2026-W38', 'completada', '2026-09-14 12:00:00+00'::timestamptz, true)
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell External Rotation on Side') limit 1),
            (select id from _ecm_ej where alias='Dumbbell External Rotation on Side'), 1, 10, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Bar Hang') limit 1),
            (select id from _ecm_ej where alias='Bar Hang'), 1, 1200, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Burpee Clean to Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Burpee Clean to Press'), 1, 10, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Burpee Clean to Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Burpee Clean to Press'), 2, 10, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 1, 10, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 2, 10, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 3, 10, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Shoulder Press') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Shoulder Press'), 1, 10, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Shoulder Press') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Shoulder Press'), 2, 10, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Shoulder Press') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Shoulder Press'), 3, 10, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Seated Wide Grip Row') limit 1),
            (select id from _ecm_ej where alias='Cable Seated Wide Grip Row'), 1, 10, 70, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Seated Wide Grip Row') limit 1),
            (select id from _ecm_ej where alias='Cable Seated Wide Grip Row'), 2, 10, 70, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Seated Wide Grip Row') limit 1),
            (select id from _ecm_ej where alias='Cable Seated Wide Grip Row'), 3, 10, 70, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Lateral Raise') limit 1),
            (select id from _ecm_ej where alias='Machine Lateral Raise'), 1, 10, 35, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Lateral Raise') limit 1),
            (select id from _ecm_ej where alias='Machine Lateral Raise'), 2, 10, 35, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Lateral Raise') limit 1),
            (select id from _ecm_ej where alias='Machine Lateral Raise'), 3, 10, 35, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 1, 10, 17.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 2, 10, 17.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 3, 10, 17.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown'), 1, 10, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown'), 2, 10, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown'), 3, 10, 40, 'kg');
  end if;

  select count(*) into v_n from rutinas where fase_id = v_fase;
  raise notice 'OK · Amauri Barbosa: fase Cycle 6 con % rutinas y % series de historial.', v_n,
        (select count(*) from series_log sl join sesiones s on s.id = sl.sesion_id where s.fase_id = v_fase);
end $cli$;

-- ─────────────────────────────────────────────────────────────────────
-- AMALIA RODRÍGUEZ · Cycle 4 · 5 semanas (2026-09-07 → 2026-10-11)
-- ─────────────────────────────────────────────────────────────────────
do $cli$
declare v_coach uuid; v_cli uuid; v_fase uuid; v_rut uuid; v_blo uuid; v_ses uuid; v_n int;
begin
  select id, user_id into v_cli, v_coach from clientes where nombre ilike '%amalia%rodr%guez%' limit 1;
  if v_cli is null then
    raise warning 'SALTADO: no encuentro a «Amalia Rodríguez» en `clientes` (patrón %%amalia%%rodr%%guez%%). Corrige el nombre y vuelve a correr.';
    return;
  end if;
  if exists (select 1 from fases where cliente_id = v_cli and nombre = 'Cycle 4') then
    raise notice 'SALTADO: «Amalia Rodríguez» ya tiene la fase Cycle 4 cargada.';
    return;
  end if;

  insert into fases (user_id, cliente_id, nombre, objetivo, notas_coach, semanas,
                     fecha_inicio, orden, estado)
  values (v_coach, v_cli, 'Cycle 4',
          'Bloque importado de Trainerize — la rutina que ya venía haciendo.',
          'Importado el 2026-09-20 desde el PDF de Trainerize (Cycle 4, 2026-09-07 a 2026-10-11). Revisar antes de enviar al cliente.',
          5, date '2026-09-07',
          coalesce((select max(orden)+1 from fases where cliente_id = v_cli), 1), 'borrador')
  returning id into v_fase;

  -- Rutina 1: Full Body
  insert into rutinas (user_id, cliente_id, fase_id, nombre, dia_orden,
                       duracion_estimada_min, tipo_sesion)
  values (v_coach, v_cli, v_fase, 'Full Body', 1, 51, 'fuerza')
  returning id into v_rut;
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'A', 'superserie', 1, 35, 1)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Dynamic Hip Opening Flow'), 1, 1, '10 por lado', 35);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Mini Band Wall Slides'), 2, 1, '10', 35);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Bodyweight Alternating Cossack Squat'), 3, 1, '8 por lado', 35);
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'B', 'circuito', 2, 40, 2)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Half Burpee with Dumbbell'), 4, 1, '8-10', 40);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Lateral Shuttle Run'), 5, 1, '60 s', 40);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Machine Seated Chest Press'), 6, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Wide Grip Lat Pulldown'), 7, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Dumbbell Bulgarian Split Squat'), 8, 3, '6-12 por lado', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Hip Thrust Machine'), 9, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Cable Bicep Curl'), 10, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown'), 11, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Dip Machine Bent Leg Raise'), 12, 3, '15', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Pallof Press'), 13, 3, '15', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Child''s Pose'), 14, 1, '30 s', null);

  -- Rutina 2: Lower Body + Core Training
  insert into rutinas (user_id, cliente_id, fase_id, nombre, dia_orden,
                       duracion_estimada_min, tipo_sesion)
  values (v_coach, v_cli, v_fase, 'Lower Body + Core Training', 2, 63, 'fuerza')
  returning id into v_rut;
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'A', 'circuito', 2, 30, 1)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Alternating Spiderman lunge to hip lift'), 1, 1, '5 por lado', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Glute Side Circle'), 2, 1, '5 por lado', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Bodyweight Alternating Cossack Squat'), 3, 1, '5 por lado', 30);
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'B', 'circuito', 2, 30, 2)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Broad Jump'), 4, 1, '10 saltos', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Lateral Shuttle Run'), 5, 1, '60 s', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Dumbbell Bulgarian Split Squat'), 6, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Cable Glute Crossover Kickback'), 7, 4, '6-12 por lado', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Machine Seated Leg Curl'), 8, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Machine Seated Leg Extension'), 9, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Machine Seated Hip Adduction'), 10, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Machine Seated Calf Raise'), 11, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Dip Machine Bent Leg Raise'), 12, 3, '15', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Seated Machine Ab Crunch'), 13, 3, '15', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Pallof Press'), 14, 3, '15', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Static Pigeon Stretch'), 15, 1, '30 s por lado', null);

  -- Rutina 3: Upper Body Training
  insert into rutinas (user_id, cliente_id, fase_id, nombre, dia_orden,
                       duracion_estimada_min, tipo_sesion)
  values (v_coach, v_cli, v_fase, 'Upper Body Training', 3, 65, 'fuerza')
  returning id into v_rut;
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'A', 'circuito', 2, 30, 1)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Dynamic Hip Opening Flow'), 1, 1, '5 por lado', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Mini Band Wall Slides'), 2, 1, '5', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Downward Dog to Scorpion'), 3, 1, '5 por lado', 30);
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'B', 'circuito', 2, 50, 2)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Half Burpee with Dumbbell'), 4, 1, '8-15', 50);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Shuttle Run'), 5, 1, '60 s', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Dumbbell Glute Bridge Chest Press'), 6, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Seated Dumbbell Front Raise to Lateral Raise'), 7, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Cable Seated Close Row'), 8, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Dumbbell Incline Alternating Curl'), 9, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Dumbbell Alternating Hammer Curl'), 10, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Cable Straight Bar Tricep Pushdown'), 11, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Cable Rope Face Pull'), 12, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Child''s Pose'), 13, 1, '30 s', null);

  select count(*) into v_n from rutinas where fase_id = v_fase;
  raise notice 'OK · Amalia Rodríguez: fase Cycle 4 con % rutinas y % series de historial.', v_n,
        (select count(*) from series_log sl join sesiones s on s.id = sl.sesion_id where s.fase_id = v_fase);
end $cli$;

-- ─────────────────────────────────────────────────────────────────────
-- ALEJANDRO AGUIRRE · Cycle 18 · 5 semanas (2026-09-07 → 2026-10-11)
-- ─────────────────────────────────────────────────────────────────────
do $cli$
declare v_coach uuid; v_cli uuid; v_fase uuid; v_rut uuid; v_blo uuid; v_ses uuid; v_n int;
begin
  select id, user_id into v_cli, v_coach from clientes where nombre ilike '%alejandro%aguirre%' limit 1;
  if v_cli is null then
    raise warning 'SALTADO: no encuentro a «Alejandro Aguirre» en `clientes` (patrón %%alejandro%%aguirre%%). Corrige el nombre y vuelve a correr.';
    return;
  end if;
  if exists (select 1 from fases where cliente_id = v_cli and nombre = 'Cycle 18') then
    raise notice 'SALTADO: «Alejandro Aguirre» ya tiene la fase Cycle 18 cargada.';
    return;
  end if;

  insert into fases (user_id, cliente_id, nombre, objetivo, notas_coach, semanas,
                     fecha_inicio, orden, estado)
  values (v_coach, v_cli, 'Cycle 18',
          'Bloque importado de Trainerize — la rutina que ya venía haciendo.',
          'Importado el 2026-09-20 desde el PDF de Trainerize (Cycle 18, 2026-09-07 a 2026-10-11). Revisar antes de enviar al cliente.',
          5, date '2026-09-07',
          coalesce((select max(orden)+1 from fases where cliente_id = v_cli), 1), 'borrador')
  returning id into v_fase;

  -- Rutina 1: Lower Body + Core Training
  insert into rutinas (user_id, cliente_id, fase_id, nombre, dia_orden,
                       duracion_estimada_min, tipo_sesion)
  values (v_coach, v_cli, v_fase, 'Lower Body + Core Training', 1, 64, 'fuerza')
  returning id into v_rut;
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Running'), 1, 1, '2-3 min a intensidad moderada', null);
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'A', 'superserie', 1, null, 1)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='90-90 Hip Switch'), 2, 1, '35 s', null);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Lateral Lunge to T-Rotation'), 3, 1, '35 s', null);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Bosu Lateral Bounce to Squat Jump'), 4, 2, '5 por lado', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Dumbbell Bulgarian Split Squat'), 5, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Machine Seated Leg Extension'), 6, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Hip Thrust Machine'), 7, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Smith Machine Sumo Deadlift'), 8, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Machine Seated Hip Adduction'), 9, 3, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Machine Seated Calf Raise'), 10, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Pallof Press'), 11, 4, '15', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Dip Machine Straight Leg Raise'), 12, 4, '15', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Seated Machine Ab Crunch'), 13, 3, '—', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Static Pigeon Stretch'), 14, 1, '30 s por lado', null);
  -- historial 2026-09-15
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-15', 2,
          '2026-W38', 'completada', '2026-09-15 12:00:00+00'::timestamptz, true)
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Leg Extension') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Leg Extension'), 1, 10, 90, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Leg Extension') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Leg Extension'), 2, 11, 90, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Leg Extension') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Leg Extension'), 3, 10, 90, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Leg Extension') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Leg Extension'), 4, 10, 90, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Hip Thrust Machine') limit 1),
            (select id from _ecm_ej where alias='Hip Thrust Machine'), 1, 10, 90, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Hip Thrust Machine') limit 1),
            (select id from _ecm_ej where alias='Hip Thrust Machine'), 2, 10, 90, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Hip Thrust Machine') limit 1),
            (select id from _ecm_ej where alias='Hip Thrust Machine'), 3, 10, 115, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Hip Thrust Machine') limit 1),
            (select id from _ecm_ej where alias='Hip Thrust Machine'), 4, 10, 115, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Smith Machine Sumo Deadlift') limit 1),
            (select id from _ecm_ej where alias='Smith Machine Sumo Deadlift'), 1, 8, 45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Smith Machine Sumo Deadlift') limit 1),
            (select id from _ecm_ej where alias='Smith Machine Sumo Deadlift'), 2, 8, 45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Smith Machine Sumo Deadlift') limit 1),
            (select id from _ecm_ej where alias='Smith Machine Sumo Deadlift'), 3, 8, 45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Smith Machine Sumo Deadlift') limit 1),
            (select id from _ecm_ej where alias='Smith Machine Sumo Deadlift'), 4, 8, 45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Hip Adduction') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Hip Adduction'), 1, 12, 180, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Hip Adduction') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Hip Adduction'), 2, 12, 190, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Hip Adduction') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Hip Adduction'), 3, 12, 190, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Calf Raise'), 1, 10, 90, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Calf Raise'), 2, 13, 90, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Calf Raise'), 3, 15, 90, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Calf Raise'), 4, 15, 90, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Pallof Press') limit 1),
            (select id from _ecm_ej where alias='Pallof Press'), 1, 10, 32.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Pallof Press') limit 1),
            (select id from _ecm_ej where alias='Pallof Press'), 2, 10, 32.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Pallof Press') limit 1),
            (select id from _ecm_ej where alias='Pallof Press'), 3, 12, 32.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Pallof Press') limit 1),
            (select id from _ecm_ej where alias='Pallof Press'), 4, 10, 32.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dip Machine Straight Leg Raise') limit 1),
            (select id from _ecm_ej where alias='Dip Machine Straight Leg Raise'), 1, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dip Machine Straight Leg Raise') limit 1),
            (select id from _ecm_ej where alias='Dip Machine Straight Leg Raise'), 2, 17, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dip Machine Straight Leg Raise') limit 1),
            (select id from _ecm_ej where alias='Dip Machine Straight Leg Raise'), 3, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Seated Machine Ab Crunch') limit 1),
            (select id from _ecm_ej where alias='Seated Machine Ab Crunch'), 1, 15, 115, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Seated Machine Ab Crunch') limit 1),
            (select id from _ecm_ej where alias='Seated Machine Ab Crunch'), 2, 15, 115, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Seated Machine Ab Crunch') limit 1),
            (select id from _ecm_ej where alias='Seated Machine Ab Crunch'), 3, 15, 115, 'kg');
  end if;
  -- historial 2026-09-12
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-12', 1,
          '2026-W37', 'completada', '2026-09-12 12:00:00+00'::timestamptz, true)
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Calf Raise'), 1, 12, 90, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Calf Raise'), 2, 12, 90, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Calf Raise'), 3, 13, 90, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Calf Raise'), 4, 13, 90, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Pallof Press') limit 1),
            (select id from _ecm_ej where alias='Pallof Press'), 1, 20, 32.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Pallof Press') limit 1),
            (select id from _ecm_ej where alias='Pallof Press'), 2, 20, 32.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Pallof Press') limit 1),
            (select id from _ecm_ej where alias='Pallof Press'), 3, 20, 32.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Pallof Press') limit 1),
            (select id from _ecm_ej where alias='Pallof Press'), 4, 20, 32.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dip Machine Straight Leg Raise') limit 1),
            (select id from _ecm_ej where alias='Dip Machine Straight Leg Raise'), 1, 13, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dip Machine Straight Leg Raise') limit 1),
            (select id from _ecm_ej where alias='Dip Machine Straight Leg Raise'), 2, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dip Machine Straight Leg Raise') limit 1),
            (select id from _ecm_ej where alias='Dip Machine Straight Leg Raise'), 3, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Seated Machine Ab Crunch') limit 1),
            (select id from _ecm_ej where alias='Seated Machine Ab Crunch'), 1, 10, 77, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Seated Machine Ab Crunch') limit 1),
            (select id from _ecm_ej where alias='Seated Machine Ab Crunch'), 2, 15, 115, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Seated Machine Ab Crunch') limit 1),
            (select id from _ecm_ej where alias='Seated Machine Ab Crunch'), 3, 15, 115, 'kg');
  end if;
  -- historial 2026-09-08
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-08', 1,
          '2026-W37', 'completada', '2026-09-08 12:00:00+00'::timestamptz, true)
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Leg Extension') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Leg Extension'), 1, 10, 85, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Leg Extension') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Leg Extension'), 2, 10, 85, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Leg Extension') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Leg Extension'), 3, 10, 100, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Leg Extension') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Leg Extension'), 4, 10, 100, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Hip Thrust Machine') limit 1),
            (select id from _ecm_ej where alias='Hip Thrust Machine'), 1, 10, 90, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Hip Thrust Machine') limit 1),
            (select id from _ecm_ej where alias='Hip Thrust Machine'), 2, 10, 90, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Hip Thrust Machine') limit 1),
            (select id from _ecm_ej where alias='Hip Thrust Machine'), 3, 10, 115, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Hip Thrust Machine') limit 1),
            (select id from _ecm_ej where alias='Hip Thrust Machine'), 4, 8, 125, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Smith Machine Sumo Deadlift') limit 1),
            (select id from _ecm_ej where alias='Smith Machine Sumo Deadlift'), 1, 8, 45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Smith Machine Sumo Deadlift') limit 1),
            (select id from _ecm_ej where alias='Smith Machine Sumo Deadlift'), 2, 9, 45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Hip Adduction') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Hip Adduction'), 1, 12, 175, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Hip Adduction') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Hip Adduction'), 2, 10, 190, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Hip Adduction') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Hip Adduction'), 3, 12, 190, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Calf Raise'), 1, 10, 90, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Calf Raise'), 2, 12, 90, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Calf Raise'), 3, 14, 90, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Calf Raise'), 4, 12, 90, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Pallof Press') limit 1),
            (select id from _ecm_ej where alias='Pallof Press'), 1, 20, 32.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Pallof Press') limit 1),
            (select id from _ecm_ej where alias='Pallof Press'), 2, 20, 32.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Pallof Press') limit 1),
            (select id from _ecm_ej where alias='Pallof Press'), 3, 20, 32.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Pallof Press') limit 1),
            (select id from _ecm_ej where alias='Pallof Press'), 4, 20, 32.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dip Machine Straight Leg Raise') limit 1),
            (select id from _ecm_ej where alias='Dip Machine Straight Leg Raise'), 1, 13, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dip Machine Straight Leg Raise') limit 1),
            (select id from _ecm_ej where alias='Dip Machine Straight Leg Raise'), 2, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dip Machine Straight Leg Raise') limit 1),
            (select id from _ecm_ej where alias='Dip Machine Straight Leg Raise'), 3, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dip Machine Straight Leg Raise') limit 1),
            (select id from _ecm_ej where alias='Dip Machine Straight Leg Raise'), 4, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Seated Machine Ab Crunch') limit 1),
            (select id from _ecm_ej where alias='Seated Machine Ab Crunch'), 1, 15, 115, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Seated Machine Ab Crunch') limit 1),
            (select id from _ecm_ej where alias='Seated Machine Ab Crunch'), 2, 12, 115, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Seated Machine Ab Crunch') limit 1),
            (select id from _ecm_ej where alias='Seated Machine Ab Crunch'), 3, 13, 115, 'kg');
  end if;

  -- Rutina 2: Pull Training
  insert into rutinas (user_id, cliente_id, fase_id, nombre, dia_orden,
                       duracion_estimada_min, tipo_sesion)
  values (v_coach, v_cli, v_fase, 'Pull Training', 2, 49, 'fuerza')
  returning id into v_rut;
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Running'), 1, 1, '2-3 min a intensidad moderada', null);
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'A', 'superserie', 1, 35, 1)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Bodyweight Spiderman Lunge To Rotation'), 2, 1, '5 por lado', 35);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Mini Band Wall Slides'), 3, 1, '8', 35);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Mini Band Standing I''s'), 4, 1, '8', 35);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Bar Hang'), 5, 1, '80 s', 25);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Plate Weighted Wide Grip Pull Up'), 6, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Cable Seated Close Row'), 7, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Machine Preacher Curl'), 8, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 9, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Machine Seated Reverse Fly'), 10, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Cable Shrug'), 11, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Suspension Low Back Stretch'), 12, 1, '30 s', null);
  -- historial 2026-09-10
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-10', 1,
          '2026-W37', 'completada', '2026-09-10 12:00:00+00'::timestamptz, true)
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Bar Hang') limit 1),
            (select id from _ecm_ej where alias='Bar Hang'), 1, 25, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Single Arm Neutral Grip Row') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Single Arm Neutral Grip Row'), 1, 10, 130, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Single Arm Neutral Grip Row') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Single Arm Neutral Grip Row'), 2, 10, 130, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Single Arm Neutral Grip Row') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Single Arm Neutral Grip Row'), 3, 10, 130, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Bicep Curl') limit 1),
            (select id from _ecm_ej where alias='Cable Bicep Curl'), 1, 10, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Bicep Curl') limit 1),
            (select id from _ecm_ej where alias='Cable Bicep Curl'), 2, 10, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Bicep Curl') limit 1),
            (select id from _ecm_ej where alias='Cable Bicep Curl'), 3, 10, 54, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Bicep Curl') limit 1),
            (select id from _ecm_ej where alias='Cable Bicep Curl'), 4, 8, 54, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 1, 10, 35, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 2, 10, 35, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 3, 10, 35, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 4, 10, 35, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Reverse Fly') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Reverse Fly'), 1, 12, 85, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Reverse Fly') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Reverse Fly'), 2, 10, 85, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Reverse Fly') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Reverse Fly'), 3, 10, 100, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Reverse Fly') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Reverse Fly'), 4, 8, 100, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Shrug') limit 1),
            (select id from _ecm_ej where alias='Cable Shrug'), 1, 12, 82, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Shrug') limit 1),
            (select id from _ecm_ej where alias='Cable Shrug'), 2, 12, 88, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Shrug') limit 1),
            (select id from _ecm_ej where alias='Cable Shrug'), 3, 13, 88, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Shrug') limit 1),
            (select id from _ecm_ej where alias='Cable Shrug'), 4, 10, 88, 'kg');
  end if;

  -- Rutina 3: Push Training
  insert into rutinas (user_id, cliente_id, fase_id, nombre, dia_orden,
                       duracion_estimada_min, tipo_sesion)
  values (v_coach, v_cli, v_fase, 'Push Training', 3, 62, 'fuerza')
  returning id into v_rut;
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Running'), 1, 1, '2-3 min a intensidad moderada', null);
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'A', 'superserie', 1, 30, 1)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Dumbbell Standing Shoulder External Rotations'), 2, 1, '5', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Bodyweight Spiderman Lunge To Rotation'), 3, 1, '5 por lado', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='SuperBand Dislocates'), 4, 1, '5', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Push Up'), 5, 2, '10-15', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Smith Machine Incline Bench Press'), 6, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Smith Machine Bench Press'), 7, 3, '6-12', 90);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Smith Machine Seated Shoulder Press'), 8, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Machine Seated Chest Fly'), 9, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Dip'), 10, 3, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Machine Lateral Raise'), 11, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown'), 12, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Cable V-Bar Overhead Tricep Extension'), 13, 3, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Child''s Pose'), 14, 1, '30 s', null);
  -- historial 2026-09-16
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-16', 2,
          '2026-W38', 'completada', '2026-09-16 12:00:00+00'::timestamptz, true)
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 1, 10, 45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 2, 10, 45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 3, 7, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 4, 7, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Chest Fly') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Chest Fly'), 1, 12, 115, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Chest Fly') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Chest Fly'), 2, 10, 130, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Chest Fly') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Chest Fly'), 3, 10, 130, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Chest Fly') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Chest Fly'), 4, 9, 130, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dip') limit 1),
            (select id from _ecm_ej where alias='Dip'), 1, 7, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dip') limit 1),
            (select id from _ecm_ej where alias='Dip'), 2, 8, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dip') limit 1),
            (select id from _ecm_ej where alias='Dip'), 3, 8, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dip') limit 1),
            (select id from _ecm_ej where alias='Dip'), 4, 7, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Kettlebell Single Arm Clean and Press') limit 1),
            (select id from _ecm_ej where alias='Kettlebell Single Arm Clean and Press'), 1, 10, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Kettlebell Single Arm Clean and Press') limit 1),
            (select id from _ecm_ej where alias='Kettlebell Single Arm Clean and Press'), 2, 10, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Kettlebell Single Arm Clean and Press') limit 1),
            (select id from _ecm_ej where alias='Kettlebell Single Arm Clean and Press'), 3, 10, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Kettlebell Single Arm Clean and Press') limit 1),
            (select id from _ecm_ej where alias='Kettlebell Single Arm Clean and Press'), 4, 9, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Alternating Lateral Raise to Front Raise') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Alternating Lateral Raise to Front Raise'), 1, 10, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Alternating Lateral Raise to Front Raise') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Alternating Lateral Raise to Front Raise'), 2, 10, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Alternating Lateral Raise to Front Raise') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Alternating Lateral Raise to Front Raise'), 3, 10, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown'), 1, 12, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown'), 2, 12, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown'), 3, 10, 54, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V-Bar Overhead Tricep Extension') limit 1),
            (select id from _ecm_ej where alias='Cable V-Bar Overhead Tricep Extension'), 1, 10, 36, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V-Bar Overhead Tricep Extension') limit 1),
            (select id from _ecm_ej where alias='Cable V-Bar Overhead Tricep Extension'), 2, 10, 36, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V-Bar Overhead Tricep Extension') limit 1),
            (select id from _ecm_ej where alias='Cable V-Bar Overhead Tricep Extension'), 3, 8, 36, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Push Up') limit 1),
            (select id from _ecm_ej where alias='Push Up'), 1, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Push Up') limit 1),
            (select id from _ecm_ej where alias='Push Up'), 2, 15, null, 'kg');
  end if;
  -- historial 2026-09-09
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-09', 1,
          '2026-W37', 'completada', '2026-09-09 12:00:00+00'::timestamptz, true)
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 1, 10, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 2, 8, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 3, 8, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 4, 5, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Chest Fly') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Chest Fly'), 1, 12, 115, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Chest Fly') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Chest Fly'), 2, 10, 130, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Chest Fly') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Chest Fly'), 3, 10, 135, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Chest Fly') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Chest Fly'), 4, 8, 140, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dip') limit 1),
            (select id from _ecm_ej where alias='Dip'), 1, 7, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dip') limit 1),
            (select id from _ecm_ej where alias='Dip'), 2, 9, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dip') limit 1),
            (select id from _ecm_ej where alias='Dip'), 3, 7, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dip') limit 1),
            (select id from _ecm_ej where alias='Dip'), 4, 5, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Kettlebell Single Arm Clean and Press') limit 1),
            (select id from _ecm_ej where alias='Kettlebell Single Arm Clean and Press'), 1, 10, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Kettlebell Single Arm Clean and Press') limit 1),
            (select id from _ecm_ej where alias='Kettlebell Single Arm Clean and Press'), 2, 10, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Kettlebell Single Arm Clean and Press') limit 1),
            (select id from _ecm_ej where alias='Kettlebell Single Arm Clean and Press'), 3, 10, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Kettlebell Single Arm Clean and Press') limit 1),
            (select id from _ecm_ej where alias='Kettlebell Single Arm Clean and Press'), 4, 10, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Alternating Lateral Raise to Front Raise') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Alternating Lateral Raise to Front Raise'), 1, 10, 10, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Alternating Lateral Raise to Front Raise') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Alternating Lateral Raise to Front Raise'), 2, 10, 10, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Alternating Lateral Raise to Front Raise') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Alternating Lateral Raise to Front Raise'), 3, 10, 10, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown'), 1, 11, 45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown'), 2, 11, 45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown'), 3, 8, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V-Bar Overhead Tricep Extension') limit 1),
            (select id from _ecm_ej where alias='Cable V-Bar Overhead Tricep Extension'), 1, 10, 36, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V-Bar Overhead Tricep Extension') limit 1),
            (select id from _ecm_ej where alias='Cable V-Bar Overhead Tricep Extension'), 2, 10, 36, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V-Bar Overhead Tricep Extension') limit 1),
            (select id from _ecm_ej where alias='Cable V-Bar Overhead Tricep Extension'), 3, 10, 36, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Push Up') limit 1),
            (select id from _ecm_ej where alias='Push Up'), 1, 13, null, 'kg');
  end if;

  -- Rutina 4: Upper Body Training
  insert into rutinas (user_id, cliente_id, fase_id, nombre, dia_orden,
                       duracion_estimada_min, tipo_sesion)
  values (v_coach, v_cli, v_fase, 'Upper Body Training', 4, 71, 'fuerza')
  returning id into v_rut;
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Running'), 1, 1, '2-3 min a intensidad moderada', null);
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'A', 'superserie', 1, 30, 1)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Bodyweight Spiderman Lunge To Rotation'), 2, 1, '6 por lado', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Dumbbell Standing Shoulder External Rotations'), 3, 1, '8', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Bar Hang'), 4, 1, '60 s', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Wide Grip Pull Up'), 5, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Cable Seated Close Grip Row'), 6, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Smith Machine Incline Bench Press'), 7, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Smith Machine Seated Shoulder Press'), 8, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Machine Seated Chest Fly'), 9, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Machine Lateral Raise'), 10, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Machine Preacher Curl'), 11, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Dumbbell Alternating Hammer Curl'), 12, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown'), 13, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Cable Single Arm Standing Overhead Tricep Extension'), 14, 3, '6-12 por lado', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Child''s Pose'), 15, 1, '30 s', null);
  -- historial 2026-09-14
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-14', 2,
          '2026-W38', 'completada', '2026-09-14 12:00:00+00'::timestamptz, true)
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Bar Hang') limit 1),
            (select id from _ecm_ej where alias='Bar Hang'), 1, 25, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Seated Close Grip Row') limit 1),
            (select id from _ecm_ej where alias='Cable Seated Close Grip Row'), 1, 12, 45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Seated Close Grip Row') limit 1),
            (select id from _ecm_ej where alias='Cable Seated Close Grip Row'), 2, 10, 45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Seated Close Grip Row') limit 1),
            (select id from _ecm_ej where alias='Cable Seated Close Grip Row'), 3, 10, 52, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Seated Close Grip Row') limit 1),
            (select id from _ecm_ej where alias='Cable Seated Close Grip Row'), 4, 10, 52, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Smith Machine Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Smith Machine Incline Bench Press'), 1, 10, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Smith Machine Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Smith Machine Incline Bench Press'), 2, 10, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Smith Machine Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Smith Machine Incline Bench Press'), 3, 10, 45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Smith Machine Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Smith Machine Incline Bench Press'), 4, 10, 45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Smith Machine Seated Shoulder Press') limit 1),
            (select id from _ecm_ej where alias='Smith Machine Seated Shoulder Press'), 1, 7, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Smith Machine Seated Shoulder Press') limit 1),
            (select id from _ecm_ej where alias='Smith Machine Seated Shoulder Press'), 2, 9, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Smith Machine Seated Shoulder Press') limit 1),
            (select id from _ecm_ej where alias='Smith Machine Seated Shoulder Press'), 3, 9, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Smith Machine Seated Shoulder Press') limit 1),
            (select id from _ecm_ej where alias='Smith Machine Seated Shoulder Press'), 4, 6, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Chest Fly') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Chest Fly'), 1, 10, 115, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Chest Fly') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Chest Fly'), 2, 10, 115, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Chest Fly') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Chest Fly'), 3, 8, 130, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Chest Fly') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Chest Fly'), 4, 8, 130, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Lateral Raise') limit 1),
            (select id from _ecm_ej where alias='Machine Lateral Raise'), 1, 10, 70, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Lateral Raise') limit 1),
            (select id from _ecm_ej where alias='Machine Lateral Raise'), 2, 8, 75, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Lateral Raise') limit 1),
            (select id from _ecm_ej where alias='Machine Lateral Raise'), 3, 9, 75, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Preacher Curl') limit 1),
            (select id from _ecm_ej where alias='Machine Preacher Curl'), 1, 10, 55, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Preacher Curl') limit 1),
            (select id from _ecm_ej where alias='Machine Preacher Curl'), 2, 9, 60, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Preacher Curl') limit 1),
            (select id from _ecm_ej where alias='Machine Preacher Curl'), 3, 9, 60, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Preacher Curl') limit 1),
            (select id from _ecm_ej where alias='Machine Preacher Curl'), 4, 8, 60, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Alternating Hammer Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Alternating Hammer Curl'), 1, 10, 35, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Alternating Hammer Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Alternating Hammer Curl'), 2, 10, 35, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Alternating Hammer Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Alternating Hammer Curl'), 3, 10, 35, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown'), 1, 12, 45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown'), 2, 10, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown'), 3, 10, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Single Arm Standing Overhead Tricep Extension') limit 1),
            (select id from _ecm_ej where alias='Cable Single Arm Standing Overhead Tricep Extension'), 1, 8, 14, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Single Arm Standing Overhead Tricep Extension') limit 1),
            (select id from _ecm_ej where alias='Cable Single Arm Standing Overhead Tricep Extension'), 2, 10, 14, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Single Arm Standing Overhead Tricep Extension') limit 1),
            (select id from _ecm_ej where alias='Cable Single Arm Standing Overhead Tricep Extension'), 3, 10, 14, 'kg');
  end if;
  -- historial 2026-09-07
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-07', 1,
          '2026-W37', 'completada', '2026-09-07 12:00:00+00'::timestamptz, true)
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Standing Shoulder External Rotations') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Standing Shoulder External Rotations'), 1, 12, 10, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Bar Hang') limit 1),
            (select id from _ecm_ej where alias='Bar Hang'), 1, 30, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Chest Fly') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Chest Fly'), 1, 10, 115, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Chest Fly') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Chest Fly'), 2, 10, 130, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Chest Fly') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Chest Fly'), 3, 10, 130, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Chest Fly') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Chest Fly'), 4, 8, 130, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Preacher Curl') limit 1),
            (select id from _ecm_ej where alias='Machine Preacher Curl'), 1, 10, 55, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Preacher Curl') limit 1),
            (select id from _ecm_ej where alias='Machine Preacher Curl'), 2, 10, 55, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Preacher Curl') limit 1),
            (select id from _ecm_ej where alias='Machine Preacher Curl'), 3, 10, 60, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Preacher Curl') limit 1),
            (select id from _ecm_ej where alias='Machine Preacher Curl'), 4, 8, 60, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown'), 1, 10, 45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown'), 2, 10, 45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown'), 3, 10, 45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown'), 4, 10, 45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Single Arm Neutral Grip Row') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Single Arm Neutral Grip Row'), 1, 10, 130, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Single Arm Neutral Grip Row') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Single Arm Neutral Grip Row'), 2, 10, 130, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Single Arm Neutral Grip Row') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Single Arm Neutral Grip Row'), 3, 8, 130, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 1, 10, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 2, 10, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 3, 10, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 4, 10, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Alternating Lateral Raise to Front Raise') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Alternating Lateral Raise to Front Raise'), 1, 10, 10, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Alternating Lateral Raise to Front Raise') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Alternating Lateral Raise to Front Raise'), 2, 10, 10, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Alternating Lateral Raise to Front Raise') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Alternating Lateral Raise to Front Raise'), 3, 10, 10, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Alternating Lateral Raise to Front Raise') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Alternating Lateral Raise to Front Raise'), 4, 8, 10, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 1, 10, 30, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 2, 10, 30, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 3, 10, 30, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 4, 10, 30, 'kg');
  end if;

  select count(*) into v_n from rutinas where fase_id = v_fase;
  raise notice 'OK · Alejandro Aguirre: fase Cycle 18 con % rutinas y % series de historial.', v_n,
        (select count(*) from series_log sl join sesiones s on s.id = sl.sesion_id where s.fase_id = v_fase);
end $cli$;

-- ─────────────────────────────────────────────────────────────────────
-- ALEJANDRA BORBÓN · Cycle 3 · 4 semanas (2026-09-07 → 2026-10-04)
-- ─────────────────────────────────────────────────────────────────────
do $cli$
declare v_coach uuid; v_cli uuid; v_fase uuid; v_rut uuid; v_blo uuid; v_ses uuid; v_n int;
begin
  select id, user_id into v_cli, v_coach from clientes where nombre ilike '%alejandra%borb%n%' limit 1;
  if v_cli is null then
    raise warning 'SALTADO: no encuentro a «Alejandra Borbón» en `clientes` (patrón %%alejandra%%borb%%n%%). Corrige el nombre y vuelve a correr.';
    return;
  end if;
  if exists (select 1 from fases where cliente_id = v_cli and nombre = 'Cycle 3') then
    raise notice 'SALTADO: «Alejandra Borbón» ya tiene la fase Cycle 3 cargada.';
    return;
  end if;

  insert into fases (user_id, cliente_id, nombre, objetivo, notas_coach, semanas,
                     fecha_inicio, orden, estado)
  values (v_coach, v_cli, 'Cycle 3',
          'Bloque importado de Trainerize — la rutina que ya venía haciendo.',
          'Importado el 2026-09-20 desde el PDF de Trainerize (Cycle 3, 2026-09-07 a 2026-10-04). Revisar antes de enviar al cliente.',
          4, date '2026-09-07',
          coalesce((select max(orden)+1 from fases where cliente_id = v_cli), 1), 'borrador')
  returning id into v_fase;

  -- Rutina 1: Lower Body + Core Training (Gym edition)
  insert into rutinas (user_id, cliente_id, fase_id, nombre, dia_orden,
                       duracion_estimada_min, tipo_sesion)
  values (v_coach, v_cli, v_fase, 'Lower Body + Core Training (Gym edition)', 1, 51, 'fuerza')
  returning id into v_rut;
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'A', 'superserie', 1, 15, 1)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Glute Side Circle'), 1, 1, '5 por lado', 15);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Bodyweight Squat To Hinge'), 2, 1, '5', 15);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Bodyweight Alternating Cossack Squat'), 3, 1, '5 por lado', 15);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Dumbbell Bulgarian Split Squat'), 4, 4, '6-12 por lado', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Dumbbell Hip Thrust'), 5, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Machine Seated Leg Extension'), 6, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Machine Seated Leg Curl'), 7, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Machine Seated Hip Adduction'), 8, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Cross Body Mountain Climber'), 9, 3, '8-15', 35);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Pallof Press'), 10, 3, '8-15', 35);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Dip Machine Bent Leg Raise'), 11, 3, '8-15', 35);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='BOSU Alternating Lateral Squat Shuffle'), 12, 1, '60 s', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Static Pigeon Stretch'), 13, 1, '30 s por lado', null);

  -- Rutina 2: Lower Body + Core Training (Home edition)
  insert into rutinas (user_id, cliente_id, fase_id, nombre, dia_orden,
                       duracion_estimada_min, tipo_sesion)
  values (v_coach, v_cli, v_fase, 'Lower Body + Core Training (Home edition)', 2, 51, 'fuerza')
  returning id into v_rut;
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'A', 'circuito', 2, 40, 1)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Cossack Squat to T-Spine Reach'), 1, 1, '5 por lado', 40);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Bodyweight Squat To Hinge'), 2, 1, '5', 40);
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'B', 'superserie', 1, 30, 2)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Shuttle Run'), 3, 1, '60 s', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Lateral Shuttle Run'), 4, 1, '60 s', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Dumbbell Reverse Lunge'), 5, 4, '6-12 por lado', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Dumbbell Sumo Deadlift'), 6, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Dumbbell Glute Bridge'), 7, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Mini Band Side Lying Hip Abduction'), 8, 4, '6-12 por lado', 50);
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'C', 'circuito', 3, 90, 3)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='High Plank Jacks'), 9, 1, '15', 90);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Knee to Elbow Crunch'), 10, 1, '10', 90);
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'D', 'superserie', 1, null, 4)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Shuttle Run'), 11, 1, '60 s', null);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Lateral Shuttle Run'), 12, 1, '60 s', null);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Static Pigeon Stretch'), 13, 1, '30 s por lado', null);
  -- historial 2026-09-14
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-14', 2,
          '2026-W38', 'completada', '2026-09-14 12:00:00+00'::timestamptz, true)
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Reverse Lunge') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Reverse Lunge'), 1, 8, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Reverse Lunge') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Reverse Lunge'), 2, 8, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Reverse Lunge') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Reverse Lunge'), 3, 8, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Reverse Lunge') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Reverse Lunge'), 4, 8, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Sumo Deadlift') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Sumo Deadlift'), 1, 12, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Sumo Deadlift') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Sumo Deadlift'), 2, 12, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Sumo Deadlift') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Sumo Deadlift'), 3, 12, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Sumo Deadlift') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Sumo Deadlift'), 4, 12, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Glute Bridge') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Glute Bridge'), 1, 12, 2.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Glute Bridge') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Glute Bridge'), 2, 12, 2.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Glute Bridge') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Glute Bridge'), 3, 12, 2.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Glute Bridge') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Glute Bridge'), 4, 12, 2.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Side Lying Hip Abduction') limit 1),
            (select id from _ecm_ej where alias='Mini Band Side Lying Hip Abduction'), 1, 10, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Side Lying Hip Abduction') limit 1),
            (select id from _ecm_ej where alias='Mini Band Side Lying Hip Abduction'), 2, 10, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Side Lying Hip Abduction') limit 1),
            (select id from _ecm_ej where alias='Mini Band Side Lying Hip Abduction'), 3, 10, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Side Lying Hip Abduction') limit 1),
            (select id from _ecm_ej where alias='Mini Band Side Lying Hip Abduction'), 4, 10, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='High Plank Jacks') limit 1),
            (select id from _ecm_ej where alias='High Plank Jacks'), 1, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='High Plank Jacks') limit 1),
            (select id from _ecm_ej where alias='High Plank Jacks'), 2, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='High Plank Jacks') limit 1),
            (select id from _ecm_ej where alias='High Plank Jacks'), 3, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Knee to Elbow Crunch') limit 1),
            (select id from _ecm_ej where alias='Knee to Elbow Crunch'), 1, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Knee to Elbow Crunch') limit 1),
            (select id from _ecm_ej where alias='Knee to Elbow Crunch'), 2, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Knee to Elbow Crunch') limit 1),
            (select id from _ecm_ej where alias='Knee to Elbow Crunch'), 3, 12, null, 'kg');
  end if;
  -- historial 2026-09-07
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-07', 1,
          '2026-W37', 'completada', '2026-09-07 12:00:00+00'::timestamptz, true)
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Sumo Deadlift') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Sumo Deadlift'), 1, 12, 3.75, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Sumo Deadlift') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Sumo Deadlift'), 2, 12, 3.75, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Sumo Deadlift') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Sumo Deadlift'), 3, 12, 3.75, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Sumo Deadlift') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Sumo Deadlift'), 4, 12, 3.75, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Glute Bridge') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Glute Bridge'), 1, 12, 2.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Glute Bridge') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Glute Bridge'), 2, 12, 2.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Glute Bridge') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Glute Bridge'), 3, 12, 2.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Glute Bridge') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Glute Bridge'), 4, 12, 2.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Side Lying Hip Abduction') limit 1),
            (select id from _ecm_ej where alias='Mini Band Side Lying Hip Abduction'), 1, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Side Lying Hip Abduction') limit 1),
            (select id from _ecm_ej where alias='Mini Band Side Lying Hip Abduction'), 2, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Side Lying Hip Abduction') limit 1),
            (select id from _ecm_ej where alias='Mini Band Side Lying Hip Abduction'), 3, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Side Lying Hip Abduction') limit 1),
            (select id from _ecm_ej where alias='Mini Band Side Lying Hip Abduction'), 4, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Bulgarian Split Squat') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Bulgarian Split Squat'), 1, 12, 3.75, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Bulgarian Split Squat') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Bulgarian Split Squat'), 2, 12, 3.75, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Bulgarian Split Squat') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Bulgarian Split Squat'), 3, 12, 3.75, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Bulgarian Split Squat') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Bulgarian Split Squat'), 4, 12, 3.75, 'kg');
  end if;

  -- Rutina 3: Upper Body Training (Gym edition)
  insert into rutinas (user_id, cliente_id, fase_id, nombre, dia_orden,
                       duracion_estimada_min, tipo_sesion)
  values (v_coach, v_cli, v_fase, 'Upper Body Training (Gym edition)', 3, 44, 'fuerza')
  returning id into v_rut;
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'A', 'superserie', 1, 30, 1)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Cobra'), 1, 1, '5', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Table Top Half Arm Thoracic Rotation'), 2, 1, '5 por lado', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Mini Band Standing I''s'), 3, 1, '5', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Bar Hang'), 4, 1, '20-35 s', null);
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'B', 'superserie', 1, 35, 2)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Lateral Shuttle Run'), 5, 1, '60 s', 35);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Half Burpee with Dumbbell'), 6, 1, '6-15', 35);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Machine Seated Chest Fly'), 7, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Cable Seated Close Grip Row'), 8, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Machine Seated Shoulder Press'), 9, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Cable Bicep Curl'), 10, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown'), 11, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Cable Rope Face Pull'), 12, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Child''s Pose'), 13, 1, '30 s', null);

  -- Rutina 4: Upper Body Training (Home edition)
  insert into rutinas (user_id, cliente_id, fase_id, nombre, dia_orden,
                       duracion_estimada_min, tipo_sesion)
  values (v_coach, v_cli, v_fase, 'Upper Body Training (Home edition)', 4, 46, 'fuerza')
  returning id into v_rut;
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'A', 'circuito', 2, 35, 1)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Cat to Cow'), 1, 1, '5', 35);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Bodyweight Spiderman Lunge To Rotation'), 2, 1, '5 por lado', 35);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Mini Band Standing I''s'), 3, 1, '6-12', 35);
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'B', 'circuito', 2, 35, 2)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Shuttle Run'), 4, 1, '60 s', 35);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Lateral Shuttle Run'), 5, 1, '60 s', 35);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Dumbbell Floor Press'), 6, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Dumbbell Single Arm Row'), 7, 4, '6-12 por lado', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Dumbbell Alternating Lateral Raise to Front Raise'), 8, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Dumbbell Alternating Bicep Curl'), 9, 4, '6-12 por lado', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Band Anchored Single Arm Tricep Kickback'), 10, 3, '6-12 por lado', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Child''s Pose'), 11, 1, '40 s', null);
  -- historial 2026-09-09
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-09', 1,
          '2026-W37', 'completada', '2026-09-09 12:00:00+00'::timestamptz, true)
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cat to Cow') limit 1),
            (select id from _ecm_ej where alias='Cat to Cow'), 1, 5, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cat to Cow') limit 1),
            (select id from _ecm_ej where alias='Cat to Cow'), 2, 5, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Wall Slides') limit 1),
            (select id from _ecm_ej where alias='Mini Band Wall Slides'), 1, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Wall Slides') limit 1),
            (select id from _ecm_ej where alias='Mini Band Wall Slides'), 2, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Wall Slides') limit 1),
            (select id from _ecm_ej where alias='Mini Band Wall Slides'), 3, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Standing I''s') limit 1),
            (select id from _ecm_ej where alias='Mini Band Standing I''s'), 1, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Standing I''s') limit 1),
            (select id from _ecm_ej where alias='Mini Band Standing I''s'), 2, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Standing I''s') limit 1),
            (select id from _ecm_ej where alias='Mini Band Standing I''s'), 3, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='SuperBand Single Arm Row') limit 1),
            (select id from _ecm_ej where alias='SuperBand Single Arm Row'), 1, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='SuperBand Single Arm Row') limit 1),
            (select id from _ecm_ej where alias='SuperBand Single Arm Row'), 2, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='SuperBand Single Arm Row') limit 1),
            (select id from _ecm_ej where alias='SuperBand Single Arm Row'), 3, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Alternating Bicep Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Alternating Bicep Curl'), 1, 12, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Alternating Bicep Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Alternating Bicep Curl'), 2, 12, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Alternating Bicep Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Alternating Bicep Curl'), 3, 12, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Floor Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Floor Press'), 1, 12, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Floor Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Floor Press'), 2, 12, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Floor Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Floor Press'), 3, 12, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Band Anchored Single Arm Tricep Kickback') limit 1),
            (select id from _ecm_ej where alias='Band Anchored Single Arm Tricep Kickback'), 1, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Band Anchored Single Arm Tricep Kickback') limit 1),
            (select id from _ecm_ej where alias='Band Anchored Single Arm Tricep Kickback'), 2, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Band Anchored Single Arm Tricep Kickback') limit 1),
            (select id from _ecm_ej where alias='Band Anchored Single Arm Tricep Kickback'), 3, 12, null, 'kg');
  end if;

  select count(*) into v_n from rutinas where fase_id = v_fase;
  raise notice 'OK · Alejandra Borbón: fase Cycle 3 con % rutinas y % series de historial.', v_n,
        (select count(*) from series_log sl join sesiones s on s.id = sl.sesion_id where s.fase_id = v_fase);
end $cli$;

-- ─────────────────────────────────────────────────────────────────────
-- CAMILO RODRÍGUEZ · Cycle 2 · 4 semanas (2026-09-07 → 2026-10-04)
-- ─────────────────────────────────────────────────────────────────────
do $cli$
declare v_coach uuid; v_cli uuid; v_fase uuid; v_rut uuid; v_blo uuid; v_ses uuid; v_n int;
begin
  select id, user_id into v_cli, v_coach from clientes where nombre ilike '%camilo%rodr%guez%' limit 1;
  if v_cli is null then
    raise warning 'SALTADO: no encuentro a «Camilo Rodríguez» en `clientes` (patrón %%camilo%%rodr%%guez%%). Corrige el nombre y vuelve a correr.';
    return;
  end if;
  if exists (select 1 from fases where cliente_id = v_cli and nombre = 'Cycle 2') then
    raise notice 'SALTADO: «Camilo Rodríguez» ya tiene la fase Cycle 2 cargada.';
    return;
  end if;

  insert into fases (user_id, cliente_id, nombre, objetivo, notas_coach, semanas,
                     fecha_inicio, orden, estado)
  values (v_coach, v_cli, 'Cycle 2',
          'Bloque importado de Trainerize — la rutina que ya venía haciendo.',
          'Importado el 2026-09-20 desde el PDF de Trainerize (Cycle 2, 2026-09-07 a 2026-10-04). Revisar antes de enviar al cliente.',
          4, date '2026-09-07',
          coalesce((select max(orden)+1 from fases where cliente_id = v_cli), 1), 'borrador')
  returning id into v_fase;

  -- Rutina 1: Lower Body + Core Training
  insert into rutinas (user_id, cliente_id, fase_id, nombre, dia_orden,
                       duracion_estimada_min, tipo_sesion)
  values (v_coach, v_cli, v_fase, 'Lower Body + Core Training', 1, 67, 'fuerza')
  returning id into v_rut;
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'A', 'superserie', 1, 35, 1)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='90-90 Hip Switch'), 1, 1, '8', 35);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Bodyweight Squat To Hinge'), 2, 1, '8', 35);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Bodyweight Alternating Cossack Squat'), 3, 1, '8 por lado', 35);
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'B', 'circuito', 2, 40, 2)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='1/2 Kneel to High Knee Hop'), 4, 1, '6 por lado', 40);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Lateral Shuttle Run'), 5, 1, '60 s', 40);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Smith Machine Back Squat'), 6, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Smith Machine Sumo Deadlift'), 7, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Hip Thrust Machine'), 8, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Machine Seated Leg Extension'), 9, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Machine Seated Leg Curl'), 10, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Machine Seated Calf Raise'), 11, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Machine Seated Hip Adduction'), 12, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Dip Machine Bent Leg Raise'), 13, 3, '15', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Ab Roller Wheel Abdominal Roll Out'), 14, 3, '6-10', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Pallof Press'), 15, 3, '15', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Static Pigeon Stretch'), 16, 1, '30 s por lado', null);

  -- Rutina 2: Upper Body Training
  insert into rutinas (user_id, cliente_id, fase_id, nombre, dia_orden,
                       duracion_estimada_min, tipo_sesion)
  values (v_coach, v_cli, v_fase, 'Upper Body Training', 2, 68, 'fuerza')
  returning id into v_rut;
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Running'), 1, 1, '2-3 min a intensidad moderada', null);
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'A', 'superserie', 1, 50, 1)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Bear Squat to Spinal Wave'), 2, 1, '5', 50);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Bodyweight Spiderman Lunge To Rotation'), 3, 1, '5 por lado', 50);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Dumbbell Standing Shoulder External Rotations'), 4, 1, '5', 50);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Clapping Push Up'), 5, 1, '5', 50);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Bar Hang'), 6, 1, '60 s', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Pull Up'), 7, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Machine Seated Single Arm Neutral Grip Row'), 8, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 9, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Machine Seated Chest Fly'), 10, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Machine Seated Parallel Grip Shoulder Press'), 11, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Machine Lateral Raise'), 12, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Machine Preacher Curl'), 13, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Dumbbell Alternating Hammer Curl'), 14, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown'), 15, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Child''s Pose'), 16, 1, '30 s', null);

  select count(*) into v_n from rutinas where fase_id = v_fase;
  raise notice 'OK · Camilo Rodríguez: fase Cycle 2 con % rutinas y % series de historial.', v_n,
        (select count(*) from series_log sl join sesiones s on s.id = sl.sesion_id where s.fase_id = v_fase);
end $cli$;

-- ─────────────────────────────────────────────────────────────────────
-- ANDRÉS YEPES · Cycle 14 · 4 semanas (2026-08-31 → 2026-09-27)
-- ─────────────────────────────────────────────────────────────────────
do $cli$
declare v_coach uuid; v_cli uuid; v_fase uuid; v_rut uuid; v_blo uuid; v_ses uuid; v_n int;
begin
  select id, user_id into v_cli, v_coach from clientes where nombre ilike '%andr%s%yep%' limit 1;
  if v_cli is null then
    raise warning 'SALTADO: no encuentro a «Andrés Yepes» en `clientes` (patrón %%andr%%s%%yep%%). Corrige el nombre y vuelve a correr.';
    return;
  end if;
  if exists (select 1 from fases where cliente_id = v_cli and nombre = 'Cycle 14') then
    raise notice 'SALTADO: «Andrés Yepes» ya tiene la fase Cycle 14 cargada.';
    return;
  end if;

  insert into fases (user_id, cliente_id, nombre, objetivo, notas_coach, semanas,
                     fecha_inicio, orden, estado)
  values (v_coach, v_cli, 'Cycle 14',
          'Bloque importado de Trainerize — la rutina que ya venía haciendo.',
          'Importado el 2026-09-20 desde el PDF de Trainerize (Cycle 14, 2026-08-31 a 2026-09-27). Revisar antes de enviar al cliente.',
          4, date '2026-08-31',
          coalesce((select max(orden)+1 from fases where cliente_id = v_cli), 1), 'borrador')
  returning id into v_fase;

  -- Rutina 1: Lower Body + Core Training
  insert into rutinas (user_id, cliente_id, fase_id, nombre, dia_orden,
                       duracion_estimada_min, tipo_sesion)
  values (v_coach, v_cli, v_fase, 'Lower Body + Core Training', 1, 68, 'fuerza')
  returning id into v_rut;
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Running'), 1, 1, '2-3 min a intensidad moderada', 30);
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'A', 'superserie', 1, 15, 1)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Bodyweight Squat To Hinge'), 2, 1, '8', 15);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Bodyweight Cossack Squat'), 3, 1, '8 por lado', 15);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Quadruped Hip Circles'), 4, 1, '8 por lado', 15);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Angled Machine Leg Press'), 5, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Machine Seated Leg Extension'), 6, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Smith Machine Sumo Deadlift'), 7, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Hip Thrust Machine'), 8, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Machine Seated Hip Adduction'), 9, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Machine Seated Calf Raise'), 10, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Dip Machine Bent Leg Raise'), 11, 4, '8-15', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Seated Machine Ab Crunch'), 12, 4, '8-15', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Pallof Press'), 13, 4, '8-15', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Ab Roller Wheel Abdominal Roll Out'), 14, 4, '8-15', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Static Pigeon Stretch'), 15, 1, '30 s por lado', null);
  -- historial 2026-09-08
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-08', 2,
          '2026-W37', 'completada', '2026-09-08 12:00:00+00'::timestamptz, true)
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Angled Machine Leg Press') limit 1),
            (select id from _ecm_ej where alias='Angled Machine Leg Press'), 1, 10, 120, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Angled Machine Leg Press') limit 1),
            (select id from _ecm_ej where alias='Angled Machine Leg Press'), 2, 10, 120, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Angled Machine Leg Press') limit 1),
            (select id from _ecm_ej where alias='Angled Machine Leg Press'), 3, 10, 120, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Angled Machine Leg Press') limit 1),
            (select id from _ecm_ej where alias='Angled Machine Leg Press'), 4, 10, 120, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Leg Extension') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Leg Extension'), 1, 10, 75, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Leg Extension') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Leg Extension'), 2, 10, 75, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Leg Extension') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Leg Extension'), 3, 10, 75, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Smith Machine Sumo Deadlift') limit 1),
            (select id from _ecm_ej where alias='Smith Machine Sumo Deadlift'), 1, 10, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Smith Machine Sumo Deadlift') limit 1),
            (select id from _ecm_ej where alias='Smith Machine Sumo Deadlift'), 2, 10, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Smith Machine Sumo Deadlift') limit 1),
            (select id from _ecm_ej where alias='Smith Machine Sumo Deadlift'), 3, 10, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Smith Machine Sumo Deadlift') limit 1),
            (select id from _ecm_ej where alias='Smith Machine Sumo Deadlift'), 4, 10, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Hip Thrust Machine') limit 1),
            (select id from _ecm_ej where alias='Hip Thrust Machine'), 1, 10, 90, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Hip Thrust Machine') limit 1),
            (select id from _ecm_ej where alias='Hip Thrust Machine'), 2, 10, 90, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Hip Thrust Machine') limit 1),
            (select id from _ecm_ej where alias='Hip Thrust Machine'), 3, 10, 90, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Hip Thrust Machine') limit 1),
            (select id from _ecm_ej where alias='Hip Thrust Machine'), 4, 10, 90, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Hip Adduction') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Hip Adduction'), 1, 10, 90, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Hip Adduction') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Hip Adduction'), 2, 10, 90, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Hip Adduction') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Hip Adduction'), 3, 10, 90, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Calf Raise'), 1, 10, 80, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Calf Raise'), 2, 10, 80, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Calf Raise'), 3, 10, 80, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dip Machine Bent Leg Raise') limit 1),
            (select id from _ecm_ej where alias='Dip Machine Bent Leg Raise'), 1, 10, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dip Machine Bent Leg Raise') limit 1),
            (select id from _ecm_ej where alias='Dip Machine Bent Leg Raise'), 2, 10, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dip Machine Bent Leg Raise') limit 1),
            (select id from _ecm_ej where alias='Dip Machine Bent Leg Raise'), 3, 10, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Seated Machine Ab Crunch') limit 1),
            (select id from _ecm_ej where alias='Seated Machine Ab Crunch'), 1, 15, 35, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Seated Machine Ab Crunch') limit 1),
            (select id from _ecm_ej where alias='Seated Machine Ab Crunch'), 2, 15, 35, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Seated Machine Ab Crunch') limit 1),
            (select id from _ecm_ej where alias='Seated Machine Ab Crunch'), 3, 15, 35, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Seated Machine Ab Crunch') limit 1),
            (select id from _ecm_ej where alias='Seated Machine Ab Crunch'), 4, 15, 35, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Ab Roller Wheel Abdominal Roll Out') limit 1),
            (select id from _ecm_ej where alias='Ab Roller Wheel Abdominal Roll Out'), 1, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Ab Roller Wheel Abdominal Roll Out') limit 1),
            (select id from _ecm_ej where alias='Ab Roller Wheel Abdominal Roll Out'), 2, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Ab Roller Wheel Abdominal Roll Out') limit 1),
            (select id from _ecm_ej where alias='Ab Roller Wheel Abdominal Roll Out'), 3, 15, null, 'kg');
  end if;
  -- historial 2026-09-01
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-01', 1,
          '2026-W36', 'completada', '2026-09-01 12:00:00+00'::timestamptz, true)
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Angled Machine Leg Press') limit 1),
            (select id from _ecm_ej where alias='Angled Machine Leg Press'), 1, 10, 120, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Angled Machine Leg Press') limit 1),
            (select id from _ecm_ej where alias='Angled Machine Leg Press'), 2, 10, 120, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Angled Machine Leg Press') limit 1),
            (select id from _ecm_ej where alias='Angled Machine Leg Press'), 3, 10, 120, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Angled Machine Leg Press') limit 1),
            (select id from _ecm_ej where alias='Angled Machine Leg Press'), 4, 10, 120, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Hip Thrust Machine') limit 1),
            (select id from _ecm_ej where alias='Hip Thrust Machine'), 1, 10, 90, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Hip Thrust Machine') limit 1),
            (select id from _ecm_ej where alias='Hip Thrust Machine'), 2, 10, 90, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Hip Thrust Machine') limit 1),
            (select id from _ecm_ej where alias='Hip Thrust Machine'), 3, 10, 90, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Hip Thrust Machine') limit 1),
            (select id from _ecm_ej where alias='Hip Thrust Machine'), 4, 10, 90, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Calf Raise'), 1, 10, 80, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Calf Raise'), 2, 10, 80, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Calf Raise'), 3, 10, 80, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dip Machine Bent Leg Raise') limit 1),
            (select id from _ecm_ej where alias='Dip Machine Bent Leg Raise'), 1, 10, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dip Machine Bent Leg Raise') limit 1),
            (select id from _ecm_ej where alias='Dip Machine Bent Leg Raise'), 2, 10, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dip Machine Bent Leg Raise') limit 1),
            (select id from _ecm_ej where alias='Dip Machine Bent Leg Raise'), 3, 10, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Ab Roller Wheel Abdominal Roll Out') limit 1),
            (select id from _ecm_ej where alias='Ab Roller Wheel Abdominal Roll Out'), 1, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Ab Roller Wheel Abdominal Roll Out') limit 1),
            (select id from _ecm_ej where alias='Ab Roller Wheel Abdominal Roll Out'), 2, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Ab Roller Wheel Abdominal Roll Out') limit 1),
            (select id from _ecm_ej where alias='Ab Roller Wheel Abdominal Roll Out'), 3, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Leg Curl') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Leg Curl'), 1, 8, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Leg Curl') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Leg Curl'), 2, 8, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Leg Curl') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Leg Curl'), 3, 8, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Leg Curl') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Leg Curl'), 4, 8, 50, 'kg');
  end if;

  -- Rutina 2: Upper Body Training
  insert into rutinas (user_id, cliente_id, fase_id, nombre, dia_orden,
                       duracion_estimada_min, tipo_sesion)
  values (v_coach, v_cli, v_fase, 'Upper Body Training', 2, 71, 'fuerza')
  returning id into v_rut;
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'A', 'superserie', 1, null, 1)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Bodyweight Spiderman Lunge To Rotation'), 1, 1, '8 por lado', null);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Bear Squat to Spinal Wave'), 2, 1, '10', null);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Dumbbell Standing Shoulder External Rotations'), 3, 1, '6', null);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Bar Hang'), 4, 1, '60 s', null);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Pull Up'), 5, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Cable Seated Close Row'), 6, 4, '6-12 por lado', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Smith Machine Incline Bench Press'), 7, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Smith Machine Seated Shoulder Press'), 8, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Cable Standing Crossover Chest Fly'), 9, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Smith Machine Shrug'), 10, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Machine Preacher Curl'), 11, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown'), 12, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 13, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Child''s Pose'), 14, 1, '30 s', null);
  -- historial 2026-09-14
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-14', 3,
          '2026-W38', 'completada', '2026-09-14 12:00:00+00'::timestamptz, true)
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Bar Hang') limit 1),
            (select id from _ecm_ej where alias='Bar Hang'), 1, 45, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Seated Close Row') limit 1),
            (select id from _ecm_ej where alias='Cable Seated Close Row'), 1, 8, 45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Seated Close Row') limit 1),
            (select id from _ecm_ej where alias='Cable Seated Close Row'), 2, 8, 45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Seated Close Row') limit 1),
            (select id from _ecm_ej where alias='Cable Seated Close Row'), 3, 8, 45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Seated Close Row') limit 1),
            (select id from _ecm_ej where alias='Cable Seated Close Row'), 4, 8, 45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Smith Machine Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Smith Machine Incline Bench Press'), 1, 10, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Smith Machine Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Smith Machine Incline Bench Press'), 2, 10, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Smith Machine Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Smith Machine Incline Bench Press'), 3, 8, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Smith Machine Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Smith Machine Incline Bench Press'), 4, 6, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Smith Machine Seated Shoulder Press') limit 1),
            (select id from _ecm_ej where alias='Smith Machine Seated Shoulder Press'), 1, 8, 55, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Smith Machine Seated Shoulder Press') limit 1),
            (select id from _ecm_ej where alias='Smith Machine Seated Shoulder Press'), 2, 8, 55, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Smith Machine Seated Shoulder Press') limit 1),
            (select id from _ecm_ej where alias='Smith Machine Seated Shoulder Press'), 3, 8, 55, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Smith Machine Seated Shoulder Press') limit 1),
            (select id from _ecm_ej where alias='Smith Machine Seated Shoulder Press'), 4, 8, 55, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Standing Crossover Chest Fly') limit 1),
            (select id from _ecm_ej where alias='Cable Standing Crossover Chest Fly'), 1, 8, 80, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Standing Crossover Chest Fly') limit 1),
            (select id from _ecm_ej where alias='Cable Standing Crossover Chest Fly'), 2, 8, 80, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Standing Crossover Chest Fly') limit 1),
            (select id from _ecm_ej where alias='Cable Standing Crossover Chest Fly'), 3, 8, 80, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Standing Crossover Chest Fly') limit 1),
            (select id from _ecm_ej where alias='Cable Standing Crossover Chest Fly'), 4, 8, 80, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Smith Machine Shrug') limit 1),
            (select id from _ecm_ej where alias='Smith Machine Shrug'), 1, 1, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Smith Machine Shrug') limit 1),
            (select id from _ecm_ej where alias='Smith Machine Shrug'), 2, 10, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Smith Machine Shrug') limit 1),
            (select id from _ecm_ej where alias='Smith Machine Shrug'), 3, 10, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Smith Machine Shrug') limit 1),
            (select id from _ecm_ej where alias='Smith Machine Shrug'), 4, 10, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Preacher Curl') limit 1),
            (select id from _ecm_ej where alias='Machine Preacher Curl'), 1, 10, 82, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Preacher Curl') limit 1),
            (select id from _ecm_ej where alias='Machine Preacher Curl'), 2, 10, 82, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Preacher Curl') limit 1),
            (select id from _ecm_ej where alias='Machine Preacher Curl'), 3, 10, 82, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown'), 1, 10, 41, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown'), 2, 10, 41, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown'), 3, 10, 41, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown'), 4, 10, 41, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 1, 10, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 2, 10, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 3, 10, 50, 'kg');
  end if;
  -- historial 2026-09-10
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-10', 2,
          '2026-W37', 'completada', '2026-09-10 12:00:00+00'::timestamptz, true)
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Bar Hang') limit 1),
            (select id from _ecm_ej where alias='Bar Hang'), 1, 2700, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Bar Hang') limit 1),
            (select id from _ecm_ej where alias='Bar Hang'), 2, 2700, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Preacher Curl') limit 1),
            (select id from _ecm_ej where alias='Machine Preacher Curl'), 1, 10, 82, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Preacher Curl') limit 1),
            (select id from _ecm_ej where alias='Machine Preacher Curl'), 2, 10, 82, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Preacher Curl') limit 1),
            (select id from _ecm_ej where alias='Machine Preacher Curl'), 3, 10, 82, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown'), 1, 10, 82, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown'), 2, 10, 82, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown'), 3, 10, 82, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 1, 10, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 2, 10, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 3, 10, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Band Internal Shoulder Rotation (90 degrees)') limit 1),
            (select id from _ecm_ej where alias='Band Internal Shoulder Rotation (90 degrees)'), 1, 5, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Band Internal Shoulder Rotation (90 degrees)') limit 1),
            (select id from _ecm_ej where alias='Band Internal Shoulder Rotation (90 degrees)'), 2, 5, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Single Arm Neutral Grip Row') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Single Arm Neutral Grip Row'), 1, 10, 100, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Single Arm Neutral Grip Row') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Single Arm Neutral Grip Row'), 2, 10, 100, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Single Arm Neutral Grip Row') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Single Arm Neutral Grip Row'), 3, 8, 100, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Single Arm Neutral Grip Row') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Single Arm Neutral Grip Row'), 4, 8, 100, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 1, 10, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 2, 8, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 3, 8, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 4, 8, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Chest Fly') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Chest Fly'), 1, 8, 130, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Chest Fly') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Chest Fly'), 2, 8, 130, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Chest Fly') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Chest Fly'), 3, 8, 130, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Chest Fly') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Chest Fly'), 4, 8, 130, 'kg');
  end if;
  -- historial 2026-09-07
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-07', 2,
          '2026-W37', 'completada', '2026-09-07 12:00:00+00'::timestamptz, true)
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Bar Hang') limit 1),
            (select id from _ecm_ej where alias='Bar Hang'), 1, 2700, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Bar Hang') limit 1),
            (select id from _ecm_ej where alias='Bar Hang'), 2, 2700, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Preacher Curl') limit 1),
            (select id from _ecm_ej where alias='Machine Preacher Curl'), 1, 10, 82, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Preacher Curl') limit 1),
            (select id from _ecm_ej where alias='Machine Preacher Curl'), 2, 10, 82, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Preacher Curl') limit 1),
            (select id from _ecm_ej where alias='Machine Preacher Curl'), 3, 10, 82, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown'), 1, 10, 82, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown'), 2, 10, 82, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown'), 3, 10, 82, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 1, 10, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 2, 10, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 3, 10, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Band Internal Shoulder Rotation (90 degrees)') limit 1),
            (select id from _ecm_ej where alias='Band Internal Shoulder Rotation (90 degrees)'), 1, 5, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Band Internal Shoulder Rotation (90 degrees)') limit 1),
            (select id from _ecm_ej where alias='Band Internal Shoulder Rotation (90 degrees)'), 2, 5, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 1, 10, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 2, 8, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 3, 8, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 4, 8, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Chest Fly') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Chest Fly'), 1, 8, 130, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Chest Fly') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Chest Fly'), 2, 8, 130, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Chest Fly') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Chest Fly'), 3, 8, 130, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Chest Fly') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Chest Fly'), 4, 8, 130, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench High Row') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench High Row'), 1, 10, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench High Row') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench High Row'), 2, 10, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench High Row') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench High Row'), 3, 10, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench High Row') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench High Row'), 4, 10, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Kettlebell Alternating Bent Over Row') limit 1),
            (select id from _ecm_ej where alias='Kettlebell Alternating Bent Over Row'), 1, 10, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Kettlebell Alternating Bent Over Row') limit 1),
            (select id from _ecm_ej where alias='Kettlebell Alternating Bent Over Row'), 2, 10, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Kettlebell Alternating Bent Over Row') limit 1),
            (select id from _ecm_ej where alias='Kettlebell Alternating Bent Over Row'), 3, 10, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Kettlebell High Pull') limit 1),
            (select id from _ecm_ej where alias='Kettlebell High Pull'), 1, 8, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Kettlebell High Pull') limit 1),
            (select id from _ecm_ej where alias='Kettlebell High Pull'), 2, 8, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Kettlebell High Pull') limit 1),
            (select id from _ecm_ej where alias='Kettlebell High Pull'), 3, 8, 20, 'kg');
  end if;
  -- historial 2026-09-03
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-03', 1,
          '2026-W36', 'completada', '2026-09-03 12:00:00+00'::timestamptz, true)
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Bar Hang') limit 1),
            (select id from _ecm_ej where alias='Bar Hang'), 1, 2700, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Bar Hang') limit 1),
            (select id from _ecm_ej where alias='Bar Hang'), 2, 2700, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Preacher Curl') limit 1),
            (select id from _ecm_ej where alias='Machine Preacher Curl'), 1, 10, 82, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Preacher Curl') limit 1),
            (select id from _ecm_ej where alias='Machine Preacher Curl'), 2, 10, 82, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Preacher Curl') limit 1),
            (select id from _ecm_ej where alias='Machine Preacher Curl'), 3, 10, 82, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown'), 1, 10, 82, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown'), 2, 10, 82, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown'), 3, 10, 82, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 1, 10, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 2, 10, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 3, 10, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Band Internal Shoulder Rotation (90 degrees)') limit 1),
            (select id from _ecm_ej where alias='Band Internal Shoulder Rotation (90 degrees)'), 1, 5, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Band Internal Shoulder Rotation (90 degrees)') limit 1),
            (select id from _ecm_ej where alias='Band Internal Shoulder Rotation (90 degrees)'), 2, 5, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 1, 10, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 2, 8, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 3, 8, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 4, 8, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Chest Fly') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Chest Fly'), 1, 8, 130, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Chest Fly') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Chest Fly'), 2, 8, 130, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Chest Fly') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Chest Fly'), 3, 8, 130, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Chest Fly') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Chest Fly'), 4, 8, 130, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench High Row') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench High Row'), 1, 10, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench High Row') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench High Row'), 2, 10, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench High Row') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench High Row'), 3, 10, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench High Row') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench High Row'), 4, 10, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Kettlebell Alternating Bent Over Row') limit 1),
            (select id from _ecm_ej where alias='Kettlebell Alternating Bent Over Row'), 1, 10, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Kettlebell Alternating Bent Over Row') limit 1),
            (select id from _ecm_ej where alias='Kettlebell Alternating Bent Over Row'), 2, 10, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Kettlebell Alternating Bent Over Row') limit 1),
            (select id from _ecm_ej where alias='Kettlebell Alternating Bent Over Row'), 3, 10, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Kettlebell High Pull') limit 1),
            (select id from _ecm_ej where alias='Kettlebell High Pull'), 1, 8, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Kettlebell High Pull') limit 1),
            (select id from _ecm_ej where alias='Kettlebell High Pull'), 2, 8, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Kettlebell High Pull') limit 1),
            (select id from _ecm_ej where alias='Kettlebell High Pull'), 3, 8, 20, 'kg');
  end if;
  -- historial 2026-08-31
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-08-31', 1,
          '2026-W36', 'completada', '2026-08-31 12:00:00+00'::timestamptz, true)
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Bar Hang') limit 1),
            (select id from _ecm_ej where alias='Bar Hang'), 1, 2700, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Bar Hang') limit 1),
            (select id from _ecm_ej where alias='Bar Hang'), 2, 2700, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Preacher Curl') limit 1),
            (select id from _ecm_ej where alias='Machine Preacher Curl'), 1, 10, 82, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Preacher Curl') limit 1),
            (select id from _ecm_ej where alias='Machine Preacher Curl'), 2, 10, 82, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Preacher Curl') limit 1),
            (select id from _ecm_ej where alias='Machine Preacher Curl'), 3, 10, 82, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown'), 1, 10, 82, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown'), 2, 10, 82, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown'), 3, 10, 82, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 1, 10, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 2, 10, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 3, 10, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Band Internal Shoulder Rotation (90 degrees)') limit 1),
            (select id from _ecm_ej where alias='Band Internal Shoulder Rotation (90 degrees)'), 1, 5, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Band Internal Shoulder Rotation (90 degrees)') limit 1),
            (select id from _ecm_ej where alias='Band Internal Shoulder Rotation (90 degrees)'), 2, 5, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 1, 10, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 2, 8, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 3, 8, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 4, 8, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Chest Fly') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Chest Fly'), 1, 8, 130, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Chest Fly') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Chest Fly'), 2, 8, 130, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Chest Fly') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Chest Fly'), 3, 8, 130, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Chest Fly') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Chest Fly'), 4, 8, 130, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench High Row') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench High Row'), 1, 10, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench High Row') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench High Row'), 2, 10, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench High Row') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench High Row'), 3, 10, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench High Row') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench High Row'), 4, 10, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Kettlebell Alternating Bent Over Row') limit 1),
            (select id from _ecm_ej where alias='Kettlebell Alternating Bent Over Row'), 1, 10, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Kettlebell Alternating Bent Over Row') limit 1),
            (select id from _ecm_ej where alias='Kettlebell Alternating Bent Over Row'), 2, 10, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Kettlebell Alternating Bent Over Row') limit 1),
            (select id from _ecm_ej where alias='Kettlebell Alternating Bent Over Row'), 3, 10, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Kettlebell High Pull') limit 1),
            (select id from _ecm_ej where alias='Kettlebell High Pull'), 1, 8, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Kettlebell High Pull') limit 1),
            (select id from _ecm_ej where alias='Kettlebell High Pull'), 2, 8, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Kettlebell High Pull') limit 1),
            (select id from _ecm_ej where alias='Kettlebell High Pull'), 3, 8, 20, 'kg');
  end if;

  select count(*) into v_n from rutinas where fase_id = v_fase;
  raise notice 'OK · Andrés Yepes: fase Cycle 14 con % rutinas y % series de historial.', v_n,
        (select count(*) from series_log sl join sesiones s on s.id = sl.sesion_id where s.fase_id = v_fase);
end $cli$;

-- ─────────────────────────────────────────────────────────────────────
-- DIANA TOVAR · Cycle 7 · 6 semanas (2026-08-17 → 2026-09-27)
-- ─────────────────────────────────────────────────────────────────────
do $cli$
declare v_coach uuid; v_cli uuid; v_fase uuid; v_rut uuid; v_blo uuid; v_ses uuid; v_n int;
begin
  select id, user_id into v_cli, v_coach from clientes where nombre ilike '%diana%tovar%' limit 1;
  if v_cli is null then
    raise warning 'SALTADO: no encuentro a «Diana Tovar» en `clientes` (patrón %%diana%%tovar%%). Corrige el nombre y vuelve a correr.';
    return;
  end if;
  if exists (select 1 from fases where cliente_id = v_cli and nombre = 'Cycle 7') then
    raise notice 'SALTADO: «Diana Tovar» ya tiene la fase Cycle 7 cargada.';
    return;
  end if;

  insert into fases (user_id, cliente_id, nombre, objetivo, notas_coach, semanas,
                     fecha_inicio, orden, estado)
  values (v_coach, v_cli, 'Cycle 7',
          'Bloque importado de Trainerize — la rutina que ya venía haciendo.',
          'Importado el 2026-09-20 desde el PDF de Trainerize (Cycle 7, 2026-08-17 a 2026-09-27). Revisar antes de enviar al cliente.',
          6, date '2026-08-17',
          coalesce((select max(orden)+1 from fases where cliente_id = v_cli), 1), 'borrador')
  returning id into v_fase;

  -- Rutina 1: Lower Body + Core
  insert into rutinas (user_id, cliente_id, fase_id, nombre, dia_orden,
                       duracion_estimada_min, tipo_sesion)
  values (v_coach, v_cli, v_fase, 'Lower Body + Core', 1, 52, 'fuerza')
  returning id into v_rut;
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'A', 'circuito', 2, 40, 1)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='90-90 Hip Switch'), 1, 1, '5', 40);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Cossack Squat to T-Spine Reach'), 2, 1, '5 por lado', 40);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Glute Side Circle'), 3, 1, '5 por lado', 40);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Lateral Shuttle Run'), 4, 1, '60 s', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Dumbbell Stationary Lunge'), 5, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Bench Hip Thrust'), 6, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Lateral Shuttle Run'), 7, 1, '60 s', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Bodyweight Deadlift'), 8, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Body Weight Calf Raise'), 9, 4, '6-12', 45);
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'B', 'circuito', 3, 45, 2)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Mountain Climber'), 10, 1, '10-15', 45);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Bodyweight Deadbug'), 11, 1, '10-15', 45);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Seated Hip Twist'), 12, 1, '10-15', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Lateral Shuttle Run'), 13, 1, '60 s', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Static Pigeon Stretch'), 14, 1, '30 s por lado', null);
  -- historial 2026-09-09
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-09', 4,
          '2026-W37', 'completada', '2026-09-09 12:00:00+00'::timestamptz, true)
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Body Weight Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Body Weight Calf Raise'), 1, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Body Weight Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Body Weight Calf Raise'), 2, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Body Weight Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Body Weight Calf Raise'), 3, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Body Weight Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Body Weight Calf Raise'), 4, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mountain Climber') limit 1),
            (select id from _ecm_ej where alias='Mountain Climber'), 1, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mountain Climber') limit 1),
            (select id from _ecm_ej where alias='Mountain Climber'), 2, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Seated Hip Twist') limit 1),
            (select id from _ecm_ej where alias='Seated Hip Twist'), 1, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Seated Hip Twist') limit 1),
            (select id from _ecm_ej where alias='Seated Hip Twist'), 2, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Seated Hip Twist') limit 1),
            (select id from _ecm_ej where alias='Seated Hip Twist'), 3, 15, null, 'kg');
  end if;
  -- historial 2026-09-02
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-02', 3,
          '2026-W36', 'completada', '2026-09-02 12:00:00+00'::timestamptz, true)
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Body Weight Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Body Weight Calf Raise'), 1, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Body Weight Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Body Weight Calf Raise'), 2, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Body Weight Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Body Weight Calf Raise'), 3, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Body Weight Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Body Weight Calf Raise'), 4, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mountain Climber') limit 1),
            (select id from _ecm_ej where alias='Mountain Climber'), 1, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mountain Climber') limit 1),
            (select id from _ecm_ej where alias='Mountain Climber'), 2, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Seated Hip Twist') limit 1),
            (select id from _ecm_ej where alias='Seated Hip Twist'), 1, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Seated Hip Twist') limit 1),
            (select id from _ecm_ej where alias='Seated Hip Twist'), 2, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Seated Hip Twist') limit 1),
            (select id from _ecm_ej where alias='Seated Hip Twist'), 3, 15, null, 'kg');
  end if;
  -- historial 2026-08-29
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-08-29', 2,
          '2026-W35', 'completada', '2026-08-29 12:00:00+00'::timestamptz, true)
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Body Weight Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Body Weight Calf Raise'), 1, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Body Weight Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Body Weight Calf Raise'), 2, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Body Weight Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Body Weight Calf Raise'), 3, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Body Weight Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Body Weight Calf Raise'), 4, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mountain Climber') limit 1),
            (select id from _ecm_ej where alias='Mountain Climber'), 1, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mountain Climber') limit 1),
            (select id from _ecm_ej where alias='Mountain Climber'), 2, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mountain Climber') limit 1),
            (select id from _ecm_ej where alias='Mountain Climber'), 3, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Seated Hip Twist') limit 1),
            (select id from _ecm_ej where alias='Seated Hip Twist'), 1, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Seated Hip Twist') limit 1),
            (select id from _ecm_ej where alias='Seated Hip Twist'), 2, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Seated Hip Twist') limit 1),
            (select id from _ecm_ej where alias='Seated Hip Twist'), 3, 15, null, 'kg');
  end if;
  -- historial 2026-08-22
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-08-22', 1,
          '2026-W34', 'completada', '2026-08-22 12:00:00+00'::timestamptz, true)
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Body Weight Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Body Weight Calf Raise'), 1, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Body Weight Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Body Weight Calf Raise'), 2, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Body Weight Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Body Weight Calf Raise'), 3, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Body Weight Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Body Weight Calf Raise'), 4, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mountain Climber') limit 1),
            (select id from _ecm_ej where alias='Mountain Climber'), 1, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mountain Climber') limit 1),
            (select id from _ecm_ej where alias='Mountain Climber'), 2, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mountain Climber') limit 1),
            (select id from _ecm_ej where alias='Mountain Climber'), 3, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Seated Hip Twist') limit 1),
            (select id from _ecm_ej where alias='Seated Hip Twist'), 1, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Seated Hip Twist') limit 1),
            (select id from _ecm_ej where alias='Seated Hip Twist'), 2, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Seated Hip Twist') limit 1),
            (select id from _ecm_ej where alias='Seated Hip Twist'), 3, 15, null, 'kg');
  end if;

  -- Rutina 2: Upper Body
  insert into rutinas (user_id, cliente_id, fase_id, nombre, dia_orden,
                       duracion_estimada_min, tipo_sesion)
  values (v_coach, v_cli, v_fase, 'Upper Body', 2, 48, 'fuerza')
  returning id into v_rut;
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'A', 'circuito', 3, 35, 1)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Hinge to T-Rotation'), 1, 1, '5 por lado', 35);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Cobra'), 2, 1, '6', 35);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Quadruped Scapular Push Up'), 3, 1, '6', 35);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Trunk Rotation'), 4, 1, '6', 35);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Lateral Shuttle Run'), 5, 1, '60 s', 30);
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'B', 'circuito', 4, 50, 2)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Mini Band Wall Slides'), 6, 1, '8-15', 50);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='SuperBand Single Arm Row'), 7, 1, '8-15 por lado', 50);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Dumbbell Alternating Bicep Curl'), 8, 1, '8-15', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Lateral Shuttle Run'), 9, 1, '60 s', 30);
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'C', 'circuito', 3, 50, 3)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Dumbbell Glute Bridge Chest Press'), 10, 1, '8-15', 50);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Dumbbell Clean to Press'), 11, 1, '8-15', 50);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='SuperBand Anchored Tricep Pushdown'), 12, 1, '6-12 por lado', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Lateral Shuttle Run'), 13, 1, '60 s', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Child''s Pose'), 14, 1, '30 s', null);
  -- historial 2026-09-11
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-11', 4,
          '2026-W37', 'completada', '2026-09-11 12:00:00+00'::timestamptz, true)
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Wall Slides') limit 1),
            (select id from _ecm_ej where alias='Mini Band Wall Slides'), 1, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Wall Slides') limit 1),
            (select id from _ecm_ej where alias='Mini Band Wall Slides'), 2, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Wall Slides') limit 1),
            (select id from _ecm_ej where alias='Mini Band Wall Slides'), 3, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Wall Slides') limit 1),
            (select id from _ecm_ej where alias='Mini Band Wall Slides'), 4, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='SuperBand Single Arm Row') limit 1),
            (select id from _ecm_ej where alias='SuperBand Single Arm Row'), 1, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='SuperBand Single Arm Row') limit 1),
            (select id from _ecm_ej where alias='SuperBand Single Arm Row'), 2, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='SuperBand Single Arm Row') limit 1),
            (select id from _ecm_ej where alias='SuperBand Single Arm Row'), 3, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='SuperBand Single Arm Row') limit 1),
            (select id from _ecm_ej where alias='SuperBand Single Arm Row'), 4, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='SuperBand Anchored Tricep Pushdown') limit 1),
            (select id from _ecm_ej where alias='SuperBand Anchored Tricep Pushdown'), 1, 12, null, 'kg');
  end if;
  -- historial 2026-09-07
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-07', 4,
          '2026-W37', 'completada', '2026-09-07 12:00:00+00'::timestamptz, true)
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Wall Slides') limit 1),
            (select id from _ecm_ej where alias='Mini Band Wall Slides'), 1, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Wall Slides') limit 1),
            (select id from _ecm_ej where alias='Mini Band Wall Slides'), 2, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Wall Slides') limit 1),
            (select id from _ecm_ej where alias='Mini Band Wall Slides'), 3, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Wall Slides') limit 1),
            (select id from _ecm_ej where alias='Mini Band Wall Slides'), 4, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='SuperBand Single Arm Row') limit 1),
            (select id from _ecm_ej where alias='SuperBand Single Arm Row'), 1, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='SuperBand Single Arm Row') limit 1),
            (select id from _ecm_ej where alias='SuperBand Single Arm Row'), 2, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='SuperBand Single Arm Row') limit 1),
            (select id from _ecm_ej where alias='SuperBand Single Arm Row'), 3, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='SuperBand Single Arm Row') limit 1),
            (select id from _ecm_ej where alias='SuperBand Single Arm Row'), 4, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='SuperBand Anchored Tricep Pushdown') limit 1),
            (select id from _ecm_ej where alias='SuperBand Anchored Tricep Pushdown'), 1, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='SuperBand Anchored Tricep Pushdown') limit 1),
            (select id from _ecm_ej where alias='SuperBand Anchored Tricep Pushdown'), 2, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='SuperBand Anchored Tricep Pushdown') limit 1),
            (select id from _ecm_ej where alias='SuperBand Anchored Tricep Pushdown'), 3, 12, null, 'kg');
  end if;
  -- historial 2026-09-04
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-04', 3,
          '2026-W36', 'completada', '2026-09-04 12:00:00+00'::timestamptz, true)
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Wall Slides') limit 1),
            (select id from _ecm_ej where alias='Mini Band Wall Slides'), 1, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Wall Slides') limit 1),
            (select id from _ecm_ej where alias='Mini Band Wall Slides'), 2, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Wall Slides') limit 1),
            (select id from _ecm_ej where alias='Mini Band Wall Slides'), 3, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Wall Slides') limit 1),
            (select id from _ecm_ej where alias='Mini Band Wall Slides'), 4, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='SuperBand Single Arm Row') limit 1),
            (select id from _ecm_ej where alias='SuperBand Single Arm Row'), 1, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='SuperBand Single Arm Row') limit 1),
            (select id from _ecm_ej where alias='SuperBand Single Arm Row'), 2, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='SuperBand Single Arm Row') limit 1),
            (select id from _ecm_ej where alias='SuperBand Single Arm Row'), 3, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='SuperBand Single Arm Row') limit 1),
            (select id from _ecm_ej where alias='SuperBand Single Arm Row'), 4, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='SuperBand Anchored Tricep Pushdown') limit 1),
            (select id from _ecm_ej where alias='SuperBand Anchored Tricep Pushdown'), 1, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='SuperBand Anchored Tricep Pushdown') limit 1),
            (select id from _ecm_ej where alias='SuperBand Anchored Tricep Pushdown'), 2, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='SuperBand Anchored Tricep Pushdown') limit 1),
            (select id from _ecm_ej where alias='SuperBand Anchored Tricep Pushdown'), 3, 15, null, 'kg');
  end if;
  -- historial 2026-08-31
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-08-31', 3,
          '2026-W36', 'completada', '2026-08-31 12:00:00+00'::timestamptz, true)
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Wall Slides') limit 1),
            (select id from _ecm_ej where alias='Mini Band Wall Slides'), 1, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Wall Slides') limit 1),
            (select id from _ecm_ej where alias='Mini Band Wall Slides'), 2, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Wall Slides') limit 1),
            (select id from _ecm_ej where alias='Mini Band Wall Slides'), 3, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Wall Slides') limit 1),
            (select id from _ecm_ej where alias='Mini Band Wall Slides'), 4, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='SuperBand Single Arm Row') limit 1),
            (select id from _ecm_ej where alias='SuperBand Single Arm Row'), 1, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='SuperBand Single Arm Row') limit 1),
            (select id from _ecm_ej where alias='SuperBand Single Arm Row'), 2, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='SuperBand Single Arm Row') limit 1),
            (select id from _ecm_ej where alias='SuperBand Single Arm Row'), 3, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='SuperBand Single Arm Row') limit 1),
            (select id from _ecm_ej where alias='SuperBand Single Arm Row'), 4, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='SuperBand Anchored Tricep Pushdown') limit 1),
            (select id from _ecm_ej where alias='SuperBand Anchored Tricep Pushdown'), 1, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='SuperBand Anchored Tricep Pushdown') limit 1),
            (select id from _ecm_ej where alias='SuperBand Anchored Tricep Pushdown'), 2, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='SuperBand Anchored Tricep Pushdown') limit 1),
            (select id from _ecm_ej where alias='SuperBand Anchored Tricep Pushdown'), 3, 12, null, 'kg');
  end if;
  -- historial 2026-08-28
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-08-28', 2,
          '2026-W35', 'completada', '2026-08-28 12:00:00+00'::timestamptz, true)
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Wall Slides') limit 1),
            (select id from _ecm_ej where alias='Mini Band Wall Slides'), 1, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Wall Slides') limit 1),
            (select id from _ecm_ej where alias='Mini Band Wall Slides'), 2, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Wall Slides') limit 1),
            (select id from _ecm_ej where alias='Mini Band Wall Slides'), 3, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Wall Slides') limit 1),
            (select id from _ecm_ej where alias='Mini Band Wall Slides'), 4, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='SuperBand Single Arm Row') limit 1),
            (select id from _ecm_ej where alias='SuperBand Single Arm Row'), 1, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='SuperBand Single Arm Row') limit 1),
            (select id from _ecm_ej where alias='SuperBand Single Arm Row'), 2, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='SuperBand Single Arm Row') limit 1),
            (select id from _ecm_ej where alias='SuperBand Single Arm Row'), 3, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='SuperBand Single Arm Row') limit 1),
            (select id from _ecm_ej where alias='SuperBand Single Arm Row'), 4, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='SuperBand Anchored Tricep Pushdown') limit 1),
            (select id from _ecm_ej where alias='SuperBand Anchored Tricep Pushdown'), 1, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='SuperBand Anchored Tricep Pushdown') limit 1),
            (select id from _ecm_ej where alias='SuperBand Anchored Tricep Pushdown'), 2, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='SuperBand Anchored Tricep Pushdown') limit 1),
            (select id from _ecm_ej where alias='SuperBand Anchored Tricep Pushdown'), 3, 15, null, 'kg');
  end if;

  select count(*) into v_n from rutinas where fase_id = v_fase;
  raise notice 'OK · Diana Tovar: fase Cycle 7 con % rutinas y % series de historial.', v_n,
        (select count(*) from series_log sl join sesiones s on s.id = sl.sesion_id where s.fase_id = v_fase);
end $cli$;

-- ─────────────────────────────────────────────────────────────────────
-- DAVID FORERO · Cycle 17 · 4 semanas (2026-08-24 → 2026-09-20)
-- ─────────────────────────────────────────────────────────────────────
do $cli$
declare v_coach uuid; v_cli uuid; v_fase uuid; v_rut uuid; v_blo uuid; v_ses uuid; v_n int;
begin
  select id, user_id into v_cli, v_coach from clientes where nombre ilike '%david%forero%' limit 1;
  if v_cli is null then
    raise warning 'SALTADO: no encuentro a «David Forero» en `clientes` (patrón %%david%%forero%%). Corrige el nombre y vuelve a correr.';
    return;
  end if;
  if exists (select 1 from fases where cliente_id = v_cli and nombre = 'Cycle 17') then
    raise notice 'SALTADO: «David Forero» ya tiene la fase Cycle 17 cargada.';
    return;
  end if;

  insert into fases (user_id, cliente_id, nombre, objetivo, notas_coach, semanas,
                     fecha_inicio, orden, estado)
  values (v_coach, v_cli, 'Cycle 17',
          'Bloque importado de Trainerize — la rutina que ya venía haciendo.',
          'Importado el 2026-09-20 desde el PDF de Trainerize (Cycle 17, 2026-08-24 a 2026-09-20). Revisar antes de enviar al cliente.',
          4, date '2026-08-24',
          coalesce((select max(orden)+1 from fases where cliente_id = v_cli), 1), 'borrador')
  returning id into v_fase;

  -- Rutina 1: Lower Body + Core Training
  insert into rutinas (user_id, cliente_id, fase_id, nombre, dia_orden,
                       duracion_estimada_min, tipo_sesion)
  values (v_coach, v_cli, v_fase, 'Lower Body + Core Training', 1, 57, 'fuerza')
  returning id into v_rut;
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Bodyweight Alternating Cossack Squat'), 1, 2, '5 por lado', null);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Bosu Lateral Bounce to Squat Jump'), 2, 2, '6-8 por lado', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Dumbbell Bulgarian Split Squat'), 3, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Machine Seated Leg Extension'), 4, 3, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Machine Lying Leg Curl'), 5, 3, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Hip Thrust Machine'), 6, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Machine Seated Hip Adduction'), 7, 3, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Leg Press Machine Calf Raise'), 8, 3, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Pallof Press'), 9, 3, '15', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Ab Roller Wheel Abdominal Roll Out'), 10, 3, '15', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Dip Machine Straight Leg Raise'), 11, 3, '15', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Static Pigeon Stretch'), 12, 1, '30 s por lado', null);
  -- historial 2026-09-08
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-08', 3,
          '2026-W37', 'completada', '2026-09-08 12:00:00+00'::timestamptz, true)
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Leg Extension') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Leg Extension'), 1, 12, 68, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Leg Extension') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Leg Extension'), 2, 9, 68, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Leg Extension') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Leg Extension'), 3, 7, 70, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Lying Leg Curl') limit 1),
            (select id from _ecm_ej where alias='Machine Lying Leg Curl'), 1, 9, 45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Lying Leg Curl') limit 1),
            (select id from _ecm_ej where alias='Machine Lying Leg Curl'), 2, 8, 45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Lying Leg Curl') limit 1),
            (select id from _ecm_ej where alias='Machine Lying Leg Curl'), 3, 7, 45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Leg Press Machine Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Leg Press Machine Calf Raise'), 1, 11, 52, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Leg Press Machine Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Leg Press Machine Calf Raise'), 2, 10, 52, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Leg Press Machine Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Leg Press Machine Calf Raise'), 3, 8, 54, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dip Machine Straight Leg Raise') limit 1),
            (select id from _ecm_ej where alias='Dip Machine Straight Leg Raise'), 1, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dip Machine Straight Leg Raise') limit 1),
            (select id from _ecm_ej where alias='Dip Machine Straight Leg Raise'), 2, 11, null, 'kg');
  end if;
  -- historial 2026-09-01
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-01', 2,
          '2026-W36', 'completada', '2026-09-01 12:00:00+00'::timestamptz, true)
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Leg Extension') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Leg Extension'), 1, 9, 68, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Leg Extension') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Leg Extension'), 2, 9, 68, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Leg Extension') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Leg Extension'), 3, 8, 68, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Lying Leg Curl') limit 1),
            (select id from _ecm_ej where alias='Machine Lying Leg Curl'), 1, 9, 45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Lying Leg Curl') limit 1),
            (select id from _ecm_ej where alias='Machine Lying Leg Curl'), 2, 9, 45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Lying Leg Curl') limit 1),
            (select id from _ecm_ej where alias='Machine Lying Leg Curl'), 3, 8, 45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Hip Adduction') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Hip Adduction'), 1, 12, 80, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Hip Adduction') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Hip Adduction'), 2, 12, 85, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Hip Adduction') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Hip Adduction'), 3, 10, 86, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Leg Press Machine Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Leg Press Machine Calf Raise'), 1, 11, 52, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Leg Press Machine Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Leg Press Machine Calf Raise'), 2, 10, 52, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Leg Press Machine Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Leg Press Machine Calf Raise'), 3, 9, 54, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Ab Roller Wheel Abdominal Roll Out') limit 1),
            (select id from _ecm_ej where alias='Ab Roller Wheel Abdominal Roll Out'), 1, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Ab Roller Wheel Abdominal Roll Out') limit 1),
            (select id from _ecm_ej where alias='Ab Roller Wheel Abdominal Roll Out'), 2, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Ab Roller Wheel Abdominal Roll Out') limit 1),
            (select id from _ecm_ej where alias='Ab Roller Wheel Abdominal Roll Out'), 3, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dip Machine Straight Leg Raise') limit 1),
            (select id from _ecm_ej where alias='Dip Machine Straight Leg Raise'), 1, 14, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dip Machine Straight Leg Raise') limit 1),
            (select id from _ecm_ej where alias='Dip Machine Straight Leg Raise'), 2, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dip Machine Straight Leg Raise') limit 1),
            (select id from _ecm_ej where alias='Dip Machine Straight Leg Raise'), 3, 12, null, 'kg');
  end if;
  -- historial 2026-08-25
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-08-25', 1,
          '2026-W35', 'completada', '2026-08-25 12:00:00+00'::timestamptz, true)
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Hip Thrust Machine') limit 1),
            (select id from _ecm_ej where alias='Hip Thrust Machine'), 1, 10, 80, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Hip Thrust Machine') limit 1),
            (select id from _ecm_ej where alias='Hip Thrust Machine'), 2, 10, 90, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Hip Thrust Machine') limit 1),
            (select id from _ecm_ej where alias='Hip Thrust Machine'), 3, 9, 100, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Hip Thrust Machine') limit 1),
            (select id from _ecm_ej where alias='Hip Thrust Machine'), 4, 8, 100, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dip Machine Straight Leg Raise') limit 1),
            (select id from _ecm_ej where alias='Dip Machine Straight Leg Raise'), 1, 14, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dip Machine Straight Leg Raise') limit 1),
            (select id from _ecm_ej where alias='Dip Machine Straight Leg Raise'), 2, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dip Machine Straight Leg Raise') limit 1),
            (select id from _ecm_ej where alias='Dip Machine Straight Leg Raise'), 3, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Smith Machine Back Squat') limit 1),
            (select id from _ecm_ej where alias='Smith Machine Back Squat'), 1, 12, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Smith Machine Back Squat') limit 1),
            (select id from _ecm_ej where alias='Smith Machine Back Squat'), 2, 9, 60, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Smith Machine Back Squat') limit 1),
            (select id from _ecm_ej where alias='Smith Machine Back Squat'), 3, 9, 60, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Smith Machine Back Squat') limit 1),
            (select id from _ecm_ej where alias='Smith Machine Back Squat'), 4, 8, 60, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Barbell Romanian Deadlift') limit 1),
            (select id from _ecm_ej where alias='Barbell Romanian Deadlift'), 1, 10, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Barbell Romanian Deadlift') limit 1),
            (select id from _ecm_ej where alias='Barbell Romanian Deadlift'), 2, 10, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Barbell Romanian Deadlift') limit 1),
            (select id from _ecm_ej where alias='Barbell Romanian Deadlift'), 3, 10, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Standing Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Machine Standing Calf Raise'), 1, 12, 100, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Standing Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Machine Standing Calf Raise'), 2, 12, 120, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Standing Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Machine Standing Calf Raise'), 3, 12, 130, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Standing Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Machine Standing Calf Raise'), 4, 12, 140, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Seated Machine Ab Crunch') limit 1),
            (select id from _ecm_ej where alias='Seated Machine Ab Crunch'), 1, 15, 43, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Seated Machine Ab Crunch') limit 1),
            (select id from _ecm_ej where alias='Seated Machine Ab Crunch'), 2, 15, 45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Seated Machine Ab Crunch') limit 1),
            (select id from _ecm_ej where alias='Seated Machine Ab Crunch'), 3, 15, 45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Russian Twist') limit 1),
            (select id from _ecm_ej where alias='Plate Russian Twist'), 1, 12, 10, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Russian Twist') limit 1),
            (select id from _ecm_ej where alias='Plate Russian Twist'), 2, 12, 10, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Russian Twist') limit 1),
            (select id from _ecm_ej where alias='Plate Russian Twist'), 3, 12, 10, 'kg');
  end if;

  -- Rutina 2: Pull Training
  insert into rutinas (user_id, cliente_id, fase_id, nombre, dia_orden,
                       duracion_estimada_min, tipo_sesion)
  values (v_coach, v_cli, v_fase, 'Pull Training', 2, 58, 'fuerza')
  returning id into v_rut;
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Running'), 1, 1, '2 min a intensidad moderada', null);
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'A', 'circuito', 2, 30, 1)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Mini Band Wall Slides'), 2, 1, '5', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Mini Band Standing I''s'), 3, 1, '5', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Bar Hang'), 4, 1, '60 s', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Plate Weighted Wide Grip Pull Up'), 5, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Cable Seated Close Grip Row'), 6, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='EZ Bar Preacher Curl'), 7, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 8, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Dumbbell Incline Alternating Curl'), 9, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Smith Machine Shrug'), 10, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Machine Seated Reverse Fly'), 11, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Half Lord of the Fishes'), 12, 1, '30 s', null);
  -- historial 2026-09-03
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-03', 2,
          '2026-W36', 'completada', '2026-09-03 12:00:00+00'::timestamptz, true)
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Bar Hang') limit 1),
            (select id from _ecm_ej where alias='Bar Hang'), 1, 30, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Weighted Wide Grip Pull Up') limit 1),
            (select id from _ecm_ej where alias='Plate Weighted Wide Grip Pull Up'), 1, 7, 7.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Weighted Wide Grip Pull Up') limit 1),
            (select id from _ecm_ej where alias='Plate Weighted Wide Grip Pull Up'), 2, 7, 7.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Weighted Wide Grip Pull Up') limit 1),
            (select id from _ecm_ej where alias='Plate Weighted Wide Grip Pull Up'), 3, 6, 7.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Weighted Wide Grip Pull Up') limit 1),
            (select id from _ecm_ej where alias='Plate Weighted Wide Grip Pull Up'), 4, 6, 7.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Seated Close Grip Row') limit 1),
            (select id from _ecm_ej where alias='Cable Seated Close Grip Row'), 1, 12, 65, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Seated Close Grip Row') limit 1),
            (select id from _ecm_ej where alias='Cable Seated Close Grip Row'), 2, 12, 65, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Seated Close Grip Row') limit 1),
            (select id from _ecm_ej where alias='Cable Seated Close Grip Row'), 3, 11, 70, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Seated Close Grip Row') limit 1),
            (select id from _ecm_ej where alias='Cable Seated Close Grip Row'), 4, 9, 77, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='EZ Bar Preacher Curl') limit 1),
            (select id from _ecm_ej where alias='EZ Bar Preacher Curl'), 1, 10, 30, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='EZ Bar Preacher Curl') limit 1),
            (select id from _ecm_ej where alias='EZ Bar Preacher Curl'), 2, 10, 30, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='EZ Bar Preacher Curl') limit 1),
            (select id from _ecm_ej where alias='EZ Bar Preacher Curl'), 3, 8, 30, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='EZ Bar Preacher Curl') limit 1),
            (select id from _ecm_ej where alias='EZ Bar Preacher Curl'), 4, 6, 34, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 1, 10, 16, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 2, 10, 16, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 3, 9, 16, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 4, 7, 18, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Alternating Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Alternating Curl'), 1, 10, 12, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Alternating Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Alternating Curl'), 2, 9, 12, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Alternating Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Alternating Curl'), 3, 8, 12, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Alternating Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Alternating Curl'), 4, 7, 12, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Smith Machine Shrug') limit 1),
            (select id from _ecm_ej where alias='Smith Machine Shrug'), 1, 10, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Smith Machine Shrug') limit 1),
            (select id from _ecm_ej where alias='Smith Machine Shrug'), 2, 10, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Smith Machine Shrug') limit 1),
            (select id from _ecm_ej where alias='Smith Machine Shrug'), 3, 10, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Smith Machine Shrug') limit 1),
            (select id from _ecm_ej where alias='Smith Machine Shrug'), 4, 7, 50, 'kg');
  end if;
  -- historial 2026-08-27
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-08-27', 1,
          '2026-W35', 'completada', '2026-08-27 12:00:00+00'::timestamptz, true)
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Wall Slides') limit 1),
            (select id from _ecm_ej where alias='Mini Band Wall Slides'), 1, 5, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Wall Slides') limit 1),
            (select id from _ecm_ej where alias='Mini Band Wall Slides'), 2, 5, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Standing I''s') limit 1),
            (select id from _ecm_ej where alias='Mini Band Standing I''s'), 1, 5, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Standing I''s') limit 1),
            (select id from _ecm_ej where alias='Mini Band Standing I''s'), 2, 5, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Bar Hang') limit 1),
            (select id from _ecm_ej where alias='Bar Hang'), 1, 30, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Weighted Wide Grip Pull Up') limit 1),
            (select id from _ecm_ej where alias='Plate Weighted Wide Grip Pull Up'), 1, 6, 7.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Weighted Wide Grip Pull Up') limit 1),
            (select id from _ecm_ej where alias='Plate Weighted Wide Grip Pull Up'), 2, 6, 7.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Weighted Wide Grip Pull Up') limit 1),
            (select id from _ecm_ej where alias='Plate Weighted Wide Grip Pull Up'), 3, 6, 7.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Weighted Wide Grip Pull Up') limit 1),
            (select id from _ecm_ej where alias='Plate Weighted Wide Grip Pull Up'), 4, 5, 7.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Seated Close Grip Row') limit 1),
            (select id from _ecm_ej where alias='Cable Seated Close Grip Row'), 1, 12, 57, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Seated Close Grip Row') limit 1),
            (select id from _ecm_ej where alias='Cable Seated Close Grip Row'), 2, 12, 65, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Seated Close Grip Row') limit 1),
            (select id from _ecm_ej where alias='Cable Seated Close Grip Row'), 3, 11, 70, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Seated Close Grip Row') limit 1),
            (select id from _ecm_ej where alias='Cable Seated Close Grip Row'), 4, 9, 77, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='EZ Bar Preacher Curl') limit 1),
            (select id from _ecm_ej where alias='EZ Bar Preacher Curl'), 1, 10, 30, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='EZ Bar Preacher Curl') limit 1),
            (select id from _ecm_ej where alias='EZ Bar Preacher Curl'), 2, 10, 30, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='EZ Bar Preacher Curl') limit 1),
            (select id from _ecm_ej where alias='EZ Bar Preacher Curl'), 3, 8, 30, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='EZ Bar Preacher Curl') limit 1),
            (select id from _ecm_ej where alias='EZ Bar Preacher Curl'), 4, 6, 34, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 1, 10, 16, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 2, 10, 16, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 3, 9, 16, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 4, 6, 18, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Alternating Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Alternating Curl'), 1, 10, 12, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Alternating Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Alternating Curl'), 2, 9, 12, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Alternating Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Alternating Curl'), 3, 8, 12, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Alternating Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Alternating Curl'), 4, 6, 12, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Smith Machine Shrug') limit 1),
            (select id from _ecm_ej where alias='Smith Machine Shrug'), 1, 10, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Smith Machine Shrug') limit 1),
            (select id from _ecm_ej where alias='Smith Machine Shrug'), 2, 10, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Smith Machine Shrug') limit 1),
            (select id from _ecm_ej where alias='Smith Machine Shrug'), 3, 9, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Smith Machine Shrug') limit 1),
            (select id from _ecm_ej where alias='Smith Machine Shrug'), 4, 6, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Reverse Fly') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Reverse Fly'), 1, 12, 36, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Reverse Fly') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Reverse Fly'), 2, 9, 39, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Reverse Fly') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Reverse Fly'), 3, 8, 39, 'kg');
  end if;

  -- Rutina 3: Push Training
  insert into rutinas (user_id, cliente_id, fase_id, nombre, dia_orden,
                       duracion_estimada_min, tipo_sesion)
  values (v_coach, v_cli, v_fase, 'Push Training', 3, 56, 'fuerza')
  returning id into v_rut;
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Running'), 1, 1, '2-3 min a intensidad moderada', null);
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'A', 'circuito', 2, 30, 1)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Bear to Step Through'), 2, 1, '5 por lado', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Dumbbell Standing Shoulder External Rotations'), 3, 1, '5', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 4, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Dumbbell Seated Arnold Press'), 5, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Plate Weighted Dip'), 6, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Machine Seated Chest Fly'), 7, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Machine Lateral Raise'), 8, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown'), 9, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Dumbbell Seated Overhead Tricep Extension'), 10, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Child''s Pose'), 11, 1, '30 s', null);
  -- historial 2026-09-02
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-02', 2,
          '2026-W36', 'completada', '2026-09-02 12:00:00+00'::timestamptz, true)
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 1, 9, 26, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 2, 8, 26, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 3, 8, 26, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 4, 7, 26, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Seated Arnold Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Seated Arnold Press'), 1, 8, 16, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Seated Arnold Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Seated Arnold Press'), 2, 8, 16, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Seated Arnold Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Seated Arnold Press'), 3, 8, 16, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Seated Arnold Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Seated Arnold Press'), 4, 8, 16, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Weighted Dip') limit 1),
            (select id from _ecm_ej where alias='Plate Weighted Dip'), 1, 10, 10, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Weighted Dip') limit 1),
            (select id from _ecm_ej where alias='Plate Weighted Dip'), 2, 8, 10, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Weighted Dip') limit 1),
            (select id from _ecm_ej where alias='Plate Weighted Dip'), 3, 8, 10, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Weighted Dip') limit 1),
            (select id from _ecm_ej where alias='Plate Weighted Dip'), 4, 7, 10, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Lateral Raise') limit 1),
            (select id from _ecm_ej where alias='Machine Lateral Raise'), 1, 10, 10, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Lateral Raise') limit 1),
            (select id from _ecm_ej where alias='Machine Lateral Raise'), 2, 10, 10, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Lateral Raise') limit 1),
            (select id from _ecm_ej where alias='Machine Lateral Raise'), 3, 7, 12, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Lateral Raise') limit 1),
            (select id from _ecm_ej where alias='Machine Lateral Raise'), 4, 7, 12, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown'), 1, 11, 28, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown'), 2, 10, 28, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown'), 3, 9, 30, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown'), 4, 8, 30, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Seated Overhead Tricep Extension') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Seated Overhead Tricep Extension'), 1, 10, 14, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Seated Overhead Tricep Extension') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Seated Overhead Tricep Extension'), 2, 10, 14, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Seated Overhead Tricep Extension') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Seated Overhead Tricep Extension'), 3, 9, 16, 'kg');
  end if;
  -- historial 2026-08-26
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-08-26', 1,
          '2026-W35', 'completada', '2026-08-26 12:00:00+00'::timestamptz, true)
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 1, 9, 26, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 2, 8, 26, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 3, 8, 26, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 4, 6, 26, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Seated Shoulder Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Seated Shoulder Press'), 1, 8, 18, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Seated Shoulder Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Seated Shoulder Press'), 2, 8, 18, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Seated Shoulder Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Seated Shoulder Press'), 3, 8, 18, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Seated Shoulder Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Seated Shoulder Press'), 4, 6, 18, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Standing Crossover Chest Fly') limit 1),
            (select id from _ecm_ej where alias='Cable Standing Crossover Chest Fly'), 1, 10, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Standing Crossover Chest Fly') limit 1),
            (select id from _ecm_ej where alias='Cable Standing Crossover Chest Fly'), 2, 9, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Standing Crossover Chest Fly') limit 1),
            (select id from _ecm_ej where alias='Cable Standing Crossover Chest Fly'), 3, 8, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Standing Crossover Chest Fly') limit 1),
            (select id from _ecm_ej where alias='Cable Standing Crossover Chest Fly'), 4, 7, 27, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dip') limit 1),
            (select id from _ecm_ej where alias='Dip'), 1, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dip') limit 1),
            (select id from _ecm_ej where alias='Dip'), 2, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dip') limit 1),
            (select id from _ecm_ej where alias='Dip'), 3, 11, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dip') limit 1),
            (select id from _ecm_ej where alias='Dip'), 4, 10, null, 'kg');
  end if;

  -- Rutina 4: Upper Body Training
  insert into rutinas (user_id, cliente_id, fase_id, nombre, dia_orden,
                       duracion_estimada_min, tipo_sesion)
  values (v_coach, v_cli, v_fase, 'Upper Body Training', 4, 56, 'fuerza')
  returning id into v_rut;
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Running'), 1, 1, '2 min a intensidad moderada', null);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Bear to Step Through'), 2, 1, '5 por lado', null);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Cable External Rotation'), 3, 1, '5 por lado', null);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Bar Hang'), 4, 1, '30 s', null);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 5, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Plate Weighted Wide Grip Pull Up'), 6, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Plate Weighted Dip'), 7, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Dumbbell Incline Bench High Row'), 8, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Machine Seated Chest Fly'), 9, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Dumbbell Seated Arnold Press'), 10, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='EZ Bar Preacher Curl'), 11, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown'), 12, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Child''s Pose'), 13, 1, '30 s', null);
  -- historial 2026-09-14
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-14', 4,
          '2026-W38', 'completada', '2026-09-14 12:00:00+00'::timestamptz, true)
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Bar Hang') limit 1),
            (select id from _ecm_ej where alias='Bar Hang'), 1, 30, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 1, 10, 24, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 2, 10, 24, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 3, 8, 24, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 4, 7, 24, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Weighted Wide Grip Pull Up') limit 1),
            (select id from _ecm_ej where alias='Plate Weighted Wide Grip Pull Up'), 1, 7, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Weighted Wide Grip Pull Up') limit 1),
            (select id from _ecm_ej where alias='Plate Weighted Wide Grip Pull Up'), 2, 6, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Weighted Wide Grip Pull Up') limit 1),
            (select id from _ecm_ej where alias='Plate Weighted Wide Grip Pull Up'), 3, 6, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Weighted Wide Grip Pull Up') limit 1),
            (select id from _ecm_ej where alias='Plate Weighted Wide Grip Pull Up'), 4, 5, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Weighted Dip') limit 1),
            (select id from _ecm_ej where alias='Plate Weighted Dip'), 1, 11, 10, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Weighted Dip') limit 1),
            (select id from _ecm_ej where alias='Plate Weighted Dip'), 2, 10, 10, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Weighted Dip') limit 1),
            (select id from _ecm_ej where alias='Plate Weighted Dip'), 3, 9, 10, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Weighted Dip') limit 1),
            (select id from _ecm_ej where alias='Plate Weighted Dip'), 4, 8, 10, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench High Row') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench High Row'), 1, 12, 14, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench High Row') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench High Row'), 2, 11, 14, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench High Row') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench High Row'), 3, 10, 16, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='EZ Bar Preacher Curl') limit 1),
            (select id from _ecm_ej where alias='EZ Bar Preacher Curl'), 1, 10, 30, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='EZ Bar Preacher Curl') limit 1),
            (select id from _ecm_ej where alias='EZ Bar Preacher Curl'), 2, 9, 30, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='EZ Bar Preacher Curl') limit 1),
            (select id from _ecm_ej where alias='EZ Bar Preacher Curl'), 3, 9, 30, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='EZ Bar Preacher Curl') limit 1),
            (select id from _ecm_ej where alias='EZ Bar Preacher Curl'), 4, 7, 30, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown'), 1, 12, 28, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown'), 2, 9, 30, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown'), 3, 8, 30, 'kg');
  end if;
  -- historial 2026-09-07
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-07', 3,
          '2026-W37', 'completada', '2026-09-07 12:00:00+00'::timestamptz, true)
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 1, 9, 26, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 2, 9, 26, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 3, 8, 26, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 4, 7, 26, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Weighted Wide Grip Pull Up') limit 1),
            (select id from _ecm_ej where alias='Plate Weighted Wide Grip Pull Up'), 1, 7, 7.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Weighted Wide Grip Pull Up') limit 1),
            (select id from _ecm_ej where alias='Plate Weighted Wide Grip Pull Up'), 2, 7, 7.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Weighted Wide Grip Pull Up') limit 1),
            (select id from _ecm_ej where alias='Plate Weighted Wide Grip Pull Up'), 3, 7, 7.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Weighted Wide Grip Pull Up') limit 1),
            (select id from _ecm_ej where alias='Plate Weighted Wide Grip Pull Up'), 4, 6, 7.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Weighted Dip') limit 1),
            (select id from _ecm_ej where alias='Plate Weighted Dip'), 1, 10, 10, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Weighted Dip') limit 1),
            (select id from _ecm_ej where alias='Plate Weighted Dip'), 2, 9, 10, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Weighted Dip') limit 1),
            (select id from _ecm_ej where alias='Plate Weighted Dip'), 3, 8, 10, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='EZ Bar Preacher Curl') limit 1),
            (select id from _ecm_ej where alias='EZ Bar Preacher Curl'), 1, 10, 30, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='EZ Bar Preacher Curl') limit 1),
            (select id from _ecm_ej where alias='EZ Bar Preacher Curl'), 2, 9, 30, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='EZ Bar Preacher Curl') limit 1),
            (select id from _ecm_ej where alias='EZ Bar Preacher Curl'), 3, 8, 30, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='EZ Bar Preacher Curl') limit 1),
            (select id from _ecm_ej where alias='EZ Bar Preacher Curl'), 4, 6, 34, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown'), 1, 11, 28, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown'), 2, 10, 28, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown'), 3, 8, 30, 'kg');
  end if;
  -- historial 2026-08-31
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-08-31', 2,
          '2026-W36', 'completada', '2026-08-31 12:00:00+00'::timestamptz, true)
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 1, 9, 26, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 2, 8, 26, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 3, 6, 26, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 4, 6, 26, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Weighted Wide Grip Pull Up') limit 1),
            (select id from _ecm_ej where alias='Plate Weighted Wide Grip Pull Up'), 1, 6, 7.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Weighted Wide Grip Pull Up') limit 1),
            (select id from _ecm_ej where alias='Plate Weighted Wide Grip Pull Up'), 2, 7, 7.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Weighted Wide Grip Pull Up') limit 1),
            (select id from _ecm_ej where alias='Plate Weighted Wide Grip Pull Up'), 3, 6, 7.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Weighted Wide Grip Pull Up') limit 1),
            (select id from _ecm_ej where alias='Plate Weighted Wide Grip Pull Up'), 4, 5, 7.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Weighted Dip') limit 1),
            (select id from _ecm_ej where alias='Plate Weighted Dip'), 1, 10, 10, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Weighted Dip') limit 1),
            (select id from _ecm_ej where alias='Plate Weighted Dip'), 2, 10, 10, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Weighted Dip') limit 1),
            (select id from _ecm_ej where alias='Plate Weighted Dip'), 3, 10, 10, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Weighted Dip') limit 1),
            (select id from _ecm_ej where alias='Plate Weighted Dip'), 4, 10, 10, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench High Row') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench High Row'), 1, 12, 14, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench High Row') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench High Row'), 2, 11, 14, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench High Row') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench High Row'), 3, 10, 14, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Chest Fly') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Chest Fly'), 1, 10, 63, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Chest Fly') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Chest Fly'), 2, 9, 63, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Chest Fly') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Chest Fly'), 3, 8, 63, 'kg');
  end if;
  -- historial 2026-08-24
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-08-24', 1,
          '2026-W35', 'completada', '2026-08-24 12:00:00+00'::timestamptz, true)
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 1, 10, 26, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 2, 10, 26, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 3, 7, 26, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 4, 7, 26, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Weighted Wide Grip Pull Up') limit 1),
            (select id from _ecm_ej where alias='Plate Weighted Wide Grip Pull Up'), 1, 6, 7.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Weighted Wide Grip Pull Up') limit 1),
            (select id from _ecm_ej where alias='Plate Weighted Wide Grip Pull Up'), 2, 6, 7.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Weighted Wide Grip Pull Up') limit 1),
            (select id from _ecm_ej where alias='Plate Weighted Wide Grip Pull Up'), 3, 6, 7.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Weighted Wide Grip Pull Up') limit 1),
            (select id from _ecm_ej where alias='Plate Weighted Wide Grip Pull Up'), 4, 5, 7.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Weighted Dip') limit 1),
            (select id from _ecm_ej where alias='Plate Weighted Dip'), 1, 10, 10, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Weighted Dip') limit 1),
            (select id from _ecm_ej where alias='Plate Weighted Dip'), 2, 10, 10, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Weighted Dip') limit 1),
            (select id from _ecm_ej where alias='Plate Weighted Dip'), 3, 10, 10, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Plate Weighted Dip') limit 1),
            (select id from _ecm_ej where alias='Plate Weighted Dip'), 4, 8, 12.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Seated Arnold Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Seated Arnold Press'), 1, 9, 16, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Seated Arnold Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Seated Arnold Press'), 2, 8, 16, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Seated Arnold Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Seated Arnold Press'), 3, 8, 16, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='EZ Bar Preacher Curl') limit 1),
            (select id from _ecm_ej where alias='EZ Bar Preacher Curl'), 1, 10, 30, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='EZ Bar Preacher Curl') limit 1),
            (select id from _ecm_ej where alias='EZ Bar Preacher Curl'), 2, 8, 30, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='EZ Bar Preacher Curl') limit 1),
            (select id from _ecm_ej where alias='EZ Bar Preacher Curl'), 3, 8, 30, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='EZ Bar Preacher Curl') limit 1),
            (select id from _ecm_ej where alias='EZ Bar Preacher Curl'), 4, 8, 30, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 1, 10, 16, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 2, 10, 16, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 3, 8, 18, 'kg');
  end if;

  select count(*) into v_n from rutinas where fase_id = v_fase;
  raise notice 'OK · David Forero: fase Cycle 17 con % rutinas y % series de historial.', v_n,
        (select count(*) from series_log sl join sesiones s on s.id = sl.sesion_id where s.fase_id = v_fase);
end $cli$;

-- ─────────────────────────────────────────────────────────────────────
-- CARLOS MARTÍNEZ · Cycle 14 · 5 semanas (2026-08-24 → 2026-09-27)
-- ─────────────────────────────────────────────────────────────────────
do $cli$
declare v_coach uuid; v_cli uuid; v_fase uuid; v_rut uuid; v_blo uuid; v_ses uuid; v_n int;
begin
  select id, user_id into v_cli, v_coach from clientes where nombre ilike '%carlos%mart%nez%' limit 1;
  if v_cli is null then
    raise warning 'SALTADO: no encuentro a «Carlos Martínez» en `clientes` (patrón %%carlos%%mart%%nez%%). Corrige el nombre y vuelve a correr.';
    return;
  end if;
  if exists (select 1 from fases where cliente_id = v_cli and nombre = 'Cycle 14') then
    raise notice 'SALTADO: «Carlos Martínez» ya tiene la fase Cycle 14 cargada.';
    return;
  end if;

  insert into fases (user_id, cliente_id, nombre, objetivo, notas_coach, semanas,
                     fecha_inicio, orden, estado)
  values (v_coach, v_cli, 'Cycle 14',
          'Bloque importado de Trainerize — la rutina que ya venía haciendo.',
          'Importado el 2026-09-20 desde el PDF de Trainerize (Cycle 14, 2026-08-24 a 2026-09-27). Revisar antes de enviar al cliente.',
          5, date '2026-08-24',
          coalesce((select max(orden)+1 from fases where cliente_id = v_cli), 1), 'borrador')
  returning id into v_fase;

  -- Rutina 1: Lower Body + Core Training
  insert into rutinas (user_id, cliente_id, fase_id, nombre, dia_orden,
                       duracion_estimada_min, tipo_sesion)
  values (v_coach, v_cli, v_fase, 'Lower Body + Core Training', 1, 57, 'fuerza')
  returning id into v_rut;
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Running'), 1, 1, '2-3 min a intensidad moderada', null);
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'A', 'superserie', 1, 40, 1)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='90-90 Hip Switch'), 2, 1, '8 por lado', 40);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Bodyweight Alternating Cossack Squat'), 3, 1, '8 por lado', 40);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Squat to Hinge'), 4, 1, '8', 40);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Lateral Shuttle Run'), 5, 1, '60 s', 15);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Seated Leg Press'), 6, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Machine Seated Leg Extension'), 7, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Dumbbell Deadlift'), 8, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Machine Lying Leg Curl'), 9, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Machine Seated Hip Adduction'), 10, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Machine Seated Calf Raise'), 11, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Lateral Shuttle Run'), 12, 1, '60 s', 15);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Pallof Press'), 13, 3, '15', 15);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Dip Machine Bent Leg Raise'), 14, 3, '15', 15);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Bicycle Crunch'), 15, 3, '15', 15);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Static Pigeon Stretch'), 16, 1, '30 s por lado', null);
  -- historial 2026-09-11
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-11', 3,
          '2026-W37', 'completada', '2026-09-11 12:00:00+00'::timestamptz, true)
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Seated Leg Press') limit 1),
            (select id from _ecm_ej where alias='Seated Leg Press'), 1, 10, 20.45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Seated Leg Press') limit 1),
            (select id from _ecm_ej where alias='Seated Leg Press'), 2, 10, 20.45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Seated Leg Press') limit 1),
            (select id from _ecm_ej where alias='Seated Leg Press'), 3, 10, 20.45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Seated Leg Press') limit 1),
            (select id from _ecm_ej where alias='Seated Leg Press'), 4, 10, 20.45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Leg Extension') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Leg Extension'), 1, 10, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Leg Extension') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Leg Extension'), 2, 10, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Leg Extension') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Leg Extension'), 3, 10, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Deadlift') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Deadlift'), 1, 10, 11.36, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Deadlift') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Deadlift'), 2, 10, 12.73, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Deadlift') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Deadlift'), 3, 10, 11.36, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Deadlift') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Deadlift'), 4, 10, 11.36, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Lying Leg Curl') limit 1),
            (select id from _ecm_ej where alias='Machine Lying Leg Curl'), 1, 10, 15.91, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Lying Leg Curl') limit 1),
            (select id from _ecm_ej where alias='Machine Lying Leg Curl'), 2, 10, 15.91, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Lying Leg Curl') limit 1),
            (select id from _ecm_ej where alias='Machine Lying Leg Curl'), 3, 10, 15.91, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Hip Adduction') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Hip Adduction'), 1, 10, 38.64, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Hip Adduction') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Hip Adduction'), 2, 10, 38.64, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Hip Adduction') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Hip Adduction'), 3, 10, 38.64, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Calf Raise'), 1, 10, 38.64, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Calf Raise'), 2, 10, 38.64, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Calf Raise'), 3, 10, 38.64, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Calf Raise'), 4, 10, 38.64, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Pallof Press') limit 1),
            (select id from _ecm_ej where alias='Pallof Press'), 1, 5, 4.55, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Pallof Press') limit 1),
            (select id from _ecm_ej where alias='Pallof Press'), 2, 5, 4.55, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Pallof Press') limit 1),
            (select id from _ecm_ej where alias='Pallof Press'), 3, 5, 4.55, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dip Machine Bent Leg Raise') limit 1),
            (select id from _ecm_ej where alias='Dip Machine Bent Leg Raise'), 1, 10, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dip Machine Bent Leg Raise') limit 1),
            (select id from _ecm_ej where alias='Dip Machine Bent Leg Raise'), 2, 10, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dip Machine Bent Leg Raise') limit 1),
            (select id from _ecm_ej where alias='Dip Machine Bent Leg Raise'), 3, 10, null, 'kg');
  end if;
  -- historial 2026-09-08
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-08', 3,
          '2026-W37', 'completada', '2026-09-08 12:00:00+00'::timestamptz, true)
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Seated Leg Press') limit 1),
            (select id from _ecm_ej where alias='Seated Leg Press'), 1, 10, 20.45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Seated Leg Press') limit 1),
            (select id from _ecm_ej where alias='Seated Leg Press'), 2, 10, 20.45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Seated Leg Press') limit 1),
            (select id from _ecm_ej where alias='Seated Leg Press'), 3, 10, 20.45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Seated Leg Press') limit 1),
            (select id from _ecm_ej where alias='Seated Leg Press'), 4, 10, 20.45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Leg Extension') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Leg Extension'), 1, 10, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Leg Extension') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Leg Extension'), 2, 10, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Leg Extension') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Leg Extension'), 3, 10, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Deadlift') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Deadlift'), 1, 10, 11.36, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Deadlift') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Deadlift'), 2, 10, 11.36, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Deadlift') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Deadlift'), 3, 10, 11.36, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Deadlift') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Deadlift'), 4, 10, 11.36, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Lying Leg Curl') limit 1),
            (select id from _ecm_ej where alias='Machine Lying Leg Curl'), 1, 10, 15.91, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Lying Leg Curl') limit 1),
            (select id from _ecm_ej where alias='Machine Lying Leg Curl'), 2, 10, 15.91, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Lying Leg Curl') limit 1),
            (select id from _ecm_ej where alias='Machine Lying Leg Curl'), 3, 10, 15.91, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Hip Adduction') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Hip Adduction'), 1, 10, 38.64, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Hip Adduction') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Hip Adduction'), 2, 10, 38.64, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Hip Adduction') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Hip Adduction'), 3, 10, 38.64, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Calf Raise'), 1, 10, 38.64, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Calf Raise'), 2, 10, 38.64, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Calf Raise'), 3, 10, 38.64, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Calf Raise'), 4, 10, 38.64, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Pallof Press') limit 1),
            (select id from _ecm_ej where alias='Pallof Press'), 1, 5, 4.55, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Pallof Press') limit 1),
            (select id from _ecm_ej where alias='Pallof Press'), 2, 5, 4.55, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Pallof Press') limit 1),
            (select id from _ecm_ej where alias='Pallof Press'), 3, 5, 4.55, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dip Machine Bent Leg Raise') limit 1),
            (select id from _ecm_ej where alias='Dip Machine Bent Leg Raise'), 1, 10, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dip Machine Bent Leg Raise') limit 1),
            (select id from _ecm_ej where alias='Dip Machine Bent Leg Raise'), 2, 10, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dip Machine Bent Leg Raise') limit 1),
            (select id from _ecm_ej where alias='Dip Machine Bent Leg Raise'), 3, 10, null, 'kg');
  end if;
  -- historial 2026-09-04
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-04', 2,
          '2026-W36', 'completada', '2026-09-04 12:00:00+00'::timestamptz, true)
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Seated Leg Press') limit 1),
            (select id from _ecm_ej where alias='Seated Leg Press'), 1, 10, 20.45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Seated Leg Press') limit 1),
            (select id from _ecm_ej where alias='Seated Leg Press'), 2, 10, 20.45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Seated Leg Press') limit 1),
            (select id from _ecm_ej where alias='Seated Leg Press'), 3, 10, 20.45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Seated Leg Press') limit 1),
            (select id from _ecm_ej where alias='Seated Leg Press'), 4, 10, 20.45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Leg Extension') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Leg Extension'), 1, 10, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Leg Extension') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Leg Extension'), 2, 10, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Leg Extension') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Leg Extension'), 3, 10, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Deadlift') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Deadlift'), 1, 10, 11.36, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Deadlift') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Deadlift'), 2, 10, 11.36, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Deadlift') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Deadlift'), 3, 10, 11.36, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Deadlift') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Deadlift'), 4, 10, 11.36, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Lying Leg Curl') limit 1),
            (select id from _ecm_ej where alias='Machine Lying Leg Curl'), 1, 10, 15.91, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Lying Leg Curl') limit 1),
            (select id from _ecm_ej where alias='Machine Lying Leg Curl'), 2, 10, 15.91, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Lying Leg Curl') limit 1),
            (select id from _ecm_ej where alias='Machine Lying Leg Curl'), 3, 10, 15.91, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Hip Adduction') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Hip Adduction'), 1, 10, 38.64, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Hip Adduction') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Hip Adduction'), 2, 10, 38.64, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Hip Adduction') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Hip Adduction'), 3, 10, 38.64, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Calf Raise'), 1, 10, 38.64, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Calf Raise'), 2, 10, 38.64, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Calf Raise'), 3, 10, 38.64, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Calf Raise'), 4, 10, 38.64, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Pallof Press') limit 1),
            (select id from _ecm_ej where alias='Pallof Press'), 1, 5, 4.55, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Pallof Press') limit 1),
            (select id from _ecm_ej where alias='Pallof Press'), 2, 5, 4.55, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Pallof Press') limit 1),
            (select id from _ecm_ej where alias='Pallof Press'), 3, 5, 4.55, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dip Machine Bent Leg Raise') limit 1),
            (select id from _ecm_ej where alias='Dip Machine Bent Leg Raise'), 1, 10, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dip Machine Bent Leg Raise') limit 1),
            (select id from _ecm_ej where alias='Dip Machine Bent Leg Raise'), 2, 10, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dip Machine Bent Leg Raise') limit 1),
            (select id from _ecm_ej where alias='Dip Machine Bent Leg Raise'), 3, 10, null, 'kg');
  end if;

  -- Rutina 2: Pull Training
  insert into rutinas (user_id, cliente_id, fase_id, nombre, dia_orden,
                       duracion_estimada_min, tipo_sesion)
  values (v_coach, v_cli, v_fase, 'Pull Training', 2, 54, 'fuerza')
  returning id into v_rut;
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Running'), 1, 1, '2-3 min a intensidad moderada', null);
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'A', 'circuito', 2, 35, 1)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Mini Band Standing I''s'), 2, 1, '5', 35);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Bar Hang'), 3, 1, '50 s', 35);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Mini Band Wall Slides'), 4, 1, '5', 35);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Machine Assisted Wide Grip Pull Up'), 5, 3, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Machine Assisted Parallel Grip Pull Up'), 6, 3, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Machine Seated Single Arm Neutral Grip Row'), 7, 4, '6-12 por lado', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Machine Preacher Curl'), 8, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Dumbbell Incline Alternating Curl'), 9, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 10, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Dumbbell Shrug'), 11, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Suspension Low Back Stretch'), 12, 1, '30 s', null);

  -- Rutina 3: Push Training
  insert into rutinas (user_id, cliente_id, fase_id, nombre, dia_orden,
                       duracion_estimada_min, tipo_sesion)
  values (v_coach, v_cli, v_fase, 'Push Training', 3, 54, 'fuerza')
  returning id into v_rut;
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Running'), 1, 1, '2-3 min a intensidad moderada', null);
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'A', 'circuito', 2, 90, 1)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Table Top Half Arm Thoracic Rotation'), 2, 1, '5 por lado', 90);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Dumbbell Standing Shoulder External Rotations'), 3, 1, '5', 90);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Dumbbell Burpee with Curl to Press'), 4, 1, '40 s', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Machine Seated Chest Press'), 5, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Machine Seated Shoulder Press'), 6, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Machine Seated Chest Fly'), 7, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Cable Lateral Raise'), 8, 4, '6-12 por lado', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown'), 9, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Cable V-Bar Overhead Tricep Extension'), 10, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Dumbbell Burpee with Curl to Press'), 11, 1, '40 s', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Child''s Pose'), 12, 1, '30 s', null);

  -- Rutina 4: Upper Body Training
  insert into rutinas (user_id, cliente_id, fase_id, nombre, dia_orden,
                       duracion_estimada_min, tipo_sesion)
  values (v_coach, v_cli, v_fase, 'Upper Body Training', 4, 64, 'fuerza')
  returning id into v_rut;
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Running'), 1, 1, '2-3 min a intensidad moderada', null);
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'A', 'superserie', 1, 30, 1)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Table Top Half Arm Thoracic Rotation'), 2, 1, '5 por lado', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Mini Band Standing I''s'), 3, 1, '5', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Dumbbell Standing Shoulder External Rotations'), 4, 1, '5', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Bar Hang'), 5, 1, '60 s', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 6, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Wide Grip Pull Up'), 7, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Machine Seated Chest Fly'), 8, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Dumbbell Single Arm Row'), 9, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Dumbbell Seated Arnold Press'), 10, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Cable Bicep Curl'), 11, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 12, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown'), 13, 4, '6-12', 50);
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'B', 'superserie', 1, 30, 2)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Dumbbell Burpee Clean to Press'), 14, 1, '8-15', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej where alias='Lateral Shuttle Run'), 15, 1, '60 s', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej where alias='Child''s Pose'), 16, 1, '30 s', null);
  -- historial 2026-08-31
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-08-31', 2,
          '2026-W36', 'completada', '2026-08-31 12:00:00+00'::timestamptz, true)
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Mini Band Standing I''s') limit 1),
            (select id from _ecm_ej where alias='Mini Band Standing I''s'), 1, 5, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Standing Shoulder External Rotations') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Standing Shoulder External Rotations'), 1, 5, 4.55, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 1, 10, 11.36, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 2, 10, 11.36, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 3, 10, 11.36, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 4, 10, 11.36, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Wide Grip Pull Up') limit 1),
            (select id from _ecm_ej where alias='Wide Grip Pull Up'), 1, 10, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Wide Grip Pull Up') limit 1),
            (select id from _ecm_ej where alias='Wide Grip Pull Up'), 2, 10, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Chest Fly') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Chest Fly'), 1, 10, 31.82, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Chest Fly') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Chest Fly'), 2, 10, 31.82, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Chest Fly') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Chest Fly'), 3, 10, 31.82, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Chest Fly') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Chest Fly'), 4, 10, 31.82, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Seated Arnold Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Seated Arnold Press'), 1, 10, 6.82, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Seated Arnold Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Seated Arnold Press'), 2, 10, 7.95, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Seated Arnold Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Seated Arnold Press'), 3, 10, 7.95, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Seated Arnold Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Seated Arnold Press'), 4, 8, 7.95, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Bicep Curl') limit 1),
            (select id from _ecm_ej where alias='Cable Bicep Curl'), 1, 8, 13.64, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Bicep Curl') limit 1),
            (select id from _ecm_ej where alias='Cable Bicep Curl'), 2, 8, 11.36, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Bicep Curl') limit 1),
            (select id from _ecm_ej where alias='Cable Bicep Curl'), 3, 8, 11.36, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable Bicep Curl') limit 1),
            (select id from _ecm_ej where alias='Cable Bicep Curl'), 4, 6, 11.36, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 1, 10, 7.95, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 2, 10, 7.95, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Hammer Curl'), 3, 10, 7.95, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown'), 1, 10, 13.64, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown'), 2, 10, 13.64, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej where alias='Cable V Bar Tricep Pushdown'), 3, 10, 13.64, 'kg');
  end if;
  -- historial 2026-08-24
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-08-24', 1,
          '2026-W35', 'completada', '2026-08-24 12:00:00+00'::timestamptz, true)
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Bar Hang') limit 1),
            (select id from _ecm_ej where alias='Bar Hang'), 1, 60, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 1, 10, 11.36, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 2, 10, 11.36, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 3, 7, 11.36, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Incline Bench Press'), 4, 6, 11.36, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Wide Grip Pull Up') limit 1),
            (select id from _ecm_ej where alias='Wide Grip Pull Up'), 1, 10, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Wide Grip Pull Up') limit 1),
            (select id from _ecm_ej where alias='Wide Grip Pull Up'), 2, 10, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Chest Fly') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Chest Fly'), 1, 10, 31.82, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Chest Fly') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Chest Fly'), 2, 10, 31.82, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Chest Fly') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Chest Fly'), 3, 10, 31.82, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Machine Seated Chest Fly') limit 1),
            (select id from _ecm_ej where alias='Machine Seated Chest Fly'), 4, 6, 31.82, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Single Arm Row') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Single Arm Row'), 1, 20, 4.55, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Single Arm Row') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Single Arm Row'), 2, 20, 4.55, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Single Arm Row') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Single Arm Row'), 3, 20, 4.55, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Single Arm Row') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Single Arm Row'), 4, 20, 4.55, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Seated Arnold Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Seated Arnold Press'), 1, 15, 3.64, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Seated Arnold Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Seated Arnold Press'), 2, 15, 2.73, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Seated Arnold Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Seated Arnold Press'), 3, 15, 1.82, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej where alias='Dumbbell Seated Arnold Press') limit 1),
            (select id from _ecm_ej where alias='Dumbbell Seated Arnold Press'), 4, 15, 1.36, 'kg');
  end if;

  select count(*) into v_n from rutinas where fase_id = v_fase;
  raise notice 'OK · Carlos Martínez: fase Cycle 14 con % rutinas y % series de historial.', v_n,
        (select count(*) from series_log sl join sesiones s on s.id = sl.sesion_id where s.fase_id = v_fase);
end $cli$;

commit;

-- ── COMPROBACIÓN ────────────────────────────────────────────────────────
-- Córrelo después para ver qué quedó cargado:
--
--   select c.nombre, f.nombre as fase, f.semanas, f.fecha_inicio, f.estado,
--          count(distinct r.id) as rutinas,
--          count(distinct s.id) as sesiones_historicas
--     from fases f
--     join clientes c on c.id = f.cliente_id
--     left join rutinas r on r.fase_id = f.id
--     left join sesiones s on s.fase_id = f.id
--    where f.notas_coach like 'Importado%Trainerize%'
--    group by 1,2,3,4,5
--    order by 1;

-- ── DESHACER ────────────────────────────────────────────────────────────
-- Borra SOLO lo que cargó este archivo (las fases importadas y, en cascada,
-- sus rutinas, bloques, sesiones y series). Los ejercicios de la galería NO
-- se borran: puedes haberlos usado ya en otra rutina.
--
--   delete from fases where notas_coach like 'Importado%Trainerize%';
--
-- Y si quieres también los ejercicios que creó (solo los que nadie usa):
--
--   delete from ejercicios e
--    where 'importado-trainerize' = any(e.tags)
--      and not exists (select 1 from rutina_ejercicios re where re.ejercicio_id = e.id)
--      and not exists (select 1 from series_log sl where sl.ejercicio_id = e.id);

drop function if exists ecm_ej(uuid, text, text, text, text, text, text[], boolean);

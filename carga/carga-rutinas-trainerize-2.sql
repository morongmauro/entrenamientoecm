-- ═══════════════════════════════════════════════════════════════════════
-- CARGA DE RUTINAS · 9 clientes más · exportadas de Trainerize (19-20 sep 2026)
-- ═══════════════════════════════════════════════════════════════════════
--
-- La segunda tanda. Los 10 primeros están en `carga-rutinas-trainerize.sql`;
-- este archivo NO los toca.
--
-- Qué hace:
--   1. Crea las fichas de los ejercicios nuevos que usan estas rutinas.
--      El nombre va en español y el original de Trainerize queda en `alias`.
--      Los que ya existen de la primera tanda se REUSAN, no se duplican.
--   2. Crea una FASE por cliente con sus semanas y fechas reales.
--   3. Crea sus RUTINAS con circuitos, series, reps, descansos Y LOS DÍAS
--      de la semana, sacados de en qué día cayó cada sesión del historial.
--   4. Carga el HISTORIAL de "Previous Stats" como sesiones completadas,
--      marcadas `origen = 'importada'` para que el CRM no las confunda con
--      lo que el cliente marque en su app.
--
-- NO se le muestra nada al cliente: las fases entran como `borrador`.
--
-- ANTES DE CORRER, en este orden:
--     1-visibilidad.sql        (si no lo has corrido)
--     4-calendario.sql         ← este archivo necesita sus dos columnas
--
-- SE PUEDE CORRER DOS VECES: si un cliente ya tiene su fase, se salta solo.
--
-- OJO con los nombres: cada cliente se busca en `clientes` por nombre. Si
-- alguno está escrito distinto en el CRM, ese cliente se salta con un aviso
-- y basta con corregir el patrón y volver a correr.
-- ═══════════════════════════════════════════════════════════════════════

-- ── Lo que este archivo da por hecho ────────────────────────────────────
-- Sin estas dos columnas la carga entraría a medias: las rutinas sin días
-- (calendario vacío) y el historial indistinguible de lo que marque el
-- cliente. Mejor parar aquí y decir cuál falta.
do $guard$
begin
  if not exists (select 1 from information_schema.columns
                  where table_name='rutinas' and column_name='dias_semana') then
    raise exception 'Falta la columna `rutinas.dias_semana`. Corre primero carga/migracion-calendario.sql (4-calendario.sql en el zip).';
  end if;
  if not exists (select 1 from information_schema.columns
                  where table_name='sesiones' and column_name='origen') then
    raise exception 'Falta la columna `sesiones.origen`. Corre primero carga/migracion-calendario.sql (4-calendario.sql en el zip).';
  end if;
end $guard$;

begin;

-- ── Busca o crea la ficha de un ejercicio en tu galería ──────────────────
-- La misma de la primera tanda, repetida a propósito: `create or replace`
-- no rompe nada si ya está, y así este archivo funciona solo aunque el
-- primero se corriera hace semanas y la función se hubiera perdido.
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

create temp table if not exists _ecm_ej2 (alias text primary key, id uuid) on commit drop;

do $cat$
declare v_coach uuid;
begin
  select user_id into v_coach from clientes order by created_at limit 1;
  if v_coach is null then raise exception 'No hay clientes en la tabla `clientes`: no sé de qué coach es esto.'; end if;
  delete from _ecm_ej2;
  -- Los que ya están en la galería de la primera tanda: se reusan por alias.
  insert into _ecm_ej2 values ('1/2 Kneel to High Knee Hop', (select id from ejercicios where user_id = v_coach and (alias = '1/2 Kneel to High Knee Hop' or lower(nombre) = lower('1/2 Kneel to High Knee Hop')) limit 1));
  insert into _ecm_ej2 values ('1/2 Kneel to Lateral Bound', (select id from ejercicios where user_id = v_coach and (alias = '1/2 Kneel to Lateral Bound' or lower(nombre) = lower('1/2 Kneel to Lateral Bound')) limit 1));
  insert into _ecm_ej2 values ('90-90 Hip Switch', (select id from ejercicios where user_id = v_coach and (alias = '90-90 Hip Switch' or lower(nombre) = lower('90-90 Hip Switch')) limit 1));
  insert into _ecm_ej2 values ('Ab Roller Wheel Abdominal Roll Out', (select id from ejercicios where user_id = v_coach and (alias = 'Ab Roller Wheel Abdominal Roll Out' or lower(nombre) = lower('Ab Roller Wheel Abdominal Roll Out')) limit 1));
  insert into _ecm_ej2 values ('Alternating Lunge Hops', (select id from ejercicios where user_id = v_coach and (alias = 'Alternating Lunge Hops' or lower(nombre) = lower('Alternating Lunge Hops')) limit 1));
  insert into _ecm_ej2 values ('Alternating Spiderman lunge to hip lift', (select id from ejercicios where user_id = v_coach and (alias = 'Alternating Spiderman lunge to hip lift' or lower(nombre) = lower('Alternating Spiderman lunge to hip lift')) limit 1));
  insert into _ecm_ej2 values ('Angled Machine Leg Press', (select id from ejercicios where user_id = v_coach and (alias = 'Angled Machine Leg Press' or lower(nombre) = lower('Angled Machine Leg Press')) limit 1));
  insert into _ecm_ej2 values ('Band Anchored Single Arm Tricep Kickback', (select id from ejercicios where user_id = v_coach and (alias = 'Band Anchored Single Arm Tricep Kickback' or lower(nombre) = lower('Band Anchored Single Arm Tricep Kickback')) limit 1));
  insert into _ecm_ej2 values ('Bar Hang', (select id from ejercicios where user_id = v_coach and (alias = 'Bar Hang' or lower(nombre) = lower('Bar Hang')) limit 1));
  insert into _ecm_ej2 values ('Bear to Step Through', (select id from ejercicios where user_id = v_coach and (alias = 'Bear to Step Through' or lower(nombre) = lower('Bear to Step Through')) limit 1));
  insert into _ecm_ej2 values ('Bench V Sit Leg Raise', (select id from ejercicios where user_id = v_coach and (alias = 'Bench V Sit Leg Raise' or lower(nombre) = lower('Bench V Sit Leg Raise')) limit 1));
  insert into _ecm_ej2 values ('Bicycle Crunch', (select id from ejercicios where user_id = v_coach and (alias = 'Bicycle Crunch' or lower(nombre) = lower('Bicycle Crunch')) limit 1));
  insert into _ecm_ej2 values ('Bodyweight Alternating Cossack Squat', (select id from ejercicios where user_id = v_coach and (alias = 'Bodyweight Alternating Cossack Squat' or lower(nombre) = lower('Bodyweight Alternating Cossack Squat')) limit 1));
  insert into _ecm_ej2 values ('Bodyweight Cossack Squat', (select id from ejercicios where user_id = v_coach and (alias = 'Bodyweight Cossack Squat' or lower(nombre) = lower('Bodyweight Cossack Squat')) limit 1));
  insert into _ecm_ej2 values ('Bodyweight Deadbug', (select id from ejercicios where user_id = v_coach and (alias = 'Bodyweight Deadbug' or lower(nombre) = lower('Bodyweight Deadbug')) limit 1));
  insert into _ecm_ej2 values ('Bodyweight Spiderman Lunge To Rotation', (select id from ejercicios where user_id = v_coach and (alias = 'Bodyweight Spiderman Lunge To Rotation' or lower(nombre) = lower('Bodyweight Spiderman Lunge To Rotation')) limit 1));
  insert into _ecm_ej2 values ('Bodyweight Squat To Hinge', (select id from ejercicios where user_id = v_coach and (alias = 'Bodyweight Squat To Hinge' or lower(nombre) = lower('Bodyweight Squat To Hinge')) limit 1));
  insert into _ecm_ej2 values ('Bosu Lateral Bounce to Squat Jump', (select id from ejercicios where user_id = v_coach and (alias = 'Bosu Lateral Bounce to Squat Jump' or lower(nombre) = lower('Bosu Lateral Bounce to Squat Jump')) limit 1));
  insert into _ecm_ej2 values ('Cable Rope Face Pull', (select id from ejercicios where user_id = v_coach and (alias = 'Cable Rope Face Pull' or lower(nombre) = lower('Cable Rope Face Pull')) limit 1));
  insert into _ecm_ej2 values ('Cable Seated Close Grip Row', (select id from ejercicios where user_id = v_coach and (alias = 'Cable Seated Close Grip Row' or lower(nombre) = lower('Cable Seated Close Grip Row')) limit 1));
  insert into _ecm_ej2 values ('Cable Seated Close Row', (select id from ejercicios where user_id = v_coach and (alias = 'Cable Seated Close Row' or lower(nombre) = lower('Cable Seated Close Row')) limit 1));
  insert into _ecm_ej2 values ('Cable Standing Crossover Chest Fly', (select id from ejercicios where user_id = v_coach and (alias = 'Cable Standing Crossover Chest Fly' or lower(nombre) = lower('Cable Standing Crossover Chest Fly')) limit 1));
  insert into _ecm_ej2 values ('Cable Straight Bar Tricep Pushdown', (select id from ejercicios where user_id = v_coach and (alias = 'Cable Straight Bar Tricep Pushdown' or lower(nombre) = lower('Cable Straight Bar Tricep Pushdown')) limit 1));
  insert into _ecm_ej2 values ('Cable V Bar Tricep Pushdown', (select id from ejercicios where user_id = v_coach and (alias = 'Cable V Bar Tricep Pushdown' or lower(nombre) = lower('Cable V Bar Tricep Pushdown')) limit 1));
  insert into _ecm_ej2 values ('Cable V-Bar Overhead Tricep Extension', (select id from ejercicios where user_id = v_coach and (alias = 'Cable V-Bar Overhead Tricep Extension' or lower(nombre) = lower('Cable V-Bar Overhead Tricep Extension')) limit 1));
  insert into _ecm_ej2 values ('Cat to Cow', (select id from ejercicios where user_id = v_coach and (alias = 'Cat to Cow' or lower(nombre) = lower('Cat to Cow')) limit 1));
  insert into _ecm_ej2 values ('Child''s Pose', (select id from ejercicios where user_id = v_coach and (alias = 'Child''s Pose' or lower(nombre) = lower('Child''s Pose')) limit 1));
  insert into _ecm_ej2 values ('Clapping Push Up', (select id from ejercicios where user_id = v_coach and (alias = 'Clapping Push Up' or lower(nombre) = lower('Clapping Push Up')) limit 1));
  insert into _ecm_ej2 values ('Cobra', (select id from ejercicios where user_id = v_coach and (alias = 'Cobra' or lower(nombre) = lower('Cobra')) limit 1));
  insert into _ecm_ej2 values ('Cossack Squat to T-Spine Reach', (select id from ejercicios where user_id = v_coach and (alias = 'Cossack Squat to T-Spine Reach' or lower(nombre) = lower('Cossack Squat to T-Spine Reach')) limit 1));
  insert into _ecm_ej2 values ('Dip', (select id from ejercicios where user_id = v_coach and (alias = 'Dip' or lower(nombre) = lower('Dip')) limit 1));
  insert into _ecm_ej2 values ('Dip Machine Bent Leg Raise', (select id from ejercicios where user_id = v_coach and (alias = 'Dip Machine Bent Leg Raise' or lower(nombre) = lower('Dip Machine Bent Leg Raise')) limit 1));
  insert into _ecm_ej2 values ('Dip Machine Straight Leg Raise', (select id from ejercicios where user_id = v_coach and (alias = 'Dip Machine Straight Leg Raise' or lower(nombre) = lower('Dip Machine Straight Leg Raise')) limit 1));
  insert into _ecm_ej2 values ('Downward Dog to Scorpion', (select id from ejercicios where user_id = v_coach and (alias = 'Downward Dog to Scorpion' or lower(nombre) = lower('Downward Dog to Scorpion')) limit 1));
  insert into _ecm_ej2 values ('Dumbbell Alternating Bicep Curl', (select id from ejercicios where user_id = v_coach and (alias = 'Dumbbell Alternating Bicep Curl' or lower(nombre) = lower('Dumbbell Alternating Bicep Curl')) limit 1));
  insert into _ecm_ej2 values ('Dumbbell Alternating Hammer Curl', (select id from ejercicios where user_id = v_coach and (alias = 'Dumbbell Alternating Hammer Curl' or lower(nombre) = lower('Dumbbell Alternating Hammer Curl')) limit 1));
  insert into _ecm_ej2 values ('Dumbbell Alternating Lateral Raise to Front Raise', (select id from ejercicios where user_id = v_coach and (alias = 'Dumbbell Alternating Lateral Raise to Front Raise' or lower(nombre) = lower('Dumbbell Alternating Lateral Raise to Front Raise')) limit 1));
  insert into _ecm_ej2 values ('Dumbbell Bench Press', (select id from ejercicios where user_id = v_coach and (alias = 'Dumbbell Bench Press' or lower(nombre) = lower('Dumbbell Bench Press')) limit 1));
  insert into _ecm_ej2 values ('Dumbbell Bulgarian Split Squat', (select id from ejercicios where user_id = v_coach and (alias = 'Dumbbell Bulgarian Split Squat' or lower(nombre) = lower('Dumbbell Bulgarian Split Squat')) limit 1));
  insert into _ecm_ej2 values ('Dumbbell Burpee Clean to Press', (select id from ejercicios where user_id = v_coach and (alias = 'Dumbbell Burpee Clean to Press' or lower(nombre) = lower('Dumbbell Burpee Clean to Press')) limit 1));
  insert into _ecm_ej2 values ('Dumbbell Burpee with Curl to Press', (select id from ejercicios where user_id = v_coach and (alias = 'Dumbbell Burpee with Curl to Press' or lower(nombre) = lower('Dumbbell Burpee with Curl to Press')) limit 1));
  insert into _ecm_ej2 values ('Dumbbell Deadlift', (select id from ejercicios where user_id = v_coach and (alias = 'Dumbbell Deadlift' or lower(nombre) = lower('Dumbbell Deadlift')) limit 1));
  insert into _ecm_ej2 values ('Dumbbell Floor Press', (select id from ejercicios where user_id = v_coach and (alias = 'Dumbbell Floor Press' or lower(nombre) = lower('Dumbbell Floor Press')) limit 1));
  insert into _ecm_ej2 values ('Dumbbell Front Squat', (select id from ejercicios where user_id = v_coach and (alias = 'Dumbbell Front Squat' or lower(nombre) = lower('Dumbbell Front Squat')) limit 1));
  insert into _ecm_ej2 values ('Dumbbell Glute Bridge', (select id from ejercicios where user_id = v_coach and (alias = 'Dumbbell Glute Bridge' or lower(nombre) = lower('Dumbbell Glute Bridge')) limit 1));
  insert into _ecm_ej2 values ('Dumbbell Glute Bridge Chest Press', (select id from ejercicios where user_id = v_coach and (alias = 'Dumbbell Glute Bridge Chest Press' or lower(nombre) = lower('Dumbbell Glute Bridge Chest Press')) limit 1));
  insert into _ecm_ej2 values ('Dumbbell Hammer Curl', (select id from ejercicios where user_id = v_coach and (alias = 'Dumbbell Hammer Curl' or lower(nombre) = lower('Dumbbell Hammer Curl')) limit 1));
  insert into _ecm_ej2 values ('Dumbbell Hip Thrust', (select id from ejercicios where user_id = v_coach and (alias = 'Dumbbell Hip Thrust' or lower(nombre) = lower('Dumbbell Hip Thrust')) limit 1));
  insert into _ecm_ej2 values ('Dumbbell Incline Alternating Curl', (select id from ejercicios where user_id = v_coach and (alias = 'Dumbbell Incline Alternating Curl' or lower(nombre) = lower('Dumbbell Incline Alternating Curl')) limit 1));
  insert into _ecm_ej2 values ('Dumbbell Incline Bench Press', (select id from ejercicios where user_id = v_coach and (alias = 'Dumbbell Incline Bench Press' or lower(nombre) = lower('Dumbbell Incline Bench Press')) limit 1));
  insert into _ecm_ej2 values ('Dumbbell Seated Arnold Press', (select id from ejercicios where user_id = v_coach and (alias = 'Dumbbell Seated Arnold Press' or lower(nombre) = lower('Dumbbell Seated Arnold Press')) limit 1));
  insert into _ecm_ej2 values ('Dumbbell Shrug', (select id from ejercicios where user_id = v_coach and (alias = 'Dumbbell Shrug' or lower(nombre) = lower('Dumbbell Shrug')) limit 1));
  insert into _ecm_ej2 values ('Dumbbell Single Arm Row', (select id from ejercicios where user_id = v_coach and (alias = 'Dumbbell Single Arm Row' or lower(nombre) = lower('Dumbbell Single Arm Row')) limit 1));
  insert into _ecm_ej2 values ('Dumbbell Standing Shoulder External Rotations', (select id from ejercicios where user_id = v_coach and (alias = 'Dumbbell Standing Shoulder External Rotations' or lower(nombre) = lower('Dumbbell Standing Shoulder External Rotations')) limit 1));
  insert into _ecm_ej2 values ('Dumbbell Stationary Lunge', (select id from ejercicios where user_id = v_coach and (alias = 'Dumbbell Stationary Lunge' or lower(nombre) = lower('Dumbbell Stationary Lunge')) limit 1));
  insert into _ecm_ej2 values ('Dumbbell Sumo Deadlift', (select id from ejercicios where user_id = v_coach and (alias = 'Dumbbell Sumo Deadlift' or lower(nombre) = lower('Dumbbell Sumo Deadlift')) limit 1));
  insert into _ecm_ej2 values ('EZ Bar Preacher Curl', (select id from ejercicios where user_id = v_coach and (alias = 'EZ Bar Preacher Curl' or lower(nombre) = lower('EZ Bar Preacher Curl')) limit 1));
  insert into _ecm_ej2 values ('Glute Side Circle', (select id from ejercicios where user_id = v_coach and (alias = 'Glute Side Circle' or lower(nombre) = lower('Glute Side Circle')) limit 1));
  insert into _ecm_ej2 values ('Half Burpee with Dumbbell', (select id from ejercicios where user_id = v_coach and (alias = 'Half Burpee with Dumbbell' or lower(nombre) = lower('Half Burpee with Dumbbell')) limit 1));
  insert into _ecm_ej2 values ('High Plank Jacks', (select id from ejercicios where user_id = v_coach and (alias = 'High Plank Jacks' or lower(nombre) = lower('High Plank Jacks')) limit 1));
  insert into _ecm_ej2 values ('Hinge to T-Rotation', (select id from ejercicios where user_id = v_coach and (alias = 'Hinge to T-Rotation' or lower(nombre) = lower('Hinge to T-Rotation')) limit 1));
  insert into _ecm_ej2 values ('Hip Thrust Machine', (select id from ejercicios where user_id = v_coach and (alias = 'Hip Thrust Machine' or lower(nombre) = lower('Hip Thrust Machine')) limit 1));
  insert into _ecm_ej2 values ('Lateral Shuttle Run', (select id from ejercicios where user_id = v_coach and (alias = 'Lateral Shuttle Run' or lower(nombre) = lower('Lateral Shuttle Run')) limit 1));
  insert into _ecm_ej2 values ('Machine Assisted Wide Grip Pull Up', (select id from ejercicios where user_id = v_coach and (alias = 'Machine Assisted Wide Grip Pull Up' or lower(nombre) = lower('Machine Assisted Wide Grip Pull Up')) limit 1));
  insert into _ecm_ej2 values ('Machine Lateral Raise', (select id from ejercicios where user_id = v_coach and (alias = 'Machine Lateral Raise' or lower(nombre) = lower('Machine Lateral Raise')) limit 1));
  insert into _ecm_ej2 values ('Machine Preacher Curl', (select id from ejercicios where user_id = v_coach and (alias = 'Machine Preacher Curl' or lower(nombre) = lower('Machine Preacher Curl')) limit 1));
  insert into _ecm_ej2 values ('Machine Seated Calf Raise', (select id from ejercicios where user_id = v_coach and (alias = 'Machine Seated Calf Raise' or lower(nombre) = lower('Machine Seated Calf Raise')) limit 1));
  insert into _ecm_ej2 values ('Machine Seated Chest Fly', (select id from ejercicios where user_id = v_coach and (alias = 'Machine Seated Chest Fly' or lower(nombre) = lower('Machine Seated Chest Fly')) limit 1));
  insert into _ecm_ej2 values ('Machine Seated Hip Adduction', (select id from ejercicios where user_id = v_coach and (alias = 'Machine Seated Hip Adduction' or lower(nombre) = lower('Machine Seated Hip Adduction')) limit 1));
  insert into _ecm_ej2 values ('Machine Seated Leg Curl', (select id from ejercicios where user_id = v_coach and (alias = 'Machine Seated Leg Curl' or lower(nombre) = lower('Machine Seated Leg Curl')) limit 1));
  insert into _ecm_ej2 values ('Machine Seated Leg Extension', (select id from ejercicios where user_id = v_coach and (alias = 'Machine Seated Leg Extension' or lower(nombre) = lower('Machine Seated Leg Extension')) limit 1));
  insert into _ecm_ej2 values ('Machine Seated Shoulder Press', (select id from ejercicios where user_id = v_coach and (alias = 'Machine Seated Shoulder Press' or lower(nombre) = lower('Machine Seated Shoulder Press')) limit 1));
  insert into _ecm_ej2 values ('Machine Seated Single Arm Neutral Grip Row', (select id from ejercicios where user_id = v_coach and (alias = 'Machine Seated Single Arm Neutral Grip Row' or lower(nombre) = lower('Machine Seated Single Arm Neutral Grip Row')) limit 1));
  insert into _ecm_ej2 values ('Mini Band Side Lying Hip Abduction', (select id from ejercicios where user_id = v_coach and (alias = 'Mini Band Side Lying Hip Abduction' or lower(nombre) = lower('Mini Band Side Lying Hip Abduction')) limit 1));
  insert into _ecm_ej2 values ('Mini Band Standing I''s', (select id from ejercicios where user_id = v_coach and (alias = 'Mini Band Standing I''s' or lower(nombre) = lower('Mini Band Standing I''s')) limit 1));
  insert into _ecm_ej2 values ('Mini Band Wall Slides', (select id from ejercicios where user_id = v_coach and (alias = 'Mini Band Wall Slides' or lower(nombre) = lower('Mini Band Wall Slides')) limit 1));
  insert into _ecm_ej2 values ('Pallof Press', (select id from ejercicios where user_id = v_coach and (alias = 'Pallof Press' or lower(nombre) = lower('Pallof Press')) limit 1));
  insert into _ecm_ej2 values ('Plate Weighted Dip', (select id from ejercicios where user_id = v_coach and (alias = 'Plate Weighted Dip' or lower(nombre) = lower('Plate Weighted Dip')) limit 1));
  insert into _ecm_ej2 values ('Plate Weighted Wide Grip Pull Up', (select id from ejercicios where user_id = v_coach and (alias = 'Plate Weighted Wide Grip Pull Up' or lower(nombre) = lower('Plate Weighted Wide Grip Pull Up')) limit 1));
  insert into _ecm_ej2 values ('Pull Up', (select id from ejercicios where user_id = v_coach and (alias = 'Pull Up' or lower(nombre) = lower('Pull Up')) limit 1));
  insert into _ecm_ej2 values ('Push Up', (select id from ejercicios where user_id = v_coach and (alias = 'Push Up' or lower(nombre) = lower('Push Up')) limit 1));
  insert into _ecm_ej2 values ('Quadruped Hip Circles', (select id from ejercicios where user_id = v_coach and (alias = 'Quadruped Hip Circles' or lower(nombre) = lower('Quadruped Hip Circles')) limit 1));
  insert into _ecm_ej2 values ('Running', (select id from ejercicios where user_id = v_coach and (alias = 'Running' or lower(nombre) = lower('Running')) limit 1));
  insert into _ecm_ej2 values ('Seated Dumbbell Front Raise to Lateral Raise', (select id from ejercicios where user_id = v_coach and (alias = 'Seated Dumbbell Front Raise to Lateral Raise' or lower(nombre) = lower('Seated Dumbbell Front Raise to Lateral Raise')) limit 1));
  insert into _ecm_ej2 values ('Seated Leg Press', (select id from ejercicios where user_id = v_coach and (alias = 'Seated Leg Press' or lower(nombre) = lower('Seated Leg Press')) limit 1));
  insert into _ecm_ej2 values ('Seated Machine Ab Crunch', (select id from ejercicios where user_id = v_coach and (alias = 'Seated Machine Ab Crunch' or lower(nombre) = lower('Seated Machine Ab Crunch')) limit 1));
  insert into _ecm_ej2 values ('Shuttle Run', (select id from ejercicios where user_id = v_coach and (alias = 'Shuttle Run' or lower(nombre) = lower('Shuttle Run')) limit 1));
  insert into _ecm_ej2 values ('Smith Machine Bench Press', (select id from ejercicios where user_id = v_coach and (alias = 'Smith Machine Bench Press' or lower(nombre) = lower('Smith Machine Bench Press')) limit 1));
  insert into _ecm_ej2 values ('Smith Machine Incline Bench Press', (select id from ejercicios where user_id = v_coach and (alias = 'Smith Machine Incline Bench Press' or lower(nombre) = lower('Smith Machine Incline Bench Press')) limit 1));
  insert into _ecm_ej2 values ('Smith Machine Seated Shoulder Press', (select id from ejercicios where user_id = v_coach and (alias = 'Smith Machine Seated Shoulder Press' or lower(nombre) = lower('Smith Machine Seated Shoulder Press')) limit 1));
  insert into _ecm_ej2 values ('Smith Machine Sumo Deadlift', (select id from ejercicios where user_id = v_coach and (alias = 'Smith Machine Sumo Deadlift' or lower(nombre) = lower('Smith Machine Sumo Deadlift')) limit 1));
  insert into _ecm_ej2 values ('Static Pigeon Stretch', (select id from ejercicios where user_id = v_coach and (alias = 'Static Pigeon Stretch' or lower(nombre) = lower('Static Pigeon Stretch')) limit 1));
  insert into _ecm_ej2 values ('SuperBand Anchored Tricep Pushdown', (select id from ejercicios where user_id = v_coach and (alias = 'SuperBand Anchored Tricep Pushdown' or lower(nombre) = lower('SuperBand Anchored Tricep Pushdown')) limit 1));
  insert into _ecm_ej2 values ('SuperBand Dislocates', (select id from ejercicios where user_id = v_coach and (alias = 'SuperBand Dislocates' or lower(nombre) = lower('SuperBand Dislocates')) limit 1));
  insert into _ecm_ej2 values ('Suspension Low Back Stretch', (select id from ejercicios where user_id = v_coach and (alias = 'Suspension Low Back Stretch' or lower(nombre) = lower('Suspension Low Back Stretch')) limit 1));
  insert into _ecm_ej2 values ('Table Top Half Arm Thoracic Rotation', (select id from ejercicios where user_id = v_coach and (alias = 'Table Top Half Arm Thoracic Rotation' or lower(nombre) = lower('Table Top Half Arm Thoracic Rotation')) limit 1));
  insert into _ecm_ej2 values ('Wide Grip Lat Pulldown', (select id from ejercicios where user_id = v_coach and (alias = 'Wide Grip Lat Pulldown' or lower(nombre) = lower('Wide Grip Lat Pulldown')) limit 1));
  insert into _ecm_ej2 values ('Wide Grip Pull Up', (select id from ejercicios where user_id = v_coach and (alias = 'Wide Grip Pull Up' or lower(nombre) = lower('Wide Grip Pull Up')) limit 1));

  -- Los nuevos de esta tanda.
  insert into _ecm_ej2 values ('Adductor Stretch with Thoracic Twist', ecm_ej(v_coach, 'Adductor Stretch with Thoracic Twist', 'Estiramiento de aductor con giro torácico', 'movilidad', 'full_body', null, array['peso_corporal']::text[], true));
  insert into _ecm_ej2 values ('Alternating Leg Drop', ecm_ej(v_coach, 'Alternating Leg Drop', 'Descenso alterno de pierna', 'fuerza', 'core', null, array['peso_corporal']::text[], true));
  insert into _ecm_ej2 values ('Band Anchored Pistol Squat to Row', ecm_ej(v_coach, 'Band Anchored Pistol Squat to Row', 'Sentadilla a una pierna con remo en banda', 'fuerza', 'full_body', 'rodilla', array['banda']::text[], true));
  insert into _ecm_ej2 values ('Band Anchored Single Arm Incline Curl', ecm_ej(v_coach, 'Band Anchored Single Arm Incline Curl', 'Curl inclinado a una mano con banda', 'fuerza', 'tren_superior', 'pull', array['banda']::text[], true));
  insert into _ecm_ej2 values ('Band Deadlift', ecm_ej(v_coach, 'Band Deadlift', 'Peso muerto con banda', 'fuerza', 'tren_inferior', 'cadera', array['banda']::text[], false));
  insert into _ecm_ej2 values ('Banded Sprinter', ecm_ej(v_coach, 'Banded Sprinter', 'Sprint en el sitio con banda', 'cardio', 'tren_inferior', 'locomocion', array['banda']::text[], false));
  insert into _ecm_ej2 values ('Barbell Hip Thrust', ecm_ej(v_coach, 'Barbell Hip Thrust', 'Hip thrust con barra', 'fuerza', 'tren_inferior', 'cadera', array['barra','banco']::text[], false));
  insert into _ecm_ej2 values ('Barbell Rear Shrug', ecm_ej(v_coach, 'Barbell Rear Shrug', 'Encogimiento de hombros con barra por detrás', 'fuerza', 'tren_superior', 'pull', array['barra']::text[], false));
  insert into _ecm_ej2 values ('Bench Hopover Burpee', ecm_ej(v_coach, 'Bench Hopover Burpee', 'Burpee saltando el banco', 'pliometrico', 'full_body', null, array['banco']::text[], false));
  insert into _ecm_ej2 values ('Bench Side Plank Hip Dip', ecm_ej(v_coach, 'Bench Side Plank Hip Dip', 'Plancha lateral en banco con descenso de cadera', 'fuerza', 'core', null, array['banco']::text[], true));
  insert into _ecm_ej2 values ('Bench Single Leg Hip Thrust', ecm_ej(v_coach, 'Bench Single Leg Hip Thrust', 'Hip thrust a una pierna en banco', 'fuerza', 'tren_inferior', 'cadera', array['banco']::text[], true));
  insert into _ecm_ej2 values ('Bench Twist Crunches', ecm_ej(v_coach, 'Bench Twist Crunches', 'Crunch con giro en banco', 'fuerza', 'core', null, array['banco']::text[], true));
  insert into _ecm_ej2 values ('Body Weight Single Leg Deadlift', ecm_ej(v_coach, 'Body Weight Single Leg Deadlift', 'Peso muerto a una pierna sin peso', 'fuerza', 'tren_inferior', 'cadera', array['peso_corporal']::text[], true));
  insert into _ecm_ej2 values ('Bodyweight Bent Knee Single Leg Calf Raise', ecm_ej(v_coach, 'Bodyweight Bent Knee Single Leg Calf Raise', 'Gemelo a una pierna con rodilla flexionada', 'fuerza', 'tren_inferior', null, array['peso_corporal']::text[], true));
  insert into _ecm_ej2 values ('Bodyweight Kang Squat', ecm_ej(v_coach, 'Bodyweight Kang Squat', 'Kang squat sin peso', 'movilidad', 'tren_inferior', 'cadera', array['peso_corporal']::text[], false));
  insert into _ecm_ej2 values ('Bodyweight Single Leg Calf Raise', ecm_ej(v_coach, 'Bodyweight Single Leg Calf Raise', 'Gemelo a una pierna sin peso', 'fuerza', 'tren_inferior', null, array['peso_corporal']::text[], true));
  insert into _ecm_ej2 values ('Bodyweight Walking Lunge', ecm_ej(v_coach, 'Bodyweight Walking Lunge', 'Zancada caminando sin peso', 'fuerza', 'tren_inferior', 'rodilla', array['peso_corporal']::text[], true));
  insert into _ecm_ej2 values ('Box Jump', ecm_ej(v_coach, 'Box Jump', 'Salto al cajón', 'pliometrico', 'tren_inferior', 'rodilla', array['cajon']::text[], false));
  insert into _ecm_ej2 values ('Box Pistol Squat', ecm_ej(v_coach, 'Box Pistol Squat', 'Sentadilla a una pierna al cajón', 'fuerza', 'tren_inferior', 'rodilla', array['cajon']::text[], true));
  insert into _ecm_ej2 values ('Bulgarian Pulses', ecm_ej(v_coach, 'Bulgarian Pulses', 'Rebotes en búlgara', 'fuerza', 'tren_inferior', 'rodilla', array['banco']::text[], true));
  insert into _ecm_ej2 values ('Burpee', ecm_ej(v_coach, 'Burpee', 'Burpee', 'pliometrico', 'full_body', null, array['peso_corporal']::text[], false));
  insert into _ecm_ej2 values ('Burpee Broad Jump', ecm_ej(v_coach, 'Burpee Broad Jump', 'Burpee con salto horizontal', 'pliometrico', 'full_body', null, array['peso_corporal']::text[], false));
  insert into _ecm_ej2 values ('Cable Single Arm Bicep Curl', ecm_ej(v_coach, 'Cable Single Arm Bicep Curl', 'Curl de bíceps a una mano en polea', 'fuerza', 'tren_superior', 'pull', array['polea']::text[], true));
  insert into _ecm_ej2 values ('Cable Tricep Kickback', ecm_ej(v_coach, 'Cable Tricep Kickback', 'Patada de tríceps en polea', 'fuerza', 'tren_superior', 'push', array['polea']::text[], true));
  insert into _ecm_ej2 values ('Chest to wall handstand', ecm_ej(v_coach, 'Chest to wall handstand', 'Pino de cara a la pared', 'fuerza', 'tren_superior', 'push', array['peso_corporal']::text[], false));
  insert into _ecm_ej2 values ('Clamshell with Hip Thrust', ecm_ej(v_coach, 'Clamshell with Hip Thrust', 'Almeja con empuje de cadera', 'fuerza', 'tren_inferior', 'cadera', array['peso_corporal']::text[], true));
  insert into _ecm_ej2 values ('Decline Plank to Pike', ecm_ej(v_coach, 'Decline Plank to Pike', 'Plancha declinada a pica', 'fuerza', 'core', null, array['banco']::text[], false));
  insert into _ecm_ej2 values ('Dragon flag tuck eccentric', ecm_ej(v_coach, 'Dragon flag tuck eccentric', 'Dragon flag agrupado excéntrico', 'fuerza', 'core', null, array['banco']::text[], false));
  insert into _ecm_ej2 values ('Dumbbell Bicep Curl', ecm_ej(v_coach, 'Dumbbell Bicep Curl', 'Curl de bíceps con mancuernas', 'fuerza', 'tren_superior', 'pull', array['mancuerna']::text[], false));
  insert into _ecm_ej2 values ('Dumbbell Calf Raise', ecm_ej(v_coach, 'Dumbbell Calf Raise', 'Gemelo de pie con mancuerna', 'fuerza', 'tren_inferior', null, array['mancuerna']::text[], false));
  insert into _ecm_ej2 values ('Dumbbell Curl to Shoulder Press', ecm_ej(v_coach, 'Dumbbell Curl to Shoulder Press', 'Curl y press de hombro con mancuernas', 'fuerza', 'tren_superior', 'push', array['mancuerna']::text[], false));
  insert into _ecm_ej2 values ('Dumbbell Incline Bicep Curl', ecm_ej(v_coach, 'Dumbbell Incline Bicep Curl', 'Curl inclinado con mancuernas', 'fuerza', 'tren_superior', 'pull', array['mancuerna','banco']::text[], false));
  insert into _ecm_ej2 values ('Dumbbell Isometric Bicep Curl', ecm_ej(v_coach, 'Dumbbell Isometric Bicep Curl', 'Curl isométrico con mancuernas', 'fuerza', 'tren_superior', 'pull', array['mancuerna']::text[], true));
  insert into _ecm_ej2 values ('Dumbbell Lateral Raise', ecm_ej(v_coach, 'Dumbbell Lateral Raise', 'Elevación lateral con mancuernas', 'fuerza', 'tren_superior', 'push', array['mancuerna']::text[], false));
  insert into _ecm_ej2 values ('Dumbbell Laying Tricep Extension to Press', ecm_ej(v_coach, 'Dumbbell Laying Tricep Extension to Press', 'Extensión de tríceps tumbado a press', 'fuerza', 'tren_superior', 'push', array['mancuerna']::text[], false));
  insert into _ecm_ej2 values ('Dumbbell Walking Lunge', ecm_ej(v_coach, 'Dumbbell Walking Lunge', 'Zancada caminando con mancuernas', 'fuerza', 'tren_inferior', 'rodilla', array['mancuerna']::text[], true));
  insert into _ecm_ej2 values ('Elevated Pike Push-Up', ecm_ej(v_coach, 'Elevated Pike Push-Up', 'Flexión en pica con pies elevados', 'fuerza', 'tren_superior', 'push', array['banco']::text[], false));
  insert into _ecm_ej2 values ('Extensión muñeca', ecm_ej(v_coach, 'Extensión muñeca', 'Extensión de muñeca', 'movilidad', 'tren_superior', null, array['mancuerna']::text[], true));
  insert into _ecm_ej2 values ('Fire Hydrant Standing', ecm_ej(v_coach, 'Fire Hydrant Standing', 'Abducción de cadera de pie', 'movilidad', 'tren_inferior', 'cadera', array['peso_corporal']::text[], true));
  insert into _ecm_ej2 values ('Glute Bridge', ecm_ej(v_coach, 'Glute Bridge', 'Puente de glúteo', 'fuerza', 'tren_inferior', 'cadera', array['peso_corporal']::text[], false));
  insert into _ecm_ej2 values ('Half Kneeling SuperBand Single Arm Row', ecm_ej(v_coach, 'Half Kneeling SuperBand Single Arm Row', 'Remo a una mano con banda de rodillas', 'fuerza', 'tren_superior', 'pull', array['banda']::text[], true));
  insert into _ecm_ej2 values ('Hollow Body Hold Flutter Kicks', ecm_ej(v_coach, 'Hollow Body Hold Flutter Kicks', 'Hollow hold con tijeras', 'fuerza', 'core', null, array['peso_corporal']::text[], false));
  insert into _ecm_ej2 values ('Horizontal Cable Rotation', ecm_ej(v_coach, 'Horizontal Cable Rotation', 'Rotación horizontal en polea', 'fuerza', 'core', null, array['polea']::text[], true));
  insert into _ecm_ej2 values ('Kettlebell Alternating Halo with Chest Press', ecm_ej(v_coach, 'Kettlebell Alternating Halo with Chest Press', 'Halo alterno con press de pecho (kettlebell)', 'fuerza', 'full_body', 'push', array['kettlebell']::text[], false));
  insert into _ecm_ej2 values ('Kettlebell Alternating Stationary Cossack Squat', ecm_ej(v_coach, 'Kettlebell Alternating Stationary Cossack Squat', 'Sentadilla cosaco alterna con kettlebell', 'fuerza', 'tren_inferior', 'rodilla', array['kettlebell']::text[], true));
  insert into _ecm_ej2 values ('Kettlebell Lateral Step Up', ecm_ej(v_coach, 'Kettlebell Lateral Step Up', 'Subida lateral al cajón con kettlebell', 'fuerza', 'tren_inferior', 'rodilla', array['kettlebell','banco']::text[], true));
  insert into _ecm_ej2 values ('Kettlebell Windmill', ecm_ej(v_coach, 'Kettlebell Windmill', 'Molino con kettlebell', 'movilidad', 'full_body', null, array['kettlebell']::text[], true));
  insert into _ecm_ej2 values ('Kick Throughs', ecm_ej(v_coach, 'Kick Throughs', 'Patada cruzada desde cuadrupedia', 'movilidad', 'full_body', null, array['peso_corporal']::text[], true));
  insert into _ecm_ej2 values ('Landmine Deadlift', ecm_ej(v_coach, 'Landmine Deadlift', 'Peso muerto con landmine', 'fuerza', 'tren_inferior', 'cadera', array['barra']::text[], false));
  insert into _ecm_ej2 values ('Landmine Half-Kneeling Single Arm Press', ecm_ej(v_coach, 'Landmine Half-Kneeling Single Arm Press', 'Press a una mano de rodillas con landmine', 'fuerza', 'tren_superior', 'push', array['barra']::text[], true));
  insert into _ecm_ej2 values ('Landmine Rotational Clean and Press', ecm_ej(v_coach, 'Landmine Rotational Clean and Press', 'Cargada y press rotacional con landmine', 'potencia', 'full_body', 'push', array['barra']::text[], true));
  insert into _ecm_ej2 values ('Lying Hip Abductions', ecm_ej(v_coach, 'Lying Hip Abductions', 'Abducción de cadera tumbado', 'fuerza', 'tren_inferior', 'cadera', array['peso_corporal']::text[], true));
  insert into _ecm_ej2 values ('Machine Assisted Dip', ecm_ej(v_coach, 'Machine Assisted Dip', 'Fondos asistidos en máquina', 'fuerza', 'tren_superior', 'push', array['maquina']::text[], false));
  insert into _ecm_ej2 values ('Medicine Ball Slam with Squat Jump', ecm_ej(v_coach, 'Medicine Ball Slam with Squat Jump', 'Golpe de balón medicinal con salto', 'potencia', 'full_body', null, array['balon_medicinal']::text[], false));
  insert into _ecm_ej2 values ('Mini Band Alternating Hip Abduction', ecm_ej(v_coach, 'Mini Band Alternating Hip Abduction', 'Abducción de cadera alterna con banda', 'fuerza', 'tren_inferior', 'cadera', array['banda']::text[], true));
  insert into _ecm_ej2 values ('Mini Band Bent Arm Pull Apart', ecm_ej(v_coach, 'Mini Band Bent Arm Pull Apart', 'Apertura con banda y codos flexionados', 'movilidad', 'tren_superior', 'pull', array['banda']::text[], false));
  insert into _ecm_ej2 values ('Mini Band Bent Over Y''s', ecm_ej(v_coach, 'Mini Band Bent Over Y''s', 'Y con banda inclinado', 'fuerza', 'tren_superior', 'pull', array['banda']::text[], false));
  insert into _ecm_ej2 values ('Mini Band Bus Drivers', ecm_ej(v_coach, 'Mini Band Bus Drivers', 'Volante con banda', 'movilidad', 'tren_superior', null, array['banda']::text[], false));
  insert into _ecm_ej2 values ('Mini Band Delt Raises', ecm_ej(v_coach, 'Mini Band Delt Raises', 'Elevación de deltoides con banda', 'fuerza', 'tren_superior', 'push', array['banda']::text[], false));
  insert into _ecm_ej2 values ('Mini Band Wall Sit', ecm_ej(v_coach, 'Mini Band Wall Sit', 'Sentadilla isométrica en pared con banda', 'fuerza', 'tren_inferior', 'rodilla', array['banda']::text[], false));
  insert into _ecm_ej2 values ('Muscle Up', ecm_ej(v_coach, 'Muscle Up', 'Muscle up', 'fuerza', 'tren_superior', 'pull', array['pull_up_bar']::text[], false));
  insert into _ecm_ej2 values ('Pilates - Oblique Twists with Ball', ecm_ej(v_coach, 'Pilates - Oblique Twists with Ball', 'Giros de oblicuos con balón', 'fuerza', 'core', null, array['balon_medicinal']::text[], true));
  insert into _ecm_ej2 values ('Pilates - Swan', ecm_ej(v_coach, 'Pilates - Swan', 'Cisne (pilates)', 'movilidad', 'core', null, array['peso_corporal']::text[], false));
  insert into _ecm_ej2 values ('Prayer Squat', ecm_ej(v_coach, 'Prayer Squat', 'Sentadilla profunda en oración', 'movilidad', 'tren_inferior', 'rodilla', array['peso_corporal']::text[], false));
  insert into _ecm_ej2 values ('Pronación muñeca con banda elástica', ecm_ej(v_coach, 'Pronación muñeca con banda elástica', 'Pronación de muñeca con banda', 'movilidad', 'tren_superior', null, array['banda']::text[], true));
  insert into _ecm_ej2 values ('Prone Scorpion Alternating', ecm_ej(v_coach, 'Prone Scorpion Alternating', 'Escorpión alterno boca abajo', 'movilidad', 'full_body', null, array['peso_corporal']::text[], true));
  insert into _ecm_ej2 values ('Reverse nordic curl band assisted', ecm_ej(v_coach, 'Reverse nordic curl band assisted', 'Nórdico inverso asistido con banda', 'fuerza', 'tren_inferior', 'rodilla', array['banda']::text[], false));
  insert into _ecm_ej2 values ('Scapular Pushups from Elbows', ecm_ej(v_coach, 'Scapular Pushups from Elbows', 'Flexión escapular desde codos', 'fuerza', 'tren_superior', 'push', array['peso_corporal']::text[], false));
  insert into _ecm_ej2 values ('Seated Dumbbell Hammer Curl to Neutral Press', ecm_ej(v_coach, 'Seated Dumbbell Hammer Curl to Neutral Press', 'Curl martillo sentado a press neutro', 'fuerza', 'tren_superior', 'push', array['mancuerna','banco']::text[], false));
  insert into _ecm_ej2 values ('Spiderman Push Up', ecm_ej(v_coach, 'Spiderman Push Up', 'Flexión spiderman', 'fuerza', 'tren_superior', 'push', array['peso_corporal']::text[], true));
  insert into _ecm_ej2 values ('Split Squat Pulse', ecm_ej(v_coach, 'Split Squat Pulse', 'Rebotes en zancada', 'fuerza', 'tren_inferior', 'rodilla', array['mancuerna']::text[], true));
  insert into _ecm_ej2 values ('Squat Pulse', ecm_ej(v_coach, 'Squat Pulse', 'Rebotes en sentadilla', 'fuerza', 'tren_inferior', 'rodilla', array['peso_corporal']::text[], false));
  insert into _ecm_ej2 values ('Squat to Squat Jump', ecm_ej(v_coach, 'Squat to Squat Jump', 'Sentadilla a sentadilla con salto', 'pliometrico', 'tren_inferior', 'rodilla', array['peso_corporal']::text[], false));
  insert into _ecm_ej2 values ('SuperBand Anchored Pistol Squat to Row', ecm_ej(v_coach, 'SuperBand Anchored Pistol Squat to Row', 'Sentadilla a una pierna con remo en superbanda', 'fuerza', 'full_body', 'rodilla', array['banda']::text[], true));
  insert into _ecm_ej2 values ('SuperBand Deadlift', ecm_ej(v_coach, 'SuperBand Deadlift', 'Peso muerto con superbanda', 'fuerza', 'tren_inferior', 'cadera', array['banda']::text[], false));
  insert into _ecm_ej2 values ('SuperBand Push Up', ecm_ej(v_coach, 'SuperBand Push Up', 'Flexión con superbanda', 'fuerza', 'tren_superior', 'push', array['banda']::text[], false));
  insert into _ecm_ej2 values ('Superband Pull Apart', ecm_ej(v_coach, 'Superband Pull Apart', 'Apertura con superbanda', 'fuerza', 'tren_superior', 'pull', array['banda']::text[], false));
  insert into _ecm_ej2 values ('Superband Squat', ecm_ej(v_coach, 'Superband Squat', 'Sentadilla con superbanda', 'fuerza', 'tren_inferior', 'rodilla', array['banda']::text[], false));
  insert into _ecm_ej2 values ('Superman Around the World', ecm_ej(v_coach, 'Superman Around the World', 'Superman con círculos de brazos', 'fuerza', 'core', null, array['peso_corporal']::text[], false));
  insert into _ecm_ej2 values ('Table Top Full Arm Thoracic Rotation', ecm_ej(v_coach, 'Table Top Full Arm Thoracic Rotation', 'Rotación torácica con brazo extendido en cuadrupedia', 'movilidad', 'core', null, array['peso_corporal']::text[], true));
  raise notice 'Catálogo listo: % ejercicios.', (select count(*) from _ecm_ej2 where id is not null);
  -- Un aviso no vale aquí. Si un alias no se resuelve, los `insert` de más
  -- abajo escriben ejercicio_id = NULL sin quejarse y la rutina queda con
  -- huecos que nadie ve hasta que el cliente la abre. Mejor no cargar nada.
  if exists (select 1 from _ecm_ej2 where id is null) then
    raise exception 'No pude resolver estos ejercicios: %. Son de la primera tanda: corre antes carga-rutinas-trainerize.sql.',
      (select string_agg(alias, ', ') from _ecm_ej2 where id is null);
  end if;
end $cat$;

-- ─────────────────────────────────────────────────────────────────────
-- JUAN ESTEBAN ECHEVERRI · Cycle 5 · 2 semanas (2026-09-07 → 2026-09-20)
--   Plan de MOVILIDAD, no de fuerza. Dos ejercicios en español de muñeca
--   sugieren lesión de muñeca.
-- ─────────────────────────────────────────────────────────────────────
do $cli$
declare v_coach uuid; v_cli uuid; v_fase uuid; v_rut uuid; v_blo uuid; v_ses uuid;
begin
  select id, user_id into v_cli, v_coach from clientes where nombre ilike '%juan%esteban%echeverri%' limit 1;
  if v_cli is null then
    raise warning 'SALTADO: no encuentro a «Juan Esteban Echeverri» en `clientes` (patrón %%juan%%esteban%%echeverri%%). Corrige el nombre y vuelve a correr.';
    return;
  end if;
  if exists (select 1 from fases where cliente_id = v_cli and nombre = 'Cycle 5') then
    raise notice 'SALTADO: «Juan Esteban Echeverri» ya tiene la fase Cycle 5 cargada.';
    return;
  end if;

  insert into fases (user_id, cliente_id, nombre, objetivo, notas_coach, semanas,
                     fecha_inicio, orden, estado)
  values (v_coach, v_cli, 'Cycle 5',
          'Bloque importado de Trainerize — la rutina que ya venía haciendo.',
          'Importado el 2026-09-25 desde el PDF de Trainerize (Cycle 5, 2026-09-07 a 2026-09-20). Revisar antes de enviar al cliente.',
          2, date '2026-09-07',
          coalesce((select max(orden)+1 from fases where cliente_id = v_cli), 1), 'borrador')
  returning id into v_fase;

  -- Rutina 1: Lower Body Mobility Routine
  insert into rutinas (user_id, cliente_id, fase_id, nombre, dia_orden,
                       duracion_estimada_min, tipo_sesion, dias_semana)
  values (v_coach, v_cli, v_fase, 'Lower Body Mobility Routine', 1, 27, 'fuerza', '{}'::text[])
  returning id into v_rut;
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'A', 'circuito', 3, 45, 1)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Cossack Squat to T-Spine Reach'), 1, 1, '6 por lado', 45);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Bodyweight Kang Squat'), 2, 1, '6', 45);
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'B', 'circuito', 3, 45, 2)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Clamshell with Hip Thrust'), 3, 1, '6 por lado', 45);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Glute Side Circle'), 4, 1, '6 por lado', 45);
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'C', 'circuito', 3, 45, 3)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Fire Hydrant Standing'), 5, 1, '6 por lado', 45);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Kettlebell Lateral Step Up'), 6, 1, '6 por lado', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Body Weight Single Leg Deadlift'), 7, 3, '6 por lado', null);

  -- Rutina 2: Morning Flow
  insert into rutinas (user_id, cliente_id, fase_id, nombre, dia_orden,
                       duracion_estimada_min, tipo_sesion, dias_semana)
  values (v_coach, v_cli, v_fase, 'Morning Flow', 2, 18, 'fuerza', array['L','M','X','J','V']::text[])
  returning id into v_rut;
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Adductor Stretch with Thoracic Twist'), 1, 3, '6 por lado', 10);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Prayer Squat'), 2, 2, '40-45 s', 10);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Clamshell with Hip Thrust'), 3, 2, '6 por lado', 10);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Cat to Cow'), 4, 3, '6', 10);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Pilates - Swan'), 5, 3, '6', 10);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Bear to Step Through'), 6, 3, '6 por lado', 10);

  -- Rutina 3: Upper Body Mobility Routine
  insert into rutinas (user_id, cliente_id, fase_id, nombre, dia_orden,
                       duracion_estimada_min, tipo_sesion, dias_semana)
  values (v_coach, v_cli, v_fase, 'Upper Body Mobility Routine', 3, 29, 'fuerza', '{}'::text[])
  returning id into v_rut;
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'A', 'circuito', 2, 45, 1)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Extensión muñeca'), 1, 1, '6 por lado', 45);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Pronación muñeca con banda elástica'), 2, 1, '6 por lado', 45);
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'B', 'circuito', 3, 45, 2)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Superman Around the World'), 3, 1, '6', 45);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Kettlebell Windmill'), 4, 1, '4 por lado', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Mini Band Bus Drivers'), 5, 3, '6', null);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Superband Pull Apart'), 6, 3, '6', 45);
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'C', 'circuito', 3, 45, 3)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='SuperBand Dislocates'), 7, 1, '6', 45);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Dumbbell Standing Shoulder External Rotations'), 8, 1, '6', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Bar Hang'), 9, 1, '120 s', null);
  raise notice 'OK: «Juan Esteban Echeverri» · Cycle 5 · 3 rutinas.';
end $cli$;

-- ─────────────────────────────────────────────────────────────────────
-- JUAN SEBASTIÁN MARIÑO · Cycle 3 · 4 semanas (2026-09-07 → 2026-10-04)
--   Rutinas en pares Gym/Home: entrena donde pueda. Solo la Upper (Home)
--   tiene historial, así que los días de las otras tres los pones tú.
-- ─────────────────────────────────────────────────────────────────────
do $cli$
declare v_coach uuid; v_cli uuid; v_fase uuid; v_rut uuid; v_blo uuid; v_ses uuid;
begin
  select id, user_id into v_cli, v_coach from clientes where nombre ilike '%juan%sebasti%n%mari%o%' limit 1;
  if v_cli is null then
    raise warning 'SALTADO: no encuentro a «Juan Sebastián Mariño» en `clientes` (patrón %%juan%%sebasti%%n%%mari%%o%%). Corrige el nombre y vuelve a correr.';
    return;
  end if;
  if exists (select 1 from fases where cliente_id = v_cli and nombre = 'Cycle 3') then
    raise notice 'SALTADO: «Juan Sebastián Mariño» ya tiene la fase Cycle 3 cargada.';
    return;
  end if;

  insert into fases (user_id, cliente_id, nombre, objetivo, notas_coach, semanas,
                     fecha_inicio, orden, estado)
  values (v_coach, v_cli, 'Cycle 3',
          'Bloque importado de Trainerize — la rutina que ya venía haciendo.',
          'Importado el 2026-09-25 desde el PDF de Trainerize (Cycle 3, 2026-09-07 a 2026-10-04). Revisar antes de enviar al cliente.',
          4, date '2026-09-07',
          coalesce((select max(orden)+1 from fases where cliente_id = v_cli), 1), 'borrador')
  returning id into v_fase;

  -- Rutina 1: Lower Body + Core Training (Gym edition)
  insert into rutinas (user_id, cliente_id, fase_id, nombre, dia_orden,
                       duracion_estimada_min, tipo_sesion, dias_semana)
  values (v_coach, v_cli, v_fase, 'Lower Body + Core Training (Gym edition)', 1, 49, 'fuerza', '{}'::text[])
  returning id into v_rut;
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'A', 'circuito', 2, 30, 1)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Bodyweight Squat To Hinge'), 1, 1, '5', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Bodyweight Alternating Cossack Squat'), 2, 1, '5 por lado', 30);
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'B', 'circuito', 1, 30, 2)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Alternating Lunge Hops'), 3, 1, '8-15 saltos', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Lateral Shuttle Run'), 4, 1, '60 s', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Seated Leg Press'), 5, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Machine Seated Leg Curl'), 6, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Machine Seated Leg Extension'), 7, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Dumbbell Hip Thrust'), 8, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Machine Seated Calf Raise'), 9, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Dip Machine Bent Leg Raise'), 10, 3, '8-15', 40);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Pallof Press'), 11, 3, '8-15', 40);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Static Pigeon Stretch'), 12, 1, '30 s por lado', null);

  -- Rutina 2: Lower Body + Core Training (Home edition)
  insert into rutinas (user_id, cliente_id, fase_id, nombre, dia_orden,
                       duracion_estimada_min, tipo_sesion, dias_semana)
  values (v_coach, v_cli, v_fase, 'Lower Body + Core Training (Home edition)', 2, 48, 'fuerza', '{}'::text[])
  returning id into v_rut;
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'A', 'circuito', 2, 30, 1)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='90-90 Hip Switch'), 1, 1, '5', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Bodyweight Alternating Cossack Squat'), 2, 1, '5 por lado', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Bodyweight Squat To Hinge'), 3, 1, '5', 30);
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'B', 'circuito', 1, 35, 2)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Burpee'), 4, 1, '8-12', 35);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Lateral Shuttle Run'), 5, 1, '60 s', 35);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Dumbbell Stationary Lunge'), 6, 4, '8-15 por lado', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Squat Pulse'), 7, 3, '6-8', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Dumbbell Deadlift'), 8, 3, '8-15', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Dumbbell Glute Bridge'), 9, 3, '8-15', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Bodyweight Single Leg Calf Raise'), 10, 3, '8-15 por lado', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='High Plank Jacks'), 11, 3, '15', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Bicycle Crunch'), 12, 3, '15', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Static Pigeon Stretch'), 13, 1, '30 s por lado', null);

  -- Rutina 3: Upper Body Training (Gym edition)
  insert into rutinas (user_id, cliente_id, fase_id, nombre, dia_orden,
                       duracion_estimada_min, tipo_sesion, dias_semana)
  values (v_coach, v_cli, v_fase, 'Upper Body Training (Gym edition)', 3, 59, 'fuerza', '{}'::text[])
  returning id into v_rut;
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'A', 'circuito', 2, 30, 1)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Table Top Half Arm Thoracic Rotation'), 1, 1, '5 por lado', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Mini Band Standing I''s'), 2, 1, '5', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Bar Hang'), 3, 1, '60 s', null);
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'B', 'circuito', 1, 35, 2)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Lateral Shuttle Run'), 4, 1, '60 s', 35);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Dumbbell Burpee with Curl to Press'), 5, 1, '8-15', 35);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Dumbbell Incline Bench Press'), 6, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Cable Seated Close Row'), 7, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Machine Seated Chest Fly'), 8, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Machine Seated Shoulder Press'), 9, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Machine Lateral Raise'), 10, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Machine Preacher Curl'), 11, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Dumbbell Hammer Curl'), 12, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Cable V Bar Tricep Pushdown'), 13, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Child''s Pose'), 14, 1, '30 s', null);

  -- Rutina 4: Upper Body Training (Home edition)
  insert into rutinas (user_id, cliente_id, fase_id, nombre, dia_orden,
                       duracion_estimada_min, tipo_sesion, dias_semana)
  values (v_coach, v_cli, v_fase, 'Upper Body Training (Home edition)', 4, 49, 'fuerza', array['M']::text[])
  returning id into v_rut;
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'A', 'circuito', 1, 50, 1)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Mini Band Standing I''s'), 1, 1, '6', 50);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Hinge to T-Rotation'), 2, 1, '5 por lado', 50);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Bear to Step Through'), 3, 1, '5 por lado', 50);
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'B', 'circuito', 1, 50, 2)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Push Up'), 4, 1, '6-8', 50);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Lateral Shuttle Run'), 5, 1, '60 s', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Dumbbell Single Arm Row'), 6, 4, '8-15 por lado', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Dumbbell Floor Press'), 7, 4, '8-15 por lado', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Dumbbell Seated Arnold Press'), 8, 3, '8-15', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Dumbbell Alternating Lateral Raise to Front Raise'), 9, 3, '8-15', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Dumbbell Isometric Bicep Curl'), 10, 3, '8-15 por lado', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Dumbbell Alternating Hammer Curl'), 11, 3, '8-15 por lado', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Band Anchored Single Arm Tricep Kickback'), 12, 3, '8-15 por lado', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Child''s Pose'), 13, 1, '40 s', null);
  -- historial 2026-09-15
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach, origen)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-15', 2,
          '2026-W38', 'completada', '2026-09-15 12:00:00+00'::timestamptz, true, 'importada')
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Mini Band Standing I''s') limit 1),
            (select id from _ecm_ej2 where alias='Mini Band Standing I''s'), 1, 6, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Mini Band Standing I''s') limit 1),
            (select id from _ecm_ej2 where alias='Mini Band Standing I''s'), 2, 6, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Push Up') limit 1),
            (select id from _ecm_ej2 where alias='Push Up'), 1, 8, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Push Up') limit 1),
            (select id from _ecm_ej2 where alias='Push Up'), 2, 8, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Single Arm Row') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Single Arm Row'), 1, 12, 12, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Single Arm Row') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Single Arm Row'), 2, 12, 12, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Single Arm Row') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Single Arm Row'), 3, 12, 12, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Single Arm Row') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Single Arm Row'), 4, 12, 12, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Floor Press') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Floor Press'), 1, 12, 22, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Floor Press') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Floor Press'), 2, 12, 22, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Floor Press') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Floor Press'), 3, 12, 22, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Floor Press') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Floor Press'), 4, 12, 22, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Seated Arnold Press') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Seated Arnold Press'), 1, 12, 10, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Seated Arnold Press') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Seated Arnold Press'), 2, 12, 10, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Seated Arnold Press') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Seated Arnold Press'), 3, 12, 10, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Alternating Lateral Raise to Front Raise') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Alternating Lateral Raise to Front Raise'), 1, 10, 10, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Alternating Lateral Raise to Front Raise') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Alternating Lateral Raise to Front Raise'), 2, 10, 10, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Alternating Lateral Raise to Front Raise') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Alternating Lateral Raise to Front Raise'), 3, 10, 10, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Isometric Bicep Curl') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Isometric Bicep Curl'), 1, 10, 22, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Isometric Bicep Curl') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Isometric Bicep Curl'), 2, 10, 22, 'kg');
  end if;
  raise notice 'OK: «Juan Sebastián Mariño» · Cycle 3 · 4 rutinas.';
end $cli$;

-- ─────────────────────────────────────────────────────────────────────
-- JUAN SINISTERRA · Cycle 4 · 4 semanas (2026-09-07 → 2026-10-04)
--   Dos datos raros del historial: 'Banded Sprinter' dice 60 reps x 40.1
--   kg (es 1 min a máxima potencia, Trainerize lo guardó en la columna
--   equivocada) y 'Lateral Shuttle Run' sale con kg. Los cargo como
--   tiempo. Además, en el 8 sep hay ejercicios que ya no están en Push
--   (Clapping Push Up, los de Smith Machine, Machine Seated Chest Fly,
--   Cable Tricep Kickback, Elevated Pike Push-Up): entran como
--   historial, no como programados.
-- ─────────────────────────────────────────────────────────────────────
do $cli$
declare v_coach uuid; v_cli uuid; v_fase uuid; v_rut uuid; v_blo uuid; v_ses uuid;
begin
  select id, user_id into v_cli, v_coach from clientes where nombre ilike '%juan%sinisterra%' limit 1;
  if v_cli is null then
    raise warning 'SALTADO: no encuentro a «Juan Sinisterra» en `clientes` (patrón %%juan%%sinisterra%%). Corrige el nombre y vuelve a correr.';
    return;
  end if;
  if exists (select 1 from fases where cliente_id = v_cli and nombre = 'Cycle 4') then
    raise notice 'SALTADO: «Juan Sinisterra» ya tiene la fase Cycle 4 cargada.';
    return;
  end if;

  insert into fases (user_id, cliente_id, nombre, objetivo, notas_coach, semanas,
                     fecha_inicio, orden, estado)
  values (v_coach, v_cli, 'Cycle 4',
          'Bloque importado de Trainerize — la rutina que ya venía haciendo.',
          'Importado el 2026-09-25 desde el PDF de Trainerize (Cycle 4, 2026-09-07 a 2026-10-04). Revisar antes de enviar al cliente. Dos datos raros del historial: ''Banded Sprinter'' dice 60 reps x 40.1 kg (es 1 min a máxima potencia, Trainerize lo guardó en la columna equivocada) y ''Lateral Shuttle Run'' sale con kg. Los cargo como tiempo. Además, en el 8 sep hay ejercicios que ya no están en Push (Clapping Push Up, los de Smith Machine, Machine Seated Chest Fly, Cable Tricep Kickback, Elevated Pike Push-Up): entran como historial, no como programados.',
          4, date '2026-09-07',
          coalesce((select max(orden)+1 from fases where cliente_id = v_cli), 1), 'borrador')
  returning id into v_fase;

  -- Rutina 1: Lower Body + Core Training
  insert into rutinas (user_id, cliente_id, fase_id, nombre, dia_orden,
                       duracion_estimada_min, tipo_sesion, dias_semana)
  values (v_coach, v_cli, v_fase, 'Lower Body + Core Training', 1, 59, 'fuerza', array['L']::text[])
  returning id into v_rut;
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'A', 'circuito', 2, 35, 1)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Quadruped Hip Circles'), 1, 1, '8-10 por lado', 35);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Kettlebell Alternating Stationary Cossack Squat'), 2, 1, '8-10 por lado', 35);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Bodyweight Squat To Hinge'), 3, 1, '8-10', 35);
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'B', 'circuito', 1, 35, 2)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Bosu Lateral Bounce to Squat Jump'), 4, 1, '8-10 por lado', 10);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Lateral Shuttle Run'), 5, 1, '60 s', 35);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Band Anchored Pistol Squat to Row'), 6, 3, '6-8 por lado', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Reverse nordic curl band assisted'), 7, 3, '6-8', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Angled Machine Leg Press'), 8, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Machine Seated Hip Adduction'), 9, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Machine Seated Calf Raise'), 10, 4, '6-12', 50);
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'C', 'circuito', 1, 35, 3)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Medicine Ball Slam with Squat Jump'), 11, 1, '8-15', 10);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Banded Sprinter'), 12, 1, '1 min máxima potencia', 35);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Dragon flag tuck eccentric'), 13, 3, '6-8', 25);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Seated Machine Ab Crunch'), 14, 4, '8-15', 25);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Pallof Press'), 15, 3, '6-8 por lado', 25);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Static Pigeon Stretch'), 16, 1, '30 s por lado', null);
  -- historial 2026-09-14
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach, origen)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-14', 2,
          '2026-W38', 'completada', '2026-09-14 12:00:00+00'::timestamptz, true, 'importada')
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Band Anchored Pistol Squat to Row') limit 1),
            (select id from _ecm_ej2 where alias='Band Anchored Pistol Squat to Row'), 1, 7, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Band Anchored Pistol Squat to Row') limit 1),
            (select id from _ecm_ej2 where alias='Band Anchored Pistol Squat to Row'), 2, 6, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Band Anchored Pistol Squat to Row') limit 1),
            (select id from _ecm_ej2 where alias='Band Anchored Pistol Squat to Row'), 3, 7, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Angled Machine Leg Press') limit 1),
            (select id from _ecm_ej2 where alias='Angled Machine Leg Press'), 1, 15, 45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Angled Machine Leg Press') limit 1),
            (select id from _ecm_ej2 where alias='Angled Machine Leg Press'), 2, 12, 70, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Angled Machine Leg Press') limit 1),
            (select id from _ecm_ej2 where alias='Angled Machine Leg Press'), 3, 12, 90, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Angled Machine Leg Press') limit 1),
            (select id from _ecm_ej2 where alias='Angled Machine Leg Press'), 4, 12, 115, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Seated Hip Adduction') limit 1),
            (select id from _ecm_ej2 where alias='Machine Seated Hip Adduction'), 1, 12, 100, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Seated Hip Adduction') limit 1),
            (select id from _ecm_ej2 where alias='Machine Seated Hip Adduction'), 2, 12, 115, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Seated Hip Adduction') limit 1),
            (select id from _ecm_ej2 where alias='Machine Seated Hip Adduction'), 3, 12, 130, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_ej2 where alias='Machine Seated Calf Raise'), 1, 12, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_ej2 where alias='Machine Seated Calf Raise'), 2, 12, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_ej2 where alias='Machine Seated Calf Raise'), 3, 12, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_ej2 where alias='Machine Seated Calf Raise'), 4, 12, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Medicine Ball Slam with Squat Jump') limit 1),
            (select id from _ecm_ej2 where alias='Medicine Ball Slam with Squat Jump'), 1, 10, 10, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Seated Machine Ab Crunch') limit 1),
            (select id from _ecm_ej2 where alias='Seated Machine Ab Crunch'), 1, 15, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Seated Machine Ab Crunch') limit 1),
            (select id from _ecm_ej2 where alias='Seated Machine Ab Crunch'), 2, 15, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Seated Machine Ab Crunch') limit 1),
            (select id from _ecm_ej2 where alias='Seated Machine Ab Crunch'), 3, 15, 60, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Seated Machine Ab Crunch') limit 1),
            (select id from _ecm_ej2 where alias='Seated Machine Ab Crunch'), 4, 12, 70, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Pallof Press') limit 1),
            (select id from _ecm_ej2 where alias='Pallof Press'), 1, 20, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Pallof Press') limit 1),
            (select id from _ecm_ej2 where alias='Pallof Press'), 2, 20, 30, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Pallof Press') limit 1),
            (select id from _ecm_ej2 where alias='Pallof Press'), 3, 15, 40, 'kg');
  end if;
  -- historial 2026-09-07
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach, origen)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-07', 1,
          '2026-W37', 'completada', '2026-09-07 12:00:00+00'::timestamptz, true, 'importada')
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Band Anchored Pistol Squat to Row') limit 1),
            (select id from _ecm_ej2 where alias='Band Anchored Pistol Squat to Row'), 1, 6, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Band Anchored Pistol Squat to Row') limit 1),
            (select id from _ecm_ej2 where alias='Band Anchored Pistol Squat to Row'), 2, 6, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Band Anchored Pistol Squat to Row') limit 1),
            (select id from _ecm_ej2 where alias='Band Anchored Pistol Squat to Row'), 3, 6, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Angled Machine Leg Press') limit 1),
            (select id from _ecm_ej2 where alias='Angled Machine Leg Press'), 1, 12, 70, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Angled Machine Leg Press') limit 1),
            (select id from _ecm_ej2 where alias='Angled Machine Leg Press'), 2, 10, 95, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Angled Machine Leg Press') limit 1),
            (select id from _ecm_ej2 where alias='Angled Machine Leg Press'), 3, 10, 95, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Angled Machine Leg Press') limit 1),
            (select id from _ecm_ej2 where alias='Angled Machine Leg Press'), 4, 11, 95, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Seated Hip Adduction') limit 1),
            (select id from _ecm_ej2 where alias='Machine Seated Hip Adduction'), 1, 12, 100, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Seated Hip Adduction') limit 1),
            (select id from _ecm_ej2 where alias='Machine Seated Hip Adduction'), 2, 12, 115, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Seated Hip Adduction') limit 1),
            (select id from _ecm_ej2 where alias='Machine Seated Hip Adduction'), 3, 12, 130, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_ej2 where alias='Machine Seated Calf Raise'), 1, 12, 45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_ej2 where alias='Machine Seated Calf Raise'), 2, 15, 45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_ej2 where alias='Machine Seated Calf Raise'), 3, 12, 45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_ej2 where alias='Machine Seated Calf Raise'), 4, 13, 45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Medicine Ball Slam with Squat Jump') limit 1),
            (select id from _ecm_ej2 where alias='Medicine Ball Slam with Squat Jump'), 1, 10, 6, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Pallof Press') limit 1),
            (select id from _ecm_ej2 where alias='Pallof Press'), 1, 20, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Pallof Press') limit 1),
            (select id from _ecm_ej2 where alias='Pallof Press'), 2, 15, 30, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Pallof Press') limit 1),
            (select id from _ecm_ej2 where alias='Pallof Press'), 3, 12, 40, 'kg');
  end if;

  -- Rutina 2: Pull Training
  insert into rutinas (user_id, cliente_id, fase_id, nombre, dia_orden,
                       duracion_estimada_min, tipo_sesion, dias_semana)
  values (v_coach, v_cli, v_fase, 'Pull Training', 2, 60, 'fuerza', array['X','S']::text[])
  returning id into v_rut;
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Running'), 1, 1, '2-3 min intensidad moderada', null);
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'A', 'circuito', 2, 30, 1)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Mini Band Standing I''s'), 2, 1, '8', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Mini Band Wall Slides'), 3, 1, '8', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Bar Hang'), 4, 1, '80 s', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Muscle Up'), 5, 3, '4-6', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Plate Weighted Wide Grip Pull Up'), 6, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Cable Seated Close Grip Row'), 7, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='EZ Bar Preacher Curl'), 8, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Dumbbell Hammer Curl'), 9, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Dumbbell Incline Bicep Curl'), 10, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Dumbbell Shrug'), 11, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Cable Rope Face Pull'), 12, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Suspension Low Back Stretch'), 13, 1, '30 s', null);
  -- historial 2026-09-19
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach, origen)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-19', 2,
          '2026-W38', 'completada', '2026-09-19 12:00:00+00'::timestamptz, true, 'importada')
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Mini Band Standing I''s') limit 1),
            (select id from _ecm_ej2 where alias='Mini Band Standing I''s'), 1, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Mini Band Standing I''s') limit 1),
            (select id from _ecm_ej2 where alias='Mini Band Standing I''s'), 2, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Mini Band Wall Slides') limit 1),
            (select id from _ecm_ej2 where alias='Mini Band Wall Slides'), 1, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Mini Band Wall Slides') limit 1),
            (select id from _ecm_ej2 where alias='Mini Band Wall Slides'), 2, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Bar Hang') limit 1),
            (select id from _ecm_ej2 where alias='Bar Hang'), 1, 80, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Seated Close Grip Row') limit 1),
            (select id from _ecm_ej2 where alias='Cable Seated Close Grip Row'), 1, 10, 100, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Seated Close Grip Row') limit 1),
            (select id from _ecm_ej2 where alias='Cable Seated Close Grip Row'), 2, 10, 100, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Seated Close Grip Row') limit 1),
            (select id from _ecm_ej2 where alias='Cable Seated Close Grip Row'), 3, 10, 100, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Seated Close Grip Row') limit 1),
            (select id from _ecm_ej2 where alias='Cable Seated Close Grip Row'), 4, 10, 100, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='EZ Bar Preacher Curl') limit 1),
            (select id from _ecm_ej2 where alias='EZ Bar Preacher Curl'), 1, 10, 60, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='EZ Bar Preacher Curl') limit 1),
            (select id from _ecm_ej2 where alias='EZ Bar Preacher Curl'), 2, 9, 60, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='EZ Bar Preacher Curl') limit 1),
            (select id from _ecm_ej2 where alias='EZ Bar Preacher Curl'), 3, 8, 60, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='EZ Bar Preacher Curl') limit 1),
            (select id from _ecm_ej2 where alias='EZ Bar Preacher Curl'), 4, 6, 60, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Hammer Curl'), 1, 12, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Hammer Curl'), 2, 7, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Hammer Curl'), 3, 6, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Hammer Curl'), 4, 6, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Rope Face Pull') limit 1),
            (select id from _ecm_ej2 where alias='Cable Rope Face Pull'), 1, 15, 90, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Rope Face Pull') limit 1),
            (select id from _ecm_ej2 where alias='Cable Rope Face Pull'), 2, 15, 90, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Rope Face Pull') limit 1),
            (select id from _ecm_ej2 where alias='Cable Rope Face Pull'), 3, 14, 100, 'kg');
  end if;
  -- historial 2026-09-16
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach, origen)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-16', 2,
          '2026-W38', 'completada', '2026-09-16 12:00:00+00'::timestamptz, true, 'importada')
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Mini Band Standing I''s') limit 1),
            (select id from _ecm_ej2 where alias='Mini Band Standing I''s'), 1, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Mini Band Standing I''s') limit 1),
            (select id from _ecm_ej2 where alias='Mini Band Standing I''s'), 2, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Mini Band Wall Slides') limit 1),
            (select id from _ecm_ej2 where alias='Mini Band Wall Slides'), 1, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Mini Band Wall Slides') limit 1),
            (select id from _ecm_ej2 where alias='Mini Band Wall Slides'), 2, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Bar Hang') limit 1),
            (select id from _ecm_ej2 where alias='Bar Hang'), 1, 80, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Plate Weighted Wide Grip Pull Up') limit 1),
            (select id from _ecm_ej2 where alias='Plate Weighted Wide Grip Pull Up'), 1, 9, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Plate Weighted Wide Grip Pull Up') limit 1),
            (select id from _ecm_ej2 where alias='Plate Weighted Wide Grip Pull Up'), 2, 8, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Plate Weighted Wide Grip Pull Up') limit 1),
            (select id from _ecm_ej2 where alias='Plate Weighted Wide Grip Pull Up'), 3, 8, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Plate Weighted Wide Grip Pull Up') limit 1),
            (select id from _ecm_ej2 where alias='Plate Weighted Wide Grip Pull Up'), 4, 8, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Seated Close Grip Row') limit 1),
            (select id from _ecm_ej2 where alias='Cable Seated Close Grip Row'), 1, 12, 100, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Seated Close Grip Row') limit 1),
            (select id from _ecm_ej2 where alias='Cable Seated Close Grip Row'), 2, 12, 115, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Seated Close Grip Row') limit 1),
            (select id from _ecm_ej2 where alias='Cable Seated Close Grip Row'), 3, 10, 130, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Seated Close Grip Row') limit 1),
            (select id from _ecm_ej2 where alias='Cable Seated Close Grip Row'), 4, 8, 145, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='EZ Bar Preacher Curl') limit 1),
            (select id from _ecm_ej2 where alias='EZ Bar Preacher Curl'), 1, 12, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='EZ Bar Preacher Curl') limit 1),
            (select id from _ecm_ej2 where alias='EZ Bar Preacher Curl'), 2, 12, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='EZ Bar Preacher Curl') limit 1),
            (select id from _ecm_ej2 where alias='EZ Bar Preacher Curl'), 3, 9, 60, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='EZ Bar Preacher Curl') limit 1),
            (select id from _ecm_ej2 where alias='EZ Bar Preacher Curl'), 4, 7, 60, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Hammer Curl'), 1, 12, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Hammer Curl'), 2, 11, 30, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Hammer Curl'), 3, 8, 35, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Hammer Curl'), 4, 6, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Incline Bicep Curl') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Incline Bicep Curl'), 1, 10, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Incline Bicep Curl') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Incline Bicep Curl'), 2, 12, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Incline Bicep Curl') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Incline Bicep Curl'), 3, 8, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Shrug') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Shrug'), 1, 15, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Shrug') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Shrug'), 2, 15, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Shrug') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Shrug'), 3, 15, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Rope Face Pull') limit 1),
            (select id from _ecm_ej2 where alias='Cable Rope Face Pull'), 1, 15, 90, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Rope Face Pull') limit 1),
            (select id from _ecm_ej2 where alias='Cable Rope Face Pull'), 2, 12, 90, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Rope Face Pull') limit 1),
            (select id from _ecm_ej2 where alias='Cable Rope Face Pull'), 3, 14, 100, 'kg');
  end if;
  -- historial 2026-09-09
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach, origen)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-09', 1,
          '2026-W37', 'completada', '2026-09-09 12:00:00+00'::timestamptz, true, 'importada')
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Mini Band Standing I''s') limit 1),
            (select id from _ecm_ej2 where alias='Mini Band Standing I''s'), 1, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Mini Band Standing I''s') limit 1),
            (select id from _ecm_ej2 where alias='Mini Band Standing I''s'), 2, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Mini Band Wall Slides') limit 1),
            (select id from _ecm_ej2 where alias='Mini Band Wall Slides'), 1, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Mini Band Wall Slides') limit 1),
            (select id from _ecm_ej2 where alias='Mini Band Wall Slides'), 2, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Bar Hang') limit 1),
            (select id from _ecm_ej2 where alias='Bar Hang'), 1, 60, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Plate Weighted Wide Grip Pull Up') limit 1),
            (select id from _ecm_ej2 where alias='Plate Weighted Wide Grip Pull Up'), 1, 6, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Plate Weighted Wide Grip Pull Up') limit 1),
            (select id from _ecm_ej2 where alias='Plate Weighted Wide Grip Pull Up'), 2, 7, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Plate Weighted Wide Grip Pull Up') limit 1),
            (select id from _ecm_ej2 where alias='Plate Weighted Wide Grip Pull Up'), 3, 6, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Seated Close Grip Row') limit 1),
            (select id from _ecm_ej2 where alias='Cable Seated Close Grip Row'), 1, 12, 100, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Seated Close Grip Row') limit 1),
            (select id from _ecm_ej2 where alias='Cable Seated Close Grip Row'), 2, 12, 115, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Seated Close Grip Row') limit 1),
            (select id from _ecm_ej2 where alias='Cable Seated Close Grip Row'), 3, 10, 130, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Seated Close Grip Row') limit 1),
            (select id from _ecm_ej2 where alias='Cable Seated Close Grip Row'), 4, 8, 145, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='EZ Bar Preacher Curl') limit 1),
            (select id from _ecm_ej2 where alias='EZ Bar Preacher Curl'), 1, 12, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='EZ Bar Preacher Curl') limit 1),
            (select id from _ecm_ej2 where alias='EZ Bar Preacher Curl'), 2, 12, 60, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='EZ Bar Preacher Curl') limit 1),
            (select id from _ecm_ej2 where alias='EZ Bar Preacher Curl'), 3, 8, 60, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Hammer Curl'), 1, 12, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Hammer Curl'), 2, 11, 30, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Hammer Curl'), 3, 9, 35, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Hammer Curl'), 4, 6, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Incline Bicep Curl') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Incline Bicep Curl'), 1, 10, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Incline Bicep Curl') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Incline Bicep Curl'), 2, 10, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Incline Bicep Curl') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Incline Bicep Curl'), 3, 6, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Shrug') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Shrug'), 1, 15, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Shrug') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Shrug'), 2, 15, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Shrug') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Shrug'), 3, 15, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Rope Face Pull') limit 1),
            (select id from _ecm_ej2 where alias='Cable Rope Face Pull'), 1, 15, 90, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Rope Face Pull') limit 1),
            (select id from _ecm_ej2 where alias='Cable Rope Face Pull'), 2, 15, 90, 'kg');
  end if;

  -- Rutina 3: Push Training
  insert into rutinas (user_id, cliente_id, fase_id, nombre, dia_orden,
                       duracion_estimada_min, tipo_sesion, dias_semana)
  values (v_coach, v_cli, v_fase, 'Push Training', 3, 61, 'fuerza', array['M','V']::text[])
  returning id into v_rut;
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Running'), 1, 1, 'Caminadora: 3 min intensidad moderada', null);
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'A', 'circuito', 2, 35, 1)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Kettlebell Alternating Halo with Chest Press'), 2, 1, '8-10', 35);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Kick Throughs'), 3, 1, '6-8 por lado', 35);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Downward Dog to Scorpion'), 4, 1, '6-8 por lado', 35);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Chest to wall handstand'), 5, 3, '10-15 s', 40);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Dumbbell Burpee Clean to Press'), 6, 2, '8-15', 40);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Dumbbell Incline Bench Press'), 7, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Landmine Rotational Clean and Press'), 8, 4, '6-12 por lado', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Plate Weighted Dip'), 9, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Cable Standing Crossover Chest Fly'), 10, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Machine Lateral Raise'), 11, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Cable V Bar Tricep Pushdown'), 12, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Child''s Pose'), 13, 1, '30 s', null);
  -- historial 2026-09-15
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach, origen)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-15', 2,
          '2026-W38', 'completada', '2026-09-15 12:00:00+00'::timestamptz, true, 'importada')
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Kettlebell Alternating Halo with Chest Press') limit 1),
            (select id from _ecm_ej2 where alias='Kettlebell Alternating Halo with Chest Press'), 1, 10, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Kettlebell Alternating Halo with Chest Press') limit 1),
            (select id from _ecm_ej2 where alias='Kettlebell Alternating Halo with Chest Press'), 2, 10, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Burpee Clean to Press') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Burpee Clean to Press'), 1, 15, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Burpee Clean to Press') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Burpee Clean to Press'), 2, 15, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Incline Bench Press'), 1, 12, 55, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Incline Bench Press'), 2, 10, 60, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Incline Bench Press'), 3, 9, 60, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Incline Bench Press'), 4, 6, 60, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Landmine Rotational Clean and Press') limit 1),
            (select id from _ecm_ej2 where alias='Landmine Rotational Clean and Press'), 1, 12, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Landmine Rotational Clean and Press') limit 1),
            (select id from _ecm_ej2 where alias='Landmine Rotational Clean and Press'), 2, 15, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Landmine Rotational Clean and Press') limit 1),
            (select id from _ecm_ej2 where alias='Landmine Rotational Clean and Press'), 3, 10, 30, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Landmine Rotational Clean and Press') limit 1),
            (select id from _ecm_ej2 where alias='Landmine Rotational Clean and Press'), 4, 10, 30, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Standing Crossover Chest Fly') limit 1),
            (select id from _ecm_ej2 where alias='Cable Standing Crossover Chest Fly'), 1, 15, 30, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Standing Crossover Chest Fly') limit 1),
            (select id from _ecm_ej2 where alias='Cable Standing Crossover Chest Fly'), 2, 15, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Standing Crossover Chest Fly') limit 1),
            (select id from _ecm_ej2 where alias='Cable Standing Crossover Chest Fly'), 3, 12, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Standing Crossover Chest Fly') limit 1),
            (select id from _ecm_ej2 where alias='Cable Standing Crossover Chest Fly'), 4, 10, 60, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Lateral Raise') limit 1),
            (select id from _ecm_ej2 where alias='Machine Lateral Raise'), 1, 12, 55, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Lateral Raise') limit 1),
            (select id from _ecm_ej2 where alias='Machine Lateral Raise'), 2, 12, 60, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Lateral Raise') limit 1),
            (select id from _ecm_ej2 where alias='Machine Lateral Raise'), 3, 11, 65, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Lateral Raise') limit 1),
            (select id from _ecm_ej2 where alias='Machine Lateral Raise'), 4, 10, 70, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej2 where alias='Cable V Bar Tricep Pushdown'), 1, 20, 90, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej2 where alias='Cable V Bar Tricep Pushdown'), 2, 20, 100, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej2 where alias='Cable V Bar Tricep Pushdown'), 3, 15, 110, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej2 where alias='Cable V Bar Tricep Pushdown'), 4, 14, 120, 'kg');
  end if;
  -- historial 2026-09-11
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach, origen)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-11', 1,
          '2026-W37', 'completada', '2026-09-11 12:00:00+00'::timestamptz, true, 'importada')
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Kettlebell Alternating Halo with Chest Press') limit 1),
            (select id from _ecm_ej2 where alias='Kettlebell Alternating Halo with Chest Press'), 1, 10, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Kettlebell Alternating Halo with Chest Press') limit 1),
            (select id from _ecm_ej2 where alias='Kettlebell Alternating Halo with Chest Press'), 2, 10, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Burpee Clean to Press') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Burpee Clean to Press'), 1, 12, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Burpee Clean to Press') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Burpee Clean to Press'), 2, 15, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Incline Bench Press'), 1, 15, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Incline Bench Press'), 2, 10, 60, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Incline Bench Press'), 3, 7, 60, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Incline Bench Press'), 4, 7, 60, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Landmine Rotational Clean and Press') limit 1),
            (select id from _ecm_ej2 where alias='Landmine Rotational Clean and Press'), 1, 8, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Landmine Rotational Clean and Press') limit 1),
            (select id from _ecm_ej2 where alias='Landmine Rotational Clean and Press'), 2, 10, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Landmine Rotational Clean and Press') limit 1),
            (select id from _ecm_ej2 where alias='Landmine Rotational Clean and Press'), 3, 12, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Landmine Rotational Clean and Press') limit 1),
            (select id from _ecm_ej2 where alias='Landmine Rotational Clean and Press'), 4, 12, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Standing Crossover Chest Fly') limit 1),
            (select id from _ecm_ej2 where alias='Cable Standing Crossover Chest Fly'), 1, 15, 30, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Standing Crossover Chest Fly') limit 1),
            (select id from _ecm_ej2 where alias='Cable Standing Crossover Chest Fly'), 2, 15, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Standing Crossover Chest Fly') limit 1),
            (select id from _ecm_ej2 where alias='Cable Standing Crossover Chest Fly'), 3, 12, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Standing Crossover Chest Fly') limit 1),
            (select id from _ecm_ej2 where alias='Cable Standing Crossover Chest Fly'), 4, 10, 60, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Lateral Raise') limit 1),
            (select id from _ecm_ej2 where alias='Machine Lateral Raise'), 1, 15, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Lateral Raise') limit 1),
            (select id from _ecm_ej2 where alias='Machine Lateral Raise'), 2, 12, 55, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Lateral Raise') limit 1),
            (select id from _ecm_ej2 where alias='Machine Lateral Raise'), 3, 10, 60, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Lateral Raise') limit 1),
            (select id from _ecm_ej2 where alias='Machine Lateral Raise'), 4, 10, 65, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej2 where alias='Cable V Bar Tricep Pushdown'), 1, 20, 90, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej2 where alias='Cable V Bar Tricep Pushdown'), 2, 15, 100, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej2 where alias='Cable V Bar Tricep Pushdown'), 3, 15, 110, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej2 where alias='Cable V Bar Tricep Pushdown'), 4, 12, 120, 'kg');
  end if;
  -- historial 2026-09-08
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach, origen)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-08', 1,
          '2026-W37', 'completada', '2026-09-08 12:00:00+00'::timestamptz, true, 'importada')
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Kettlebell Alternating Halo with Chest Press') limit 1),
            (select id from _ecm_ej2 where alias='Kettlebell Alternating Halo with Chest Press'), 1, 10, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Kettlebell Alternating Halo with Chest Press') limit 1),
            (select id from _ecm_ej2 where alias='Kettlebell Alternating Halo with Chest Press'), 2, 10, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Kettlebell Alternating Halo with Chest Press') limit 1),
            (select id from _ecm_ej2 where alias='Kettlebell Alternating Halo with Chest Press'), 3, 10, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Clapping Push Up') limit 1),
            (select id from _ecm_ej2 where alias='Clapping Push Up'), 1, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Clapping Push Up') limit 1),
            (select id from _ecm_ej2 where alias='Clapping Push Up'), 2, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Clapping Push Up') limit 1),
            (select id from _ecm_ej2 where alias='Clapping Push Up'), 3, 14, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Smith Machine Incline Bench Press') limit 1),
            (select id from _ecm_ej2 where alias='Smith Machine Incline Bench Press'), 1, 10, 45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Smith Machine Incline Bench Press') limit 1),
            (select id from _ecm_ej2 where alias='Smith Machine Incline Bench Press'), 2, 8, 45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Smith Machine Incline Bench Press') limit 1),
            (select id from _ecm_ej2 where alias='Smith Machine Incline Bench Press'), 3, 8, 45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Smith Machine Incline Bench Press') limit 1),
            (select id from _ecm_ej2 where alias='Smith Machine Incline Bench Press'), 4, 7, 45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Smith Machine Seated Shoulder Press') limit 1),
            (select id from _ecm_ej2 where alias='Smith Machine Seated Shoulder Press'), 1, 12, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Smith Machine Seated Shoulder Press') limit 1),
            (select id from _ecm_ej2 where alias='Smith Machine Seated Shoulder Press'), 2, 9, 30, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Smith Machine Seated Shoulder Press') limit 1),
            (select id from _ecm_ej2 where alias='Smith Machine Seated Shoulder Press'), 3, 5, 35, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Smith Machine Seated Shoulder Press') limit 1),
            (select id from _ecm_ej2 where alias='Smith Machine Seated Shoulder Press'), 4, 6, 30, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Smith Machine Bench Press') limit 1),
            (select id from _ecm_ej2 where alias='Smith Machine Bench Press'), 1, 10, 45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Smith Machine Bench Press') limit 1),
            (select id from _ecm_ej2 where alias='Smith Machine Bench Press'), 2, 7, 55, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Smith Machine Bench Press') limit 1),
            (select id from _ecm_ej2 where alias='Smith Machine Bench Press'), 3, 6, 60, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Seated Chest Fly') limit 1),
            (select id from _ecm_ej2 where alias='Machine Seated Chest Fly'), 1, 12, 145, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Seated Chest Fly') limit 1),
            (select id from _ecm_ej2 where alias='Machine Seated Chest Fly'), 2, 10, 150, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Seated Chest Fly') limit 1),
            (select id from _ecm_ej2 where alias='Machine Seated Chest Fly'), 3, 8, 155, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Seated Chest Fly') limit 1),
            (select id from _ecm_ej2 where alias='Machine Seated Chest Fly'), 4, 6, 160, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Seated Dumbbell Front Raise to Lateral Raise') limit 1),
            (select id from _ecm_ej2 where alias='Seated Dumbbell Front Raise to Lateral Raise'), 1, 10, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Seated Dumbbell Front Raise to Lateral Raise') limit 1),
            (select id from _ecm_ej2 where alias='Seated Dumbbell Front Raise to Lateral Raise'), 2, 10, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Seated Dumbbell Front Raise to Lateral Raise') limit 1),
            (select id from _ecm_ej2 where alias='Seated Dumbbell Front Raise to Lateral Raise'), 3, 10, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Seated Dumbbell Front Raise to Lateral Raise') limit 1),
            (select id from _ecm_ej2 where alias='Seated Dumbbell Front Raise to Lateral Raise'), 4, 10, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Tricep Kickback') limit 1),
            (select id from _ecm_ej2 where alias='Cable Tricep Kickback'), 1, 20, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Tricep Kickback') limit 1),
            (select id from _ecm_ej2 where alias='Cable Tricep Kickback'), 2, 15, 30, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Tricep Kickback') limit 1),
            (select id from _ecm_ej2 where alias='Cable Tricep Kickback'), 3, 10, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Tricep Kickback') limit 1),
            (select id from _ecm_ej2 where alias='Cable Tricep Kickback'), 4, 10, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable V-Bar Overhead Tricep Extension') limit 1),
            (select id from _ecm_ej2 where alias='Cable V-Bar Overhead Tricep Extension'), 1, 10, 90, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable V-Bar Overhead Tricep Extension') limit 1),
            (select id from _ecm_ej2 where alias='Cable V-Bar Overhead Tricep Extension'), 2, 10, 90, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable V-Bar Overhead Tricep Extension') limit 1),
            (select id from _ecm_ej2 where alias='Cable V-Bar Overhead Tricep Extension'), 3, 10, 100, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable V-Bar Overhead Tricep Extension') limit 1),
            (select id from _ecm_ej2 where alias='Cable V-Bar Overhead Tricep Extension'), 4, 10, 100, 'kg');
  end if;
  raise notice 'OK: «Juan Sinisterra» · Cycle 4 · 3 rutinas.';
end $cli$;

-- ─────────────────────────────────────────────────────────────────────
-- JULIO DIÉGUEZ · Cycle 12 · 5 semanas (2026-09-07 → 2026-10-11)
--   Plan de CALISTENIA: muscle up, handstand, dragon flag, pistol squat.
--   Casi todo peso corporal y bandas.
--   Ojo: 'Lateral Shuttle Run' aparece en el historial como '1 reps x 60
--   kg'. Son 60 SEGUNDOS, no 60 kg — Trainerize lo guardó en la columna
--   equivocada. Lo cargo como 60 s.
-- ─────────────────────────────────────────────────────────────────────
do $cli$
declare v_coach uuid; v_cli uuid; v_fase uuid; v_rut uuid; v_blo uuid; v_ses uuid;
begin
  select id, user_id into v_cli, v_coach from clientes where nombre ilike '%julio%di%guez%' limit 1;
  if v_cli is null then
    raise warning 'SALTADO: no encuentro a «Julio Diéguez» en `clientes` (patrón %%julio%%di%%guez%%). Corrige el nombre y vuelve a correr.';
    return;
  end if;
  if exists (select 1 from fases where cliente_id = v_cli and nombre = 'Cycle 12') then
    raise notice 'SALTADO: «Julio Diéguez» ya tiene la fase Cycle 12 cargada.';
    return;
  end if;

  insert into fases (user_id, cliente_id, nombre, objetivo, notas_coach, semanas,
                     fecha_inicio, orden, estado)
  values (v_coach, v_cli, 'Cycle 12',
          'Bloque importado de Trainerize — la rutina que ya venía haciendo.',
          'Importado el 2026-09-25 desde el PDF de Trainerize (Cycle 12, 2026-09-07 a 2026-10-11). Revisar antes de enviar al cliente. Ojo: ''Lateral Shuttle Run'' aparece en el historial como ''1 reps x 60 kg''. Son 60 SEGUNDOS, no 60 kg — Trainerize lo guardó en la columna equivocada. Lo cargo como 60 s.',
          5, date '2026-09-07',
          coalesce((select max(orden)+1 from fases where cliente_id = v_cli), 1), 'borrador')
  returning id into v_fase;

  -- Rutina 1: Full Body Training
  insert into rutinas (user_id, cliente_id, fase_id, nombre, dia_orden,
                       duracion_estimada_min, tipo_sesion, dias_semana)
  values (v_coach, v_cli, v_fase, 'Full Body Training', 1, 75, 'fuerza', '{}'::text[])
  returning id into v_rut;
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'A', 'circuito', 1, 30, 1)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Downward Dog to Scorpion'), 1, 1, '5 por lado', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Kick Throughs'), 2, 1, '5 por lado', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Lateral Shuttle Run'), 3, 1, '60 s', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Bar Hang'), 4, 1, '60 s', null);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Chest to wall handstand'), 5, 4, '10-15 s', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Muscle Up'), 6, 4, '4-6', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Wide Grip Pull Up'), 7, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Dip'), 8, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='SuperBand Push Up'), 9, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Elevated Pike Push-Up'), 10, 3, '6-10', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='SuperBand Anchored Pistol Squat to Row'), 11, 4, '6-12 por lado', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Band Deadlift'), 12, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Bench Single Leg Hip Thrust'), 13, 3, '6-12 por lado', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Dragon flag tuck eccentric'), 14, 3, '6-10', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Hollow Body Hold Flutter Kicks'), 15, 3, '15 s', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Child''s Pose'), 16, 1, '30 s', null);

  -- Rutina 2: Lower Body + Core Training
  insert into rutinas (user_id, cliente_id, fase_id, nombre, dia_orden,
                       duracion_estimada_min, tipo_sesion, dias_semana)
  values (v_coach, v_cli, v_fase, 'Lower Body + Core Training', 2, 60, 'fuerza', array['S','D']::text[])
  returning id into v_rut;
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'A', 'circuito', 1, 90, 1)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Bodyweight Cossack Squat'), 1, 1, '8 por lado', 90);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='90-90 Hip Switch'), 2, 1, '8 por lado', 90);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Bodyweight Squat To Hinge'), 3, 1, '8', 90);
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'B', 'circuito', 2, 30, 2)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='1/2 Kneel to Lateral Bound'), 4, 1, '8', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='1/2 Kneel to High Knee Hop'), 5, 1, '6 por lado', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Lateral Shuttle Run'), 6, 1, '60 s', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='SuperBand Anchored Pistol Squat to Row'), 7, 4, '6-10 por lado', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Superband Squat'), 8, 3, '8-15', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Band Deadlift'), 9, 4, '8-15', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Bench Single Leg Hip Thrust'), 10, 4, '6-8 por lado', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Bodyweight Single Leg Calf Raise'), 11, 4, '6-12 por lado', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Dragon flag tuck eccentric'), 12, 3, '6', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Hollow Body Hold Flutter Kicks'), 13, 3, '15 s', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Bench Twist Crunches'), 14, 3, '15', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Static Pigeon Stretch'), 15, 1, '30 s por lado', null);
  -- historial 2026-09-19
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach, origen)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-19', 2,
          '2026-W38', 'completada', '2026-09-19 12:00:00+00'::timestamptz, true, 'importada')
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Lateral Shuttle Run') limit 1),
            (select id from _ecm_ej2 where alias='Lateral Shuttle Run'), 1, 1, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='SuperBand Anchored Pistol Squat to Row') limit 1),
            (select id from _ecm_ej2 where alias='SuperBand Anchored Pistol Squat to Row'), 1, 10, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='SuperBand Anchored Pistol Squat to Row') limit 1),
            (select id from _ecm_ej2 where alias='SuperBand Anchored Pistol Squat to Row'), 2, 10, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='SuperBand Anchored Pistol Squat to Row') limit 1),
            (select id from _ecm_ej2 where alias='SuperBand Anchored Pistol Squat to Row'), 3, 10, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='SuperBand Anchored Pistol Squat to Row') limit 1),
            (select id from _ecm_ej2 where alias='SuperBand Anchored Pistol Squat to Row'), 4, 10, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Superband Squat') limit 1),
            (select id from _ecm_ej2 where alias='Superband Squat'), 1, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Superband Squat') limit 1),
            (select id from _ecm_ej2 where alias='Superband Squat'), 2, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Superband Squat') limit 1),
            (select id from _ecm_ej2 where alias='Superband Squat'), 3, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Band Deadlift') limit 1),
            (select id from _ecm_ej2 where alias='Band Deadlift'), 1, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Band Deadlift') limit 1),
            (select id from _ecm_ej2 where alias='Band Deadlift'), 2, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Band Deadlift') limit 1),
            (select id from _ecm_ej2 where alias='Band Deadlift'), 3, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Band Deadlift') limit 1),
            (select id from _ecm_ej2 where alias='Band Deadlift'), 4, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Hollow Body Hold Flutter Kicks') limit 1),
            (select id from _ecm_ej2 where alias='Hollow Body Hold Flutter Kicks'), 1, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Hollow Body Hold Flutter Kicks') limit 1),
            (select id from _ecm_ej2 where alias='Hollow Body Hold Flutter Kicks'), 2, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Hollow Body Hold Flutter Kicks') limit 1),
            (select id from _ecm_ej2 where alias='Hollow Body Hold Flutter Kicks'), 3, 15, null, 'kg');
  end if;
  -- historial 2026-09-13
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach, origen)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-13', 1,
          '2026-W37', 'completada', '2026-09-13 12:00:00+00'::timestamptz, true, 'importada')
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Lateral Shuttle Run') limit 1),
            (select id from _ecm_ej2 where alias='Lateral Shuttle Run'), 1, 1, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='SuperBand Anchored Pistol Squat to Row') limit 1),
            (select id from _ecm_ej2 where alias='SuperBand Anchored Pistol Squat to Row'), 1, 10, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='SuperBand Anchored Pistol Squat to Row') limit 1),
            (select id from _ecm_ej2 where alias='SuperBand Anchored Pistol Squat to Row'), 2, 10, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='SuperBand Anchored Pistol Squat to Row') limit 1),
            (select id from _ecm_ej2 where alias='SuperBand Anchored Pistol Squat to Row'), 3, 10, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='SuperBand Anchored Pistol Squat to Row') limit 1),
            (select id from _ecm_ej2 where alias='SuperBand Anchored Pistol Squat to Row'), 4, 10, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Superband Squat') limit 1),
            (select id from _ecm_ej2 where alias='Superband Squat'), 1, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Superband Squat') limit 1),
            (select id from _ecm_ej2 where alias='Superband Squat'), 2, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Superband Squat') limit 1),
            (select id from _ecm_ej2 where alias='Superband Squat'), 3, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Band Deadlift') limit 1),
            (select id from _ecm_ej2 where alias='Band Deadlift'), 1, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Band Deadlift') limit 1),
            (select id from _ecm_ej2 where alias='Band Deadlift'), 2, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Band Deadlift') limit 1),
            (select id from _ecm_ej2 where alias='Band Deadlift'), 3, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Band Deadlift') limit 1),
            (select id from _ecm_ej2 where alias='Band Deadlift'), 4, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Hollow Body Hold Flutter Kicks') limit 1),
            (select id from _ecm_ej2 where alias='Hollow Body Hold Flutter Kicks'), 1, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Hollow Body Hold Flutter Kicks') limit 1),
            (select id from _ecm_ej2 where alias='Hollow Body Hold Flutter Kicks'), 2, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Hollow Body Hold Flutter Kicks') limit 1),
            (select id from _ecm_ej2 where alias='Hollow Body Hold Flutter Kicks'), 3, 15, null, 'kg');
  end if;

  -- Rutina 3: Upper Body Training
  insert into rutinas (user_id, cliente_id, fase_id, nombre, dia_orden,
                       duracion_estimada_min, tipo_sesion, dias_semana)
  values (v_coach, v_cli, v_fase, 'Upper Body Training', 3, 68, 'fuerza', array['X','J']::text[])
  returning id into v_rut;
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'A', 'circuito', 1, 30, 1)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Downward Dog to Scorpion'), 1, 1, '6 por lado', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Kick Throughs'), 2, 1, '10', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Mini Band Bent Over Y''s'), 3, 1, '6', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Mini Band Bent Arm Pull Apart'), 4, 1, '6', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Bar Hang'), 5, 1, '60 s', 30);
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'B', 'circuito', 2, 40, 2)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Burpee'), 6, 1, '8-10', 40);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Lateral Shuttle Run'), 7, 1, '60 s', 40);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Chest to wall handstand'), 8, 4, '10-15 s', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Muscle Up'), 9, 4, '4-6', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Wide Grip Pull Up'), 10, 3, '8-15', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Dip'), 11, 4, '8-15', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Elevated Pike Push-Up'), 12, 4, '6-10', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='SuperBand Push Up'), 13, 4, '8-15', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Band Anchored Single Arm Incline Curl'), 14, 4, '8-15 por lado', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='SuperBand Anchored Tricep Pushdown'), 15, 4, '8-15 por lado', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Child''s Pose'), 16, 1, '30 s', null);
  -- historial 2026-09-17
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach, origen)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-17', 2,
          '2026-W38', 'completada', '2026-09-17 12:00:00+00'::timestamptz, true, 'importada')
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Bar Hang') limit 1),
            (select id from _ecm_ej2 where alias='Bar Hang'), 1, 60, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Lateral Shuttle Run') limit 1),
            (select id from _ecm_ej2 where alias='Lateral Shuttle Run'), 1, 1, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dip') limit 1),
            (select id from _ecm_ej2 where alias='Dip'), 1, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dip') limit 1),
            (select id from _ecm_ej2 where alias='Dip'), 2, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dip') limit 1),
            (select id from _ecm_ej2 where alias='Dip'), 3, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dip') limit 1),
            (select id from _ecm_ej2 where alias='Dip'), 4, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='SuperBand Push Up') limit 1),
            (select id from _ecm_ej2 where alias='SuperBand Push Up'), 1, 10, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='SuperBand Push Up') limit 1),
            (select id from _ecm_ej2 where alias='SuperBand Push Up'), 2, 10, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='SuperBand Push Up') limit 1),
            (select id from _ecm_ej2 where alias='SuperBand Push Up'), 3, 10, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='SuperBand Push Up') limit 1),
            (select id from _ecm_ej2 where alias='SuperBand Push Up'), 4, 10, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Band Anchored Single Arm Incline Curl') limit 1),
            (select id from _ecm_ej2 where alias='Band Anchored Single Arm Incline Curl'), 1, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Band Anchored Single Arm Incline Curl') limit 1),
            (select id from _ecm_ej2 where alias='Band Anchored Single Arm Incline Curl'), 2, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Band Anchored Single Arm Incline Curl') limit 1),
            (select id from _ecm_ej2 where alias='Band Anchored Single Arm Incline Curl'), 3, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Band Anchored Single Arm Incline Curl') limit 1),
            (select id from _ecm_ej2 where alias='Band Anchored Single Arm Incline Curl'), 4, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='SuperBand Anchored Tricep Pushdown') limit 1),
            (select id from _ecm_ej2 where alias='SuperBand Anchored Tricep Pushdown'), 1, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='SuperBand Anchored Tricep Pushdown') limit 1),
            (select id from _ecm_ej2 where alias='SuperBand Anchored Tricep Pushdown'), 2, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='SuperBand Anchored Tricep Pushdown') limit 1),
            (select id from _ecm_ej2 where alias='SuperBand Anchored Tricep Pushdown'), 3, 12, null, 'kg');
  end if;
  -- historial 2026-09-09
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach, origen)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-09', 1,
          '2026-W37', 'completada', '2026-09-09 12:00:00+00'::timestamptz, true, 'importada')
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Bar Hang') limit 1),
            (select id from _ecm_ej2 where alias='Bar Hang'), 1, 60, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dip') limit 1),
            (select id from _ecm_ej2 where alias='Dip'), 1, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dip') limit 1),
            (select id from _ecm_ej2 where alias='Dip'), 2, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dip') limit 1),
            (select id from _ecm_ej2 where alias='Dip'), 3, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dip') limit 1),
            (select id from _ecm_ej2 where alias='Dip'), 4, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='SuperBand Anchored Tricep Pushdown') limit 1),
            (select id from _ecm_ej2 where alias='SuperBand Anchored Tricep Pushdown'), 1, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='SuperBand Anchored Tricep Pushdown') limit 1),
            (select id from _ecm_ej2 where alias='SuperBand Anchored Tricep Pushdown'), 2, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='SuperBand Anchored Tricep Pushdown') limit 1),
            (select id from _ecm_ej2 where alias='SuperBand Anchored Tricep Pushdown'), 3, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Spiderman Push Up') limit 1),
            (select id from _ecm_ej2 where alias='Spiderman Push Up'), 1, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Spiderman Push Up') limit 1),
            (select id from _ecm_ej2 where alias='Spiderman Push Up'), 2, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Spiderman Push Up') limit 1),
            (select id from _ecm_ej2 where alias='Spiderman Push Up'), 3, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Spiderman Push Up') limit 1),
            (select id from _ecm_ej2 where alias='Spiderman Push Up'), 4, 15, null, 'kg');
  end if;
  raise notice 'OK: «Julio Diéguez» · Cycle 12 · 3 rutinas.';
end $cli$;

-- ─────────────────────────────────────────────────────────────────────
-- MARÍA ALEJANDRA GONZÁLEZ SIERRA · Cycle 4 · 5 semanas (2026-09-14 → 2026-10-18)
--   Sin historial: la fase arrancó el 14 sep y el PDF es del 20 sep,
--   pero no registró ninguna sesión. Los días los pones tú.
--   El PDF dice 'GONZALEZ SIERRA' (con Z) pero tu lista de clientes
--   autorizados dice 'Maria Alejandra Gonzales' (con S). El patrón se
--   corta en 'gonz' para que la encuentre esté como esté escrita.
-- ─────────────────────────────────────────────────────────────────────
do $cli$
declare v_coach uuid; v_cli uuid; v_fase uuid; v_rut uuid; v_blo uuid; v_ses uuid;
begin
  select id, user_id into v_cli, v_coach from clientes where nombre ilike '%alejandra%gonz%' limit 1;
  if v_cli is null then
    raise warning 'SALTADO: no encuentro a «María Alejandra González Sierra» en `clientes` (patrón %%alejandra%%gonz%%). Corrige el nombre y vuelve a correr.';
    return;
  end if;
  if exists (select 1 from fases where cliente_id = v_cli and nombre = 'Cycle 4') then
    raise notice 'SALTADO: «María Alejandra González Sierra» ya tiene la fase Cycle 4 cargada.';
    return;
  end if;

  insert into fases (user_id, cliente_id, nombre, objetivo, notas_coach, semanas,
                     fecha_inicio, orden, estado)
  values (v_coach, v_cli, 'Cycle 4',
          'Bloque importado de Trainerize — la rutina que ya venía haciendo.',
          'Importado el 2026-09-25 desde el PDF de Trainerize (Cycle 4, 2026-09-14 a 2026-10-18). Revisar antes de enviar al cliente.',
          5, date '2026-09-14',
          coalesce((select max(orden)+1 from fases where cliente_id = v_cli), 1), 'borrador')
  returning id into v_fase;

  -- Rutina 1: Full Body Training
  insert into rutinas (user_id, cliente_id, fase_id, nombre, dia_orden,
                       duracion_estimada_min, tipo_sesion, dias_semana)
  values (v_coach, v_cli, v_fase, 'Full Body Training', 1, 61, 'fuerza', '{}'::text[])
  returning id into v_rut;
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'A', 'circuito', 2, 30, 1)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Bodyweight Squat To Hinge'), 1, 1, '5', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Table Top Full Arm Thoracic Rotation'), 2, 1, '5 por lado', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Mini Band Standing I''s'), 3, 1, '5', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Burpee Broad Jump'), 4, 1, '8-15 saltos', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Dumbbell Walking Lunge'), 5, 4, '6-12 por lado', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Dumbbell Glute Bridge Chest Press'), 6, 4, '8-15', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Dumbbell Single Arm Row'), 7, 4, '8-15', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Burpee Broad Jump'), 8, 1, '8-15 saltos', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Seated Dumbbell Front Raise to Lateral Raise'), 9, 4, '8-15', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Dumbbell Bicep Curl'), 10, 4, '8-15', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Dumbbell Laying Tricep Extension to Press'), 11, 4, '8-15', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Bench V Sit Leg Raise'), 12, 4, '8-15', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Burpee Broad Jump'), 13, 1, '8-15 saltos', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Child''s Pose'), 14, 1, '30 s', null);

  -- Rutina 2: Lower Body + Core Training
  insert into rutinas (user_id, cliente_id, fase_id, nombre, dia_orden,
                       duracion_estimada_min, tipo_sesion, dias_semana)
  values (v_coach, v_cli, v_fase, 'Lower Body + Core Training', 2, 67, 'fuerza', '{}'::text[])
  returning id into v_rut;
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'A', 'circuito', 2, 30, 1)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Glute Side Circle'), 1, 1, '5 por lado', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Bodyweight Squat To Hinge'), 2, 1, '5', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Bodyweight Cossack Squat'), 3, 1, '5 por lado', 30);
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'B', 'circuito', 2, 45, 2)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Squat to Squat Jump'), 4, 1, '8-12', 45);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Lateral Shuttle Run'), 5, 1, '60 s', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Dumbbell Walking Lunge'), 6, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Dumbbell Hip Thrust'), 7, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Dumbbell Sumo Deadlift'), 8, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Lying Hip Abductions'), 9, 4, '6-12 por lado', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Bodyweight Single Leg Calf Raise'), 10, 4, '6-12 por lado', 50);
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'C', 'circuito', 4, 45, 3)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Bench V Sit Leg Raise'), 11, 1, '15', 10);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Pilates - Oblique Twists with Ball'), 12, 1, '15', 10);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Bench Side Plank Hip Dip'), 13, 1, '15', 10);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Static Pigeon Stretch'), 14, 1, '30 s por lado', null);

  -- Rutina 3: Scapular Mobility Flow
  insert into rutinas (user_id, cliente_id, fase_id, nombre, dia_orden,
                       duracion_estimada_min, tipo_sesion, dias_semana)
  values (v_coach, v_cli, v_fase, 'Scapular Mobility Flow', 3, 11, 'fuerza', '{}'::text[])
  returning id into v_rut;
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'A', 'circuito', 2, 50, 1)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Mini Band Standing I''s'), 1, 1, '5-8', 10);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Pilates - Swan'), 2, 1, '5-8', 10);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Mini Band Wall Slides'), 3, 1, '5-8', 10);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Scapular Pushups from Elbows'), 4, 1, '5-8', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Child''s Pose'), 5, 1, '45 s', null);

  -- Rutina 4: Upper Body Training
  insert into rutinas (user_id, cliente_id, fase_id, nombre, dia_orden,
                       duracion_estimada_min, tipo_sesion, dias_semana)
  values (v_coach, v_cli, v_fase, 'Upper Body Training', 4, 54, 'fuerza', '{}'::text[])
  returning id into v_rut;
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'A', 'circuito', 2, 35, 1)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Mini Band Wall Slides'), 1, 1, '5', 35);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Mini Band Delt Raises'), 2, 1, '5', 35);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Bodyweight Spiderman Lunge To Rotation'), 3, 1, '5 por lado', 35);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Lateral Shuttle Run'), 4, 1, '60 s', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Dumbbell Floor Press'), 5, 4, '8-15', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Dumbbell Single Arm Row'), 6, 4, '8-15 por lado', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Lateral Shuttle Run'), 7, 1, '60 s', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Dumbbell Curl to Shoulder Press'), 8, 4, '8-15', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Dumbbell Lateral Raise'), 9, 4, '8-15', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Lateral Shuttle Run'), 10, 1, '60 s', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Dumbbell Hammer Curl'), 11, 3, '8-15', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Dumbbell Laying Tricep Extension to Press'), 12, 4, '8-15', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Lateral Shuttle Run'), 13, 1, '60 s', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Child''s Pose'), 14, 1, '30 s', null);
  raise notice 'OK: «María Alejandra González Sierra» · Cycle 4 · 4 rutinas.';
end $cli$;

-- ─────────────────────────────────────────────────────────────────────
-- MARYU ALZATE · Cycle 11 · 5 semanas (2026-09-07 → 2026-10-11)
--   En el historial del 8-10 sep hay ejercicios que YA NO están en la
--   rutina (Dumbbell Walking Lunge, Mini Band Side Lying Hip Abduction,
--   Bodyweight Bent Knee Single Leg Calf Raise, Half Burpee with
--   Dumbbell, Dumbbell Glute Bridge Chest Press, Seated Dumbbell Front
--   Raise to Lateral Raise, Dumbbell Isometric Bicep Curl). Entran como
--   historial, no como programados.
--   El PDF la llama 'MAR ALZATE'. Uso 'Maryu Alzate' (el nombre del
--   archivo). Confirma cómo está en el CRM.
-- ─────────────────────────────────────────────────────────────────────
do $cli$
declare v_coach uuid; v_cli uuid; v_fase uuid; v_rut uuid; v_blo uuid; v_ses uuid;
begin
  select id, user_id into v_cli, v_coach from clientes where nombre ilike '%maryu%alzate%' limit 1;
  if v_cli is null then
    raise warning 'SALTADO: no encuentro a «Maryu Alzate» en `clientes` (patrón %%maryu%%alzate%%). Corrige el nombre y vuelve a correr.';
    return;
  end if;
  if exists (select 1 from fases where cliente_id = v_cli and nombre = 'Cycle 11') then
    raise notice 'SALTADO: «Maryu Alzate» ya tiene la fase Cycle 11 cargada.';
    return;
  end if;

  insert into fases (user_id, cliente_id, nombre, objetivo, notas_coach, semanas,
                     fecha_inicio, orden, estado)
  values (v_coach, v_cli, 'Cycle 11',
          'Bloque importado de Trainerize — la rutina que ya venía haciendo.',
          'Importado el 2026-09-25 desde el PDF de Trainerize (Cycle 11, 2026-09-07 a 2026-10-11). Revisar antes de enviar al cliente. En el historial del 8-10 sep hay ejercicios que YA NO están en la rutina (Dumbbell Walking Lunge, Mini Band Side Lying Hip Abduction, Bodyweight Bent Knee Single Leg Calf Raise, Half Burpee with Dumbbell, Dumbbell Glute Bridge Chest Press, Seated Dumbbell Front Raise to Lateral Raise, Dumbbell Isometric Bicep Curl). Entran como historial, no como programados.',
          5, date '2026-09-07',
          coalesce((select max(orden)+1 from fases where cliente_id = v_cli), 1), 'borrador')
  returning id into v_fase;

  -- Rutina 1: Lower Body + Core
  insert into rutinas (user_id, cliente_id, fase_id, nombre, dia_orden,
                       duracion_estimada_min, tipo_sesion, dias_semana)
  values (v_coach, v_cli, v_fase, 'Lower Body + Core', 1, 61, 'fuerza', array['L','X']::text[])
  returning id into v_rut;
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'A', 'circuito', 1, 30, 1)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Bodyweight Squat To Hinge'), 1, 1, '10', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='90-90 Hip Switch'), 2, 1, '8 por lado', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Cossack Squat to T-Spine Reach'), 3, 1, '8 por lado', 30);
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'B', 'circuito', 2, 40, 2)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Bench Hopover Burpee'), 4, 1, '8-12', 40);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Shuttle Run'), 5, 1, '60 s', 40);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Dumbbell Front Squat'), 6, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Bulgarian Pulses'), 7, 3, '6-12 por lado', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Barbell Hip Thrust'), 8, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Dumbbell Sumo Deadlift'), 9, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Mini Band Alternating Hip Abduction'), 10, 3, '6-12 por lado', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Dumbbell Calf Raise'), 11, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Bicycle Crunch'), 12, 3, '15', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Bench V Sit Leg Raise'), 13, 3, '15', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Pallof Press'), 14, 3, '15', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Static Pigeon Stretch'), 15, 1, '30 s', null);
  -- historial 2026-09-16
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach, origen)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-16', 2,
          '2026-W38', 'completada', '2026-09-16 12:00:00+00'::timestamptz, true, 'importada')
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Front Squat') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Front Squat'), 1, 12, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Front Squat') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Front Squat'), 2, 12, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Front Squat') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Front Squat'), 3, 12, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Front Squat') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Front Squat'), 4, 12, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Bulgarian Pulses') limit 1),
            (select id from _ecm_ej2 where alias='Bulgarian Pulses'), 1, 12, 7.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Bulgarian Pulses') limit 1),
            (select id from _ecm_ej2 where alias='Bulgarian Pulses'), 2, 12, 7.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Bulgarian Pulses') limit 1),
            (select id from _ecm_ej2 where alias='Bulgarian Pulses'), 3, 12, 7.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Barbell Hip Thrust') limit 1),
            (select id from _ecm_ej2 where alias='Barbell Hip Thrust'), 1, 12, 35, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Barbell Hip Thrust') limit 1),
            (select id from _ecm_ej2 where alias='Barbell Hip Thrust'), 2, 12, 35, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Barbell Hip Thrust') limit 1),
            (select id from _ecm_ej2 where alias='Barbell Hip Thrust'), 3, 12, 35, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Barbell Hip Thrust') limit 1),
            (select id from _ecm_ej2 where alias='Barbell Hip Thrust'), 4, 10, 35, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Sumo Deadlift') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Sumo Deadlift'), 1, 12, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Sumo Deadlift') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Sumo Deadlift'), 2, 12, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Sumo Deadlift') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Sumo Deadlift'), 3, 12, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Sumo Deadlift') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Sumo Deadlift'), 4, 12, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Mini Band Alternating Hip Abduction') limit 1),
            (select id from _ecm_ej2 where alias='Mini Band Alternating Hip Abduction'), 1, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Mini Band Alternating Hip Abduction') limit 1),
            (select id from _ecm_ej2 where alias='Mini Band Alternating Hip Abduction'), 2, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Mini Band Alternating Hip Abduction') limit 1),
            (select id from _ecm_ej2 where alias='Mini Band Alternating Hip Abduction'), 3, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Calf Raise') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Calf Raise'), 1, 12, 10, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Calf Raise') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Calf Raise'), 2, 12, 10, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Bicycle Crunch') limit 1),
            (select id from _ecm_ej2 where alias='Bicycle Crunch'), 1, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Bicycle Crunch') limit 1),
            (select id from _ecm_ej2 where alias='Bicycle Crunch'), 2, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Bicycle Crunch') limit 1),
            (select id from _ecm_ej2 where alias='Bicycle Crunch'), 3, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Bench V Sit Leg Raise') limit 1),
            (select id from _ecm_ej2 where alias='Bench V Sit Leg Raise'), 1, 15, 0.75, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Bench V Sit Leg Raise') limit 1),
            (select id from _ecm_ej2 where alias='Bench V Sit Leg Raise'), 2, 15, 0.75, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Bench V Sit Leg Raise') limit 1),
            (select id from _ecm_ej2 where alias='Bench V Sit Leg Raise'), 3, 15, 0.75, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Pallof Press') limit 1),
            (select id from _ecm_ej2 where alias='Pallof Press'), 1, 15, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Pallof Press') limit 1),
            (select id from _ecm_ej2 where alias='Pallof Press'), 2, 15, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Pallof Press') limit 1),
            (select id from _ecm_ej2 where alias='Pallof Press'), 3, 15, 20, 'kg');
  end if;
  -- historial 2026-09-14
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach, origen)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-14', 2,
          '2026-W38', 'completada', '2026-09-14 12:00:00+00'::timestamptz, true, 'importada')
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Front Squat') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Front Squat'), 1, 12, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Front Squat') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Front Squat'), 2, 12, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Front Squat') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Front Squat'), 3, 12, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Front Squat') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Front Squat'), 4, 12, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Bulgarian Pulses') limit 1),
            (select id from _ecm_ej2 where alias='Bulgarian Pulses'), 1, 12, 7.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Bulgarian Pulses') limit 1),
            (select id from _ecm_ej2 where alias='Bulgarian Pulses'), 2, 12, 7.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Bulgarian Pulses') limit 1),
            (select id from _ecm_ej2 where alias='Bulgarian Pulses'), 3, 12, 7.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Barbell Hip Thrust') limit 1),
            (select id from _ecm_ej2 where alias='Barbell Hip Thrust'), 1, 12, 35, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Barbell Hip Thrust') limit 1),
            (select id from _ecm_ej2 where alias='Barbell Hip Thrust'), 2, 12, 35, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Barbell Hip Thrust') limit 1),
            (select id from _ecm_ej2 where alias='Barbell Hip Thrust'), 3, 12, 35, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Barbell Hip Thrust') limit 1),
            (select id from _ecm_ej2 where alias='Barbell Hip Thrust'), 4, 12, 35, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Sumo Deadlift') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Sumo Deadlift'), 1, 12, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Sumo Deadlift') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Sumo Deadlift'), 2, 12, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Sumo Deadlift') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Sumo Deadlift'), 3, 12, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Sumo Deadlift') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Sumo Deadlift'), 4, 12, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Mini Band Alternating Hip Abduction') limit 1),
            (select id from _ecm_ej2 where alias='Mini Band Alternating Hip Abduction'), 1, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Mini Band Alternating Hip Abduction') limit 1),
            (select id from _ecm_ej2 where alias='Mini Band Alternating Hip Abduction'), 2, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Mini Band Alternating Hip Abduction') limit 1),
            (select id from _ecm_ej2 where alias='Mini Band Alternating Hip Abduction'), 3, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Calf Raise') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Calf Raise'), 1, 12, 7.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Calf Raise') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Calf Raise'), 2, 12, 7.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Calf Raise') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Calf Raise'), 3, 15, 7.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Bicycle Crunch') limit 1),
            (select id from _ecm_ej2 where alias='Bicycle Crunch'), 1, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Bicycle Crunch') limit 1),
            (select id from _ecm_ej2 where alias='Bicycle Crunch'), 2, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Bicycle Crunch') limit 1),
            (select id from _ecm_ej2 where alias='Bicycle Crunch'), 3, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Bench V Sit Leg Raise') limit 1),
            (select id from _ecm_ej2 where alias='Bench V Sit Leg Raise'), 1, 15, 0.75, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Bench V Sit Leg Raise') limit 1),
            (select id from _ecm_ej2 where alias='Bench V Sit Leg Raise'), 2, 15, 0.75, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Bench V Sit Leg Raise') limit 1),
            (select id from _ecm_ej2 where alias='Bench V Sit Leg Raise'), 3, 15, 0.72, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Pallof Press') limit 1),
            (select id from _ecm_ej2 where alias='Pallof Press'), 1, 15, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Pallof Press') limit 1),
            (select id from _ecm_ej2 where alias='Pallof Press'), 2, 15, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Pallof Press') limit 1),
            (select id from _ecm_ej2 where alias='Pallof Press'), 3, 15, 20, 'kg');
  end if;
  -- historial 2026-09-09
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach, origen)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-09', 1,
          '2026-W37', 'completada', '2026-09-09 12:00:00+00'::timestamptz, true, 'importada')
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Barbell Hip Thrust') limit 1),
            (select id from _ecm_ej2 where alias='Barbell Hip Thrust'), 1, 12, 35, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Barbell Hip Thrust') limit 1),
            (select id from _ecm_ej2 where alias='Barbell Hip Thrust'), 2, 12, 35, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Barbell Hip Thrust') limit 1),
            (select id from _ecm_ej2 where alias='Barbell Hip Thrust'), 3, 12, 35, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Barbell Hip Thrust') limit 1),
            (select id from _ecm_ej2 where alias='Barbell Hip Thrust'), 4, 12, 35, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Sumo Deadlift') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Sumo Deadlift'), 1, 10, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Sumo Deadlift') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Sumo Deadlift'), 2, 12, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Sumo Deadlift') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Sumo Deadlift'), 3, 12, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Sumo Deadlift') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Sumo Deadlift'), 4, 12, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Bicycle Crunch') limit 1),
            (select id from _ecm_ej2 where alias='Bicycle Crunch'), 1, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Bicycle Crunch') limit 1),
            (select id from _ecm_ej2 where alias='Bicycle Crunch'), 2, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Bicycle Crunch') limit 1),
            (select id from _ecm_ej2 where alias='Bicycle Crunch'), 3, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Bicycle Crunch') limit 1),
            (select id from _ecm_ej2 where alias='Bicycle Crunch'), 4, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Bench V Sit Leg Raise') limit 1),
            (select id from _ecm_ej2 where alias='Bench V Sit Leg Raise'), 1, 15, 0.75, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Bench V Sit Leg Raise') limit 1),
            (select id from _ecm_ej2 where alias='Bench V Sit Leg Raise'), 2, 15, 0.75, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Bench V Sit Leg Raise') limit 1),
            (select id from _ecm_ej2 where alias='Bench V Sit Leg Raise'), 3, 15, 0.75, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Bench V Sit Leg Raise') limit 1),
            (select id from _ecm_ej2 where alias='Bench V Sit Leg Raise'), 4, 15, 0.75, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Pallof Press') limit 1),
            (select id from _ecm_ej2 where alias='Pallof Press'), 1, 15, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Pallof Press') limit 1),
            (select id from _ecm_ej2 where alias='Pallof Press'), 2, 15, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Pallof Press') limit 1),
            (select id from _ecm_ej2 where alias='Pallof Press'), 3, 15, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Walking Lunge') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Walking Lunge'), 1, 20, 10, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Walking Lunge') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Walking Lunge'), 2, 20, 10, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Walking Lunge') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Walking Lunge'), 3, 20, 10, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Walking Lunge') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Walking Lunge'), 4, 20, 10, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Mini Band Side Lying Hip Abduction') limit 1),
            (select id from _ecm_ej2 where alias='Mini Band Side Lying Hip Abduction'), 1, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Mini Band Side Lying Hip Abduction') limit 1),
            (select id from _ecm_ej2 where alias='Mini Band Side Lying Hip Abduction'), 2, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Mini Band Side Lying Hip Abduction') limit 1),
            (select id from _ecm_ej2 where alias='Mini Band Side Lying Hip Abduction'), 3, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Bodyweight Bent Knee Single Leg Calf Raise') limit 1),
            (select id from _ecm_ej2 where alias='Bodyweight Bent Knee Single Leg Calf Raise'), 1, 12, 10, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Bodyweight Bent Knee Single Leg Calf Raise') limit 1),
            (select id from _ecm_ej2 where alias='Bodyweight Bent Knee Single Leg Calf Raise'), 2, 12, 10, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Bodyweight Bent Knee Single Leg Calf Raise') limit 1),
            (select id from _ecm_ej2 where alias='Bodyweight Bent Knee Single Leg Calf Raise'), 3, 12, 10, 'kg');
  end if;

  -- Rutina 2: Upper Body
  insert into rutinas (user_id, cliente_id, fase_id, nombre, dia_orden,
                       duracion_estimada_min, tipo_sesion, dias_semana)
  values (v_coach, v_cli, v_fase, 'Upper Body', 2, 57, 'fuerza', array['M','J']::text[])
  returning id into v_rut;
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'A', 'circuito', 1, 30, 1)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Table Top Half Arm Thoracic Rotation'), 1, 1, '8 por lado', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Bodyweight Spiderman Lunge To Rotation'), 2, 1, '8 por lado', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Dumbbell Standing Shoulder External Rotations'), 3, 1, '6', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Bar Hang'), 4, 1, '40 s', 30);
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'B', 'circuito', 2, 40, 2)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Dumbbell Burpee with Curl to Press'), 5, 1, '8-12', 40);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Lateral Shuttle Run'), 6, 1, '60 s', 40);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Dumbbell Bench Press'), 7, 4, '6-12', 90);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Wide Grip Lat Pulldown'), 8, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Dumbbell Single Arm Row'), 9, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Dumbbell Incline Alternating Curl'), 10, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Dumbbell Hammer Curl'), 11, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Cable Straight Bar Tricep Pushdown'), 12, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Cable Rope Face Pull'), 13, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Child''s Pose'), 14, 1, '30 s', null);
  -- historial 2026-09-17
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach, origen)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-17', 2,
          '2026-W38', 'completada', '2026-09-17 12:00:00+00'::timestamptz, true, 'importada')
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Standing Shoulder External Rotations') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Standing Shoulder External Rotations'), 1, 6, 0.75, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Bar Hang') limit 1),
            (select id from _ecm_ej2 where alias='Bar Hang'), 1, 20, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Burpee with Curl to Press') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Burpee with Curl to Press'), 1, 12, 7.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Burpee with Curl to Press') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Burpee with Curl to Press'), 2, 12, 7.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Bench Press') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Bench Press'), 1, 12, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Bench Press') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Bench Press'), 2, 12, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Bench Press') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Bench Press'), 3, 12, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Bench Press') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Bench Press'), 4, 12, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Wide Grip Lat Pulldown') limit 1),
            (select id from _ecm_ej2 where alias='Wide Grip Lat Pulldown'), 1, 12, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Wide Grip Lat Pulldown') limit 1),
            (select id from _ecm_ej2 where alias='Wide Grip Lat Pulldown'), 2, 12, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Wide Grip Lat Pulldown') limit 1),
            (select id from _ecm_ej2 where alias='Wide Grip Lat Pulldown'), 3, 12, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Wide Grip Lat Pulldown') limit 1),
            (select id from _ecm_ej2 where alias='Wide Grip Lat Pulldown'), 4, 12, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Single Arm Row') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Single Arm Row'), 1, 9, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Single Arm Row') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Single Arm Row'), 2, 10, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Single Arm Row') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Single Arm Row'), 3, 10, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Incline Alternating Curl') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Incline Alternating Curl'), 1, 12, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Incline Alternating Curl') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Incline Alternating Curl'), 2, 12, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Incline Alternating Curl') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Incline Alternating Curl'), 3, 12, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Hammer Curl'), 1, 12, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Hammer Curl'), 2, 12, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Hammer Curl'), 3, 12, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Straight Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej2 where alias='Cable Straight Bar Tricep Pushdown'), 1, 12, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Straight Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej2 where alias='Cable Straight Bar Tricep Pushdown'), 2, 12, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Straight Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej2 where alias='Cable Straight Bar Tricep Pushdown'), 3, 12, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Rope Face Pull') limit 1),
            (select id from _ecm_ej2 where alias='Cable Rope Face Pull'), 1, 12, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Rope Face Pull') limit 1),
            (select id from _ecm_ej2 where alias='Cable Rope Face Pull'), 2, 12, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Rope Face Pull') limit 1),
            (select id from _ecm_ej2 where alias='Cable Rope Face Pull'), 3, 12, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Rope Face Pull') limit 1),
            (select id from _ecm_ej2 where alias='Cable Rope Face Pull'), 4, 12, 40, 'kg');
  end if;
  -- historial 2026-09-15
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach, origen)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-15', 2,
          '2026-W38', 'completada', '2026-09-15 12:00:00+00'::timestamptz, true, 'importada')
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Bar Hang') limit 1),
            (select id from _ecm_ej2 where alias='Bar Hang'), 1, 25, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Burpee with Curl to Press') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Burpee with Curl to Press'), 1, 12, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Burpee with Curl to Press') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Burpee with Curl to Press'), 2, 8, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Bench Press') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Bench Press'), 1, 12, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Bench Press') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Bench Press'), 2, 12, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Bench Press') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Bench Press'), 3, 12, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Bench Press') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Bench Press'), 4, 12, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Wide Grip Lat Pulldown') limit 1),
            (select id from _ecm_ej2 where alias='Wide Grip Lat Pulldown'), 1, 12, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Wide Grip Lat Pulldown') limit 1),
            (select id from _ecm_ej2 where alias='Wide Grip Lat Pulldown'), 2, 12, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Wide Grip Lat Pulldown') limit 1),
            (select id from _ecm_ej2 where alias='Wide Grip Lat Pulldown'), 3, 12, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Wide Grip Lat Pulldown') limit 1),
            (select id from _ecm_ej2 where alias='Wide Grip Lat Pulldown'), 4, 12, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Single Arm Row') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Single Arm Row'), 1, 9, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Single Arm Row') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Single Arm Row'), 2, 10, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Single Arm Row') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Single Arm Row'), 3, 10, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Incline Alternating Curl') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Incline Alternating Curl'), 1, 12, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Incline Alternating Curl') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Incline Alternating Curl'), 2, 12, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Incline Alternating Curl') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Incline Alternating Curl'), 3, 12, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Hammer Curl'), 1, 12, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Hammer Curl'), 2, 12, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Hammer Curl'), 3, 12, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Straight Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej2 where alias='Cable Straight Bar Tricep Pushdown'), 1, 12, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Straight Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej2 where alias='Cable Straight Bar Tricep Pushdown'), 2, 12, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Straight Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej2 where alias='Cable Straight Bar Tricep Pushdown'), 3, 12, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Rope Face Pull') limit 1),
            (select id from _ecm_ej2 where alias='Cable Rope Face Pull'), 1, 12, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Rope Face Pull') limit 1),
            (select id from _ecm_ej2 where alias='Cable Rope Face Pull'), 2, 12, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Rope Face Pull') limit 1),
            (select id from _ecm_ej2 where alias='Cable Rope Face Pull'), 3, 12, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Rope Face Pull') limit 1),
            (select id from _ecm_ej2 where alias='Cable Rope Face Pull'), 4, 12, 40, 'kg');
  end if;
  -- historial 2026-09-10
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach, origen)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-10', 1,
          '2026-W37', 'completada', '2026-09-10 12:00:00+00'::timestamptz, true, 'importada')
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Wide Grip Lat Pulldown') limit 1),
            (select id from _ecm_ej2 where alias='Wide Grip Lat Pulldown'), 1, 12, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Wide Grip Lat Pulldown') limit 1),
            (select id from _ecm_ej2 where alias='Wide Grip Lat Pulldown'), 2, 12, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Wide Grip Lat Pulldown') limit 1),
            (select id from _ecm_ej2 where alias='Wide Grip Lat Pulldown'), 3, 12, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Wide Grip Lat Pulldown') limit 1),
            (select id from _ecm_ej2 where alias='Wide Grip Lat Pulldown'), 4, 12, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Hammer Curl'), 1, 10, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Hammer Curl'), 2, 10, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Hammer Curl'), 3, 10, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Straight Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej2 where alias='Cable Straight Bar Tricep Pushdown'), 1, 15, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Straight Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej2 where alias='Cable Straight Bar Tricep Pushdown'), 2, 12, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Straight Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej2 where alias='Cable Straight Bar Tricep Pushdown'), 3, 12, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Straight Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej2 where alias='Cable Straight Bar Tricep Pushdown'), 4, 10, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Rope Face Pull') limit 1),
            (select id from _ecm_ej2 where alias='Cable Rope Face Pull'), 1, 12, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Rope Face Pull') limit 1),
            (select id from _ecm_ej2 where alias='Cable Rope Face Pull'), 2, 12, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Rope Face Pull') limit 1),
            (select id from _ecm_ej2 where alias='Cable Rope Face Pull'), 3, 12, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Rope Face Pull') limit 1),
            (select id from _ecm_ej2 where alias='Cable Rope Face Pull'), 4, 12, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Half Burpee with Dumbbell') limit 1),
            (select id from _ecm_ej2 where alias='Half Burpee with Dumbbell'), 1, 12, 7.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Glute Bridge Chest Press') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Glute Bridge Chest Press'), 1, 12, 10, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Glute Bridge Chest Press') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Glute Bridge Chest Press'), 2, 12, 10, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Glute Bridge Chest Press') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Glute Bridge Chest Press'), 3, 12, 10, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Glute Bridge Chest Press') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Glute Bridge Chest Press'), 4, 12, 10, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Seated Dumbbell Front Raise to Lateral Raise') limit 1),
            (select id from _ecm_ej2 where alias='Seated Dumbbell Front Raise to Lateral Raise'), 1, 12, 2.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Seated Dumbbell Front Raise to Lateral Raise') limit 1),
            (select id from _ecm_ej2 where alias='Seated Dumbbell Front Raise to Lateral Raise'), 2, 12, 2.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Seated Dumbbell Front Raise to Lateral Raise') limit 1),
            (select id from _ecm_ej2 where alias='Seated Dumbbell Front Raise to Lateral Raise'), 3, 2, 2.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Isometric Bicep Curl') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Isometric Bicep Curl'), 1, 12, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Isometric Bicep Curl') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Isometric Bicep Curl'), 2, 12, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Isometric Bicep Curl') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Isometric Bicep Curl'), 3, 12, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Isometric Bicep Curl') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Isometric Bicep Curl'), 4, 12, 5, 'kg');
  end if;
  -- historial 2026-09-08
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach, origen)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-08', 1,
          '2026-W37', 'completada', '2026-09-08 12:00:00+00'::timestamptz, true, 'importada')
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Wide Grip Lat Pulldown') limit 1),
            (select id from _ecm_ej2 where alias='Wide Grip Lat Pulldown'), 1, 12, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Wide Grip Lat Pulldown') limit 1),
            (select id from _ecm_ej2 where alias='Wide Grip Lat Pulldown'), 2, 12, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Wide Grip Lat Pulldown') limit 1),
            (select id from _ecm_ej2 where alias='Wide Grip Lat Pulldown'), 3, 12, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Wide Grip Lat Pulldown') limit 1),
            (select id from _ecm_ej2 where alias='Wide Grip Lat Pulldown'), 4, 12, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Hammer Curl'), 1, 10, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Hammer Curl'), 2, 10, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Hammer Curl'), 3, 10, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Straight Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej2 where alias='Cable Straight Bar Tricep Pushdown'), 1, 12, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Straight Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej2 where alias='Cable Straight Bar Tricep Pushdown'), 2, 12, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Straight Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej2 where alias='Cable Straight Bar Tricep Pushdown'), 3, 12, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Straight Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej2 where alias='Cable Straight Bar Tricep Pushdown'), 4, 12, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Rope Face Pull') limit 1),
            (select id from _ecm_ej2 where alias='Cable Rope Face Pull'), 1, 12, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Rope Face Pull') limit 1),
            (select id from _ecm_ej2 where alias='Cable Rope Face Pull'), 2, 12, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Rope Face Pull') limit 1),
            (select id from _ecm_ej2 where alias='Cable Rope Face Pull'), 3, 12, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Rope Face Pull') limit 1),
            (select id from _ecm_ej2 where alias='Cable Rope Face Pull'), 4, 12, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Half Burpee with Dumbbell') limit 1),
            (select id from _ecm_ej2 where alias='Half Burpee with Dumbbell'), 1, 12, 7.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Glute Bridge Chest Press') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Glute Bridge Chest Press'), 1, 12, 7.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Glute Bridge Chest Press') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Glute Bridge Chest Press'), 2, 12, 7.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Glute Bridge Chest Press') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Glute Bridge Chest Press'), 3, 12, 7.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Glute Bridge Chest Press') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Glute Bridge Chest Press'), 4, 12, 7.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Seated Dumbbell Front Raise to Lateral Raise') limit 1),
            (select id from _ecm_ej2 where alias='Seated Dumbbell Front Raise to Lateral Raise'), 1, 12, 2.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Seated Dumbbell Front Raise to Lateral Raise') limit 1),
            (select id from _ecm_ej2 where alias='Seated Dumbbell Front Raise to Lateral Raise'), 2, 12, 2.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Seated Dumbbell Front Raise to Lateral Raise') limit 1),
            (select id from _ecm_ej2 where alias='Seated Dumbbell Front Raise to Lateral Raise'), 3, 12, 2.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Isometric Bicep Curl') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Isometric Bicep Curl'), 1, 12, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Isometric Bicep Curl') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Isometric Bicep Curl'), 2, 12, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Isometric Bicep Curl') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Isometric Bicep Curl'), 3, 12, 5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Isometric Bicep Curl') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Isometric Bicep Curl'), 4, 12, 5, 'kg');
  end if;
  raise notice 'OK: «Maryu Alzate» · Cycle 11 · 2 rutinas.';
end $cli$;

-- ─────────────────────────────────────────────────────────────────────
-- NATALIA SAMPER · Cycle 3 · 5 semanas (2026-08-17 → 2026-09-20)
--   Plan de CASA: solo peso corporal, mancuernas, banda y colchoneta.
--   Ninguna máquina.
-- ─────────────────────────────────────────────────────────────────────
do $cli$
declare v_coach uuid; v_cli uuid; v_fase uuid; v_rut uuid; v_blo uuid; v_ses uuid;
begin
  select id, user_id into v_cli, v_coach from clientes where nombre ilike '%natalia%samper%' limit 1;
  if v_cli is null then
    raise warning 'SALTADO: no encuentro a «Natalia Samper» en `clientes` (patrón %%natalia%%samper%%). Corrige el nombre y vuelve a correr.';
    return;
  end if;
  if exists (select 1 from fases where cliente_id = v_cli and nombre = 'Cycle 3') then
    raise notice 'SALTADO: «Natalia Samper» ya tiene la fase Cycle 3 cargada.';
    return;
  end if;

  insert into fases (user_id, cliente_id, nombre, objetivo, notas_coach, semanas,
                     fecha_inicio, orden, estado)
  values (v_coach, v_cli, 'Cycle 3',
          'Bloque importado de Trainerize — la rutina que ya venía haciendo.',
          'Importado el 2026-09-25 desde el PDF de Trainerize (Cycle 3, 2026-08-17 a 2026-09-20). Revisar antes de enviar al cliente.',
          5, date '2026-08-17',
          coalesce((select max(orden)+1 from fases where cliente_id = v_cli), 1), 'borrador')
  returning id into v_fase;

  -- Rutina 1: Full Body Training
  insert into rutinas (user_id, cliente_id, fase_id, nombre, dia_orden,
                       duracion_estimada_min, tipo_sesion, dias_semana)
  values (v_coach, v_cli, v_fase, 'Full Body Training', 1, 59, 'fuerza', array['J']::text[])
  returning id into v_rut;
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'A', 'circuito', 2, 35, 1)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Hinge to T-Rotation'), 1, 1, '5 por lado', 35);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Bodyweight Alternating Cossack Squat'), 2, 1, '5 por lado', 35);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Prone Scorpion Alternating'), 3, 1, '5 por lado', 35);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Dumbbell Floor Press'), 4, 3, '8-15', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Half Kneeling SuperBand Single Arm Row'), 5, 3, '8-15', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Seated Dumbbell Hammer Curl to Neutral Press'), 6, 3, '8-15', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Mini Band Standing I''s'), 7, 3, '8-15', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Dumbbell Alternating Bicep Curl'), 8, 3, '8-15', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Bodyweight Walking Lunge'), 9, 3, '8-15', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Glute Bridge'), 10, 3, '8-15', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Lying Hip Abductions'), 11, 3, '8-15', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Bodyweight Deadbug'), 12, 3, '8-15', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Lateral Shuttle Run'), 13, 1, '60 s', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Child''s Pose'), 14, 1, '30 s', null);
  -- historial 2026-09-10
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach, origen)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-10', 4,
          '2026-W37', 'completada', '2026-09-10 12:00:00+00'::timestamptz, true, 'importada')
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Floor Press') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Floor Press'), 1, 15, 2, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Floor Press') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Floor Press'), 2, 15, 2, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Floor Press') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Floor Press'), 3, 15, 2, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Half Kneeling SuperBand Single Arm Row') limit 1),
            (select id from _ecm_ej2 where alias='Half Kneeling SuperBand Single Arm Row'), 1, 10, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Half Kneeling SuperBand Single Arm Row') limit 1),
            (select id from _ecm_ej2 where alias='Half Kneeling SuperBand Single Arm Row'), 2, 10, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Half Kneeling SuperBand Single Arm Row') limit 1),
            (select id from _ecm_ej2 where alias='Half Kneeling SuperBand Single Arm Row'), 3, 10, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Seated Dumbbell Hammer Curl to Neutral Press') limit 1),
            (select id from _ecm_ej2 where alias='Seated Dumbbell Hammer Curl to Neutral Press'), 1, 15, 2, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Seated Dumbbell Hammer Curl to Neutral Press') limit 1),
            (select id from _ecm_ej2 where alias='Seated Dumbbell Hammer Curl to Neutral Press'), 2, 15, 2, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Seated Dumbbell Hammer Curl to Neutral Press') limit 1),
            (select id from _ecm_ej2 where alias='Seated Dumbbell Hammer Curl to Neutral Press'), 3, 15, 2, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Mini Band Standing I''s') limit 1),
            (select id from _ecm_ej2 where alias='Mini Band Standing I''s'), 1, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Mini Band Standing I''s') limit 1),
            (select id from _ecm_ej2 where alias='Mini Band Standing I''s'), 2, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Mini Band Standing I''s') limit 1),
            (select id from _ecm_ej2 where alias='Mini Band Standing I''s'), 3, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Alternating Bicep Curl') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Alternating Bicep Curl'), 1, 15, 2, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Alternating Bicep Curl') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Alternating Bicep Curl'), 2, 15, 2, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Alternating Bicep Curl') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Alternating Bicep Curl'), 3, 15, 2, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Bodyweight Walking Lunge') limit 1),
            (select id from _ecm_ej2 where alias='Bodyweight Walking Lunge'), 1, 16, 2.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Bodyweight Walking Lunge') limit 1),
            (select id from _ecm_ej2 where alias='Bodyweight Walking Lunge'), 2, 16, 2.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Bodyweight Walking Lunge') limit 1),
            (select id from _ecm_ej2 where alias='Bodyweight Walking Lunge'), 3, 16, 2.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Glute Bridge') limit 1),
            (select id from _ecm_ej2 where alias='Glute Bridge'), 1, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Glute Bridge') limit 1),
            (select id from _ecm_ej2 where alias='Glute Bridge'), 2, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Glute Bridge') limit 1),
            (select id from _ecm_ej2 where alias='Glute Bridge'), 3, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Lying Hip Abductions') limit 1),
            (select id from _ecm_ej2 where alias='Lying Hip Abductions'), 1, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Lying Hip Abductions') limit 1),
            (select id from _ecm_ej2 where alias='Lying Hip Abductions'), 2, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Lying Hip Abductions') limit 1),
            (select id from _ecm_ej2 where alias='Lying Hip Abductions'), 3, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Bodyweight Deadbug') limit 1),
            (select id from _ecm_ej2 where alias='Bodyweight Deadbug'), 1, 10, 0.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Bodyweight Deadbug') limit 1),
            (select id from _ecm_ej2 where alias='Bodyweight Deadbug'), 2, 10, 0.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Bodyweight Deadbug') limit 1),
            (select id from _ecm_ej2 where alias='Bodyweight Deadbug'), 3, 10, 0.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Lateral Shuttle Run') limit 1),
            (select id from _ecm_ej2 where alias='Lateral Shuttle Run'), 1, 1, 0.5, 'kg');
  end if;

  -- Rutina 2: Lower Body + Core Training
  insert into rutinas (user_id, cliente_id, fase_id, nombre, dia_orden,
                       duracion_estimada_min, tipo_sesion, dias_semana)
  values (v_coach, v_cli, v_fase, 'Lower Body + Core Training', 2, 57, 'fuerza', '{}'::text[])
  returning id into v_rut;
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'A', 'circuito', 2, 25, 1)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Bodyweight Squat To Hinge'), 1, 1, '6', 25);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Glute Side Circle'), 2, 1, '6 por lado', 25);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='90-90 Hip Switch'), 3, 1, '6', 25);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Lateral Shuttle Run'), 4, 1, '60 s', 25);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Bodyweight Walking Lunge'), 5, 4, '15-20 pasos', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Mini Band Wall Sit'), 6, 3, '30 s', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='SuperBand Deadlift'), 7, 4, '8-15', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Glute Bridge'), 8, 4, '8-15', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Lying Hip Abductions'), 9, 3, '8-15 por lado', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Bodyweight Single Leg Calf Raise'), 10, 3, '8-15 por lado', 50);
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'B', 'circuito', 3, 35, 2)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Alternating Leg Drop'), 11, 1, '7 por lado', 10);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Bodyweight Deadbug'), 12, 1, '7 por lado', 35);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Lateral Shuttle Run'), 13, 1, '60 s', null);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Static Pigeon Stretch'), 14, 1, '30 s por lado', null);

  -- Rutina 3: Upper Body Training
  insert into rutinas (user_id, cliente_id, fase_id, nombre, dia_orden,
                       duracion_estimada_min, tipo_sesion, dias_semana)
  values (v_coach, v_cli, v_fase, 'Upper Body Training', 3, 48, 'fuerza', '{}'::text[])
  returning id into v_rut;
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'A', 'circuito', 2, 35, 1)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Table Top Half Arm Thoracic Rotation'), 1, 1, '5 por lado', 35);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Cobra'), 2, 1, '5', 35);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Prone Scorpion Alternating'), 3, 1, '5 por lado', 35);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Lateral Shuttle Run'), 4, 1, '60 s', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Dumbbell Floor Press'), 5, 3, '8-15', 60);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Half Kneeling SuperBand Single Arm Row'), 6, 3, '8-15 por lado', 60);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Mini Band Standing I''s'), 7, 3, '8-15', 60);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Lateral Shuttle Run'), 8, 1, '60 s', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Seated Dumbbell Hammer Curl to Neutral Press'), 9, 3, '8-15', 60);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Dumbbell Alternating Bicep Curl'), 10, 3, '8-15 por lado', 60);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Dumbbell Laying Tricep Extension to Press'), 11, 3, '8-15', 60);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Lateral Shuttle Run'), 12, 1, '60 s', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Child''s Pose'), 13, 1, '30 s', null);
  raise notice 'OK: «Natalia Samper» · Cycle 3 · 3 rutinas.';
end $cli$;

-- ─────────────────────────────────────────────────────────────────────
-- SANTIAGO FONSECA · Cycle 2 · 5 semanas (2026-09-14 → 2026-10-18)
--   En el historial del 16 sep, 'Mini Band Wall Slides' serie 1 dice 133
--   reps (la 2 dice 13). Es un dedazo suyo. Lo cargo como 13 y te lo
--   aviso.
-- ─────────────────────────────────────────────────────────────────────
do $cli$
declare v_coach uuid; v_cli uuid; v_fase uuid; v_rut uuid; v_blo uuid; v_ses uuid;
begin
  select id, user_id into v_cli, v_coach from clientes where nombre ilike '%santiago%fonseca%' limit 1;
  if v_cli is null then
    raise warning 'SALTADO: no encuentro a «Santiago Fonseca» en `clientes` (patrón %%santiago%%fonseca%%). Corrige el nombre y vuelve a correr.';
    return;
  end if;
  if exists (select 1 from fases where cliente_id = v_cli and nombre = 'Cycle 2') then
    raise notice 'SALTADO: «Santiago Fonseca» ya tiene la fase Cycle 2 cargada.';
    return;
  end if;

  insert into fases (user_id, cliente_id, nombre, objetivo, notas_coach, semanas,
                     fecha_inicio, orden, estado)
  values (v_coach, v_cli, 'Cycle 2',
          'Bloque importado de Trainerize — la rutina que ya venía haciendo.',
          'Importado el 2026-09-25 desde el PDF de Trainerize (Cycle 2, 2026-09-14 a 2026-10-18). Revisar antes de enviar al cliente. En el historial del 16 sep, ''Mini Band Wall Slides'' serie 1 dice 133 reps (la 2 dice 13). Es un dedazo suyo. Lo cargo como 13 y te lo aviso.',
          5, date '2026-09-14',
          coalesce((select max(orden)+1 from fases where cliente_id = v_cli), 1), 'borrador')
  returning id into v_fase;

  -- Rutina 1: Lower Body + Core Training
  insert into rutinas (user_id, cliente_id, fase_id, nombre, dia_orden,
                       duracion_estimada_min, tipo_sesion, dias_semana)
  values (v_coach, v_cli, v_fase, 'Lower Body + Core Training', 1, 69, 'fuerza', array['L','J']::text[])
  returning id into v_rut;
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'A', 'circuito', 2, 30, 1)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='90-90 Hip Switch'), 1, 1, '6', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Cossack Squat to T-Spine Reach'), 2, 1, '6 por lado', 30);
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'B', 'circuito', 2, 30, 2)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='1/2 Kneel to High Knee Hop'), 3, 1, '6 por lado', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='1/2 Kneel to Lateral Bound'), 4, 1, '8', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Shuttle Run'), 5, 1, '60 s', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Angled Machine Leg Press'), 6, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Smith Machine Sumo Deadlift'), 7, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Hip Thrust Machine'), 8, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Machine Seated Leg Extension'), 9, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Machine Seated Hip Adduction'), 10, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Machine Seated Calf Raise'), 11, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Dip Machine Straight Leg Raise'), 12, 3, '15', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Seated Machine Ab Crunch'), 13, 4, '15', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Horizontal Cable Rotation'), 14, 3, '15', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Static Pigeon Stretch'), 15, 1, '30 s por lado', null);
  -- historial 2026-09-17
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach, origen)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-17', 1,
          '2026-W38', 'completada', '2026-09-17 12:00:00+00'::timestamptz, true, 'importada')
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Angled Machine Leg Press') limit 1),
            (select id from _ecm_ej2 where alias='Angled Machine Leg Press'), 1, 10, 57.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Angled Machine Leg Press') limit 1),
            (select id from _ecm_ej2 where alias='Angled Machine Leg Press'), 2, 8, 70, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Angled Machine Leg Press') limit 1),
            (select id from _ecm_ej2 where alias='Angled Machine Leg Press'), 3, 8, 70, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Angled Machine Leg Press') limit 1),
            (select id from _ecm_ej2 where alias='Angled Machine Leg Press'), 4, 7, 70, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Smith Machine Sumo Deadlift') limit 1),
            (select id from _ecm_ej2 where alias='Smith Machine Sumo Deadlift'), 1, 12, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Smith Machine Sumo Deadlift') limit 1),
            (select id from _ecm_ej2 where alias='Smith Machine Sumo Deadlift'), 2, 10, 22.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Smith Machine Sumo Deadlift') limit 1),
            (select id from _ecm_ej2 where alias='Smith Machine Sumo Deadlift'), 3, 9, 22.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Smith Machine Sumo Deadlift') limit 1),
            (select id from _ecm_ej2 where alias='Smith Machine Sumo Deadlift'), 4, 7, 22.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Hip Thrust Machine') limit 1),
            (select id from _ecm_ej2 where alias='Hip Thrust Machine'), 1, 9, 45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Hip Thrust Machine') limit 1),
            (select id from _ecm_ej2 where alias='Hip Thrust Machine'), 2, 8, 45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Hip Thrust Machine') limit 1),
            (select id from _ecm_ej2 where alias='Hip Thrust Machine'), 3, 8, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Hip Thrust Machine') limit 1),
            (select id from _ecm_ej2 where alias='Hip Thrust Machine'), 4, 7, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Seated Leg Extension') limit 1),
            (select id from _ecm_ej2 where alias='Machine Seated Leg Extension'), 1, 12, 72, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Seated Leg Extension') limit 1),
            (select id from _ecm_ej2 where alias='Machine Seated Leg Extension'), 2, 10, 80, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Seated Leg Extension') limit 1),
            (select id from _ecm_ej2 where alias='Machine Seated Leg Extension'), 3, 10, 80, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_ej2 where alias='Machine Seated Calf Raise'), 1, 10, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_ej2 where alias='Machine Seated Calf Raise'), 2, 10, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_ej2 where alias='Machine Seated Calf Raise'), 3, 10, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_ej2 where alias='Machine Seated Calf Raise'), 4, 10, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dip Machine Straight Leg Raise') limit 1),
            (select id from _ecm_ej2 where alias='Dip Machine Straight Leg Raise'), 1, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dip Machine Straight Leg Raise') limit 1),
            (select id from _ecm_ej2 where alias='Dip Machine Straight Leg Raise'), 2, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dip Machine Straight Leg Raise') limit 1),
            (select id from _ecm_ej2 where alias='Dip Machine Straight Leg Raise'), 3, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Seated Machine Ab Crunch') limit 1),
            (select id from _ecm_ej2 where alias='Seated Machine Ab Crunch'), 1, 15, 35, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Seated Machine Ab Crunch') limit 1),
            (select id from _ecm_ej2 where alias='Seated Machine Ab Crunch'), 2, 15, 35, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Seated Machine Ab Crunch') limit 1),
            (select id from _ecm_ej2 where alias='Seated Machine Ab Crunch'), 3, 15, 35, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Seated Machine Ab Crunch') limit 1),
            (select id from _ecm_ej2 where alias='Seated Machine Ab Crunch'), 4, 15, 35, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Horizontal Cable Rotation') limit 1),
            (select id from _ecm_ej2 where alias='Horizontal Cable Rotation'), 1, 20, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Horizontal Cable Rotation') limit 1),
            (select id from _ecm_ej2 where alias='Horizontal Cable Rotation'), 2, 20, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Horizontal Cable Rotation') limit 1),
            (select id from _ecm_ej2 where alias='Horizontal Cable Rotation'), 3, 20, 15, 'kg');
  end if;
  -- historial 2026-09-14
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach, origen)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-14', 1,
          '2026-W38', 'completada', '2026-09-14 12:00:00+00'::timestamptz, true, 'importada')
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Angled Machine Leg Press') limit 1),
            (select id from _ecm_ej2 where alias='Angled Machine Leg Press'), 1, 12, 47.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Angled Machine Leg Press') limit 1),
            (select id from _ecm_ej2 where alias='Angled Machine Leg Press'), 2, 9, 60, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Angled Machine Leg Press') limit 1),
            (select id from _ecm_ej2 where alias='Angled Machine Leg Press'), 3, 9, 60, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Angled Machine Leg Press') limit 1),
            (select id from _ecm_ej2 where alias='Angled Machine Leg Press'), 4, 8, 72, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Smith Machine Sumo Deadlift') limit 1),
            (select id from _ecm_ej2 where alias='Smith Machine Sumo Deadlift'), 1, 12, 12.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Smith Machine Sumo Deadlift') limit 1),
            (select id from _ecm_ej2 where alias='Smith Machine Sumo Deadlift'), 2, 10, 15.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Smith Machine Sumo Deadlift') limit 1),
            (select id from _ecm_ej2 where alias='Smith Machine Sumo Deadlift'), 3, 8, 22.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Smith Machine Sumo Deadlift') limit 1),
            (select id from _ecm_ej2 where alias='Smith Machine Sumo Deadlift'), 4, 7, 22.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Hip Thrust Machine') limit 1),
            (select id from _ecm_ej2 where alias='Hip Thrust Machine'), 1, 8, 45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Hip Thrust Machine') limit 1),
            (select id from _ecm_ej2 where alias='Hip Thrust Machine'), 2, 8, 45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Hip Thrust Machine') limit 1),
            (select id from _ecm_ej2 where alias='Hip Thrust Machine'), 3, 8, 45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Hip Thrust Machine') limit 1),
            (select id from _ecm_ej2 where alias='Hip Thrust Machine'), 4, 7, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Seated Leg Extension') limit 1),
            (select id from _ecm_ej2 where alias='Machine Seated Leg Extension'), 1, 12, 54, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Seated Leg Extension') limit 1),
            (select id from _ecm_ej2 where alias='Machine Seated Leg Extension'), 2, 10, 72, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Seated Leg Extension') limit 1),
            (select id from _ecm_ej2 where alias='Machine Seated Leg Extension'), 3, 8, 72, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Seated Hip Adduction') limit 1),
            (select id from _ecm_ej2 where alias='Machine Seated Hip Adduction'), 1, 12, 85, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Seated Hip Adduction') limit 1),
            (select id from _ecm_ej2 where alias='Machine Seated Hip Adduction'), 2, 10, 102.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Seated Hip Adduction') limit 1),
            (select id from _ecm_ej2 where alias='Machine Seated Hip Adduction'), 3, 10, 102.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_ej2 where alias='Machine Seated Calf Raise'), 1, 10, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_ej2 where alias='Machine Seated Calf Raise'), 2, 10, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_ej2 where alias='Machine Seated Calf Raise'), 3, 10, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_ej2 where alias='Machine Seated Calf Raise'), 4, 1, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dip Machine Straight Leg Raise') limit 1),
            (select id from _ecm_ej2 where alias='Dip Machine Straight Leg Raise'), 1, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dip Machine Straight Leg Raise') limit 1),
            (select id from _ecm_ej2 where alias='Dip Machine Straight Leg Raise'), 2, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dip Machine Straight Leg Raise') limit 1),
            (select id from _ecm_ej2 where alias='Dip Machine Straight Leg Raise'), 3, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Seated Machine Ab Crunch') limit 1),
            (select id from _ecm_ej2 where alias='Seated Machine Ab Crunch'), 1, 15, 35, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Seated Machine Ab Crunch') limit 1),
            (select id from _ecm_ej2 where alias='Seated Machine Ab Crunch'), 2, 15, 35, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Seated Machine Ab Crunch') limit 1),
            (select id from _ecm_ej2 where alias='Seated Machine Ab Crunch'), 3, 15, 35, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Seated Machine Ab Crunch') limit 1),
            (select id from _ecm_ej2 where alias='Seated Machine Ab Crunch'), 4, 15, 35, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Horizontal Cable Rotation') limit 1),
            (select id from _ecm_ej2 where alias='Horizontal Cable Rotation'), 1, 15, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Horizontal Cable Rotation') limit 1),
            (select id from _ecm_ej2 where alias='Horizontal Cable Rotation'), 2, 15, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Horizontal Cable Rotation') limit 1),
            (select id from _ecm_ej2 where alias='Horizontal Cable Rotation'), 3, 15, 20, 'kg');
  end if;

  -- Rutina 2: Pull Training
  insert into rutinas (user_id, cliente_id, fase_id, nombre, dia_orden,
                       duracion_estimada_min, tipo_sesion, dias_semana)
  values (v_coach, v_cli, v_fase, 'Pull Training', 2, 55, 'fuerza', array['X']::text[])
  returning id into v_rut;
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Running'), 1, 1, '3 min intensidad moderada', null);
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'A', 'circuito', 2, 30, 1)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Table Top Half Arm Thoracic Rotation'), 2, 1, '5 por lado', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Mini Band Wall Slides'), 3, 1, '8', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Bar Hang'), 4, 2, '40 s', 40);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Pull Up'), 5, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Machine Seated Single Arm Neutral Grip Row'), 6, 4, '6-12 por lado', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Machine Preacher Curl'), 7, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Dumbbell Hammer Curl'), 8, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Cable Single Arm Bicep Curl'), 9, 3, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Cable Rope Face Pull'), 10, 3, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Dumbbell Shrug'), 11, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Suspension Low Back Stretch'), 12, 1, '30 s', null);
  -- historial 2026-09-16
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach, origen)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-16', 1,
          '2026-W38', 'completada', '2026-09-16 12:00:00+00'::timestamptz, true, 'importada')
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Mini Band Wall Slides') limit 1),
            (select id from _ecm_ej2 where alias='Mini Band Wall Slides'), 1, 13, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Mini Band Wall Slides') limit 1),
            (select id from _ecm_ej2 where alias='Mini Band Wall Slides'), 2, 13, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Bar Hang') limit 1),
            (select id from _ecm_ej2 where alias='Bar Hang'), 1, 40, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Bar Hang') limit 1),
            (select id from _ecm_ej2 where alias='Bar Hang'), 2, 40, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Seated Single Arm Neutral Grip Row') limit 1),
            (select id from _ecm_ej2 where alias='Machine Seated Single Arm Neutral Grip Row'), 1, 8, 70, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Seated Single Arm Neutral Grip Row') limit 1),
            (select id from _ecm_ej2 where alias='Machine Seated Single Arm Neutral Grip Row'), 2, 7, 70, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Preacher Curl') limit 1),
            (select id from _ecm_ej2 where alias='Machine Preacher Curl'), 1, 12, 27.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Preacher Curl') limit 1),
            (select id from _ecm_ej2 where alias='Machine Preacher Curl'), 2, 10, 30, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Preacher Curl') limit 1),
            (select id from _ecm_ej2 where alias='Machine Preacher Curl'), 3, 8, 30, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Preacher Curl') limit 1),
            (select id from _ecm_ej2 where alias='Machine Preacher Curl'), 4, 6, 32.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Hammer Curl'), 1, 10, 12.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Hammer Curl'), 2, 10, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Hammer Curl'), 3, 8, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Hammer Curl'), 4, 8, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Single Arm Bicep Curl') limit 1),
            (select id from _ecm_ej2 where alias='Cable Single Arm Bicep Curl'), 1, 10, 23, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Single Arm Bicep Curl') limit 1),
            (select id from _ecm_ej2 where alias='Cable Single Arm Bicep Curl'), 2, 7, 27.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Single Arm Bicep Curl') limit 1),
            (select id from _ecm_ej2 where alias='Cable Single Arm Bicep Curl'), 3, 7, 27.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Rope Face Pull') limit 1),
            (select id from _ecm_ej2 where alias='Cable Rope Face Pull'), 1, 9, 41, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Rope Face Pull') limit 1),
            (select id from _ecm_ej2 where alias='Cable Rope Face Pull'), 2, 9, 41, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable Rope Face Pull') limit 1),
            (select id from _ecm_ej2 where alias='Cable Rope Face Pull'), 3, 9, 41, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Shrug') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Shrug'), 1, 10, 22.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Shrug') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Shrug'), 2, 8, 27.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Shrug') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Shrug'), 3, 8, 27.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Shrug') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Shrug'), 4, 8, 27.5, 'kg');
  end if;

  -- Rutina 3: Push Training
  insert into rutinas (user_id, cliente_id, fase_id, nombre, dia_orden,
                       duracion_estimada_min, tipo_sesion, dias_semana)
  values (v_coach, v_cli, v_fase, 'Push Training', 3, 58, 'fuerza', array['M']::text[])
  returning id into v_rut;
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Running'), 1, 1, 'Caminadora: 3 min intensidad moderada', null);
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'A', 'circuito', 2, 30, 1)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Decline Plank to Pike'), 2, 1, '5', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Dumbbell Standing Shoulder External Rotations'), 3, 1, '5', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='SuperBand Dislocates'), 4, 1, '5', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Dumbbell Incline Bench Press'), 5, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Landmine Half-Kneeling Single Arm Press'), 6, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Dip'), 7, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Machine Seated Chest Fly'), 8, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Machine Lateral Raise'), 9, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Cable V Bar Tricep Pushdown'), 10, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Cable V-Bar Overhead Tricep Extension'), 11, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Child''s Pose'), 12, 1, '30 s', null);
  -- historial 2026-09-15
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach, origen)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-15', 1,
          '2026-W38', 'completada', '2026-09-15 12:00:00+00'::timestamptz, true, 'importada')
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Incline Bench Press'), 1, 10, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Incline Bench Press'), 2, 10, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Incline Bench Press'), 3, 8, 22.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Incline Bench Press'), 4, 8, 22.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Landmine Half-Kneeling Single Arm Press') limit 1),
            (select id from _ecm_ej2 where alias='Landmine Half-Kneeling Single Arm Press'), 1, 10, 10, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Landmine Half-Kneeling Single Arm Press') limit 1),
            (select id from _ecm_ej2 where alias='Landmine Half-Kneeling Single Arm Press'), 2, 8, 10, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Landmine Half-Kneeling Single Arm Press') limit 1),
            (select id from _ecm_ej2 where alias='Landmine Half-Kneeling Single Arm Press'), 3, 7, 12.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Landmine Half-Kneeling Single Arm Press') limit 1),
            (select id from _ecm_ej2 where alias='Landmine Half-Kneeling Single Arm Press'), 4, 7, 12.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dip') limit 1),
            (select id from _ecm_ej2 where alias='Dip'), 1, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dip') limit 1),
            (select id from _ecm_ej2 where alias='Dip'), 2, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dip') limit 1),
            (select id from _ecm_ej2 where alias='Dip'), 3, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dip') limit 1),
            (select id from _ecm_ej2 where alias='Dip'), 4, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Seated Chest Fly') limit 1),
            (select id from _ecm_ej2 where alias='Machine Seated Chest Fly'), 1, 10, 80, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Seated Chest Fly') limit 1),
            (select id from _ecm_ej2 where alias='Machine Seated Chest Fly'), 2, 9, 80, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Seated Chest Fly') limit 1),
            (select id from _ecm_ej2 where alias='Machine Seated Chest Fly'), 3, 8, 80, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Seated Chest Fly') limit 1),
            (select id from _ecm_ej2 where alias='Machine Seated Chest Fly'), 4, 7, 80, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Lateral Raise') limit 1),
            (select id from _ecm_ej2 where alias='Machine Lateral Raise'), 1, 10, 27.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Lateral Raise') limit 1),
            (select id from _ecm_ej2 where alias='Machine Lateral Raise'), 2, 10, 27.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Lateral Raise') limit 1),
            (select id from _ecm_ej2 where alias='Machine Lateral Raise'), 3, 7, 35, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Lateral Raise') limit 1),
            (select id from _ecm_ej2 where alias='Machine Lateral Raise'), 4, 7, 35, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej2 where alias='Cable V Bar Tricep Pushdown'), 1, 10, 23, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej2 where alias='Cable V Bar Tricep Pushdown'), 2, 8, 27, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej2 where alias='Cable V Bar Tricep Pushdown'), 3, 7, 27, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_ej2 where alias='Cable V Bar Tricep Pushdown'), 4, 6, 27, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable V-Bar Overhead Tricep Extension') limit 1),
            (select id from _ecm_ej2 where alias='Cable V-Bar Overhead Tricep Extension'), 1, 8, 45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable V-Bar Overhead Tricep Extension') limit 1),
            (select id from _ecm_ej2 where alias='Cable V-Bar Overhead Tricep Extension'), 2, 8, 45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable V-Bar Overhead Tricep Extension') limit 1),
            (select id from _ecm_ej2 where alias='Cable V-Bar Overhead Tricep Extension'), 3, 8, 45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Cable V-Bar Overhead Tricep Extension') limit 1),
            (select id from _ecm_ej2 where alias='Cable V-Bar Overhead Tricep Extension'), 4, 8, 45, 'kg');
  end if;
  raise notice 'OK: «Santiago Fonseca» · Cycle 2 · 3 rutinas.';
end $cli$;

-- ─────────────────────────────────────────────────────────────────────
-- SEBASTIÁN MOJICA · Cycle 1 · 4 semanas (2026-08-31 → 2026-09-27)
--   En el historial aparece 'Split Squat Pulse' con series, pero YA NO
--   está en la rutina: se lo quitaste después. Entra como historial, no
--   como ejercicio programado.
-- ─────────────────────────────────────────────────────────────────────
do $cli$
declare v_coach uuid; v_cli uuid; v_fase uuid; v_rut uuid; v_blo uuid; v_ses uuid;
begin
  select id, user_id into v_cli, v_coach from clientes where nombre ilike '%sebasti%n%mojica%' limit 1;
  if v_cli is null then
    raise warning 'SALTADO: no encuentro a «Sebastián Mojica» en `clientes` (patrón %%sebasti%%n%%mojica%%). Corrige el nombre y vuelve a correr.';
    return;
  end if;
  if exists (select 1 from fases where cliente_id = v_cli and nombre = 'Cycle 1') then
    raise notice 'SALTADO: «Sebastián Mojica» ya tiene la fase Cycle 1 cargada.';
    return;
  end if;

  insert into fases (user_id, cliente_id, nombre, objetivo, notas_coach, semanas,
                     fecha_inicio, orden, estado)
  values (v_coach, v_cli, 'Cycle 1',
          'Bloque importado de Trainerize — la rutina que ya venía haciendo.',
          'Importado el 2026-09-25 desde el PDF de Trainerize (Cycle 1, 2026-08-31 a 2026-09-27). Revisar antes de enviar al cliente. En el historial aparece ''Split Squat Pulse'' con series, pero YA NO está en la rutina: se lo quitaste después. Entra como historial, no como ejercicio programado.',
          4, date '2026-08-31',
          coalesce((select max(orden)+1 from fases where cliente_id = v_cli), 1), 'borrador')
  returning id into v_fase;

  -- Rutina 1: Lower Body + Core Training
  insert into rutinas (user_id, cliente_id, fase_id, nombre, dia_orden,
                       duracion_estimada_min, tipo_sesion, dias_semana)
  values (v_coach, v_cli, v_fase, 'Lower Body + Core Training', 1, 64, 'fuerza', array['M','J']::text[])
  returning id into v_rut;
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'A', 'circuito', 2, 30, 1)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='90-90 Hip Switch'), 1, 1, '6', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Alternating Spiderman lunge to hip lift'), 2, 1, '6 por lado', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Cossack Squat to T-Spine Reach'), 3, 1, '6 por lado', 30);
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'B', 'circuito', 1, 30, 2)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Lateral Shuttle Run'), 4, 1, '60 s', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Shuttle Run'), 5, 1, '60 s', 30);
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'C', 'circuito', 4, 45, 3)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Dumbbell Bulgarian Split Squat'), 6, 1, '6-12 por lado', 15);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Box Pistol Squat'), 7, 1, '6-12 por lado', 45);
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'D', 'circuito', 4, 45, 4)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Landmine Deadlift'), 8, 1, '6-12', 10);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Box Jump'), 9, 1, '6-8 saltos', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Hip Thrust Machine'), 10, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Machine Seated Calf Raise'), 11, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Seated Machine Ab Crunch'), 12, 4, '8-15', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Horizontal Cable Rotation'), 13, 4, '8-15', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Ab Roller Wheel Abdominal Roll Out'), 14, 3, '8-15', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Static Pigeon Stretch'), 15, 1, '30 s por lado', null);
  -- historial 2026-09-17
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach, origen)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-17', 3,
          '2026-W38', 'completada', '2026-09-17 12:00:00+00'::timestamptz, true, 'importada')
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Bulgarian Split Squat') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Bulgarian Split Squat'), 1, 12, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Bulgarian Split Squat') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Bulgarian Split Squat'), 2, 12, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Bulgarian Split Squat') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Bulgarian Split Squat'), 3, 12, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Bulgarian Split Squat') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Bulgarian Split Squat'), 4, 12, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Split Squat Pulse') limit 1),
            (select id from _ecm_ej2 where alias='Split Squat Pulse'), 1, 12, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Split Squat Pulse') limit 1),
            (select id from _ecm_ej2 where alias='Split Squat Pulse'), 2, 12, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Split Squat Pulse') limit 1),
            (select id from _ecm_ej2 where alias='Split Squat Pulse'), 3, 12, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Split Squat Pulse') limit 1),
            (select id from _ecm_ej2 where alias='Split Squat Pulse'), 4, 12, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Hip Thrust Machine') limit 1),
            (select id from _ecm_ej2 where alias='Hip Thrust Machine'), 1, 12, 120, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Hip Thrust Machine') limit 1),
            (select id from _ecm_ej2 where alias='Hip Thrust Machine'), 2, 12, 120, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Hip Thrust Machine') limit 1),
            (select id from _ecm_ej2 where alias='Hip Thrust Machine'), 3, 12, 120, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Hip Thrust Machine') limit 1),
            (select id from _ecm_ej2 where alias='Hip Thrust Machine'), 4, 12, 120, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_ej2 where alias='Machine Seated Calf Raise'), 1, 12, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_ej2 where alias='Machine Seated Calf Raise'), 2, 12, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_ej2 where alias='Machine Seated Calf Raise'), 3, 12, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_ej2 where alias='Machine Seated Calf Raise'), 4, 12, 40, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Horizontal Cable Rotation') limit 1),
            (select id from _ecm_ej2 where alias='Horizontal Cable Rotation'), 1, 12, 11.25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Horizontal Cable Rotation') limit 1),
            (select id from _ecm_ej2 where alias='Horizontal Cable Rotation'), 2, 12, 13.75, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Horizontal Cable Rotation') limit 1),
            (select id from _ecm_ej2 where alias='Horizontal Cable Rotation'), 3, 12, 13.75, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Horizontal Cable Rotation') limit 1),
            (select id from _ecm_ej2 where alias='Horizontal Cable Rotation'), 4, 12, 13.75, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Ab Roller Wheel Abdominal Roll Out') limit 1),
            (select id from _ecm_ej2 where alias='Ab Roller Wheel Abdominal Roll Out'), 1, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Ab Roller Wheel Abdominal Roll Out') limit 1),
            (select id from _ecm_ej2 where alias='Ab Roller Wheel Abdominal Roll Out'), 2, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Ab Roller Wheel Abdominal Roll Out') limit 1),
            (select id from _ecm_ej2 where alias='Ab Roller Wheel Abdominal Roll Out'), 3, 15, null, 'kg');
  end if;
  -- historial 2026-09-08
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach, origen)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-08', 2,
          '2026-W37', 'completada', '2026-09-08 12:00:00+00'::timestamptz, true, 'importada')
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Bulgarian Split Squat') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Bulgarian Split Squat'), 1, 10, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Bulgarian Split Squat') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Bulgarian Split Squat'), 2, 10, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Bulgarian Split Squat') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Bulgarian Split Squat'), 3, 10, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Dumbbell Bulgarian Split Squat') limit 1),
            (select id from _ecm_ej2 where alias='Dumbbell Bulgarian Split Squat'), 4, 12, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Split Squat Pulse') limit 1),
            (select id from _ecm_ej2 where alias='Split Squat Pulse'), 1, 12, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Split Squat Pulse') limit 1),
            (select id from _ecm_ej2 where alias='Split Squat Pulse'), 2, 12, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Hip Thrust Machine') limit 1),
            (select id from _ecm_ej2 where alias='Hip Thrust Machine'), 1, 12, 120, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Hip Thrust Machine') limit 1),
            (select id from _ecm_ej2 where alias='Hip Thrust Machine'), 2, 12, 120, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Hip Thrust Machine') limit 1),
            (select id from _ecm_ej2 where alias='Hip Thrust Machine'), 3, 12, 120, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Hip Thrust Machine') limit 1),
            (select id from _ecm_ej2 where alias='Hip Thrust Machine'), 4, 10, 120, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_ej2 where alias='Machine Seated Calf Raise'), 1, 15, 130, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_ej2 where alias='Machine Seated Calf Raise'), 2, 12, 150, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_ej2 where alias='Machine Seated Calf Raise'), 3, 12, 150, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_ej2 where alias='Machine Seated Calf Raise'), 4, 12, 150, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Ab Roller Wheel Abdominal Roll Out') limit 1),
            (select id from _ecm_ej2 where alias='Ab Roller Wheel Abdominal Roll Out'), 1, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Ab Roller Wheel Abdominal Roll Out') limit 1),
            (select id from _ecm_ej2 where alias='Ab Roller Wheel Abdominal Roll Out'), 2, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses,
            (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_ej2 where alias='Ab Roller Wheel Abdominal Roll Out') limit 1),
            (select id from _ecm_ej2 where alias='Ab Roller Wheel Abdominal Roll Out'), 3, 15, null, 'kg');
  end if;

  -- Rutina 2: Upper Body
  insert into rutinas (user_id, cliente_id, fase_id, nombre, dia_orden,
                       duracion_estimada_min, tipo_sesion, dias_semana)
  values (v_coach, v_cli, v_fase, 'Upper Body', 2, 77, 'fuerza', '{}'::text[])
  returning id into v_rut;
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Running'), 1, 1, '2-3 min intensidad moderada', null);
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'A', 'circuito', 2, 30, 1)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Table Top Half Arm Thoracic Rotation'), 2, 1, '5 por lado', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Mini Band Wall Slides'), 3, 1, '5', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_ej2 where alias='Dumbbell Standing Shoulder External Rotations'), 4, 1, '5', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Bar Hang'), 5, 1, '60 s', null);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Machine Seated Single Arm Neutral Grip Row'), 6, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Machine Assisted Wide Grip Pull Up'), 7, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Dumbbell Incline Bench Press'), 8, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Machine Assisted Dip'), 9, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Dumbbell Seated Arnold Press'), 10, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Machine Seated Chest Fly'), 11, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Machine Preacher Curl'), 12, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Dumbbell Hammer Curl'), 13, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Cable V Bar Tricep Pushdown'), 14, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Barbell Rear Shrug'), 15, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_ej2 where alias='Child''s Pose'), 16, 1, '30 s', null);
  raise notice 'OK: «Sebastián Mojica» · Cycle 1 · 2 rutinas.';
end $cli$;

-- ═══════════════════════════════════════════════════════════════════════
-- QUÉ QUEDÓ
-- ═══════════════════════════════════════════════════════════════════════
select c.nombre as cliente, f.nombre as fase, f.estado,
       count(distinct r.id) as rutinas,
       array_to_string(f.dias_semana, ' ') as dias,
       count(distinct s.id) as sesiones
  from clientes c
  join fases f on f.cliente_id = c.id
  left join rutinas r on r.fase_id = f.id
  left join sesiones s on s.fase_id = f.id
 where f.notas_coach like '%%Importado el%%'
 group by c.nombre, f.nombre, f.estado, f.dias_semana
 order by c.nombre;

commit;

-- Después de esto, vuelve a correr `4-calendario.sql`: rellena los días de
-- la fase a partir de los de sus rutinas. Es idempotente, no rompe nada.


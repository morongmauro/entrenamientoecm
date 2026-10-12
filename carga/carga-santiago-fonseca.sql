-- ═══════════════════════════════════════════════════════════════════════
-- SANTIAGO FONSECA · su ciclo de Trainerize (en el CRM se llama «Santiago F»)
-- ═══════════════════════════════════════════════════════════════════════
-- Dónde: Supabase del CRM → SQL Editor → pegar TODO → Run.
--
-- Por qué: las tres cargas de Trainerize lo buscaban como «Santiago
-- Fonseca» y en el CRM está como «Santiago F», así que las tres lo saltaron
-- y no le entró nada. Esto es lo mismo que esas tres cargas, SOLO para él,
-- buscándolo como «Santiago F…» (vale «Santiago F» y «Santiago Fonseca»):
--   1. Su Ciclo 2 (14 sep → 18 oct) con sus 3 rutinas (Lower + Core, Push,
--      Pull) y el historial de septiembre.
--   2. El historial del 20 sep al 8 oct y las rutinas como están hoy.
--   3. Lo del 12 oct: sesiones hasta hoy, sus días (L y J Lower · M y V
--      Push · X y S Pull) y el ciclo enviado a su app.
-- No toca a ningún otro cliente. Se puede correr dos veces: lo que ya
-- entró se salta solo.
-- ═══════════════════════════════════════════════════════════════════════

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
-- SANTIAGO FONSECA · Cycle 2 · 5 semanas (2026-09-14 → 2026-10-18)
--   En el historial del 16 sep, 'Mini Band Wall Slides' serie 1 dice 133
--   reps (la 2 dice 13). Es un dedazo suyo. Lo cargo como 13 y te lo
--   aviso.
-- ─────────────────────────────────────────────────────────────────────
do $cli$
declare v_coach uuid; v_cli uuid; v_fase uuid; v_rut uuid; v_blo uuid; v_ses uuid;
begin
  select id, user_id into v_cli, v_coach from clientes where nombre ilike '%santiago f%' limit 1;
  if v_cli is null then
    raise warning 'SALTADO: no encuentro a «Santiago Fonseca» en `clientes` (patrón %%santiago f%%). Corrige el nombre y vuelve a correr.';
    return;
  end if;
  if exists (select 1 from fases where cliente_id = v_cli and nombre in ('Cycle 2', 'Ciclo 2')) then
    raise notice 'SALTADO: «Santiago Fonseca» ya tiene la fase Cycle 2 cargada.';
    return;
  end if;

  insert into fases (user_id, cliente_id, nombre, objetivo, notas_coach, semanas,
                     fecha_inicio, orden, estado)
  values (v_coach, v_cli, 'Cycle 2',
          null,
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

select c.nombre as cliente, f.nombre as fase, f.estado, count(distinct r.id) as rutinas
  from clientes c join fases f on f.cliente_id = c.id left join rutinas r on r.fase_id = f.id
 where c.nombre ilike '%santiago f%'
 group by c.nombre, f.nombre, f.estado;

commit;


-- ═══════════════════════════════════════════════════════════════════════
-- CARGA DE TRAINERIZE · exportado el 10 oct 2026 · 15 clientes
-- ═══════════════════════════════════════════════════════════════════════
-- Dónde: Supabase del CRM → SQL Editor → pegar todo → Run.
-- Al final sale una tabla con una fila por cliente diciendo qué hizo.
--
-- QUÉ HACE
--   1. Guarda una FOTO de Trainerize por cliente (tabla nueva
--      `trainerize_resumen`): ciclo, cumplimiento 6/14, días de fuerza,
--      cardio programado y, por rutina, cada ejercicio con lo prescrito y su
--      último registro (reps @ peso, fecha, si es del ciclo anterior, ⚠).
--      Es lo que el CRM pone AL LADO de lo tuyo para que decidas.
--   2. Mete el HISTORIAL nuevo (las sesiones del 20 sep al 8 oct que no
--      estaban) como sesiones completadas `origen = 'importada'`, con sus
--      series. Así el CRM y la app conocen los últimos pesos.
--   3. Crea las 3 FASES que todavía no estaban (Andrea Ciclo 9, David
--      Ciclo 18, Sebastián Mojica Ciclo 2) como BORRADOR: el cliente no ve
--      nada hasta que tú la publiques.
--   4. Corrige las rutinas que cambiaste en Trainerize después del 19 sep
--      (Julio: Upper; Santiago: Push y Pull), SOLO si en el CRM siguen
--      exactamente como se importaron y el cliente todavía no las ve. Si ya
--      las tocaste en el CRM o ya están publicadas, no las toca y te lo dice
--      en la tabla del final.
--   5. Crea en la galería el único ejercicio que faltaba (Muscle Up Tutorial).
--
-- QUÉ NO HACE (a propósito)
--   · No borra ni cambia videos, fichas, fases publicadas ni seguimientos.
--   · No pisa nada que hayas escrito: si una sesión de ese día ya existe
--     (importada antes o marcada por el cliente en su app), se salta.
--   · El historial importado NO se suma solo a tu performance: el CRM lo
--     muestra al lado («📦 De su historial de Trainerize … usar»).
--   · Los registros con ⚠ (un Bar Hang de 40 minutos, un curl de 59 kg)
--     NO entran al historial: le saldrían al cliente como récord. Quedan en
--     la foto con su ⚠ para que los veas.
--   · Lo marcado «ciclo anterior» tampoco entra como sesión (no se sabe de
--     qué rutina vieja era); queda en la foto y el asistente lo usa.
--
-- SE PUEDE CORRER DOS VECES: la segunda no duplica nada.
-- Necesita migracion-calendario.sql (ya corrido en las cargas anteriores).
-- ═══════════════════════════════════════════════════════════════════════

do $guard$
begin
  if not exists (select 1 from information_schema.columns
                  where table_name='rutinas' and column_name='dias_semana') then
    raise exception 'Falta la columna `rutinas.dias_semana`. Corre primero carga/migracion-calendario.sql.';
  end if;
  if not exists (select 1 from information_schema.columns
                  where table_name='sesiones' and column_name='origen') then
    raise exception 'Falta la columna `sesiones.origen`. Corre primero carga/migracion-calendario.sql.';
  end if;
end $guard$;

begin;

-- ── 1. La foto de Trainerize ────────────────────────────────────────────
create table if not exists trainerize_resumen (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  cliente_id uuid not null references clientes(id) on delete cascade,
  exportado date not null,              -- qué día se sacó de Trainerize
  trainerize_id text,
  ciclo text, inicio date, fin date,
  hechas int, programadas int,          -- cumplimiento de fuerza del ciclo
  dias_fuerza text[] default '{}',      -- L M X J V S D, como clientes.dias_entreno
  fase_id uuid references fases(id) on delete set null,
  datos jsonb not null default '{}',    -- estructura, calendario, cardio y rutinas con su último registro
  created_at timestamptz default now(),
  unique (cliente_id, exportado)
);
create index if not exists trainerize_resumen_cli_idx on trainerize_resumen (cliente_id, exportado desc);

alter table trainerize_resumen enable row level security;
drop policy if exists trainerize_resumen_propios on trainerize_resumen;
create policy trainerize_resumen_propios on trainerize_resumen for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

comment on table trainerize_resumen is
  'Foto de Trainerize por cliente (export del coach). Solo lectura para el CRM: cumplimiento, días, cardio y últimos registros por ejercicio. No la ve el cliente.';

-- ── 2. Ayudantes (solo viven mientras corre este archivo) ───────────────

-- La ficha de un ejercicio por su nombre de Trainerize. Si hay dos fichas
-- con el mismo nombre, gana la que ya usa este cliente, luego la que tiene
-- video y luego la más vieja. Si no existe, la crea (sin video).
create or replace function pg_temp.ecm_tz_ej(p_coach uuid, p_cli uuid, p_alias text) returns uuid
language plpgsql as $fn$
declare v_id uuid;
begin
  select e.id into v_id from ejercicios e
   where e.user_id = p_coach
     and (e.alias = p_alias or lower(e.nombre) = lower(p_alias))
   order by coalesce(e.archivado, false),
            exists (select 1 from rutina_ejercicios re join rutinas r on r.id = re.rutina_id
                     where re.ejercicio_id = e.id and r.cliente_id = p_cli) desc,
            (coalesce(e.video_fuente, 'ninguno') <> 'ninguno') desc,
            e.created_at
   limit 1;
  if v_id is not null then return v_id; end if;
  insert into ejercicios (user_id, nombre, alias, tipo, segmento, patron, equipo, unilateral, nivel, tags)
  values (p_coach,
          case p_alias when 'Muscle Up Tutorial' then 'Muscle up (progresión)' else p_alias end,
          p_alias,
          'fuerza',
          case when p_alias ~* 'muscle up|pull|row|curl|press|push|dip|tricep|bicep|shoulder|chest' then 'tren_superior' else null end,
          case when p_alias ~* 'muscle up|pull|row|curl' then 'pull' else null end,
          case when p_alias ~* 'muscle up|pull up|bar hang' then array['pull_up_bar'] else '{}'::text[] end,
          false, 'intermedio', array['importado-trainerize'])
  returning id into v_id;
  return v_id;
end $fn$;

-- La línea de una rutina que corresponde a un ejercicio de Trainerize
-- (la primera que no se haya usado ya: hay rutinas con el mismo ejercicio
-- dos veces, como el Shuttle Run en dos circuitos).
create or replace function pg_temp.ecm_tz_linea(p_rut uuid, p_alias text, p_es text, p_usadas uuid[]) returns rutina_ejercicios
language sql as $fn$
  select re.* from rutina_ejercicios re join ejercicios e on e.id = re.ejercicio_id
   where re.rutina_id = p_rut
     and (e.alias = p_alias or lower(e.nombre) = lower(p_alias) or lower(e.nombre) = lower(p_es))
     and not (re.id = any(coalesce(p_usadas, '{}')))
   order by (e.alias = p_alias) desc, re.orden, re.created_at
   limit 1;
$fn$;

-- ¿La rutina del CRM tiene exactamente esta lista, en este orden? Un
-- ejercicio cuenta como el mismo por su nombre de Trainerize o por el nombre
-- en español con que lo creó la carga anterior (algunas fichas se
-- reconocieron con otro nombre: «Squat to Hinge» quedó en la ficha de
-- «Bodyweight Squat To Hinge»).
create or replace function pg_temp.ecm_tz_igual(p_rut uuid, p_lista jsonb) returns boolean
language sql as $fn$
  with crm as (
    select row_number() over (order by re.orden, re.created_at) as i, e.alias as ca, e.nombre as cn
      from rutina_ejercicios re join ejercicios e on e.id = re.ejercicio_id
     where re.rutina_id = p_rut),
  l as (select t.i, t.x->>'alias' as a, t.x->>'es' as s from jsonb_array_elements(p_lista) with ordinality as t(x, i))
  select (select count(*) from crm) = (select count(*) from l)
     and not exists (select 1 from l join crm on crm.i = l.i
                      where not (crm.ca is not distinct from l.a or lower(crm.cn) = lower(l.a)
                                 or (l.s is not null and lower(crm.cn) = lower(l.s))));
$fn$;

-- Arma una rutina nueva entera (para las fases que no estaban).
create or replace function pg_temp.ecm_tz_armar(p_coach uuid, p_cli uuid, p_rut uuid, p_r jsonb) returns void
language plpgsql as $fn$
declare b jsonb; e jsonb; v_blo uuid; i int := 0; letras text := 'ABCDEFGHIJKLMNOP';
begin
  create temp table if not exists _tz_blo (ss int primary key, id uuid) on commit drop;
  delete from _tz_blo;
  for b in select * from jsonb_array_elements(p_r->'bloques') loop
    i := i + 1;
    insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
    values (p_rut, substr(letras, i, 1), b->>'tipo', (b->>'vueltas')::int, (b->>'descanso')::int, i)
    returning id into v_blo;
    insert into _tz_blo values ((b->>'ss')::int, v_blo);
  end loop;
  for e in select * from jsonb_array_elements(p_r->'ejercicios') loop
    insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
    values (p_rut,
            (select id from _tz_blo where ss = (e->>'ss')::int),
            pg_temp.ecm_tz_ej(p_coach, p_cli, e->>'alias'),
            (e->>'n')::int, (e->>'series')::int, e->>'reps', (e->>'descanso')::int);
  end loop;
end $fn$;

-- Pone una rutina que existe igual que en Trainerize: saca lo que ya no
-- está, mete lo nuevo en su sitio y reordena. Solo se llama cuando la rutina
-- sigue EXACTAMENTE como se importó (no la tocaste en el CRM). El historial
-- de lo que sale no se pierde: las series guardan su propio ejercicio.
create or replace function pg_temp.ecm_tz_corregir(p_coach uuid, p_cli uuid, p_rut uuid, p_r jsonb) returns text
language plpgsql as $fn$
declare e jsonb; l rutina_ejercicios; usadas uuid[] := '{}'; v_blo uuid; sale text[] := '{}'; entra text[] := '{}';
        hermano jsonb; v_n int;
begin
  for e in select * from jsonb_array_elements(p_r->'ejercicios') order by (value->>'n')::int loop
    l := pg_temp.ecm_tz_linea(p_rut, e->>'alias', e->>'es', usadas);
    if l.id is not null then
      update rutina_ejercicios set orden = (e->>'n')::int where id = l.id;
      usadas := usadas || l.id;
    end if;
  end loop;
  select array_agg(coalesce(ej.alias, ej.nombre)) into sale
    from rutina_ejercicios re join ejercicios ej on ej.id = re.ejercicio_id
   where re.rutina_id = p_rut and not (re.id = any(usadas));
  delete from rutina_ejercicios where rutina_id = p_rut and not (id = any(usadas));
  for e in select * from jsonb_array_elements(p_r->'ejercicios') order by (value->>'n')::int loop
    if exists (select 1 from rutina_ejercicios where rutina_id = p_rut and orden = (e->>'n')::int) then continue; end if;
    v_blo := null;
    if e->>'ss' is not null then
      -- Al bloque de sus compañeros de superserie, si ya hay uno.
      select re.bloque_id into v_blo from rutina_ejercicios re
       where re.rutina_id = p_rut and re.bloque_id is not null
         and re.orden in (select (x->>'n')::int from jsonb_array_elements(p_r->'ejercicios') x
                           where x->>'ss' = e->>'ss' and x->>'n' <> e->>'n')
       limit 1;
      if v_blo is null then
        select b into hermano from jsonb_array_elements(p_r->'bloques') b where b->>'ss' = e->>'ss';
        select coalesce(max(orden), 0) + 1 into v_n from rutina_bloques where rutina_id = p_rut;
        insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
        values (p_rut, chr(64 + v_n), coalesce(hermano->>'tipo', 'superserie'), (hermano->>'vueltas')::int, (hermano->>'descanso')::int, v_n)
        returning id into v_blo;
      end if;
    end if;
    insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
    values (p_rut, v_blo, pg_temp.ecm_tz_ej(p_coach, p_cli, e->>'alias'),
            (e->>'n')::int, (e->>'series')::int, e->>'reps', (e->>'descanso')::int);
    entra := entra || (e->>'alias');
  end loop;
  -- Bloques que quedaron vacíos.
  delete from rutina_bloques b where b.rutina_id = p_rut
     and not exists (select 1 from rutina_ejercicios re where re.bloque_id = b.id);
  update rutinas set notas_coach = concat_ws(E'\n', nullif(notas_coach, ''),
         'Puesta igual que en Trainerize (export 10 oct 2026). Sale: ' || coalesce(array_to_string(sale, ', '), '—')
         || '. Entra: ' || coalesce(nullif(array_to_string(entra, ', '), ''), '—') || '.'),
         updated_at = now()
   where id = p_rut;
  return 'sale ' || coalesce(array_to_string(sale, ', '), '—') || ' · entra ' || coalesce(nullif(array_to_string(entra, ', '), ''), '—');
end $fn$;

-- Un cliente entero.
create or replace function pg_temp.ecm_tz_cliente(p_patron text, d jsonb)
returns table (cliente text, ciclo text, fase text, sesiones_nuevas int, series_nuevas int, cambios text)
language plpgsql as $fn$
declare
  v_cli uuid; v_coach uuid; v_nombre text; v_fase uuid; v_fase_nombre text; v_nueva boolean := false;
  r jsonb; e jsonb; v_rut uuid; v_ses uuid; v_fecha date; l rutina_ejercicios; usadas uuid[];
  n_ses int := 0; n_ser int := 0; notas text[] := '{}'; v_ej uuid; s jsonb; k int; v_ini date;
begin
  select c.id, c.user_id, c.nombre into v_cli, v_coach, v_nombre from clientes c
   where c.nombre ilike p_patron
      or exists (select 1 from unnest(coalesce(c.nombres_alternos, '{}')) a where a ilike p_patron)
   order by (c.nombre ilike p_patron) desc, c.created_at
   limit 1;
  if v_cli is null then
    return query select d->>'nombre', d->>'ciclo', null::text, 0, 0,
      format('SALTADO: no lo encuentro en clientes (busqué %s). Corrige el patrón y vuelve a correr.', p_patron);
    return;
  end if;
  v_ini := (d->>'inicio')::date;

  -- La fase de ese ciclo: por nombre («Cycle 3» o «Ciclo 3») o por la fecha de inicio.
  select f.id, f.nombre into v_fase, v_fase_nombre from fases f
   where f.cliente_id = v_cli and coalesce(f.estado, '') <> 'archivada'
     and (f.nombre ~* ('^\s*(cycle|ciclo)\s*' || (d->>'num') || '\s*$') or f.fecha_inicio = v_ini)
   order by (f.nombre ~* ('^\s*(cycle|ciclo)\s*' || (d->>'num') || '\s*$')) desc, f.created_at
   limit 1;

  if v_fase is null then
    v_nueva := true;
    v_fase_nombre := 'Ciclo ' || (d->>'num');
    insert into fases (user_id, cliente_id, nombre, objetivo, notas_coach, semanas, fecha_inicio, dias_semana, orden, estado)
    values (v_coach, v_cli, v_fase_nombre, null,
            format('Importado el 11 oct 2026 del export de Trainerize del 10 oct (%s, %s a %s). Revisar antes de enviar al cliente.',
                   d->>'ciclo', d->>'inicio', d->>'fin'),
            (d->>'semanas')::int, v_ini,
            array(select jsonb_array_elements_text(d->'dias_fuerza')),
            coalesce((select max(orden) + 1 from fases where cliente_id = v_cli), 1), 'borrador')
    returning id into v_fase;
    k := 0;
    for r in select * from jsonb_array_elements(d->'rutinas') loop
      k := k + 1;
      insert into rutinas (user_id, cliente_id, fase_id, nombre, dia_orden, duracion_estimada_min, tipo_sesion, dias_semana)
      values (v_coach, v_cli, v_fase, r->>'nombre', k, (r->>'duracion')::int,
              case when r->>'nombre' ~* 'mobility|movilidad|flow' then 'movilidad' else 'fuerza' end,
              array(select jsonb_array_elements_text(r->'dias')))
      returning id into v_rut;
      perform pg_temp.ecm_tz_armar(v_coach, v_cli, v_rut, r);
    end loop;
    notas := notas || ('fase nueva en borrador con ' || k || ' rutinas');
  end if;

  -- Por rutina: corregir si cambió en Trainerize, y meter el historial.
  for r in select * from jsonb_array_elements(d->'rutinas') loop
    select ru.id into v_rut from rutinas ru
     where ru.fase_id = v_fase and lower(btrim(ru.nombre)) = lower(btrim(r->>'nombre'))
       and coalesce(ru.archivada, false) = false
     order by ru.dia_orden limit 1;
    if v_rut is null then
      notas := notas || format('«%s» no está en la fase del CRM: su historial queda solo en la foto', r->>'nombre');
      continue;
    end if;

    if not v_nueva and not pg_temp.ecm_tz_igual(v_rut, r->'ejercicios') then
      if coalesce((select coalesce(ru.visible_cliente, f.visible_cliente) from rutinas ru join fases f on f.id = ru.fase_id where ru.id = v_rut), false) then
        notas := notas || format('%s: cambió en Trainerize, pero el cliente ya la ve en su app; no la toqué (cámbiala tú si quieres)', r->>'nombre');
      elsif r ? 'antes' and pg_temp.ecm_tz_igual(v_rut, r->'antes') then
        notas := notas || format('%s corregida (%s)', r->>'nombre', pg_temp.ecm_tz_corregir(v_coach, v_cli, v_rut, r));
      else
        notas := notas || format('%s: no coincide con Trainerize y ya la editaste en el CRM, no la toqué', r->>'nombre');
      end if;
    end if;

    -- Historial: una sesión por fecha con lo que se registró ese día.
    for v_fecha in
      select distinct (x->>'fecha')::date from jsonb_array_elements(r->'ejercicios') x
       where x ? 'fecha' and not coalesce((x->>'anterior')::boolean, false) and not (x ? 'alerta')
       order by 1
    loop
      v_ses := null;
      insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num, semana_iso,
                            estado, finalizada_en, vista_por_coach, origen)
      values (v_coach, v_cli, v_rut, v_fase, v_fecha,
              greatest(1, ((v_fecha - v_ini) / 7) + 1),
              to_char(v_fecha, 'IYYY-"W"IW'),
              'completada', ((v_fecha + time '12:00') at time zone 'UTC'), true, 'importada')
      on conflict do nothing
      returning id into v_ses;
      if v_ses is null then continue; end if;   -- ya había sesión ese día: no se toca
      n_ses := n_ses + 1;
      usadas := '{}';
      for e in select * from jsonb_array_elements(r->'ejercicios') x
                where x->>'fecha' = v_fecha::text and not coalesce((x->>'anterior')::boolean, false) and not (x ? 'alerta')
                order by (x->>'n')::int
      loop
        l := pg_temp.ecm_tz_linea(v_rut, e->>'alias', e->>'es', usadas);
        if l.id is not null then usadas := usadas || l.id; v_ej := l.ejercicio_id;
        else v_ej := pg_temp.ecm_tz_ej(v_coach, v_cli, e->>'alias'); end if;
        k := 0;
        for s in select * from jsonb_array_elements(e->'hist') loop
          k := k + 1;
          -- [reps o segundos, kg]. Las series en 0 o sin reps no se hicieron.
          if s->>0 is null or (s->>0)::int = 0 then continue; end if;
          insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad, notas)
          values (v_ses, l.id, v_ej, k, (s->>0)::int, (s->>1)::numeric, 'kg',
                  case when coalesce((e->>'tiempo')::boolean, false) then 'segundos' end);
          n_ser := n_ser + 1;
        end loop;
      end loop;
    end loop;
  end loop;

  -- La foto (se reemplaza si corres esto otra vez: es la del mismo export).
  insert into trainerize_resumen (user_id, cliente_id, exportado, trainerize_id, ciclo, inicio, fin, hechas, programadas,
                                  dias_fuerza, fase_id, datos)
  values (v_coach, v_cli, date '2026-10-10', d->>'trainerize_id', d->>'ciclo', v_ini, (d->>'fin')::date,
          (d->>'hechas')::int, (d->>'programadas')::int,
          array(select jsonb_array_elements_text(d->'dias_fuerza')), v_fase,
          jsonb_build_object('estructura', d->'estructura', 'calendario', d->'calendario', 'cardio', d->'cardio',
                             'rutinas', (select jsonb_agg(x - 'antes' - 'bloques') from jsonb_array_elements(d->'rutinas') x)))
  on conflict (cliente_id, exportado) do update
    set ciclo = excluded.ciclo, inicio = excluded.inicio, fin = excluded.fin, hechas = excluded.hechas,
        programadas = excluded.programadas, dias_fuerza = excluded.dias_fuerza, fase_id = excluded.fase_id,
        datos = excluded.datos, trainerize_id = excluded.trainerize_id;

  return query select v_nombre, d->>'ciclo', v_fase_nombre || case when v_nueva then ' (nueva, borrador)' else '' end,
                      n_ses, n_ser, coalesce(nullif(array_to_string(notas, ' · '), ''), 'ok');
end $fn$;

-- La tabla del resumen vive hasta que se cierra la conexión (no hasta el
-- commit): así se puede mostrar DESPUÉS de guardar, como último resultado,
-- que es el que enseña el editor de Supabase.
drop table if exists _tz_res;
create temp table _tz_res (cliente text, ciclo text, fase text, sesiones_nuevas int, series_nuevas int, cambios text);














-- Santiago Fonseca · Cycle 2 (2026-09-14 → 2026-10-18) · 21/24
insert into _tz_res select * from pg_temp.ecm_tz_cliente('%santiago f%', $tz${"nombre":"Santiago Fonseca","trainerize_id":"30858078","ciclo":"Cycle 2","num":2,"inicio":"2026-09-14","fin":"2026-10-18","semanas":5,"hechas":21,"programadas":24,"estructura":"Lower Body + Core Training / Push Training / Pull Training","calendario":"Lun: Lower Body + Core Training · Mar: Push Training · Mié: Pull Training · Jue: Lower Body + Core Training · Vie: Push Training · Sáb: Pull Training","cardio":[{"tipo":"Walking","dias":["L","M","X","J","V","S","D"],"hechas":1,"programadas":27},{"tipo":"Running","dias":["L","M","X","J","V","S"],"hechas":0,"programadas":24}],"dias_fuerza":["L","M","X","J","V","S"],"rutinas":[{"nombre":"Lower Body + Core Training","dias":["L","J"],"hechas":8,"programadas":8,"ultima":"2026-10-08","duracion":69,"bloques":[{"ss":1,"tipo":"superserie","vueltas":2,"descanso":30},{"ss":2,"tipo":"circuito","vueltas":2,"descanso":30}],"ejercicios":[{"n":1,"alias":"90-90 Hip Switch","es":"Cambio de cadera 90-90","ss":1,"vueltas":2,"series":1,"reps":"6","descanso":30,"prescrito":"2× 6 reps","ultimo":"2× 6 (2026-10-08)","fecha":"2026-10-08","anterior":false,"hist":[[6,null],[6,null]]},{"n":2,"alias":"Cossack Squat to T-Spine Reach","es":"Sentadilla cosaco con alcance torácico","ss":1,"vueltas":2,"series":1,"reps":"6 por lado","descanso":30,"prescrito":"2× 6 reps ea. side","ultimo":"2× 6 (2026-10-08)","fecha":"2026-10-08","anterior":false,"hist":[[6,null],[6,null]]},{"n":3,"alias":"1/2 Kneel to High Knee Hop","es":"Salto de rodilla alta desde media rodilla","ss":2,"vueltas":2,"series":1,"reps":"6 por lado","descanso":30,"prescrito":"2× 6 reps ea. side","ultimo":"2× 6 (2026-10-08)","fecha":"2026-10-08","anterior":false,"hist":[[6,null],[6,null]]},{"n":4,"alias":"1/2 Kneel to Lateral Bound","es":"Salto lateral desde media rodilla","ss":2,"vueltas":2,"series":1,"reps":"8","descanso":30,"prescrito":"2× 8 reps","ultimo":"2× 6 (2026-10-08)","fecha":"2026-10-08","anterior":false,"hist":[[6,null],[6,null]]},{"n":5,"alias":"Shuttle Run","es":"Ida y vuelta corta","ss":2,"vueltas":2,"series":1,"reps":"60 s","descanso":30,"prescrito":"2× 60 secs","ultimo":"2× 60 (2026-10-08)","fecha":"2026-10-08","anterior":false,"hist":[[60,null],[60,null]]},{"n":6,"alias":"Angled Machine Leg Press","es":"Prensa inclinada","ss":null,"vueltas":4,"series":4,"reps":"6-12","descanso":50,"prescrito":"4× 6-12 reps","ultimo":"10 @ 70kg, 10 @ 70kg, 10 @ 70kg, 8 @ 70kg (2026-10-08)","fecha":"2026-10-08","anterior":false,"hist":[[10,70.0],[10,70.0],[10,70.0],[8,70.0]]},{"n":7,"alias":"Smith Machine Sumo Deadlift","es":"Peso muerto sumo en multipower","ss":null,"vueltas":4,"series":4,"reps":"6-12","descanso":50,"prescrito":"4× 6-12 reps","ultimo":"10 @ 17.5kg, 9 @ 17.5kg, 9 @ 17.5kg, 9 @ 17.5kg (2026-10-05)","fecha":"2026-10-05","anterior":false,"hist":[[10,17.5],[9,17.5],[9,17.5],[9,17.5]]},{"n":8,"alias":"Hip Thrust Machine","es":"Hip thrust en máquina","ss":null,"vueltas":4,"series":4,"reps":"6-12","descanso":50,"prescrito":"4× 6-12 reps","ultimo":"8 @ 45kg, 8 @ 45kg, 8 @ 45kg, 7 @ 45kg (2026-10-08)","fecha":"2026-10-08","anterior":false,"hist":[[8,45.0],[8,45.0],[8,45.0],[7,45.0]]},{"n":9,"alias":"Machine Seated Leg Extension","es":"Extensión de cuádriceps en máquina","ss":null,"vueltas":3,"series":3,"reps":"6-12","descanso":50,"prescrito":"3× 6-12 reps","ultimo":"10 @ 70kg, 9 @ 80kg, 9 @ 80kg (2026-10-08)","fecha":"2026-10-08","anterior":false,"hist":[[10,70.0],[9,80.0],[9,80.0]]},{"n":10,"alias":"Machine Seated Hip Adduction","es":"Aductores en máquina","ss":null,"vueltas":3,"series":3,"reps":"6-12","descanso":50,"prescrito":"3× 6-12 reps","ultimo":"3× 10 @ 110kg (2026-10-08)","fecha":"2026-10-08","anterior":false,"hist":[[10,110.0],[10,110.0],[10,110.0]]},{"n":11,"alias":"Machine Seated Calf Raise","es":"Gemelo sentado en máquina","ss":null,"vueltas":4,"series":4,"reps":"6-12","descanso":50,"prescrito":"4× 6-12 reps","ultimo":"4× 10 @ 22.5kg (2026-10-08)","fecha":"2026-10-08","anterior":false,"hist":[[10,22.5],[10,22.5],[10,22.5],[10,22.5]]},{"n":12,"alias":"Dip Machine Straight Leg Raise","es":"Elevación de piernas rectas en paralelas","ss":null,"vueltas":3,"series":3,"reps":"15","descanso":50,"prescrito":"3× 15 reps","ultimo":"3× 15 (2026-10-08)","fecha":"2026-10-08","anterior":false,"hist":[[15,null],[15,null],[15,null]]},{"n":13,"alias":"Seated Machine Ab Crunch","es":"Crunch abdominal en máquina","ss":null,"vueltas":4,"series":4,"reps":"15","descanso":30,"prescrito":"4× 15 reps","ultimo":"4× 15 (2026-10-08)","fecha":"2026-10-08","anterior":false,"hist":[[15,null],[15,null],[15,null],[15,null]]},{"n":14,"alias":"Horizontal Cable Rotation","es":"Rotación horizontal en polea","ss":null,"vueltas":3,"series":3,"reps":"15","descanso":30,"prescrito":"3× 15 reps","ultimo":"15 @ 20kg, 12 @ 20kg, 12 @ 20kg (2026-10-08)","fecha":"2026-10-08","anterior":false,"hist":[[15,20.0],[12,20.0],[12,20.0]]},{"n":15,"alias":"Static Pigeon Stretch","es":"Estiramiento de paloma","ss":null,"vueltas":1,"series":1,"reps":"30 s por lado","descanso":null,"prescrito":"1× 30 secs ea. side","ultimo":"sin registro"}],"antes":[{"alias":"90-90 Hip Switch","es":"Cambio de cadera 90-90"},{"alias":"Cossack Squat to T-Spine Reach","es":"Sentadilla cosaco con alcance torácico"},{"alias":"1/2 Kneel to High Knee Hop","es":"Salto de rodilla alta desde media rodilla"},{"alias":"1/2 Kneel to Lateral Bound","es":"Salto lateral desde media rodilla"},{"alias":"Shuttle Run","es":"Ida y vuelta corta"},{"alias":"Angled Machine Leg Press","es":"Prensa inclinada"},{"alias":"Smith Machine Sumo Deadlift","es":"Peso muerto sumo en multipower"},{"alias":"Hip Thrust Machine","es":"Hip thrust en máquina"},{"alias":"Machine Seated Leg Extension","es":"Extensión de cuádriceps en máquina"},{"alias":"Machine Seated Hip Adduction","es":"Aductores en máquina"},{"alias":"Machine Seated Calf Raise","es":"Gemelo sentado en máquina"},{"alias":"Dip Machine Straight Leg Raise","es":"Elevación de piernas rectas en paralelas"},{"alias":"Seated Machine Ab Crunch","es":"Crunch abdominal en máquina"},{"alias":"Horizontal Cable Rotation","es":"Rotación horizontal en polea"},{"alias":"Static Pigeon Stretch","es":"Estiramiento de paloma"}]},{"nombre":"Push Training","dias":["M","V"],"hechas":7,"programadas":8,"ultima":"2026-10-06","duracion":58,"bloques":[{"ss":1,"tipo":"superserie","vueltas":2,"descanso":30}],"ejercicios":[{"n":1,"alias":"Running","es":"Carrera continua","ss":null,"vueltas":1,"series":1,"reps":"Caminadora: 3 min intensidad moderada","descanso":45,"prescrito":"1× Treadmill: 3 minutes at a moderate intensity","ultimo":"1× 1500s (2026-09-15) ⚠ tiempo atípico","fecha":"2026-09-15","anterior":false,"hist":[[1500,null]],"alerta":"tiempo atípico","tiempo":true},{"n":2,"alias":"Dumbbell Standing Shoulder External Rotations","es":"Rotación externa de hombro de pie","ss":1,"vueltas":2,"series":1,"reps":"6","descanso":30,"prescrito":"2× 6 reps","ultimo":"2× 6 (2026-10-06)","fecha":"2026-10-06","anterior":false,"hist":[[6,null],[6,null]]},{"n":3,"alias":"SuperBand Dislocates","es":"Dislocaciones de hombro con banda","ss":1,"vueltas":2,"series":1,"reps":"6","descanso":30,"prescrito":"2× 6 reps","ultimo":"sin registro"},{"n":4,"alias":"Clapping Push Up","es":"Flexión con palmada","ss":null,"vueltas":2,"series":2,"reps":"6-8","descanso":45,"prescrito":"2× 6-8 reps","ultimo":"2× 6 (2026-10-06)","fecha":"2026-10-06","anterior":false,"hist":[[6,null],[6,null]]},{"n":5,"alias":"Dumbbell Incline Bench Press","es":"Press inclinado con mancuernas","ss":null,"vueltas":4,"series":4,"reps":"6-12","descanso":45,"prescrito":"4× 6-12 reps","ultimo":"12 @ 20kg, 10 @ 20kg, 9 @ 20kg, 9 @ 20kg (2026-10-06)","fecha":"2026-10-06","anterior":false,"hist":[[12,20.0],[10,20.0],[9,20.0],[9,20.0]]},{"n":6,"alias":"Dip","es":"Fondos en paralelas","ss":null,"vueltas":4,"series":4,"reps":"6-12","descanso":45,"prescrito":"4× 6-12 reps","ultimo":"4× 9 (2026-10-06)","fecha":"2026-10-06","anterior":false,"hist":[[9,null],[9,null],[9,null],[9,null]]},{"n":7,"alias":"Machine Seated Chest Fly","es":"Aperturas en máquina","ss":null,"vueltas":4,"series":4,"reps":"6-12","descanso":45,"prescrito":"4× 6-12 reps","ultimo":"10 @ 72kg, 10 @ 72kg, 9 @ 72kg, 7 @ 80kg (2026-10-06)","fecha":"2026-10-06","anterior":false,"hist":[[10,72.0],[10,72.0],[9,72.0],[7,80.0]]},{"n":8,"alias":"Dumbbell Seated Arnold Press","es":"Press Arnold sentado","ss":null,"vueltas":4,"series":4,"reps":"6-12","descanso":45,"prescrito":"4× 6-12 reps","ultimo":"12 @ 12.5kg, 10 @ 12.5kg, 8 @ 12.5kg, 9 @ 12.5kg (2026-10-06)","fecha":"2026-10-06","anterior":false,"hist":[[12,12.5],[10,12.5],[8,12.5],[9,12.5]]},{"n":9,"alias":"Cable Lateral Raise","es":"Elevación lateral en polea","ss":null,"vueltas":4,"series":4,"reps":"6-12 por lado","descanso":45,"prescrito":"4× 6-12 reps ea. side","ultimo":"12 @ 3.7kg, 10 @ 6.25kg, 9 @ 6.25kg, 9 @ 6.25kg (2026-10-06)","fecha":"2026-10-06","anterior":false,"hist":[[12,3.7],[10,6.25],[9,6.25],[9,6.25]]},{"n":10,"alias":"Cable V Bar Tricep Pushdown","es":"Extensión de tríceps en polea alta","ss":null,"vueltas":4,"series":4,"reps":"6-12","descanso":45,"prescrito":"4× 6-12 reps","ultimo":"12 @ 23kg, 8 @ 27kg, 8 @ 27kg, 7 @ 27kg (2026-10-06)","fecha":"2026-10-06","anterior":false,"hist":[[12,23.0],[8,27.0],[8,27.0],[7,27.0]]},{"n":11,"alias":"Cable V-Bar Overhead Tricep Extension","es":"Extensión de tríceps sobre la cabeza en polea","ss":null,"vueltas":4,"series":4,"reps":"6-12","descanso":45,"prescrito":"4× 6-12 reps","ultimo":"12 @ 36kg, 10 @ 36kg, 12 @ 36kg, 10 @ 36kg (2026-10-06)","fecha":"2026-10-06","anterior":false,"hist":[[12,36.0],[10,36.0],[12,36.0],[10,36.0]]},{"n":12,"alias":"Child's Pose","es":"Postura del niño","ss":null,"vueltas":1,"series":1,"reps":"30 s","descanso":null,"prescrito":"1× 1 set x 30 secs","ultimo":"sin registro"}],"antes":[{"alias":"Running","es":"Carrera continua"},{"alias":"Decline Plank to Pike","es":"Plancha declinada a pica"},{"alias":"Dumbbell Standing Shoulder External Rotations","es":"Rotación externa de hombro de pie"},{"alias":"SuperBand Dislocates","es":"Dislocaciones de hombro con banda"},{"alias":"Dumbbell Incline Bench Press","es":"Press inclinado con mancuernas"},{"alias":"Landmine Half-Kneeling Single Arm Press","es":"Press a una mano de rodillas con landmine"},{"alias":"Dip","es":"Fondos en paralelas"},{"alias":"Machine Seated Chest Fly","es":"Aperturas en máquina"},{"alias":"Machine Lateral Raise","es":"Elevación lateral en máquina"},{"alias":"Cable V Bar Tricep Pushdown","es":"Extensión de tríceps en polea alta"},{"alias":"Cable V-Bar Overhead Tricep Extension","es":"Extensión de tríceps sobre la cabeza en polea"},{"alias":"Child's Pose","es":"Postura del niño"}]},{"nombre":"Pull Training","dias":["X","S"],"hechas":6,"programadas":8,"ultima":"2026-10-07","duracion":55,"bloques":[{"ss":1,"tipo":"superserie","vueltas":2,"descanso":30}],"ejercicios":[{"n":1,"alias":"Running","es":"Carrera continua","ss":null,"vueltas":1,"series":1,"reps":"3 min a intensidad moderada","descanso":45,"prescrito":"1× 3 minutes at a moderate intensity","ultimo":"1× 900s (2026-09-26) ⚠ tiempo atípico","fecha":"2026-09-26","anterior":false,"hist":[[900,null]],"alerta":"tiempo atípico","tiempo":true},{"n":2,"alias":"Table Top Half Arm Thoracic Rotation","es":"Rotación torácica en cuadrupedia","ss":1,"vueltas":2,"series":1,"reps":"5 por lado","descanso":30,"prescrito":"2× 5 reps ea. side","ultimo":"sin registro"},{"n":3,"alias":"Mini Band Wall Slides","es":"Deslizamientos en pared con banda","ss":1,"vueltas":2,"series":1,"reps":"8","descanso":30,"prescrito":"2× 8 reps","ultimo":"2× 12 (2026-10-07)","fecha":"2026-10-07","anterior":false,"hist":[[12,null],[12,null]]},{"n":4,"alias":"Cable External Rotation","es":"Rotación externa en polea","ss":null,"vueltas":1,"series":1,"reps":"8 por lado","descanso":45,"prescrito":"1× 8 reps ea. side","ultimo":"1× 9 @ 9kg (2026-10-07)","fecha":"2026-10-07","anterior":false,"hist":[[9,9.0]]},{"n":5,"alias":"Bar Hang","es":"Colgarse de la barra","ss":null,"vueltas":1,"series":1,"reps":"60 s","descanso":40,"prescrito":"1× 60 secs","ultimo":"1× 60s (2026-10-07)","fecha":"2026-10-07","anterior":false,"hist":[[60,null]],"tiempo":true},{"n":6,"alias":"Pull Up","es":"Dominada","ss":null,"vueltas":4,"series":4,"reps":"6-12","descanso":45,"prescrito":"4× 6-12 reps","ultimo":"10, 9, 9, 7 (2026-10-07)","fecha":"2026-10-07","anterior":false,"hist":[[10,null],[9,null],[9,null],[7,null]]},{"n":7,"alias":"Machine Seated Single Arm Neutral Grip Row","es":"Remo a una mano en máquina agarre neutro","ss":null,"vueltas":4,"series":4,"reps":"6-12 por lado","descanso":45,"prescrito":"4× 6-12 reps ea. side","ultimo":"10 @ 50kg, 10 @ 50kg, 8 @ 50kg, 8 @ 50kg (2026-10-07)","fecha":"2026-10-07","anterior":false,"hist":[[10,50.0],[10,50.0],[8,50.0],[8,50.0]]},{"n":8,"alias":"EZ Bar Preacher Curl","es":"Curl predicador con barra Z","ss":null,"vueltas":4,"series":4,"reps":"6-12","descanso":45,"prescrito":"4× 6-12 reps","ultimo":"9 @ 8.5kg, 9 @ 8.5kg, 9 @ 10kg, 8 @ 10kg (2026-10-07)","fecha":"2026-10-07","anterior":false,"hist":[[9,8.5],[9,8.5],[9,10.0],[8,10.0]]},{"n":9,"alias":"Dumbbell Incline Bicep Curl","es":"Curl inclinado con mancuernas","ss":null,"vueltas":4,"series":4,"reps":"6-12","descanso":45,"prescrito":"4× 6-12 reps","ultimo":"9 @ 12.5kg, 8 @ 12.5kg, 7 @ 12.5kg, 7 @ 12.5kg (2026-10-07)","fecha":"2026-10-07","anterior":false,"hist":[[9,12.5],[8,12.5],[7,12.5],[7,12.5]]},{"n":10,"alias":"Dumbbell Hammer Curl","es":"Curl martillo con mancuernas","ss":null,"vueltas":4,"series":4,"reps":"6-12","descanso":45,"prescrito":"4× 6-12 reps","ultimo":"4× 12 @ 12.5kg (2026-10-07)","fecha":"2026-10-07","anterior":false,"hist":[[12,12.5],[12,12.5],[12,12.5],[12,12.5]]},{"n":11,"alias":"Dumbbell Shrug","es":"Encogimiento de trapecio con mancuernas","ss":null,"vueltas":4,"series":4,"reps":"6-12","descanso":45,"prescrito":"4× 6-12 reps","ultimo":"12 @ 25kg, 10 @ 25kg, 10 @ 25kg, 8 @ 25kg (2026-10-07)","fecha":"2026-10-07","anterior":false,"hist":[[12,25.0],[10,25.0],[10,25.0],[8,25.0]]},{"n":12,"alias":"Machine Seated Reverse Fly","es":"Pájaro en máquina","ss":null,"vueltas":4,"series":4,"reps":"6-12","descanso":45,"prescrito":"4× 6-12 reps","ultimo":"10 @ 50kg, 8 @ 70kg, 8 @ 70kg, - @ 70kg (2026-10-07)","fecha":"2026-10-07","anterior":false,"hist":[[10,50.0],[8,70.0],[8,70.0],[null,70.0]]},{"n":13,"alias":"Suspension Low Back Stretch","es":"Estiramiento lumbar en suspensión","ss":null,"vueltas":1,"series":1,"reps":"30 s","descanso":null,"prescrito":"1× 30 secs","ultimo":"sin registro"}],"antes":[{"alias":"Running","es":"Carrera continua"},{"alias":"Table Top Half Arm Thoracic Rotation","es":"Rotación torácica en cuadrupedia"},{"alias":"Mini Band Wall Slides","es":"Deslizamientos en pared con banda"},{"alias":"Bar Hang","es":"Colgarse de la barra"},{"alias":"Pull Up","es":"Dominada"},{"alias":"Machine Seated Single Arm Neutral Grip Row","es":"Remo a una mano en máquina agarre neutro"},{"alias":"Machine Preacher Curl","es":"Curl predicador en máquina"},{"alias":"Dumbbell Hammer Curl","es":"Curl martillo con mancuernas"},{"alias":"Cable Single Arm Bicep Curl","es":"Curl de bíceps a una mano en polea"},{"alias":"Cable Rope Face Pull","es":"Face pull con cuerda"},{"alias":"Dumbbell Shrug","es":"Encogimiento de trapecio con mancuernas"},{"alias":"Suspension Low Back Stretch","es":"Estiramiento lumbar en suspensión"}]}]}$tz$::jsonb);



commit;

-- Una fila por cliente: qué hizo la carga.
select * from _tz_res order by cliente;


-- ═══════════════════════════════════════════════════════════════════════
-- CARGA DE TRAINERIZE · export del 12 oct 2026 · 9 clientes con ciclo activo
-- ═══════════════════════════════════════════════════════════════════════
-- Dónde: Supabase del CRM → SQL Editor → pegar todo → Run.
-- Al final sale una tabla con una fila por cliente: qué fase quedó, si ya la
-- ve en la app, qué rutina cae cada día y qué cambió.
--
-- QUÉ HACE, por cliente
--   1. Deja en el CRM la fase de su ciclo ACTUAL con sus rutinas tal como
--      están en Trainerize hoy (si la fase no estaba, la crea; si una rutina
--      falta, la crea).
--   2. Pone los DÍAS de cada rutina según su calendario de Trainerize, para
--      que en la app le caiga lo mismo que allá.
--   3. Mete el HISTORIAL del 28 sep al 11 oct: cada sesión que hizo, con sus
--      series (reps y peso), como sesiones completadas `origen = 'importada'`.
--      Así la app le muestra «la última vez» y el CRM conoce sus pesos.
--   4. ENVÍA la fase al cliente (activa y visible) para que la use desde ya
--      en la app. La fase anterior que seguía activa pasa a «finalizada»
--      (no se borra y su historial sigue ahí).
--   5. Guarda la foto de Trainerize de este export (cumplimiento, días,
--      cardio y último registro por ejercicio), que el CRM pone al lado.
--
-- QUÉ NO HACE (a propósito)
--   · No borra nada. No toca videos, fichas, ni lo que el cliente marcó en su
--     app: si ese día ya tiene una sesión suya, esa manda y no se toca.
--   · No pisa lo que editaste en el CRM: si una rutina ya no está como la
--     dejó una carga anterior, se queda como la tienes y te lo dice abajo.
--   · Si el cliente ya veía la fase, no le cambia ejercicios ni días (te
--     avisa si difieren de Trainerize).
--   · Los registros con ⚠ (Bar Hang de 20 min, 1104 kg) no entran al
--     historial; quedan en la foto con su ⚠ para que los veas.
--   · Natalia Samper: su ciclo terminó el 20 sep y no tiene uno nuevo; no se
--     le envía nada (solo historial y foto).
--
-- SE PUEDE CORRER DOS VECES: la segunda no duplica nada.
-- Funciona haya o no corrido antes carga-trainerize-10oct.sql.
-- Necesita migracion-visibilidad.sql y migracion-calendario.sql (ya corridos).
-- ═══════════════════════════════════════════════════════════════════════

do $guard$
begin
  if not exists (select 1 from information_schema.columns
                  where table_name='rutinas' and column_name='dias_semana') then
    raise exception 'Falta la columna `rutinas.dias_semana`. Corre primero carga/migracion-calendario.sql.';
  end if;
  if not exists (select 1 from information_schema.columns
                  where table_name='sesiones' and column_name='origen') then
    raise exception 'Falta la columna `sesiones.origen`. Corre primero carga/migracion-calendario.sql.';
  end if;
  if not exists (select 1 from information_schema.columns
                  where table_name='fases' and column_name='visible_cliente') then
    raise exception 'Falta la columna `fases.visible_cliente`. Corre primero carga/migracion-visibilidad.sql.';
  end if;
end $guard$;

begin;

-- ── 1. La foto de Trainerize ────────────────────────────────────────────
create table if not exists trainerize_resumen (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  cliente_id uuid not null references clientes(id) on delete cascade,
  exportado date not null,              -- qué día se sacó de Trainerize
  trainerize_id text,
  ciclo text, inicio date, fin date,
  hechas int, programadas int,          -- cumplimiento de fuerza del ciclo
  dias_fuerza text[] default '{}',      -- L M X J V S D, como clientes.dias_entreno
  fase_id uuid references fases(id) on delete set null,
  datos jsonb not null default '{}',    -- estructura, calendario, cardio y rutinas con su último registro
  created_at timestamptz default now(),
  unique (cliente_id, exportado)
);
create index if not exists trainerize_resumen_cli_idx on trainerize_resumen (cliente_id, exportado desc);

alter table trainerize_resumen enable row level security;
drop policy if exists trainerize_resumen_propios on trainerize_resumen;
create policy trainerize_resumen_propios on trainerize_resumen for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

comment on table trainerize_resumen is
  'Foto de Trainerize por cliente (export del coach). Solo lectura para el CRM: cumplimiento, días, cardio y últimos registros por ejercicio. No la ve el cliente.';

-- ── 2. Ayudantes (solo viven mientras corre este archivo) ───────────────

-- La ficha de un ejercicio por su nombre de Trainerize. Si hay dos fichas
-- con el mismo nombre, gana la que ya usa este cliente, luego la que tiene
-- video y luego la más vieja. Si no existe, la crea (sin video).
create or replace function pg_temp.ecm_tz_ej(p_coach uuid, p_cli uuid, p_alias text) returns uuid
language plpgsql as $fn$
declare v_id uuid;
begin
  select e.id into v_id from ejercicios e
   where e.user_id = p_coach
     and (e.alias = p_alias or lower(e.nombre) = lower(p_alias))
   order by coalesce(e.archivado, false),
            exists (select 1 from rutina_ejercicios re join rutinas r on r.id = re.rutina_id
                     where re.ejercicio_id = e.id and r.cliente_id = p_cli) desc,
            (coalesce(e.video_fuente, 'ninguno') <> 'ninguno') desc,
            e.created_at
   limit 1;
  if v_id is not null then return v_id; end if;
  insert into ejercicios (user_id, nombre, alias, tipo, segmento, patron, equipo, unilateral, nivel, tags)
  values (p_coach,
          case p_alias when 'Muscle Up Tutorial' then 'Muscle up (progresión)' else p_alias end,
          p_alias,
          'fuerza',
          case when p_alias ~* 'muscle up|pull|row|curl|press|push|dip|tricep|bicep|shoulder|chest' then 'tren_superior' else null end,
          case when p_alias ~* 'muscle up|pull|row|curl' then 'pull' else null end,
          case when p_alias ~* 'muscle up|pull up|bar hang' then array['pull_up_bar'] else '{}'::text[] end,
          false, 'intermedio', array['importado-trainerize'])
  returning id into v_id;
  return v_id;
end $fn$;

-- La línea de una rutina que corresponde a un ejercicio de Trainerize
-- (la primera que no se haya usado ya: hay rutinas con el mismo ejercicio
-- dos veces, como el Shuttle Run en dos circuitos).
create or replace function pg_temp.ecm_tz_linea(p_rut uuid, p_alias text, p_es text, p_usadas uuid[]) returns rutina_ejercicios
language sql as $fn$
  select re.* from rutina_ejercicios re join ejercicios e on e.id = re.ejercicio_id
   where re.rutina_id = p_rut
     and (e.alias = p_alias or lower(e.nombre) = lower(p_alias) or lower(e.nombre) = lower(p_es))
     and not (re.id = any(coalesce(p_usadas, '{}')))
   order by (e.alias = p_alias) desc, re.orden, re.created_at
   limit 1;
$fn$;

-- ¿La rutina del CRM tiene exactamente esta lista, en este orden? Un
-- ejercicio cuenta como el mismo por su nombre de Trainerize o por el nombre
-- en español con que lo creó la carga anterior (algunas fichas se
-- reconocieron con otro nombre: «Squat to Hinge» quedó en la ficha de
-- «Bodyweight Squat To Hinge»).
create or replace function pg_temp.ecm_tz_igual(p_rut uuid, p_lista jsonb) returns boolean
language sql as $fn$
  with crm as (
    select row_number() over (order by re.orden, re.created_at) as i, e.alias as ca, e.nombre as cn
      from rutina_ejercicios re join ejercicios e on e.id = re.ejercicio_id
     where re.rutina_id = p_rut),
  l as (select t.i, t.x->>'alias' as a, t.x->>'es' as s from jsonb_array_elements(p_lista) with ordinality as t(x, i))
  select (select count(*) from crm) = (select count(*) from l)
     and not exists (select 1 from l join crm on crm.i = l.i
                      where not (crm.ca is not distinct from l.a or lower(crm.cn) = lower(l.a)
                                 or (l.s is not null and lower(crm.cn) = lower(l.s))));
$fn$;

-- Arma una rutina nueva entera (para las fases que no estaban).
create or replace function pg_temp.ecm_tz_armar(p_coach uuid, p_cli uuid, p_rut uuid, p_r jsonb) returns void
language plpgsql as $fn$
declare b jsonb; e jsonb; v_blo uuid; i int := 0; letras text := 'ABCDEFGHIJKLMNOP';
begin
  create temp table if not exists _tz_blo (ss int primary key, id uuid) on commit drop;
  delete from _tz_blo;
  for b in select * from jsonb_array_elements(p_r->'bloques') loop
    i := i + 1;
    insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
    values (p_rut, substr(letras, i, 1), b->>'tipo', (b->>'vueltas')::int, (b->>'descanso')::int, i)
    returning id into v_blo;
    insert into _tz_blo values ((b->>'ss')::int, v_blo);
  end loop;
  for e in select * from jsonb_array_elements(p_r->'ejercicios') loop
    insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
    values (p_rut,
            (select id from _tz_blo where ss = (e->>'ss')::int),
            pg_temp.ecm_tz_ej(p_coach, p_cli, e->>'alias'),
            (e->>'n')::int, (e->>'series')::int, e->>'reps', (e->>'descanso')::int);
  end loop;
end $fn$;

-- Pone una rutina que existe igual que en Trainerize: saca lo que ya no
-- está, mete lo nuevo en su sitio y reordena. Solo se llama cuando la rutina
-- sigue EXACTAMENTE como se importó (no la tocaste en el CRM). El historial
-- de lo que sale no se pierde: las series guardan su propio ejercicio.
create or replace function pg_temp.ecm_tz_corregir(p_coach uuid, p_cli uuid, p_rut uuid, p_r jsonb) returns text
language plpgsql as $fn$
declare e jsonb; l rutina_ejercicios; usadas uuid[] := '{}'; v_blo uuid; sale text[] := '{}'; entra text[] := '{}';
        hermano jsonb; v_n int;
begin
  for e in select * from jsonb_array_elements(p_r->'ejercicios') order by (value->>'n')::int loop
    l := pg_temp.ecm_tz_linea(p_rut, e->>'alias', e->>'es', usadas);
    if l.id is not null then
      update rutina_ejercicios set orden = (e->>'n')::int where id = l.id;
      usadas := usadas || l.id;
    end if;
  end loop;
  select array_agg(coalesce(ej.alias, ej.nombre)) into sale
    from rutina_ejercicios re join ejercicios ej on ej.id = re.ejercicio_id
   where re.rutina_id = p_rut and not (re.id = any(usadas));
  delete from rutina_ejercicios where rutina_id = p_rut and not (id = any(usadas));
  for e in select * from jsonb_array_elements(p_r->'ejercicios') order by (value->>'n')::int loop
    if exists (select 1 from rutina_ejercicios where rutina_id = p_rut and orden = (e->>'n')::int) then continue; end if;
    v_blo := null;
    if e->>'ss' is not null then
      -- Al bloque de sus compañeros de superserie, si ya hay uno.
      select re.bloque_id into v_blo from rutina_ejercicios re
       where re.rutina_id = p_rut and re.bloque_id is not null
         and re.orden in (select (x->>'n')::int from jsonb_array_elements(p_r->'ejercicios') x
                           where x->>'ss' = e->>'ss' and x->>'n' <> e->>'n')
       limit 1;
      if v_blo is null then
        select b into hermano from jsonb_array_elements(p_r->'bloques') b where b->>'ss' = e->>'ss';
        select coalesce(max(orden), 0) + 1 into v_n from rutina_bloques where rutina_id = p_rut;
        insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
        values (p_rut, chr(64 + v_n), coalesce(hermano->>'tipo', 'superserie'), (hermano->>'vueltas')::int, (hermano->>'descanso')::int, v_n)
        returning id into v_blo;
      end if;
    end if;
    insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
    values (p_rut, v_blo, pg_temp.ecm_tz_ej(p_coach, p_cli, e->>'alias'),
            (e->>'n')::int, (e->>'series')::int, e->>'reps', (e->>'descanso')::int);
    entra := entra || (e->>'alias');
  end loop;
  -- Bloques que quedaron vacíos.
  delete from rutina_bloques b where b.rutina_id = p_rut
     and not exists (select 1 from rutina_ejercicios re where re.bloque_id = b.id);
  update rutinas set notas_coach = concat_ws(E'\n', nullif(notas_coach, ''),
         'Puesta igual que en Trainerize (export 12 oct 2026). Sale: ' || coalesce(array_to_string(sale, ', '), '—')
         || '. Entra: ' || coalesce(nullif(array_to_string(entra, ', '), ''), '—') || '.'),
         updated_at = now()
   where id = p_rut;
  return 'sale ' || coalesce(array_to_string(sale, ', '), '—') || ' · entra ' || coalesce(nullif(array_to_string(entra, ', '), ''), '—');
end $fn$;

-- Un cliente entero.

create or replace function pg_temp.ecm_tz12_cliente(p_patron text, d jsonb)
returns table (cliente text, ciclo text, fase text, en_la_app text, dias text, sesiones_nuevas int, series_nuevas int, cambios text)
language plpgsql as $fn$
declare
  v_cli uuid; v_coach uuid; v_nombre text; v_fase uuid; v_fase_nombre text; v_nueva boolean := false;
  v_visible boolean; v_estado text; v_ini date; v_sem int; v_fin date;
  r jsonb; e jsonb; s jsonb; v_rut uuid; v_ses uuid; v_ses_fase uuid; v_ses_ini date; v_origen text;
  l rutina_ejercicios; usadas uuid[]; v_ej uuid; k int; a jsonb; v_dias text[]; v_dias_crm text[];
  n_ses int := 0; n_ser int := 0; notas text[] := '{}'; v_app text := '—'; v_otra record; v_nombres text[] := '{}';
  v_corregida boolean;
begin
  select c.id, c.user_id, c.nombre into v_cli, v_coach, v_nombre from clientes c
   where c.nombre ilike p_patron
      or exists (select 1 from unnest(coalesce(c.nombres_alternos, '{}')) x where x ilike p_patron)
   order by (c.nombre ilike p_patron) desc, c.created_at
   limit 1;
  if v_cli is null then
    return query select d->>'nombre', d->>'ciclo', null::text, 'no'::text, null::text, 0, 0,
      format('SALTADO: no lo encuentro en clientes (busqué %s). Créalo en el CRM con ese nombre y vuelve a correr este archivo.', p_patron);
    return;
  end if;
  v_ini := (d->>'inicio')::date; v_sem := (d->>'semanas')::int; v_fin := v_ini + v_sem * 7 - 1;

  -- ── La fase de ese ciclo: por número («Cycle 5» / «Ciclo 5») o por la fecha de inicio.
  select f.id, f.nombre, f.visible_cliente, f.estado into v_fase, v_fase_nombre, v_visible, v_estado from fases f
   where f.cliente_id = v_cli and coalesce(f.estado, '') <> 'archivada'
     and (f.nombre ~* ('^\s*(cycle|ciclo)\s*' || (d->>'num') || '\s*$') or f.fecha_inicio = v_ini)
   order by (f.nombre ~* ('^\s*(cycle|ciclo)\s*' || (d->>'num') || '\s*$')) desc, f.created_at
   limit 1;

  if v_fase is null then
    v_nueva := true; v_visible := false; v_estado := 'borrador';
    v_fase_nombre := 'Ciclo ' || (d->>'num');
    insert into fases (user_id, cliente_id, nombre, objetivo, notas_coach, semanas, fecha_inicio, dias_semana, orden, estado)
    values (v_coach, v_cli, v_fase_nombre, null,
            format('Importado del export de Trainerize del 12 oct 2026 (%s, %s a %s).', d->>'ciclo', d->>'inicio', d->>'fin'),
            v_sem, v_ini, array(select jsonb_array_elements_text(d->'dias_fuerza')),
            coalesce((select max(orden) + 1 from fases where cliente_id = v_cli), 1), 'borrador')
    returning id into v_fase;
    notas := notas || 'fase nueva'::text;
  else
    -- Fechas del ciclo: solo se ajustan si el cliente todavía no la ve.
    if not v_visible and coalesce((d->>'publicar')::boolean, false) and exists (select 1 from fases where id = v_fase
                                  and (fecha_inicio is distinct from v_ini or semanas is distinct from v_sem)) then
      update fases set fecha_inicio = v_ini, semanas = v_sem, updated_at = now() where id = v_fase;
      notas := notas || format('fechas del ciclo puestas como en Trainerize (%s, %s semanas)', v_ini, v_sem);
    end if;
  end if;

  -- ── Las rutinas: crear las que falten, corregir las que no tocaste, poner sus días.
  k := 0;
  for r in select * from jsonb_array_elements(d->'rutinas') loop
    k := k + 1;
    v_nombres := v_nombres || lower(btrim(r->>'nombre'));
    v_dias := array(select jsonb_array_elements_text(r->'dias'));
    select ru.id into v_rut from rutinas ru
     where ru.fase_id = v_fase and lower(btrim(ru.nombre)) = lower(btrim(r->>'nombre'))
       and coalesce(ru.archivada, false) = false
     order by ru.dia_orden limit 1;
    if v_rut is null then
      insert into rutinas (user_id, cliente_id, fase_id, nombre, dia_orden, duracion_estimada_min, tipo_sesion, dias_semana)
      values (v_coach, v_cli, v_fase, r->>'nombre',
              coalesce((select max(dia_orden) + 1 from rutinas where fase_id = v_fase), k),
              (r->>'duracion')::int,
              case when r->>'nombre' ~* 'mobility|movilidad|flow' then 'movilidad' else 'fuerza' end, v_dias)
      returning id into v_rut;
      perform pg_temp.ecm_tz_armar(v_coach, v_cli, v_rut, r);
      if not v_nueva then notas := notas || format('%s: no estaba en el CRM, creada', r->>'nombre'); end if;
    else
      if not pg_temp.ecm_tz_igual(v_rut, r->'ejercicios') then
        v_corregida := false;
        if coalesce((select coalesce(ru.visible_cliente, f.visible_cliente) from rutinas ru join fases f on f.id = ru.fase_id where ru.id = v_rut), false) then
          notas := notas || format('%s: cambió en Trainerize pero el cliente ya la ve en su app; no la toqué', r->>'nombre');
        else
          -- Solo si sigue EXACTAMENTE como la dejó una carga anterior (no la editaste en el CRM).
          for a in select * from jsonb_array_elements(coalesce(r->'antes', '[]'::jsonb)) loop
            if pg_temp.ecm_tz_igual(v_rut, a) then
              notas := notas || format('%s corregida (%s)', r->>'nombre', pg_temp.ecm_tz_corregir(v_coach, v_cli, v_rut, r));
              v_corregida := true; exit;
            end if;
          end loop;
          if not v_corregida then
            notas := notas || format('%s: distinta a Trainerize y ya la editaste en el CRM; quedó como la tienes', r->>'nombre');
          end if;
        end if;
      end if;
      -- Los días: se ponen si no tenía, o si el cliente aún no ve la fase. Nunca
      -- se dejan vacíos salvo a propósito (la movilidad que va con otra rutina).
      select ru.dias_semana into v_dias_crm from rutinas ru where ru.id = v_rut;
      if not coalesce((d->>'publicar')::boolean, false)
         or (coalesce(array_length(v_dias, 1), 0) = 0 and not coalesce((r->>'sin_dia')::boolean, false)) then
        null;   -- a este cliente no se le envía nada / Trainerize no dice qué día: quedan los del CRM
      elsif coalesce(array_length(v_dias_crm, 1), 0) = 0 or not v_visible then
        if v_dias_crm is distinct from v_dias then
          update rutinas set dias_semana = v_dias, updated_at = now() where id = v_rut;
        end if;
      elsif v_dias_crm is distinct from v_dias then
        notas := notas || format('%s: en el CRM cae %s y en Trainerize %s; dejé los del CRM', r->>'nombre',
                                 array_to_string(v_dias_crm, ''), coalesce(nullif(array_to_string(v_dias, ''), ''), 'sin día'));
      end if;
      -- Que se vea dentro de la fase (sin pisar una que escondiste a propósito en una fase ya enviada).
      if not v_visible and coalesce((d->>'publicar')::boolean, false) then
        update rutinas set visible_cliente = null where id = v_rut and visible_cliente is false;
      end if;
    end if;
  end loop;

  -- Rutinas del CRM en esta fase que Trainerize ya no tiene: se esconden (no se borran)
  -- para que el cliente no vea un día que no le toca. Solo si aún no la ve.
  if not v_visible and coalesce((d->>'publicar')::boolean, false) then
    for v_otra in select ru.id, ru.nombre from rutinas ru
                   where ru.fase_id = v_fase and coalesce(ru.archivada, false) = false
                     and not (lower(btrim(ru.nombre)) = any(v_nombres))
                     and coalesce(ru.visible_cliente, true) loop
      update rutinas set visible_cliente = false, updated_at = now() where id = v_otra.id;
      notas := notas || format('«%s» no está en Trainerize: la escondí (no se borró)', v_otra.nombre);
    end loop;
  end if;
  if coalesce((d->>'publicar')::boolean, false) and jsonb_array_length(d->'dias_fuerza') > 0 then
    update fases set dias_semana = array(select jsonb_array_elements_text(d->'dias_fuerza'))
     where id = v_fase and (not v_visible or coalesce(array_length(dias_semana, 1), 0) = 0);
  end if;

  -- ── Historial: cada sesión que hizo, con sus series.
  for s in select * from jsonb_array_elements(coalesce(d->'sesiones', '[]'::jsonb)) loop
    -- Su fase: la de este ciclo, o la que corría ese día (las del ciclo anterior).
    if (s->>'fecha')::date >= v_ini then
      v_ses_fase := v_fase; v_ses_ini := v_ini;
    else
      select f.id, f.fecha_inicio into v_ses_fase, v_ses_ini from fases f
       where f.cliente_id = v_cli and coalesce(f.estado, '') <> 'archivada' and f.id <> v_fase
         and f.fecha_inicio <= (s->>'fecha')::date
       order by f.fecha_inicio desc, f.orden desc limit 1;
    end if;
    v_rut := null;
    if v_ses_fase is not null then
      select ru.id into v_rut from rutinas ru
       where ru.fase_id = v_ses_fase and lower(btrim(ru.nombre)) = lower(btrim(s->>'rutina'))
       order by coalesce(ru.archivada, false), ru.dia_orden limit 1;
    end if;
    if v_rut is null then
      notas := notas || format('sesión del %s (%s) sin rutina en el CRM: no entró', s->>'fecha', s->>'rutina');
      continue;
    end if;

    select se.id, se.origen into v_ses, v_origen from sesiones se
     where se.cliente_id = v_cli and se.rutina_id = v_rut and se.fecha = (s->>'fecha')::date limit 1;
    if v_ses is not null and coalesce(v_origen, 'cliente') <> 'importada' then
      continue;   -- la marcó el cliente en su app: lo suyo manda, no se toca
    end if;
    if v_ses is null then
      insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num, semana_iso,
                            estado, finalizada_en, duracion_seg, vista_por_coach, origen)
      values (v_coach, v_cli, v_rut, v_ses_fase, (s->>'fecha')::date,
              greatest(1, (((s->>'fecha')::date - v_ses_ini) / 7) + 1),
              to_char((s->>'fecha')::date, 'IYYY-"W"IW'),
              'completada', (((s->>'fecha')::date + time '12:00') at time zone 'UTC'),
              (s->>'duracion_seg')::int, true, 'importada')
      returning id into v_ses;
      n_ses := n_ses + 1;
    end if;

    -- Las series: solo de los ejercicios que esa sesión todavía no tiene
    -- (una sesión importada antes traía solo el último registro de cada uno).
    usadas := '{}';
    for e in select * from jsonb_array_elements(s->'ejercicios') order by (value->>'n')::int loop
      l := pg_temp.ecm_tz_linea(v_rut, e->>'alias', e->>'es', usadas);
      if l.id is not null then usadas := usadas || l.id; v_ej := l.ejercicio_id;
      else v_ej := pg_temp.ecm_tz_ej(v_coach, v_cli, e->>'alias'); end if;
      if exists (select 1 from series_log sl where sl.sesion_id = v_ses
                  and (sl.ejercicio_id = v_ej or (l.id is not null and sl.rutina_ejercicio_id = l.id))) then
        continue;
      end if;
      k := 0;
      for a in select * from jsonb_array_elements(e->'hist') loop
        k := k + 1;
        if a->>0 is null or (a->>0)::int = 0 then continue; end if;
        insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad, notas)
        values (v_ses, l.id, v_ej, k, (a->>0)::int, (a->>1)::numeric, 'kg',
                case when coalesce((e->>'tiempo')::boolean, false) then 'segundos' end);
        n_ser := n_ser + 1;
      end loop;
    end loop;
  end loop;

  -- ── Que la app la tome ya: la fase de este ciclo queda ACTIVA y ENVIADA.
  if coalesce((d->>'publicar')::boolean, false) then
    select f.id, f.nombre into v_otra from fases f
     where f.cliente_id = v_cli and f.id <> v_fase and f.estado = 'activa' and f.visible_cliente
       and f.fecha_inicio > v_ini
     limit 1;
    if v_otra.id is not null then
      notas := notas || format('NO la envié: ya tiene enviada «%s», que empieza después', v_otra.nombre);
      v_app := 'no (ya ve otra más nueva)';
    else
      -- Las anteriores que seguían activas pasan a finalizadas (se siguen viendo en su historial).
      update fases set estado = 'finalizada', updated_at = now()
       where cliente_id = v_cli and id <> v_fase and estado = 'activa'
         and coalesce(fecha_inicio, date '1900-01-01') < v_ini;
      update fases set visible_cliente = true, estado = 'activa',
                       publicada_en = coalesce(publicada_en, now()),
                       orden = greatest(orden, coalesce((select max(f2.orden) + 1 from fases f2
                                                          where f2.cliente_id = v_cli and f2.id <> v_fase
                                                            and coalesce(f2.estado, '') <> 'archivada'), orden)),
                       updated_at = now()
       where id = v_fase;
      v_app := case when v_visible then 'sí (ya la veía)' else 'sí (enviada ahora)' end;
    end if;
  else
    v_app := 'no';
    notas := notas || coalesce(d->>'aviso', 'no se envía');
  end if;

  -- ── La foto de Trainerize de este export (el CRM la pone al lado de lo tuyo).
  insert into trainerize_resumen (user_id, cliente_id, exportado, trainerize_id, ciclo, inicio, fin, hechas, programadas,
                                  dias_fuerza, fase_id, datos)
  values (v_coach, v_cli, date '2026-10-12', d->>'trainerize_id', d->>'ciclo',
          (d->'foto'->>'inicio')::date, (d->>'fin')::date,
          (d->'foto'->>'hechas')::int, (d->'foto'->>'programadas')::int,
          array(select jsonb_array_elements_text(d->'dias_fuerza')), v_fase, d->'foto'->'datos')
  on conflict (cliente_id, exportado) do update
    set ciclo = excluded.ciclo, inicio = excluded.inicio, fin = excluded.fin, hechas = excluded.hechas,
        programadas = excluded.programadas, dias_fuerza = excluded.dias_fuerza, fase_id = excluded.fase_id,
        datos = excluded.datos, trainerize_id = coalesce(excluded.trainerize_id, trainerize_resumen.trainerize_id);

  return query select v_nombre, d->>'ciclo',
    v_fase_nombre || ' · ' || to_char(v_ini, 'DD/MM') || ' → ' || to_char(v_fin, 'DD/MM'),
    v_app,
    (select string_agg(ru.nombre || ': ' || coalesce(nullif(array_to_string(ru.dias_semana, ' '), ''), 'sin día fijo'), ' · ' order by ru.dia_orden)
       from rutinas ru where ru.fase_id = v_fase and coalesce(ru.archivada, false) = false and coalesce(ru.visible_cliente, true)),
    n_ses, n_ser, coalesce(nullif(array_to_string(notas, ' · '), ''), 'ok');
end $fn$;

-- La tabla del resumen vive hasta que se cierra la conexión (no hasta el
-- commit): así se muestra DESPUÉS de guardar, como último resultado.
drop table if exists _tz12_res;
create temp table _tz12_res (cliente text, ciclo text, fase text, en_la_app text, dias text,
                             sesiones_nuevas int, series_nuevas int, cambios text);





-- Santiago Fonseca · Cycle 2 (2026-09-14 → 2026-10-18)
insert into _tz12_res select * from pg_temp.ecm_tz12_cliente('%santiago f%', $tz${"nombre":"Santiago Fonseca","trainerize_id":"30858078","ciclo":"Cycle 2","num":2,"inicio":"2026-09-14","fin":"2026-10-18","semanas":5,"dias_fuerza":["L","M","X","J","V","S"],"publicar":true,"rutinas":[{"nombre":"Lower Body + Core Training","duracion":69,"bloques":[{"ss":1,"tipo":"superserie","vueltas":2,"descanso":30},{"ss":2,"tipo":"circuito","vueltas":2,"descanso":30}],"ejercicios":[{"n":1,"alias":"90-90 Hip Switch","es":"Cambio de cadera 90-90","ss":1,"vueltas":2,"series":1,"reps":"6","descanso":30,"prescrito":"2× 6 reps"},{"n":2,"alias":"Cossack Squat to T-Spine Reach","es":"Sentadilla cosaco con alcance torácico","ss":1,"vueltas":2,"series":1,"reps":"6 por lado","descanso":30,"prescrito":"2× 6 reps ea. side"},{"n":3,"alias":"1/2 Kneel to High Knee Hop","es":"Salto de rodilla alta desde media rodilla","ss":2,"vueltas":2,"series":1,"reps":"6 por lado","descanso":30,"prescrito":"2× 6 reps ea. side"},{"n":4,"alias":"1/2 Kneel to Lateral Bound","es":"Salto lateral desde media rodilla","ss":2,"vueltas":2,"series":1,"reps":"8","descanso":30,"prescrito":"2× 8 reps"},{"n":5,"alias":"Shuttle Run","es":"Ida y vuelta corta","ss":2,"vueltas":2,"series":1,"reps":"60 s","descanso":30,"prescrito":"2× 60 secs"},{"n":6,"alias":"Angled Machine Leg Press","es":"Prensa inclinada","ss":null,"vueltas":4,"series":4,"reps":"6-12","descanso":50,"prescrito":"4× 6-12 reps"},{"n":7,"alias":"Smith Machine Sumo Deadlift","es":"Peso muerto sumo en multipower","ss":null,"vueltas":4,"series":4,"reps":"6-12","descanso":50,"prescrito":"4× 6-12 reps"},{"n":8,"alias":"Hip Thrust Machine","es":"Hip thrust en máquina","ss":null,"vueltas":4,"series":4,"reps":"6-12","descanso":50,"prescrito":"4× 6-12 reps"},{"n":9,"alias":"Machine Seated Leg Extension","es":"Extensión de cuádriceps en máquina","ss":null,"vueltas":3,"series":3,"reps":"6-12","descanso":50,"prescrito":"3× 6-12 reps"},{"n":10,"alias":"Machine Seated Hip Adduction","es":"Aductores en máquina","ss":null,"vueltas":3,"series":3,"reps":"6-12","descanso":50,"prescrito":"3× 6-12 reps"},{"n":11,"alias":"Machine Seated Calf Raise","es":"Gemelo sentado en máquina","ss":null,"vueltas":4,"series":4,"reps":"6-12","descanso":50,"prescrito":"4× 6-12 reps"},{"n":12,"alias":"Dip Machine Straight Leg Raise","es":"Elevación de piernas rectas en paralelas","ss":null,"vueltas":3,"series":3,"reps":"15","descanso":50,"prescrito":"3× 15 reps"},{"n":13,"alias":"Seated Machine Ab Crunch","es":"Crunch abdominal en máquina","ss":null,"vueltas":4,"series":4,"reps":"15","descanso":30,"prescrito":"4× 15 reps"},{"n":14,"alias":"Horizontal Cable Rotation","es":"Rotación horizontal en polea","ss":null,"vueltas":3,"series":3,"reps":"15","descanso":30,"prescrito":"3× 15 reps"},{"n":15,"alias":"Static Pigeon Stretch","es":"Estiramiento de paloma","ss":null,"vueltas":1,"series":1,"reps":"30 s por lado","descanso":null,"prescrito":"1× 30 secs ea. side"}],"antes":[[{"alias":"90-90 Hip Switch","es":"Cambio de cadera 90-90"},{"alias":"Cossack Squat to T-Spine Reach","es":"Sentadilla cosaco con alcance torácico"},{"alias":"1/2 Kneel to High Knee Hop","es":"Salto de rodilla alta desde media rodilla"},{"alias":"1/2 Kneel to Lateral Bound","es":"Salto lateral desde media rodilla"},{"alias":"Shuttle Run","es":"Ida y vuelta corta"},{"alias":"Angled Machine Leg Press","es":"Prensa inclinada"},{"alias":"Smith Machine Sumo Deadlift","es":"Peso muerto sumo en multipower"},{"alias":"Hip Thrust Machine","es":"Hip thrust en máquina"},{"alias":"Machine Seated Leg Extension","es":"Extensión de cuádriceps en máquina"},{"alias":"Machine Seated Hip Adduction","es":"Aductores en máquina"},{"alias":"Machine Seated Calf Raise","es":"Gemelo sentado en máquina"},{"alias":"Dip Machine Straight Leg Raise","es":"Elevación de piernas rectas en paralelas"},{"alias":"Seated Machine Ab Crunch","es":"Crunch abdominal en máquina"},{"alias":"Horizontal Cable Rotation","es":"Rotación horizontal en polea"},{"alias":"Static Pigeon Stretch","es":"Estiramiento de paloma"}],[{"alias":"90-90 Hip Switch","es":"Cambio de cadera 90-90"},{"alias":"Cossack Squat to T-Spine Reach","es":"Sentadilla cosaco con alcance torácico"},{"alias":"1/2 Kneel to High Knee Hop","es":"Salto de rodilla alta desde media rodilla"},{"alias":"1/2 Kneel to Lateral Bound","es":"Salto lateral desde media rodilla"},{"alias":"Shuttle Run","es":"Ida y vuelta corta"},{"alias":"Angled Machine Leg Press","es":"Prensa inclinada"},{"alias":"Smith Machine Sumo Deadlift","es":"Peso muerto sumo en multipower"},{"alias":"Hip Thrust Machine","es":"Hip thrust en máquina"},{"alias":"Machine Seated Leg Extension","es":"Extensión de cuádriceps en máquina"},{"alias":"Machine Seated Hip Adduction","es":"Aductores en máquina"},{"alias":"Machine Seated Calf Raise","es":"Gemelo sentado en máquina"},{"alias":"Dip Machine Straight Leg Raise","es":"Elevación de piernas rectas en paralelas"},{"alias":"Seated Machine Ab Crunch","es":"Crunch abdominal en máquina"},{"alias":"Horizontal Cable Rotation","es":"Rotación horizontal en polea"},{"alias":"Static Pigeon Stretch","es":"Estiramiento de paloma"}]],"dias":["L","J"]},{"nombre":"Pull Training","duracion":61,"bloques":[{"ss":1,"tipo":"superserie","vueltas":2,"descanso":30}],"ejercicios":[{"n":1,"alias":"Running","es":"Carrera continua","ss":null,"vueltas":1,"series":1,"reps":"3 min a intensidad moderada","descanso":45,"prescrito":"1× 3 minutes at a moderate intensity"},{"n":2,"alias":"Table Top Half Arm Thoracic Rotation","es":"Rotación torácica en cuadrupedia","ss":1,"vueltas":2,"series":1,"reps":"5 por lado","descanso":30,"prescrito":"2× 5 reps ea. side"},{"n":3,"alias":"Mini Band Wall Slides","es":"Deslizamientos en pared con banda","ss":1,"vueltas":2,"series":1,"reps":"8","descanso":30,"prescrito":"2× 8 reps"},{"n":4,"alias":"Cable External Rotation","es":"Rotación externa en polea","ss":null,"vueltas":1,"series":1,"reps":"8 por lado","descanso":45,"prescrito":"1× 8 reps ea. side"},{"n":5,"alias":"Bar Hang","es":"Colgarse de la barra","ss":null,"vueltas":1,"series":1,"reps":"60 s","descanso":30,"prescrito":"1× 60 secs"},{"n":6,"alias":"Pull Up","es":"Dominada","ss":null,"vueltas":4,"series":4,"reps":"6-12","descanso":50,"prescrito":"4× 6-12 reps"},{"n":7,"alias":"Machine Seated Single Arm Neutral Grip Row","es":"Remo a una mano en máquina agarre neutro","ss":null,"vueltas":4,"series":4,"reps":"6-12 por lado","descanso":50,"prescrito":"4× 6-12 reps ea. side"},{"n":8,"alias":"EZ Bar Preacher Curl","es":"Curl predicador con barra Z","ss":null,"vueltas":4,"series":4,"reps":"6-12","descanso":50,"prescrito":"4× 6-12 reps"},{"n":9,"alias":"Dumbbell Incline Bicep Curl","es":"Curl inclinado con mancuernas","ss":null,"vueltas":4,"series":4,"reps":"6-12","descanso":50,"prescrito":"4× 6-12 reps"},{"n":10,"alias":"Dumbbell Hammer Curl","es":"Curl martillo con mancuernas","ss":null,"vueltas":4,"series":4,"reps":"6-12","descanso":50,"prescrito":"4× 6-12 reps"},{"n":11,"alias":"Dumbbell Shrug","es":"Encogimiento de trapecio con mancuernas","ss":null,"vueltas":4,"series":4,"reps":"6-12","descanso":50,"prescrito":"4× 6-12 reps"},{"n":12,"alias":"Machine Seated Reverse Fly","es":"Pájaro en máquina","ss":null,"vueltas":4,"series":4,"reps":"6-12","descanso":50,"prescrito":"4× 6-12 reps"},{"n":13,"alias":"Suspension Low Back Stretch","es":"Estiramiento lumbar en suspensión","ss":null,"vueltas":1,"series":1,"reps":"30 s","descanso":null,"prescrito":"1× 30 secs"}],"antes":[[{"alias":"Running","es":"Carrera continua"},{"alias":"Table Top Half Arm Thoracic Rotation","es":"Rotación torácica en cuadrupedia"},{"alias":"Mini Band Wall Slides","es":"Deslizamientos en pared con banda"},{"alias":"Cable External Rotation","es":"Rotación externa en polea"},{"alias":"Bar Hang","es":"Colgarse de la barra"},{"alias":"Pull Up","es":"Dominada"},{"alias":"Machine Seated Single Arm Neutral Grip Row","es":"Remo a una mano en máquina agarre neutro"},{"alias":"EZ Bar Preacher Curl","es":"Curl predicador con barra Z"},{"alias":"Dumbbell Incline Bicep Curl","es":"Curl inclinado con mancuernas"},{"alias":"Dumbbell Hammer Curl","es":"Curl martillo con mancuernas"},{"alias":"Dumbbell Shrug","es":"Encogimiento de trapecio con mancuernas"},{"alias":"Machine Seated Reverse Fly","es":"Pájaro en máquina"},{"alias":"Suspension Low Back Stretch","es":"Estiramiento lumbar en suspensión"}],[{"alias":"Running","es":"Carrera continua"},{"alias":"Table Top Half Arm Thoracic Rotation","es":"Rotación torácica en cuadrupedia"},{"alias":"Mini Band Wall Slides","es":"Deslizamientos en pared con banda"},{"alias":"Bar Hang","es":"Colgarse de la barra"},{"alias":"Pull Up","es":"Dominada"},{"alias":"Machine Seated Single Arm Neutral Grip Row","es":"Remo a una mano en máquina agarre neutro"},{"alias":"Machine Preacher Curl","es":"Curl predicador en máquina"},{"alias":"Dumbbell Hammer Curl","es":"Curl martillo con mancuernas"},{"alias":"Cable Single Arm Bicep Curl","es":"Curl de bíceps a una mano en polea"},{"alias":"Cable Rope Face Pull","es":"Face pull con cuerda"},{"alias":"Dumbbell Shrug","es":"Encogimiento de trapecio con mancuernas"},{"alias":"Suspension Low Back Stretch","es":"Estiramiento lumbar en suspensión"}]],"dias":["X","S"]},{"nombre":"Push Training","duracion":61,"bloques":[{"ss":1,"tipo":"superserie","vueltas":2,"descanso":30}],"ejercicios":[{"n":1,"alias":"Running","es":"Carrera continua","ss":null,"vueltas":1,"series":1,"reps":"Caminadora: 3 min intensidad moderada","descanso":45,"prescrito":"1× Treadmill: 3 minutes at a moderate intensity"},{"n":2,"alias":"Dumbbell Standing Shoulder External Rotations","es":"Rotación externa de hombro de pie","ss":1,"vueltas":2,"series":1,"reps":"6","descanso":30,"prescrito":"2× 6 reps"},{"n":3,"alias":"SuperBand Dislocates","es":"Dislocaciones de hombro con banda","ss":1,"vueltas":2,"series":1,"reps":"6","descanso":30,"prescrito":"2× 6 reps"},{"n":4,"alias":"Clapping Push Up","es":"Flexión con palmada","ss":null,"vueltas":2,"series":2,"reps":"6-8","descanso":30,"prescrito":"2× 6-8 reps"},{"n":5,"alias":"Dumbbell Incline Bench Press","es":"Press inclinado con mancuernas","ss":null,"vueltas":4,"series":4,"reps":"6-12","descanso":50,"prescrito":"4× 6-12 reps"},{"n":6,"alias":"Dip","es":"Fondos en paralelas","ss":null,"vueltas":4,"series":4,"reps":"6-12","descanso":50,"prescrito":"4× 6-12 reps"},{"n":7,"alias":"Machine Seated Chest Fly","es":"Aperturas en máquina","ss":null,"vueltas":4,"series":4,"reps":"6-12","descanso":50,"prescrito":"4× 6-12 reps"},{"n":8,"alias":"Dumbbell Seated Arnold Press","es":"Press Arnold sentado","ss":null,"vueltas":4,"series":4,"reps":"6-12","descanso":50,"prescrito":"4× 6-12 reps"},{"n":9,"alias":"Cable Lateral Raise","es":"Elevación lateral en polea","ss":null,"vueltas":4,"series":4,"reps":"6-12 por lado","descanso":50,"prescrito":"4× 6-12 reps ea. side"},{"n":10,"alias":"Cable V Bar Tricep Pushdown","es":"Extensión de tríceps en polea alta","ss":null,"vueltas":4,"series":4,"reps":"6-12","descanso":50,"prescrito":"4× 6-12 reps"},{"n":11,"alias":"Cable V-Bar Overhead Tricep Extension","es":"Extensión de tríceps sobre la cabeza en polea","ss":null,"vueltas":4,"series":4,"reps":"6-12","descanso":50,"prescrito":"4× 6-12 reps"},{"n":12,"alias":"Child's Pose","es":"Postura del niño","ss":null,"vueltas":1,"series":1,"reps":"30 s","descanso":null,"prescrito":"1× 1 set x 30 secs"}],"antes":[[{"alias":"Running","es":"Carrera continua"},{"alias":"Dumbbell Standing Shoulder External Rotations","es":"Rotación externa de hombro de pie"},{"alias":"SuperBand Dislocates","es":"Dislocaciones de hombro con banda"},{"alias":"Clapping Push Up","es":"Flexión con palmada"},{"alias":"Dumbbell Incline Bench Press","es":"Press inclinado con mancuernas"},{"alias":"Dip","es":"Fondos en paralelas"},{"alias":"Machine Seated Chest Fly","es":"Aperturas en máquina"},{"alias":"Dumbbell Seated Arnold Press","es":"Press Arnold sentado"},{"alias":"Cable Lateral Raise","es":"Elevación lateral en polea"},{"alias":"Cable V Bar Tricep Pushdown","es":"Extensión de tríceps en polea alta"},{"alias":"Cable V-Bar Overhead Tricep Extension","es":"Extensión de tríceps sobre la cabeza en polea"},{"alias":"Child's Pose","es":"Postura del niño"}],[{"alias":"Running","es":"Carrera continua"},{"alias":"Decline Plank to Pike","es":"Plancha declinada a pica"},{"alias":"Dumbbell Standing Shoulder External Rotations","es":"Rotación externa de hombro de pie"},{"alias":"SuperBand Dislocates","es":"Dislocaciones de hombro con banda"},{"alias":"Dumbbell Incline Bench Press","es":"Press inclinado con mancuernas"},{"alias":"Landmine Half-Kneeling Single Arm Press","es":"Press a una mano de rodillas con landmine"},{"alias":"Dip","es":"Fondos en paralelas"},{"alias":"Machine Seated Chest Fly","es":"Aperturas en máquina"},{"alias":"Machine Lateral Raise","es":"Elevación lateral en máquina"},{"alias":"Cable V Bar Tricep Pushdown","es":"Extensión de tríceps en polea alta"},{"alias":"Cable V-Bar Overhead Tricep Extension","es":"Extensión de tríceps sobre la cabeza en polea"},{"alias":"Child's Pose","es":"Postura del niño"}]],"dias":["M","V"]}],"sesiones":[{"fecha":"2026-09-28","rutina":"Lower Body + Core Training","duracion_seg":4140,"ejercicios":[{"n":1,"alias":"90-90 Hip Switch","es":"Cambio de cadera 90-90","hist":[[6,null],[6,null]]},{"n":2,"alias":"Cossack Squat to T-Spine Reach","es":"Sentadilla cosaco con alcance torácico","hist":[[6,null],[6,null]]},{"n":3,"alias":"1/2 Kneel to High Knee Hop","es":"Salto de rodilla alta desde media rodilla","hist":[[6,null]]},{"n":4,"alias":"1/2 Kneel to Lateral Bound","es":"Salto lateral desde media rodilla","hist":[[8,null]]},{"n":5,"alias":"Shuttle Run","es":"Ida y vuelta corta","hist":[[60,null]]},{"n":6,"alias":"Angled Machine Leg Press","es":"Prensa inclinada","hist":[[12,70.0],[12,70.0],[9,82.5],[8,82.5]]},{"n":7,"alias":"Smith Machine Sumo Deadlift","es":"Peso muerto sumo en multipower","hist":[[9,22.5],[8,22.5],[8,22.5],[8,22.5]]},{"n":8,"alias":"Hip Thrust Machine","es":"Hip thrust en máquina","hist":[[8,45.0],[8,45.0],[8,50.0],[7,50.0]]},{"n":9,"alias":"Machine Seated Leg Extension","es":"Extensión de cuádriceps en máquina","hist":[[9,80.0],[8,80.0],[8,80.0]]},{"n":10,"alias":"Machine Seated Hip Adduction","es":"Aductores en máquina","hist":[[12,102.5],[11,110.0]]},{"n":11,"alias":"Machine Seated Calf Raise","es":"Gemelo sentado en máquina","hist":[[10,25.0],[10,25.0],[10,25.0],[10,25.0]]},{"n":12,"alias":"Dip Machine Straight Leg Raise","es":"Elevación de piernas rectas en paralelas","hist":[[15,null],[15,null],[15,null]]},{"n":13,"alias":"Seated Machine Ab Crunch","es":"Crunch abdominal en máquina","hist":[[15,35.0],[15,35.0],[15,35.0],[15,35.0]]},{"n":14,"alias":"Horizontal Cable Rotation","es":"Rotación horizontal en polea","hist":[[15,20.0],[15,23.0],[12,23.0]]}]},{"fecha":"2026-09-29","rutina":"Push Training","duracion_seg":4980,"ejercicios":[{"n":1,"alias":"Dumbbell Standing Shoulder External Rotations","es":"Rotación externa de hombro de pie","hist":[[6,null],[6,null]]},{"n":2,"alias":"Dumbbell Incline Bench Press","es":"Press inclinado con mancuernas","hist":[[8,25.0],[8,25.0],[8,25.0],[8,25.0]]},{"n":3,"alias":"Dip","es":"Fondos en paralelas","hist":[[9,null],[9,null],[9,null],[9,null]]},{"n":4,"alias":"Machine Seated Chest Fly","es":"Aperturas en máquina","hist":[[9,80.0],[9,80.0],[8,80.0],[7,80.0]]},{"n":5,"alias":"Dumbbell Seated Arnold Press","es":"Press Arnold sentado","hist":[[9,12.5],[8,12.5],[8,12.5],[9,12.5]]},{"n":6,"alias":"Cable Lateral Raise","es":"Elevación lateral en polea","hist":[[12,3.7],[11,6.25],[9,6.25],[9,6.25]]},{"n":7,"alias":"Cable V Bar Tricep Pushdown","es":"Extensión de tríceps en polea alta","hist":[[12,23.0],[10,27.0],[10,27.0],[7,32.0]]},{"n":8,"alias":"Cable V-Bar Overhead Tricep Extension","es":"Extensión de tríceps sobre la cabeza en polea","hist":[[10,36.0],[12,41.0],[12,41.0],[10,41.0]]}]},{"fecha":"2026-09-30","rutina":"Pull Training","duracion_seg":3660,"ejercicios":[{"n":1,"alias":"Mini Band Wall Slides","es":"Deslizamientos en pared con banda","hist":[[12,null],[12,null]]},{"n":2,"alias":"Cable External Rotation","es":"Rotación externa en polea","hist":[[8,9.0]]},{"n":3,"alias":"Bar Hang","es":"Colgarse de la barra","hist":[[60,null]],"tiempo":true},{"n":4,"alias":"Pull Up","es":"Dominada","hist":[[9,null],[9,null],[8,null],[7,null]]},{"n":5,"alias":"Machine Seated Single Arm Neutral Grip Row","es":"Remo a una mano en máquina agarre neutro","hist":[[8,70.0],[8,70.0],[7,70.0],[7,70.0]]},{"n":6,"alias":"EZ Bar Preacher Curl","es":"Curl predicador con barra Z","hist":[[8,10.0],[8,10.0],[7,10.0],[7,10.0]]},{"n":7,"alias":"Dumbbell Incline Bicep Curl","es":"Curl inclinado con mancuernas","hist":[[11,12.5],[8,12.5],[7,12.5],[7,12.5]]},{"n":8,"alias":"Dumbbell Hammer Curl","es":"Curl martillo con mancuernas","hist":[[12,12.5],[8,12.5],[8,15.0],[7,15.0]]},{"n":9,"alias":"Dumbbell Shrug","es":"Encogimiento de trapecio con mancuernas","hist":[[12,25.0],[12,25.0],[12,25.0],[12,25.0]]}]},{"fecha":"2026-10-01","rutina":"Lower Body + Core Training","duracion_seg":null,"ejercicios":[{"n":1,"alias":"90-90 Hip Switch","es":"Cambio de cadera 90-90","hist":[[6,null],[6,null]]},{"n":2,"alias":"Cossack Squat to T-Spine Reach","es":"Sentadilla cosaco con alcance torácico","hist":[[6,null],[6,null]]},{"n":3,"alias":"1/2 Kneel to High Knee Hop","es":"Salto de rodilla alta desde media rodilla","hist":[[6,null],[6,null]]},{"n":4,"alias":"1/2 Kneel to Lateral Bound","es":"Salto lateral desde media rodilla","hist":[[8,null],[8,null]]},{"n":5,"alias":"Shuttle Run","es":"Ida y vuelta corta","hist":[[60,null]]},{"n":6,"alias":"Angled Machine Leg Press","es":"Prensa inclinada","hist":[[9,70.0],[9,70.0],[7,82.5],[7,82.5]]},{"n":7,"alias":"Hip Thrust Machine","es":"Hip thrust en máquina","hist":[[10,45.0],[7,57.5],[7,57.5],[7,57.5]]},{"n":8,"alias":"Machine Seated Leg Extension","es":"Extensión de cuádriceps en máquina","hist":[[9,80.0],[9,80.0],[8,87.5]]},{"n":9,"alias":"Machine Seated Hip Adduction","es":"Aductores en máquina","hist":[[12,110.0],[12,110.0],[12,110.0]]},{"n":10,"alias":"Machine Seated Calf Raise","es":"Gemelo sentado en máquina","hist":[[10,25.0],[10,25.0],[9,25.0],[9,25.0]]},{"n":11,"alias":"Dip Machine Straight Leg Raise","es":"Elevación de piernas rectas en paralelas","hist":[[15,null],[15,null],[15,null]]},{"n":12,"alias":"Seated Machine Ab Crunch","es":"Crunch abdominal en máquina","hist":[[15,35.0],[15,35.0],[15,35.0],[15,35.0]]}]},{"fecha":"2026-10-02","rutina":"Push Training","duracion_seg":null,"ejercicios":[{"n":1,"alias":"Dumbbell Standing Shoulder External Rotations","es":"Rotación externa de hombro de pie","hist":[[6,null],[6,null]]},{"n":2,"alias":"Clapping Push Up","es":"Flexión con palmada","hist":[[6,null],[6,null]]},{"n":3,"alias":"Dumbbell Incline Bench Press","es":"Press inclinado con mancuernas","hist":[[8,25.0],[8,25.0],[8,25.0],[7,25.0]]},{"n":4,"alias":"Dip","es":"Fondos en paralelas","hist":[[9,null],[10,null],[8,null],[8,null]]},{"n":5,"alias":"Machine Seated Chest Fly","es":"Aperturas en máquina","hist":[[10,80.0],[9,80.0],[8,80.0],[7,80.0]]},{"n":6,"alias":"Dumbbell Seated Arnold Press","es":"Press Arnold sentado","hist":[[10,12.5],[10,12.5],[8,12.5],[8,12.5]]},{"n":7,"alias":"Cable Lateral Raise","es":"Elevación lateral en polea","hist":[[12,3.7],[12,6.25],[8,6.25],[8,6.25]]},{"n":8,"alias":"Cable V Bar Tricep Pushdown","es":"Extensión de tríceps en polea alta","hist":[[10,23.0],[8,27.0],[8,27.0],[7,32.0]]},{"n":9,"alias":"Cable V-Bar Overhead Tricep Extension","es":"Extensión de tríceps sobre la cabeza en polea","hist":[[10,36.0],[10,36.0],[10,36.0],[10,36.0]]}]},{"fecha":"2026-10-05","rutina":"Lower Body + Core Training","duracion_seg":null,"ejercicios":[{"n":1,"alias":"90-90 Hip Switch","es":"Cambio de cadera 90-90","hist":[[6,null],[6,null]]},{"n":2,"alias":"Cossack Squat to T-Spine Reach","es":"Sentadilla cosaco con alcance torácico","hist":[[6,null],[6,null]]},{"n":3,"alias":"1/2 Kneel to High Knee Hop","es":"Salto de rodilla alta desde media rodilla","hist":[[6,null],[6,null]]},{"n":4,"alias":"1/2 Kneel to Lateral Bound","es":"Salto lateral desde media rodilla","hist":[[8,null],[6,null]]},{"n":5,"alias":"Shuttle Run","es":"Ida y vuelta corta","hist":[[60,null],[60,null]]},{"n":6,"alias":"Angled Machine Leg Press","es":"Prensa inclinada","hist":[[10,70.0],[10,70.0],[8,82.5],[8,82.5]]},{"n":7,"alias":"Smith Machine Sumo Deadlift","es":"Peso muerto sumo en multipower","hist":[[10,17.5],[9,17.5],[9,17.5],[9,17.5]]},{"n":8,"alias":"Hip Thrust Machine","es":"Hip thrust en máquina","hist":[[9,45.0],[9,45.0],[8,45.0],[7,45.0]]},{"n":9,"alias":"Machine Seated Leg Extension","es":"Extensión de cuádriceps en máquina","hist":[[9,80.0],[9,80.0],[8,80.0]]},{"n":10,"alias":"Machine Seated Hip Adduction","es":"Aductores en máquina","hist":[[12,110.0],[10,110.0]],"nota":"1104 kg (¿dedazo?)"},{"n":11,"alias":"Machine Seated Calf Raise","es":"Gemelo sentado en máquina","hist":[[12,22.5],[12,22.5],[12,22.5],[10,22.5]]},{"n":12,"alias":"Dip Machine Straight Leg Raise","es":"Elevación de piernas rectas en paralelas","hist":[[15,null],[15,null],[15,null]]}]},{"fecha":"2026-10-06","rutina":"Push Training","duracion_seg":null,"ejercicios":[{"n":1,"alias":"Dumbbell Standing Shoulder External Rotations","es":"Rotación externa de hombro de pie","hist":[[6,null],[6,null]]},{"n":2,"alias":"Clapping Push Up","es":"Flexión con palmada","hist":[[6,null],[6,null]]},{"n":3,"alias":"Dumbbell Incline Bench Press","es":"Press inclinado con mancuernas","hist":[[12,20.0],[10,20.0],[9,20.0],[9,20.0]]},{"n":4,"alias":"Dip","es":"Fondos en paralelas","hist":[[9,null],[9,null],[9,null],[9,null]]},{"n":5,"alias":"Machine Seated Chest Fly","es":"Aperturas en máquina","hist":[[10,72.0],[10,72.0],[9,72.0],[7,80.0]]},{"n":6,"alias":"Dumbbell Seated Arnold Press","es":"Press Arnold sentado","hist":[[12,12.5],[10,12.5],[8,12.5],[9,12.5]]},{"n":7,"alias":"Cable Lateral Raise","es":"Elevación lateral en polea","hist":[[12,3.7],[10,6.25],[9,6.25],[9,6.25]]},{"n":8,"alias":"Cable V Bar Tricep Pushdown","es":"Extensión de tríceps en polea alta","hist":[[12,23.0],[8,27.0],[8,27.0],[7,27.0]]},{"n":9,"alias":"Cable V-Bar Overhead Tricep Extension","es":"Extensión de tríceps sobre la cabeza en polea","hist":[[12,36.0],[10,36.0],[12,36.0],[10,36.0]]}]},{"fecha":"2026-10-07","rutina":"Pull Training","duracion_seg":null,"ejercicios":[{"n":1,"alias":"Mini Band Wall Slides","es":"Deslizamientos en pared con banda","hist":[[12,null],[12,null]]},{"n":2,"alias":"Cable External Rotation","es":"Rotación externa en polea","hist":[[9,9.0]]},{"n":3,"alias":"Bar Hang","es":"Colgarse de la barra","hist":[[60,null]],"tiempo":true},{"n":4,"alias":"Pull Up","es":"Dominada","hist":[[10,null],[9,null],[9,null],[7,null]]},{"n":5,"alias":"Machine Seated Single Arm Neutral Grip Row","es":"Remo a una mano en máquina agarre neutro","hist":[[10,50.0],[10,50.0],[8,50.0],[8,50.0]]},{"n":6,"alias":"EZ Bar Preacher Curl","es":"Curl predicador con barra Z","hist":[[9,8.5],[9,8.5],[9,10.0],[8,10.0]]},{"n":7,"alias":"Dumbbell Incline Bicep Curl","es":"Curl inclinado con mancuernas","hist":[[9,12.5],[8,12.5],[7,12.5],[7,12.5]]},{"n":8,"alias":"Dumbbell Hammer Curl","es":"Curl martillo con mancuernas","hist":[[12,12.5],[12,12.5],[12,12.5],[12,12.5]]},{"n":9,"alias":"Dumbbell Shrug","es":"Encogimiento de trapecio con mancuernas","hist":[[12,25.0],[10,25.0],[10,25.0],[8,25.0]]},{"n":10,"alias":"Machine Seated Reverse Fly","es":"Pájaro en máquina","hist":[[10,50.0],[8,70.0],[8,70.0]]}]},{"fecha":"2026-10-08","rutina":"Lower Body + Core Training","duracion_seg":8340,"ejercicios":[{"n":1,"alias":"90-90 Hip Switch","es":"Cambio de cadera 90-90","hist":[[6,null],[6,null]]},{"n":2,"alias":"Cossack Squat to T-Spine Reach","es":"Sentadilla cosaco con alcance torácico","hist":[[6,null],[6,null]]},{"n":3,"alias":"1/2 Kneel to High Knee Hop","es":"Salto de rodilla alta desde media rodilla","hist":[[6,null],[6,null]]},{"n":4,"alias":"1/2 Kneel to Lateral Bound","es":"Salto lateral desde media rodilla","hist":[[6,null],[6,null]]},{"n":5,"alias":"Shuttle Run","es":"Ida y vuelta corta","hist":[[60,null],[60,null]]},{"n":6,"alias":"Angled Machine Leg Press","es":"Prensa inclinada","hist":[[10,70.0],[10,70.0],[10,70.0],[8,70.0]]},{"n":7,"alias":"Hip Thrust Machine","es":"Hip thrust en máquina","hist":[[8,45.0],[8,45.0],[8,45.0],[7,45.0]]},{"n":8,"alias":"Machine Seated Leg Extension","es":"Extensión de cuádriceps en máquina","hist":[[10,70.0],[9,80.0],[9,80.0]]},{"n":9,"alias":"Machine Seated Hip Adduction","es":"Aductores en máquina","hist":[[10,110.0],[10,110.0],[10,110.0]]},{"n":10,"alias":"Machine Seated Calf Raise","es":"Gemelo sentado en máquina","hist":[[10,22.5],[10,22.5],[10,22.5],[10,22.5]]},{"n":11,"alias":"Dip Machine Straight Leg Raise","es":"Elevación de piernas rectas en paralelas","hist":[[15,null],[15,null],[15,null]]},{"n":12,"alias":"Seated Machine Ab Crunch","es":"Crunch abdominal en máquina","hist":[[15,null],[15,null],[15,null],[15,null]]},{"n":13,"alias":"Horizontal Cable Rotation","es":"Rotación horizontal en polea","hist":[[15,20.0],[12,20.0],[12,20.0]]}]}],"foto":{"inicio":"2026-09-28","hechas":9,"programadas":12,"datos":{"estructura":"Lower Body + Core Training / Pull Training / Push Training","calendario":"Lun: Lower Body + Core Training · Mar: Push Training · Mié: Pull Training · Jue: Lower Body + Core Training · Vie: Push Training · Sáb: Pull Training","ventana":"2026-09-28 → 2026-10-11","ciclo_inicio":"2026-09-14","cardio":[{"tipo":"Walking","dias":["L","M","X","J","V","S","D"],"hechas":0,"programadas":14},{"tipo":"Running","dias":["L","M","X","J","V","S"],"hechas":0,"programadas":12}],"rutinas":[{"nombre":"Lower Body + Core Training","dias":["L","J"],"hechas":4,"programadas":4,"ultima":"2026-10-08","duracion":69,"ejercicios":[{"n":1,"alias":"90-90 Hip Switch","es":"Cambio de cadera 90-90","ss":1,"series":1,"reps":"6","descanso":30,"prescrito":"2× 6 reps","ultimo":"2× 6 (2026-10-08)","fecha":"2026-10-08","anterior":false,"hist":[[6,null],[6,null]]},{"n":2,"alias":"Cossack Squat to T-Spine Reach","es":"Sentadilla cosaco con alcance torácico","ss":1,"series":1,"reps":"6 por lado","descanso":30,"prescrito":"2× 6 reps ea. side","ultimo":"2× 6 (2026-10-08)","fecha":"2026-10-08","anterior":false,"hist":[[6,null],[6,null]]},{"n":3,"alias":"1/2 Kneel to High Knee Hop","es":"Salto de rodilla alta desde media rodilla","ss":2,"series":1,"reps":"6 por lado","descanso":30,"prescrito":"2× 6 reps ea. side","ultimo":"2× 6 (2026-10-08)","fecha":"2026-10-08","anterior":false,"hist":[[6,null],[6,null]]},{"n":4,"alias":"1/2 Kneel to Lateral Bound","es":"Salto lateral desde media rodilla","ss":2,"series":1,"reps":"8","descanso":30,"prescrito":"2× 8 reps","ultimo":"2× 6 (2026-10-08)","fecha":"2026-10-08","anterior":false,"hist":[[6,null],[6,null]]},{"n":5,"alias":"Shuttle Run","es":"Ida y vuelta corta","ss":2,"series":1,"reps":"60 s","descanso":30,"prescrito":"2× 60 secs","ultimo":"2× 60 (2026-10-08)","fecha":"2026-10-08","anterior":false,"hist":[[60,null],[60,null]]},{"n":6,"alias":"Angled Machine Leg Press","es":"Prensa inclinada","ss":null,"series":4,"reps":"6-12","descanso":50,"prescrito":"4× 6-12 reps","ultimo":"10 @ 70kg, 10 @ 70kg, 10 @ 70kg, 8 @ 70kg (2026-10-08)","fecha":"2026-10-08","anterior":false,"hist":[[10,70.0],[10,70.0],[10,70.0],[8,70.0]]},{"n":7,"alias":"Smith Machine Sumo Deadlift","es":"Peso muerto sumo en multipower","ss":null,"series":4,"reps":"6-12","descanso":50,"prescrito":"4× 6-12 reps","ultimo":"10 @ 17.5kg, 9 @ 17.5kg, 9 @ 17.5kg, 9 @ 17.5kg (2026-10-05)","fecha":"2026-10-05","anterior":false,"hist":[[10,17.5],[9,17.5],[9,17.5],[9,17.5]]},{"n":8,"alias":"Hip Thrust Machine","es":"Hip thrust en máquina","ss":null,"series":4,"reps":"6-12","descanso":50,"prescrito":"4× 6-12 reps","ultimo":"8 @ 45kg, 8 @ 45kg, 8 @ 45kg, 7 @ 45kg (2026-10-08)","fecha":"2026-10-08","anterior":false,"hist":[[8,45.0],[8,45.0],[8,45.0],[7,45.0]]},{"n":9,"alias":"Machine Seated Leg Extension","es":"Extensión de cuádriceps en máquina","ss":null,"series":3,"reps":"6-12","descanso":50,"prescrito":"3× 6-12 reps","ultimo":"10 @ 70kg, 9 @ 80kg, 9 @ 80kg (2026-10-08)","fecha":"2026-10-08","anterior":false,"hist":[[10,70.0],[9,80.0],[9,80.0]]},{"n":10,"alias":"Machine Seated Hip Adduction","es":"Aductores en máquina","ss":null,"series":3,"reps":"6-12","descanso":50,"prescrito":"3× 6-12 reps","ultimo":"3× 10 @ 110kg (2026-10-08)","fecha":"2026-10-08","anterior":false,"hist":[[10,110.0],[10,110.0],[10,110.0]]},{"n":11,"alias":"Machine Seated Calf Raise","es":"Gemelo sentado en máquina","ss":null,"series":4,"reps":"6-12","descanso":50,"prescrito":"4× 6-12 reps","ultimo":"4× 10 @ 22.5kg (2026-10-08)","fecha":"2026-10-08","anterior":false,"hist":[[10,22.5],[10,22.5],[10,22.5],[10,22.5]]},{"n":12,"alias":"Dip Machine Straight Leg Raise","es":"Elevación de piernas rectas en paralelas","ss":null,"series":3,"reps":"15","descanso":50,"prescrito":"3× 15 reps","ultimo":"3× 15 (2026-10-08)","fecha":"2026-10-08","anterior":false,"hist":[[15,null],[15,null],[15,null]]},{"n":13,"alias":"Seated Machine Ab Crunch","es":"Crunch abdominal en máquina","ss":null,"series":4,"reps":"15","descanso":30,"prescrito":"4× 15 reps","ultimo":"4× 15 (2026-10-08)","fecha":"2026-10-08","anterior":false,"hist":[[15,null],[15,null],[15,null],[15,null]]},{"n":14,"alias":"Horizontal Cable Rotation","es":"Rotación horizontal en polea","ss":null,"series":3,"reps":"15","descanso":30,"prescrito":"3× 15 reps","ultimo":"15 @ 20kg, 12 @ 20kg, 12 @ 20kg (2026-10-08)","fecha":"2026-10-08","anterior":false,"hist":[[15,20.0],[12,20.0],[12,20.0]]},{"n":15,"alias":"Static Pigeon Stretch","es":"Estiramiento de paloma","ss":null,"series":1,"reps":"30 s por lado","descanso":null,"prescrito":"1× 30 secs ea. side","ultimo":"sin registro"}]},{"nombre":"Pull Training","dias":["X","S"],"hechas":2,"programadas":4,"ultima":"2026-10-07","duracion":61,"ejercicios":[{"n":1,"alias":"Running","es":"Carrera continua","ss":null,"series":1,"reps":"3 min a intensidad moderada","descanso":45,"prescrito":"1× 3 minutes at a moderate intensity","ultimo":"1× 900s (2026-09-26) ⚠ tiempo atípico","fecha":"2026-09-26","anterior":false,"hist":[[900,null]],"tiempo":true,"alerta":"tiempo atípico"},{"n":2,"alias":"Table Top Half Arm Thoracic Rotation","es":"Rotación torácica en cuadrupedia","ss":1,"series":1,"reps":"5 por lado","descanso":30,"prescrito":"2× 5 reps ea. side","ultimo":"sin registro"},{"n":3,"alias":"Mini Band Wall Slides","es":"Deslizamientos en pared con banda","ss":1,"series":1,"reps":"8","descanso":30,"prescrito":"2× 8 reps","ultimo":"2× 12 (2026-10-07)","fecha":"2026-10-07","anterior":false,"hist":[[12,null],[12,null]]},{"n":4,"alias":"Cable External Rotation","es":"Rotación externa en polea","ss":null,"series":1,"reps":"8 por lado","descanso":45,"prescrito":"1× 8 reps ea. side","ultimo":"9 @ 9kg (2026-10-07)","fecha":"2026-10-07","anterior":false,"hist":[[9,9.0]]},{"n":5,"alias":"Bar Hang","es":"Colgarse de la barra","ss":null,"series":1,"reps":"60 s","descanso":30,"prescrito":"1× 60 secs","ultimo":"60s (2026-10-07)","fecha":"2026-10-07","anterior":false,"hist":[[60,null]],"tiempo":true},{"n":6,"alias":"Pull Up","es":"Dominada","ss":null,"series":4,"reps":"6-12","descanso":50,"prescrito":"4× 6-12 reps","ultimo":"10, 9, 9, 7 (2026-10-07)","fecha":"2026-10-07","anterior":false,"hist":[[10,null],[9,null],[9,null],[7,null]]},{"n":7,"alias":"Machine Seated Single Arm Neutral Grip Row","es":"Remo a una mano en máquina agarre neutro","ss":null,"series":4,"reps":"6-12 por lado","descanso":50,"prescrito":"4× 6-12 reps ea. side","ultimo":"10 @ 50kg, 10 @ 50kg, 8 @ 50kg, 8 @ 50kg (2026-10-07)","fecha":"2026-10-07","anterior":false,"hist":[[10,50.0],[10,50.0],[8,50.0],[8,50.0]]},{"n":8,"alias":"EZ Bar Preacher Curl","es":"Curl predicador con barra Z","ss":null,"series":4,"reps":"6-12","descanso":50,"prescrito":"4× 6-12 reps","ultimo":"9 @ 8.5kg, 9 @ 8.5kg, 9 @ 10kg, 8 @ 10kg (2026-10-07)","fecha":"2026-10-07","anterior":false,"hist":[[9,8.5],[9,8.5],[9,10.0],[8,10.0]]},{"n":9,"alias":"Dumbbell Incline Bicep Curl","es":"Curl inclinado con mancuernas","ss":null,"series":4,"reps":"6-12","descanso":50,"prescrito":"4× 6-12 reps","ultimo":"9 @ 12.5kg, 8 @ 12.5kg, 7 @ 12.5kg, 7 @ 12.5kg (2026-10-07)","fecha":"2026-10-07","anterior":false,"hist":[[9,12.5],[8,12.5],[7,12.5],[7,12.5]]},{"n":10,"alias":"Dumbbell Hammer Curl","es":"Curl martillo con mancuernas","ss":null,"series":4,"reps":"6-12","descanso":50,"prescrito":"4× 6-12 reps","ultimo":"4× 12 @ 12.5kg (2026-10-07)","fecha":"2026-10-07","anterior":false,"hist":[[12,12.5],[12,12.5],[12,12.5],[12,12.5]]},{"n":11,"alias":"Dumbbell Shrug","es":"Encogimiento de trapecio con mancuernas","ss":null,"series":4,"reps":"6-12","descanso":50,"prescrito":"4× 6-12 reps","ultimo":"12 @ 25kg, 10 @ 25kg, 10 @ 25kg, 8 @ 25kg (2026-10-07)","fecha":"2026-10-07","anterior":false,"hist":[[12,25.0],[10,25.0],[10,25.0],[8,25.0]]},{"n":12,"alias":"Machine Seated Reverse Fly","es":"Pájaro en máquina","ss":null,"series":4,"reps":"6-12","descanso":50,"prescrito":"4× 6-12 reps","ultimo":"10 @ 50kg, 8 @ 70kg, 8 @ 70kg (2026-10-07)","fecha":"2026-10-07","anterior":false,"hist":[[10,50.0],[8,70.0],[8,70.0]]},{"n":13,"alias":"Suspension Low Back Stretch","es":"Estiramiento lumbar en suspensión","ss":null,"series":1,"reps":"30 s","descanso":null,"prescrito":"1× 30 secs","ultimo":"sin registro"}]},{"nombre":"Push Training","dias":["M","V"],"hechas":3,"programadas":4,"ultima":"2026-10-06","duracion":61,"ejercicios":[{"n":1,"alias":"Running","es":"Carrera continua","ss":null,"series":1,"reps":"Caminadora: 3 min intensidad moderada","descanso":45,"prescrito":"1× Treadmill: 3 minutes at a moderate intensity","ultimo":"1× 900s (2026-09-26) ⚠ tiempo atípico","fecha":"2026-09-26","anterior":false,"hist":[[900,null]],"tiempo":true,"alerta":"tiempo atípico"},{"n":2,"alias":"Dumbbell Standing Shoulder External Rotations","es":"Rotación externa de hombro de pie","ss":1,"series":1,"reps":"6","descanso":30,"prescrito":"2× 6 reps","ultimo":"2× 6 (2026-10-06)","fecha":"2026-10-06","anterior":false,"hist":[[6,null],[6,null]]},{"n":3,"alias":"SuperBand Dislocates","es":"Dislocaciones de hombro con banda","ss":1,"series":1,"reps":"6","descanso":30,"prescrito":"2× 6 reps","ultimo":"sin registro"},{"n":4,"alias":"Clapping Push Up","es":"Flexión con palmada","ss":null,"series":2,"reps":"6-8","descanso":30,"prescrito":"2× 6-8 reps","ultimo":"2× 6 (2026-10-06)","fecha":"2026-10-06","anterior":false,"hist":[[6,null],[6,null]]},{"n":5,"alias":"Dumbbell Incline Bench Press","es":"Press inclinado con mancuernas","ss":null,"series":4,"reps":"6-12","descanso":50,"prescrito":"4× 6-12 reps","ultimo":"12 @ 20kg, 10 @ 20kg, 9 @ 20kg, 9 @ 20kg (2026-10-06)","fecha":"2026-10-06","anterior":false,"hist":[[12,20.0],[10,20.0],[9,20.0],[9,20.0]]},{"n":6,"alias":"Dip","es":"Fondos en paralelas","ss":null,"series":4,"reps":"6-12","descanso":50,"prescrito":"4× 6-12 reps","ultimo":"4× 9 (2026-10-06)","fecha":"2026-10-06","anterior":false,"hist":[[9,null],[9,null],[9,null],[9,null]]},{"n":7,"alias":"Machine Seated Chest Fly","es":"Aperturas en máquina","ss":null,"series":4,"reps":"6-12","descanso":50,"prescrito":"4× 6-12 reps","ultimo":"10 @ 72kg, 10 @ 72kg, 9 @ 72kg, 7 @ 80kg (2026-10-06)","fecha":"2026-10-06","anterior":false,"hist":[[10,72.0],[10,72.0],[9,72.0],[7,80.0]]},{"n":8,"alias":"Dumbbell Seated Arnold Press","es":"Press Arnold sentado","ss":null,"series":4,"reps":"6-12","descanso":50,"prescrito":"4× 6-12 reps","ultimo":"12 @ 12.5kg, 10 @ 12.5kg, 8 @ 12.5kg, 9 @ 12.5kg (2026-10-06)","fecha":"2026-10-06","anterior":false,"hist":[[12,12.5],[10,12.5],[8,12.5],[9,12.5]]},{"n":9,"alias":"Cable Lateral Raise","es":"Elevación lateral en polea","ss":null,"series":4,"reps":"6-12 por lado","descanso":50,"prescrito":"4× 6-12 reps ea. side","ultimo":"12 @ 3.7kg, 10 @ 6.25kg, 9 @ 6.25kg, 9 @ 6.25kg (2026-10-06)","fecha":"2026-10-06","anterior":false,"hist":[[12,3.7],[10,6.25],[9,6.25],[9,6.25]]},{"n":10,"alias":"Cable V Bar Tricep Pushdown","es":"Extensión de tríceps en polea alta","ss":null,"series":4,"reps":"6-12","descanso":50,"prescrito":"4× 6-12 reps","ultimo":"12 @ 23kg, 8 @ 27kg, 8 @ 27kg, 7 @ 27kg (2026-10-06)","fecha":"2026-10-06","anterior":false,"hist":[[12,23.0],[8,27.0],[8,27.0],[7,27.0]]},{"n":11,"alias":"Cable V-Bar Overhead Tricep Extension","es":"Extensión de tríceps sobre la cabeza en polea","ss":null,"series":4,"reps":"6-12","descanso":50,"prescrito":"4× 6-12 reps","ultimo":"12 @ 36kg, 10 @ 36kg, 12 @ 36kg, 10 @ 36kg (2026-10-06)","fecha":"2026-10-06","anterior":false,"hist":[[12,36.0],[10,36.0],[12,36.0],[10,36.0]]},{"n":12,"alias":"Child's Pose","es":"Postura del niño","ss":null,"series":1,"reps":"30 s","descanso":null,"prescrito":"1× 1 set x 30 secs","ultimo":"sin registro"}]}]}}}$tz$::jsonb);






commit;

-- Una fila por cliente: qué hizo la carga.
select * from _tz12_res order by cliente;


-- Ciclo en español, como los demás (renombrar-ciclos.sql, solo para él).
update fases set nombre = regexp_replace(nombre, '\mcycle\M', 'Ciclo', 'gi')
 where nombre ~* '\mcycle\M' and cliente_id in (select id from clientes where nombre ilike '%santiago f%');

select c.nombre as cliente, f.nombre as fase, f.estado, f.visible_cliente as enviado, array_to_string(f.dias_semana, ' ') as dias,
       (select count(*) from rutinas r where r.fase_id = f.id and not r.archivada) as rutinas,
       (select count(*) from sesiones s where s.fase_id = f.id) as sesiones
  from clientes c join fases f on f.cliente_id = c.id
 where c.nombre ilike '%santiago f%';

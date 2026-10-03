-- ═══════════════════════════════════════════════════════════════════════
-- CARGA DE RUTINA · Mauro Morón · Ciclo 2 · exportada de Trainerize (20 sep 2026)
-- ═══════════════════════════════════════════════════════════════════════
-- Dónde: Supabase del CRM → SQL Editor → pegar todo → Run.
--
-- Qué hace (igual que las cargas anteriores):
--   1. Reusa las fichas de los 38 ejercicios (ya están en tu galería desde las
--      cargas anteriores; si faltara alguno, lo crea con su nombre en español
--      y el de Trainerize en `alias`).
--   2. Crea la FASE «Ciclo 2»: 5 semanas, del 14 sep al 18 oct 2026, L-M-X-J.
--   3. Crea las 3 RUTINAS con sus circuitos, series, reps, descansos y días:
--        Lower Body + Core Training → lunes y jueves
--        Push Training              → martes
--        Pull Training              → miércoles
--   4. Carga el HISTORIAL de «Previous Stats» (14, 15, 16 y 17 sep) como
--      sesiones completadas con `origen = 'importada'`.
--
-- DIFERENCIA con las otras cargas: esta fase entra ACTIVA y VISIBLE, para que
-- la veas ya en la app. Las de los clientes entraron como borrador.
--
-- Se puede correr dos veces: si Mauro ya tiene «Ciclo 2», se salta solo.
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

create temp table if not exists _ecm_mm (alias text primary key, id uuid) on commit drop;

do $cli$
declare v_coach uuid; v_cli uuid; v_fase uuid; v_rut uuid; v_blo uuid; v_ses uuid;
begin
  select id, user_id into v_cli, v_coach from clientes where nombre ilike '%mauro%mor%n%' limit 1;
  if v_cli is null then
    raise warning 'SALTADO: no encuentro a «Mauro Morón» en `clientes`. Corrige el nombre y vuelve a correr.';
    return;
  end if;
  if exists (select 1 from fases where cliente_id = v_cli and nombre in ('Cycle 2', 'Ciclo 2')) then
    raise notice 'SALTADO: «Mauro Morón» ya tiene la fase Ciclo 2 cargada.';
    return;
  end if;

  delete from _ecm_mm;
  insert into _ecm_mm values ('90-90 Hip Switch', ecm_ej(v_coach, '90-90 Hip Switch', 'Cambio de cadera 90-90', 'movilidad', 'core', null, array['peso_corporal']::text[], false));
  insert into _ecm_mm values ('Cossack Squat to T-Spine Reach', ecm_ej(v_coach, 'Cossack Squat to T-Spine Reach', 'Sentadilla cosaco con alcance torácico', 'movilidad', 'full_body', null, array['peso_corporal']::text[], true));
  insert into _ecm_mm values ('1/2 Kneel to High Knee Hop', ecm_ej(v_coach, '1/2 Kneel to High Knee Hop', 'Salto de rodilla alta desde media rodilla', 'pliometrico', 'tren_inferior', null, array['peso_corporal']::text[], true));
  insert into _ecm_mm values ('1/2 Kneel to Lateral Bound', ecm_ej(v_coach, '1/2 Kneel to Lateral Bound', 'Salto lateral desde media rodilla', 'pliometrico', 'tren_inferior', null, array['peso_corporal']::text[], true));
  insert into _ecm_mm values ('Shuttle Run', ecm_ej(v_coach, 'Shuttle Run', 'Ida y vuelta corta', 'agilidad', 'full_body', 'locomocion', array['peso_corporal']::text[], false));
  insert into _ecm_mm values ('Angled Machine Leg Press', ecm_ej(v_coach, 'Angled Machine Leg Press', 'Prensa inclinada', 'fuerza', 'tren_inferior', 'rodilla', array['maquina']::text[], false));
  insert into _ecm_mm values ('Smith Machine Sumo Deadlift', ecm_ej(v_coach, 'Smith Machine Sumo Deadlift', 'Peso muerto sumo en multipower', 'fuerza', 'tren_inferior', 'cadera', array['maquina']::text[], false));
  insert into _ecm_mm values ('Hip Thrust Machine', ecm_ej(v_coach, 'Hip Thrust Machine', 'Hip thrust en máquina', 'fuerza', 'tren_inferior', 'cadera', array['maquina']::text[], false));
  insert into _ecm_mm values ('Machine Seated Leg Extension', ecm_ej(v_coach, 'Machine Seated Leg Extension', 'Extensión de cuádriceps en máquina', 'fuerza', 'tren_inferior', 'rodilla', array['maquina']::text[], false));
  insert into _ecm_mm values ('Machine Seated Hip Adduction', ecm_ej(v_coach, 'Machine Seated Hip Adduction', 'Aductores en máquina', 'fuerza', 'tren_inferior', null, array['maquina']::text[], false));
  insert into _ecm_mm values ('Machine Seated Calf Raise', ecm_ej(v_coach, 'Machine Seated Calf Raise', 'Gemelo sentado en máquina', 'fuerza', 'tren_inferior', null, array['maquina']::text[], false));
  insert into _ecm_mm values ('Dip Machine Straight Leg Raise', ecm_ej(v_coach, 'Dip Machine Straight Leg Raise', 'Elevación de piernas rectas en paralelas', 'core', 'core', 'core', array['maquina']::text[], false));
  insert into _ecm_mm values ('Seated Machine Ab Crunch', ecm_ej(v_coach, 'Seated Machine Ab Crunch', 'Crunch abdominal en máquina', 'core', 'core', 'core', array['maquina']::text[], false));
  insert into _ecm_mm values ('Horizontal Cable Rotation', ecm_ej(v_coach, 'Horizontal Cable Rotation', 'Rotación horizontal en polea', 'fuerza', 'core', null, array['polea']::text[], true));
  insert into _ecm_mm values ('Static Pigeon Stretch', ecm_ej(v_coach, 'Static Pigeon Stretch', 'Estiramiento de paloma', 'estiramiento_pasivo', 'tren_inferior', null, array['peso_corporal']::text[], true));
  insert into _ecm_mm values ('Running', ecm_ej(v_coach, 'Running', 'Carrera continua', 'cardio', 'full_body', 'locomocion', array['peso_corporal']::text[], false));
  insert into _ecm_mm values ('Table Top Half Arm Thoracic Rotation', ecm_ej(v_coach, 'Table Top Half Arm Thoracic Rotation', 'Rotación torácica en cuadrupedia', 'movilidad', 'core', null, array['peso_corporal']::text[], true));
  insert into _ecm_mm values ('Mini Band Wall Slides', ecm_ej(v_coach, 'Mini Band Wall Slides', 'Deslizamientos en pared con banda', 'movilidad', 'tren_superior', null, array['banda']::text[], false));
  insert into _ecm_mm values ('Bar Hang', ecm_ej(v_coach, 'Bar Hang', 'Colgarse de la barra', 'fuerza', 'tren_superior', 'pull', array['pull_up_bar']::text[], false));
  insert into _ecm_mm values ('Pull Up', ecm_ej(v_coach, 'Pull Up', 'Dominada', 'fuerza', 'tren_superior', 'pull', array['pull_up_bar']::text[], false));
  insert into _ecm_mm values ('Machine Seated Single Arm Neutral Grip Row', ecm_ej(v_coach, 'Machine Seated Single Arm Neutral Grip Row', 'Remo a una mano en máquina agarre neutro', 'fuerza', 'tren_superior', 'pull', array['maquina']::text[], true));
  insert into _ecm_mm values ('Machine Preacher Curl', ecm_ej(v_coach, 'Machine Preacher Curl', 'Curl predicador en máquina', 'fuerza', 'tren_superior', 'pull', array['maquina']::text[], false));
  insert into _ecm_mm values ('Dumbbell Hammer Curl', ecm_ej(v_coach, 'Dumbbell Hammer Curl', 'Curl martillo con mancuernas', 'fuerza', 'tren_superior', 'pull', array['mancuerna']::text[], false));
  insert into _ecm_mm values ('Cable Single Arm Bicep Curl', ecm_ej(v_coach, 'Cable Single Arm Bicep Curl', 'Curl de bíceps a una mano en polea', 'fuerza', 'tren_superior', 'pull', array['polea']::text[], true));
  insert into _ecm_mm values ('Cable Rope Face Pull', ecm_ej(v_coach, 'Cable Rope Face Pull', 'Face pull con cuerda', 'fuerza', 'tren_superior', 'pull', array['polea']::text[], false));
  insert into _ecm_mm values ('Dumbbell Shrug', ecm_ej(v_coach, 'Dumbbell Shrug', 'Encogimiento de trapecio con mancuernas', 'fuerza', 'tren_superior', 'pull', array['mancuerna']::text[], false));
  insert into _ecm_mm values ('Suspension Low Back Stretch', ecm_ej(v_coach, 'Suspension Low Back Stretch', 'Estiramiento lumbar en suspensión', 'estiramiento_pasivo', 'core', null, array['trx']::text[], false));
  insert into _ecm_mm values ('Decline Plank to Pike', ecm_ej(v_coach, 'Decline Plank to Pike', 'Plancha declinada a pica', 'fuerza', 'core', null, array['banco']::text[], false));
  insert into _ecm_mm values ('Dumbbell Standing Shoulder External Rotations', ecm_ej(v_coach, 'Dumbbell Standing Shoulder External Rotations', 'Rotación externa de hombro de pie', 'movilidad', 'tren_superior', null, array['mancuerna']::text[], false));
  insert into _ecm_mm values ('SuperBand Dislocates', ecm_ej(v_coach, 'SuperBand Dislocates', 'Dislocaciones de hombro con banda', 'movilidad', 'tren_superior', null, array['banda']::text[], false));
  insert into _ecm_mm values ('Dumbbell Incline Bench Press', ecm_ej(v_coach, 'Dumbbell Incline Bench Press', 'Press inclinado con mancuernas', 'fuerza', 'tren_superior', 'push', array['mancuerna','banco']::text[], false));
  insert into _ecm_mm values ('Landmine Half-Kneeling Single Arm Press', ecm_ej(v_coach, 'Landmine Half-Kneeling Single Arm Press', 'Press a una mano de rodillas con landmine', 'fuerza', 'tren_superior', 'push', array['barra']::text[], true));
  insert into _ecm_mm values ('Dip', ecm_ej(v_coach, 'Dip', 'Fondos en paralelas', 'fuerza', 'tren_superior', 'push', array['peso_corporal']::text[], false));
  insert into _ecm_mm values ('Machine Seated Chest Fly', ecm_ej(v_coach, 'Machine Seated Chest Fly', 'Aperturas en máquina', 'fuerza', 'tren_superior', 'push', array['maquina']::text[], false));
  insert into _ecm_mm values ('Machine Lateral Raise', ecm_ej(v_coach, 'Machine Lateral Raise', 'Elevación lateral en máquina', 'fuerza', 'tren_superior', 'push', array['maquina']::text[], false));
  insert into _ecm_mm values ('Cable V Bar Tricep Pushdown', ecm_ej(v_coach, 'Cable V Bar Tricep Pushdown', 'Extensión de tríceps en polea alta', 'fuerza', 'tren_superior', 'push', array['polea']::text[], false));
  insert into _ecm_mm values ('Cable V-Bar Overhead Tricep Extension', ecm_ej(v_coach, 'Cable V-Bar Overhead Tricep Extension', 'Extensión de tríceps sobre la cabeza en polea', 'fuerza', 'tren_superior', 'push', array['polea']::text[], false));
  insert into _ecm_mm values ('Child''s Pose', ecm_ej(v_coach, 'Child''s Pose', 'Postura del niño', 'estiramiento_pasivo', 'core', null, array['peso_corporal']::text[], false));
  if exists (select 1 from _ecm_mm where id is null) then
    raise exception 'No pude resolver: %', (select string_agg(alias, ', ') from _ecm_mm where id is null);
  end if;

  -- Las fases que ya tuviera activas quedan como finalizadas: el cliente ve
  -- una sola fase a la vez, la más nueva.
  update fases set estado = 'finalizada' where cliente_id = v_cli and estado = 'activa';

  insert into fases (user_id, cliente_id, nombre, objetivo, notas_coach, semanas,
                     fecha_inicio, dias_semana, orden, estado, visible_cliente, publicada_en)
  values (v_coach, v_cli, 'Ciclo 2',
          null,
          'Importado el 2026-09-27 desde el PDF de Trainerize (Ciclo 2, 2026-09-14 a 2026-10-18).',
          5, date '2026-09-14', array['L','M','X','J']::text[],
          coalesce((select max(orden)+1 from fases where cliente_id = v_cli), 1), 'activa', true, now())
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
  values (v_rut, v_blo, (select id from _ecm_mm where alias='90-90 Hip Switch'), 1, 1, '6', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_mm where alias='Cossack Squat to T-Spine Reach'), 2, 1, '6 por lado', 30);
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'B', 'circuito', 2, 30, 2)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_mm where alias='1/2 Kneel to High Knee Hop'), 3, 1, '6 por lado', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_mm where alias='1/2 Kneel to Lateral Bound'), 4, 1, '8', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_mm where alias='Shuttle Run'), 5, 1, '60 s', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_mm where alias='Angled Machine Leg Press'), 6, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_mm where alias='Smith Machine Sumo Deadlift'), 7, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_mm where alias='Hip Thrust Machine'), 8, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_mm where alias='Machine Seated Leg Extension'), 9, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_mm where alias='Machine Seated Hip Adduction'), 10, 3, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_mm where alias='Machine Seated Calf Raise'), 11, 4, '6-12', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_mm where alias='Dip Machine Straight Leg Raise'), 12, 3, '15', 50);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_mm where alias='Seated Machine Ab Crunch'), 13, 4, '15', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_mm where alias='Horizontal Cable Rotation'), 14, 3, '15', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_mm where alias='Static Pigeon Stretch'), 15, 1, '30 s por lado', null);
  -- historial 2026-09-14
  v_ses := null;
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach, origen)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-14', 1,
          '2026-W38', 'completada', '2026-09-14 12:00:00+00'::timestamptz, true, 'importada')
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Angled Machine Leg Press') limit 1),
            (select id from _ecm_mm where alias='Angled Machine Leg Press'), 1, 12, 47.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Angled Machine Leg Press') limit 1),
            (select id from _ecm_mm where alias='Angled Machine Leg Press'), 2, 9, 60, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Angled Machine Leg Press') limit 1),
            (select id from _ecm_mm where alias='Angled Machine Leg Press'), 3, 9, 60, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Angled Machine Leg Press') limit 1),
            (select id from _ecm_mm where alias='Angled Machine Leg Press'), 4, 8, 72, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Smith Machine Sumo Deadlift') limit 1),
            (select id from _ecm_mm where alias='Smith Machine Sumo Deadlift'), 1, 12, 12.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Smith Machine Sumo Deadlift') limit 1),
            (select id from _ecm_mm where alias='Smith Machine Sumo Deadlift'), 2, 10, 15.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Smith Machine Sumo Deadlift') limit 1),
            (select id from _ecm_mm where alias='Smith Machine Sumo Deadlift'), 3, 8, 22.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Smith Machine Sumo Deadlift') limit 1),
            (select id from _ecm_mm where alias='Smith Machine Sumo Deadlift'), 4, 7, 22.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Hip Thrust Machine') limit 1),
            (select id from _ecm_mm where alias='Hip Thrust Machine'), 1, 8, 45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Hip Thrust Machine') limit 1),
            (select id from _ecm_mm where alias='Hip Thrust Machine'), 2, 8, 45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Hip Thrust Machine') limit 1),
            (select id from _ecm_mm where alias='Hip Thrust Machine'), 3, 8, 45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Hip Thrust Machine') limit 1),
            (select id from _ecm_mm where alias='Hip Thrust Machine'), 4, 7, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Machine Seated Leg Extension') limit 1),
            (select id from _ecm_mm where alias='Machine Seated Leg Extension'), 1, 12, 54, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Machine Seated Leg Extension') limit 1),
            (select id from _ecm_mm where alias='Machine Seated Leg Extension'), 2, 10, 72, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Machine Seated Leg Extension') limit 1),
            (select id from _ecm_mm where alias='Machine Seated Leg Extension'), 3, 8, 72, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Machine Seated Hip Adduction') limit 1),
            (select id from _ecm_mm where alias='Machine Seated Hip Adduction'), 1, 12, 85, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Machine Seated Hip Adduction') limit 1),
            (select id from _ecm_mm where alias='Machine Seated Hip Adduction'), 2, 10, 102.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Machine Seated Hip Adduction') limit 1),
            (select id from _ecm_mm where alias='Machine Seated Hip Adduction'), 3, 10, 102.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_mm where alias='Machine Seated Calf Raise'), 1, 10, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_mm where alias='Machine Seated Calf Raise'), 2, 10, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_mm where alias='Machine Seated Calf Raise'), 3, 10, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_mm where alias='Machine Seated Calf Raise'), 4, 1, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Dip Machine Straight Leg Raise') limit 1),
            (select id from _ecm_mm where alias='Dip Machine Straight Leg Raise'), 1, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Dip Machine Straight Leg Raise') limit 1),
            (select id from _ecm_mm where alias='Dip Machine Straight Leg Raise'), 2, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Dip Machine Straight Leg Raise') limit 1),
            (select id from _ecm_mm where alias='Dip Machine Straight Leg Raise'), 3, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Seated Machine Ab Crunch') limit 1),
            (select id from _ecm_mm where alias='Seated Machine Ab Crunch'), 1, 15, 35, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Seated Machine Ab Crunch') limit 1),
            (select id from _ecm_mm where alias='Seated Machine Ab Crunch'), 2, 15, 35, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Seated Machine Ab Crunch') limit 1),
            (select id from _ecm_mm where alias='Seated Machine Ab Crunch'), 3, 15, 35, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Seated Machine Ab Crunch') limit 1),
            (select id from _ecm_mm where alias='Seated Machine Ab Crunch'), 4, 15, 35, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Horizontal Cable Rotation') limit 1),
            (select id from _ecm_mm where alias='Horizontal Cable Rotation'), 1, 15, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Horizontal Cable Rotation') limit 1),
            (select id from _ecm_mm where alias='Horizontal Cable Rotation'), 2, 15, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Horizontal Cable Rotation') limit 1),
            (select id from _ecm_mm where alias='Horizontal Cable Rotation'), 3, 15, 20, 'kg');
  end if;
  -- historial 2026-09-17
  v_ses := null;
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach, origen)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-17', 1,
          '2026-W38', 'completada', '2026-09-17 12:00:00+00'::timestamptz, true, 'importada')
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Angled Machine Leg Press') limit 1),
            (select id from _ecm_mm where alias='Angled Machine Leg Press'), 1, 10, 57.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Angled Machine Leg Press') limit 1),
            (select id from _ecm_mm where alias='Angled Machine Leg Press'), 2, 8, 70, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Angled Machine Leg Press') limit 1),
            (select id from _ecm_mm where alias='Angled Machine Leg Press'), 3, 8, 70, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Angled Machine Leg Press') limit 1),
            (select id from _ecm_mm where alias='Angled Machine Leg Press'), 4, 7, 70, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Smith Machine Sumo Deadlift') limit 1),
            (select id from _ecm_mm where alias='Smith Machine Sumo Deadlift'), 1, 12, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Smith Machine Sumo Deadlift') limit 1),
            (select id from _ecm_mm where alias='Smith Machine Sumo Deadlift'), 2, 10, 22.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Smith Machine Sumo Deadlift') limit 1),
            (select id from _ecm_mm where alias='Smith Machine Sumo Deadlift'), 3, 9, 22.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Smith Machine Sumo Deadlift') limit 1),
            (select id from _ecm_mm where alias='Smith Machine Sumo Deadlift'), 4, 7, 22.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Hip Thrust Machine') limit 1),
            (select id from _ecm_mm where alias='Hip Thrust Machine'), 1, 9, 45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Hip Thrust Machine') limit 1),
            (select id from _ecm_mm where alias='Hip Thrust Machine'), 2, 8, 45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Hip Thrust Machine') limit 1),
            (select id from _ecm_mm where alias='Hip Thrust Machine'), 3, 8, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Hip Thrust Machine') limit 1),
            (select id from _ecm_mm where alias='Hip Thrust Machine'), 4, 7, 50, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Machine Seated Leg Extension') limit 1),
            (select id from _ecm_mm where alias='Machine Seated Leg Extension'), 1, 12, 72, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Machine Seated Leg Extension') limit 1),
            (select id from _ecm_mm where alias='Machine Seated Leg Extension'), 2, 10, 80, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Machine Seated Leg Extension') limit 1),
            (select id from _ecm_mm where alias='Machine Seated Leg Extension'), 3, 10, 80, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_mm where alias='Machine Seated Calf Raise'), 1, 10, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_mm where alias='Machine Seated Calf Raise'), 2, 10, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_mm where alias='Machine Seated Calf Raise'), 3, 10, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Machine Seated Calf Raise') limit 1),
            (select id from _ecm_mm where alias='Machine Seated Calf Raise'), 4, 10, 25, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Dip Machine Straight Leg Raise') limit 1),
            (select id from _ecm_mm where alias='Dip Machine Straight Leg Raise'), 1, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Dip Machine Straight Leg Raise') limit 1),
            (select id from _ecm_mm where alias='Dip Machine Straight Leg Raise'), 2, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Dip Machine Straight Leg Raise') limit 1),
            (select id from _ecm_mm where alias='Dip Machine Straight Leg Raise'), 3, 15, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Seated Machine Ab Crunch') limit 1),
            (select id from _ecm_mm where alias='Seated Machine Ab Crunch'), 1, 15, 35, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Seated Machine Ab Crunch') limit 1),
            (select id from _ecm_mm where alias='Seated Machine Ab Crunch'), 2, 15, 35, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Seated Machine Ab Crunch') limit 1),
            (select id from _ecm_mm where alias='Seated Machine Ab Crunch'), 3, 15, 35, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Seated Machine Ab Crunch') limit 1),
            (select id from _ecm_mm where alias='Seated Machine Ab Crunch'), 4, 15, 35, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Horizontal Cable Rotation') limit 1),
            (select id from _ecm_mm where alias='Horizontal Cable Rotation'), 1, 20, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Horizontal Cable Rotation') limit 1),
            (select id from _ecm_mm where alias='Horizontal Cable Rotation'), 2, 20, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Horizontal Cable Rotation') limit 1),
            (select id from _ecm_mm where alias='Horizontal Cable Rotation'), 3, 20, 15, 'kg');
  end if;

  -- Rutina 2: Push Training
  insert into rutinas (user_id, cliente_id, fase_id, nombre, dia_orden,
                       duracion_estimada_min, tipo_sesion, dias_semana)
  values (v_coach, v_cli, v_fase, 'Push Training', 2, 58, 'fuerza', array['M']::text[])
  returning id into v_rut;
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_mm where alias='Running'), 1, 1, 'Caminadora: 3 min intensidad moderada', null);
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'A', 'circuito', 2, 30, 1)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_mm where alias='Decline Plank to Pike'), 2, 1, '5', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_mm where alias='Dumbbell Standing Shoulder External Rotations'), 3, 1, '5', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_mm where alias='SuperBand Dislocates'), 4, 1, '5', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_mm where alias='Dumbbell Incline Bench Press'), 5, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_mm where alias='Landmine Half-Kneeling Single Arm Press'), 6, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_mm where alias='Dip'), 7, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_mm where alias='Machine Seated Chest Fly'), 8, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_mm where alias='Machine Lateral Raise'), 9, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_mm where alias='Cable V Bar Tricep Pushdown'), 10, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_mm where alias='Cable V-Bar Overhead Tricep Extension'), 11, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_mm where alias='Child''s Pose'), 12, 1, '30 s', null);
  -- historial 2026-09-15
  v_ses := null;
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach, origen)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-15', 1,
          '2026-W38', 'completada', '2026-09-15 12:00:00+00'::timestamptz, true, 'importada')
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_mm where alias='Dumbbell Incline Bench Press'), 1, 10, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_mm where alias='Dumbbell Incline Bench Press'), 2, 10, 20, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_mm where alias='Dumbbell Incline Bench Press'), 3, 8, 22.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Dumbbell Incline Bench Press') limit 1),
            (select id from _ecm_mm where alias='Dumbbell Incline Bench Press'), 4, 8, 22.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Landmine Half-Kneeling Single Arm Press') limit 1),
            (select id from _ecm_mm where alias='Landmine Half-Kneeling Single Arm Press'), 1, 10, 10, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Landmine Half-Kneeling Single Arm Press') limit 1),
            (select id from _ecm_mm where alias='Landmine Half-Kneeling Single Arm Press'), 2, 8, 10, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Landmine Half-Kneeling Single Arm Press') limit 1),
            (select id from _ecm_mm where alias='Landmine Half-Kneeling Single Arm Press'), 3, 7, 12.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Landmine Half-Kneeling Single Arm Press') limit 1),
            (select id from _ecm_mm where alias='Landmine Half-Kneeling Single Arm Press'), 4, 7, 12.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Dip') limit 1),
            (select id from _ecm_mm where alias='Dip'), 1, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Dip') limit 1),
            (select id from _ecm_mm where alias='Dip'), 2, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Dip') limit 1),
            (select id from _ecm_mm where alias='Dip'), 3, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Dip') limit 1),
            (select id from _ecm_mm where alias='Dip'), 4, 12, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Machine Seated Chest Fly') limit 1),
            (select id from _ecm_mm where alias='Machine Seated Chest Fly'), 1, 10, 80, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Machine Seated Chest Fly') limit 1),
            (select id from _ecm_mm where alias='Machine Seated Chest Fly'), 2, 9, 80, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Machine Seated Chest Fly') limit 1),
            (select id from _ecm_mm where alias='Machine Seated Chest Fly'), 3, 8, 80, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Machine Seated Chest Fly') limit 1),
            (select id from _ecm_mm where alias='Machine Seated Chest Fly'), 4, 7, 80, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Machine Lateral Raise') limit 1),
            (select id from _ecm_mm where alias='Machine Lateral Raise'), 1, 10, 27.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Machine Lateral Raise') limit 1),
            (select id from _ecm_mm where alias='Machine Lateral Raise'), 2, 10, 27.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Machine Lateral Raise') limit 1),
            (select id from _ecm_mm where alias='Machine Lateral Raise'), 3, 7, 35, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Machine Lateral Raise') limit 1),
            (select id from _ecm_mm where alias='Machine Lateral Raise'), 4, 7, 35, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_mm where alias='Cable V Bar Tricep Pushdown'), 1, 10, 23, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_mm where alias='Cable V Bar Tricep Pushdown'), 2, 8, 27, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_mm where alias='Cable V Bar Tricep Pushdown'), 3, 7, 27, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Cable V Bar Tricep Pushdown') limit 1),
            (select id from _ecm_mm where alias='Cable V Bar Tricep Pushdown'), 4, 6, 27, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Cable V-Bar Overhead Tricep Extension') limit 1),
            (select id from _ecm_mm where alias='Cable V-Bar Overhead Tricep Extension'), 1, 8, 45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Cable V-Bar Overhead Tricep Extension') limit 1),
            (select id from _ecm_mm where alias='Cable V-Bar Overhead Tricep Extension'), 2, 8, 45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Cable V-Bar Overhead Tricep Extension') limit 1),
            (select id from _ecm_mm where alias='Cable V-Bar Overhead Tricep Extension'), 3, 8, 45, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Cable V-Bar Overhead Tricep Extension') limit 1),
            (select id from _ecm_mm where alias='Cable V-Bar Overhead Tricep Extension'), 4, 8, 45, 'kg');
  end if;

  -- Rutina 3: Pull Training
  insert into rutinas (user_id, cliente_id, fase_id, nombre, dia_orden,
                       duracion_estimada_min, tipo_sesion, dias_semana)
  values (v_coach, v_cli, v_fase, 'Pull Training', 3, 55, 'fuerza', array['X']::text[])
  returning id into v_rut;
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_mm where alias='Running'), 1, 1, '3 min intensidad moderada', null);
  insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden)
  values (v_rut, 'A', 'circuito', 2, 30, 1)
  returning id into v_blo;
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_mm where alias='Table Top Half Arm Thoracic Rotation'), 2, 1, '5 por lado', 30);
  insert into rutina_ejercicios (rutina_id, bloque_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, v_blo, (select id from _ecm_mm where alias='Mini Band Wall Slides'), 3, 1, '8', 30);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_mm where alias='Bar Hang'), 4, 2, '40 s', 40);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_mm where alias='Pull Up'), 5, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_mm where alias='Machine Seated Single Arm Neutral Grip Row'), 6, 4, '6-12 por lado', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_mm where alias='Machine Preacher Curl'), 7, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_mm where alias='Dumbbell Hammer Curl'), 8, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_mm where alias='Cable Single Arm Bicep Curl'), 9, 3, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_mm where alias='Cable Rope Face Pull'), 10, 3, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_mm where alias='Dumbbell Shrug'), 11, 4, '6-12', 45);
  insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
  values (v_rut, (select id from _ecm_mm where alias='Suspension Low Back Stretch'), 12, 1, '30 s', null);
  -- historial 2026-09-16
  v_ses := null;
  insert into sesiones (user_id, cliente_id, rutina_id, fase_id, fecha, semana_num,
                        semana_iso, estado, finalizada_en, vista_por_coach, origen)
  values (v_coach, v_cli, v_rut, v_fase, date '2026-09-16', 1,
          '2026-W38', 'completada', '2026-09-16 12:00:00+00'::timestamptz, true, 'importada')
  on conflict do nothing returning id into v_ses;
  if v_ses is not null then
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Mini Band Wall Slides') limit 1),
            (select id from _ecm_mm where alias='Mini Band Wall Slides'), 1, 13, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Mini Band Wall Slides') limit 1),
            (select id from _ecm_mm where alias='Mini Band Wall Slides'), 2, 13, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Bar Hang') limit 1),
            (select id from _ecm_mm where alias='Bar Hang'), 1, 40, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Bar Hang') limit 1),
            (select id from _ecm_mm where alias='Bar Hang'), 2, 40, null, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Machine Seated Single Arm Neutral Grip Row') limit 1),
            (select id from _ecm_mm where alias='Machine Seated Single Arm Neutral Grip Row'), 1, 8, 70, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Machine Seated Single Arm Neutral Grip Row') limit 1),
            (select id from _ecm_mm where alias='Machine Seated Single Arm Neutral Grip Row'), 2, 7, 70, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Machine Preacher Curl') limit 1),
            (select id from _ecm_mm where alias='Machine Preacher Curl'), 1, 12, 27.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Machine Preacher Curl') limit 1),
            (select id from _ecm_mm where alias='Machine Preacher Curl'), 2, 10, 30, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Machine Preacher Curl') limit 1),
            (select id from _ecm_mm where alias='Machine Preacher Curl'), 3, 8, 30, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Machine Preacher Curl') limit 1),
            (select id from _ecm_mm where alias='Machine Preacher Curl'), 4, 6, 32.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_mm where alias='Dumbbell Hammer Curl'), 1, 10, 12.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_mm where alias='Dumbbell Hammer Curl'), 2, 10, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_mm where alias='Dumbbell Hammer Curl'), 3, 8, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Dumbbell Hammer Curl') limit 1),
            (select id from _ecm_mm where alias='Dumbbell Hammer Curl'), 4, 8, 15, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Cable Single Arm Bicep Curl') limit 1),
            (select id from _ecm_mm where alias='Cable Single Arm Bicep Curl'), 1, 10, 23, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Cable Single Arm Bicep Curl') limit 1),
            (select id from _ecm_mm where alias='Cable Single Arm Bicep Curl'), 2, 7, 27.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Cable Single Arm Bicep Curl') limit 1),
            (select id from _ecm_mm where alias='Cable Single Arm Bicep Curl'), 3, 7, 27.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Cable Rope Face Pull') limit 1),
            (select id from _ecm_mm where alias='Cable Rope Face Pull'), 1, 9, 41, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Cable Rope Face Pull') limit 1),
            (select id from _ecm_mm where alias='Cable Rope Face Pull'), 2, 9, 41, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Cable Rope Face Pull') limit 1),
            (select id from _ecm_mm where alias='Cable Rope Face Pull'), 3, 9, 41, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Dumbbell Shrug') limit 1),
            (select id from _ecm_mm where alias='Dumbbell Shrug'), 1, 10, 22.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Dumbbell Shrug') limit 1),
            (select id from _ecm_mm where alias='Dumbbell Shrug'), 2, 8, 27.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Dumbbell Shrug') limit 1),
            (select id from _ecm_mm where alias='Dumbbell Shrug'), 3, 8, 27.5, 'kg');
    insert into series_log (sesion_id, rutina_ejercicio_id, ejercicio_id, serie_num, reps, peso, unidad)
    values (v_ses, (select re.id from rutina_ejercicios re where re.rutina_id = v_rut
               and re.ejercicio_id = (select id from _ecm_mm where alias='Dumbbell Shrug') limit 1),
            (select id from _ecm_mm where alias='Dumbbell Shrug'), 4, 8, 27.5, 'kg');
  end if;

  raise notice 'OK: «Mauro Morón» · Ciclo 2 · 3 rutinas, activa y visible.';
end $cli$;

-- ═══════════════════════════════════════════════════════════════════════
-- QUÉ QUEDÓ
-- ═══════════════════════════════════════════════════════════════════════
select c.nombre as cliente, f.nombre as fase, f.estado, f.visible_cliente as visible,
       array_to_string(f.dias_semana, ' ') as dias,
       count(distinct r.id) as rutinas, count(distinct s.id) as sesiones_importadas
  from clientes c
  join fases f on f.cliente_id = c.id
  left join rutinas r on r.fase_id = f.id
  left join sesiones s on s.fase_id = f.id and s.origen = 'importada'
 where c.nombre ilike '%mauro%mor%n%'
 group by c.nombre, f.nombre, f.estado, f.visible_cliente, f.dias_semana, f.orden
 order by f.orden;

commit;

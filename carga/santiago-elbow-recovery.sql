-- ═══════════════════════════════════════════════════════════════════════
-- SANTIAGO F · rutina «Elbow Recovery» (reacondicionamiento de codo)
-- ═══════════════════════════════════════════════════════════════════════
-- Dónde: Supabase del CRM → SQL Editor → pegar todo → Run. DESPUÉS de
-- carga-santiago-fonseca.sql. Se puede correr dos veces.
--
-- Qué hace:
--   1. Los 3 ejercicios en la galería, con el nombre en inglés (grande) y en
--      español (debajo), y su video de Proet:
--        Banded Forearm Supination · Supinación de antebrazo con banda
--          → 882. Supinación de antebrazo con banda elástica
--        Banded Wrist Pronation    · Pronación de muñeca con banda elástica
--          → 794. Pronación de muñeca con banda elástica
--        Banded Wrist Extension    · Extensión de muñeca con banda
--          → 791. Extensión excéntrica de muñeca con banda elástica
--      «Pronación muñeca con banda elástica» y «Extensión muñeca» ya estaban
--      en tu galería (de la carga de Trainerize): se usan esas mismas fichas
--      y el nombre de Trainerize queda en la búsqueda, para encontrarlas
--      igual. «Supinación antebrazo» no estaba: se crea.
--   2. En el ciclo que va de Santiago, la rutina «Elbow Recovery»:
--      3 series × 6-8 reps de cada uno, ~9 min. SIN DÍA FIJO: así le sale
--      todos los días en «También en tu ciclo» y la puede hacer a diario,
--      aparte de su rutina de fuerza de ese día.
--
-- No toca ninguna otra rutina, sesión ni cliente.
-- ═══════════════════════════════════════════════════════════════════════

begin;

do $sf$
declare
  v_cli uuid; v_coach uuid; v_fase uuid; v_rut uuid; v_orden int;
  v_ej uuid; k int := 0; e record;
  hay_busqueda boolean := exists (select 1 from information_schema.columns where table_name = 'ejercicios' and column_name = 'busqueda');
  hay_elegido boolean := exists (select 1 from information_schema.columns where table_name = 'ejercicios' and column_name = 'video_elegido_at');
begin
  select id, user_id into v_cli, v_coach from clientes where nombre ilike '%santiago f%' order by created_at limit 1;
  if v_cli is null then raise exception 'No encuentro a «Santiago F» en clientes.'; end if;

  -- El ciclo que va: el activo y enviado (o, si no, el último).
  select id into v_fase from fases where cliente_id = v_cli
   order by (estado = 'activa' and coalesce(visible_cliente, false)) desc, (estado = 'activa') desc, orden desc nulls last, created_at desc
   limit 1;
  if v_fase is null then raise exception 'Santiago F no tiene ciclo: corre antes carga-santiago-fonseca.sql.'; end if;

  -- La rutina (una sola vez).
  select id into v_rut from rutinas where fase_id = v_fase and nombre = 'Elbow Recovery' and not archivada limit 1;
  if v_rut is null then
    select coalesce(max(dia_orden), 0) + 1 into v_orden from rutinas where fase_id = v_fase;
    insert into rutinas (user_id, cliente_id, fase_id, nombre, descripcion, tipo_sesion, duracion_estimada_min, dia_orden, dias_semana, dia_semana, archivada)
    values (v_coach, v_cli, v_fase, 'Elbow Recovery', 'Reacondicionamiento de codo · a diario', 'fuerza', 9, v_orden, '{}', null, false)
    returning id into v_rut;
    raise notice 'Rutina «Elbow Recovery» creada.';
  else
    raise notice 'La rutina «Elbow Recovery» ya estaba: solo se revisan sus ejercicios.';
  end if;

  for e in
    select * from (values
      (1, 'Banded Forearm Supination', 'Supinación de antebrazo con banda', 'Supinación antebrazo', '0sTN04ugWoE',
       'Codo pegado al cuerpo y doblado a 90°, la banda en la mano con la palma hacia abajo. Gira la palma hacia arriba despacio y vuelve controlando.'),
      (2, 'Banded Wrist Pronation', 'Pronación de muñeca con banda elástica', 'Pronación muñeca con banda elástica', 'SYx26hPIDXw',
       'Codo pegado al cuerpo y doblado a 90°, la banda en la mano con la palma hacia arriba. Gira la palma hacia abajo despacio y vuelve controlando.'),
      (3, 'Banded Wrist Extension', 'Extensión de muñeca con banda', 'Extensión muñeca', 'aW5Dqo2cnnY',
       'Antebrazo apoyado en el muslo o en un banco, palma hacia abajo y la banda pisada. Sube el dorso de la mano y baja lento, en unos 3 segundos.')
    ) as t(n, en, es, trainerize, video, como)
  loop
    -- La ficha: la de Trainerize si está (por su nombre de antes o por el nuevo).
    select id into v_ej from ejercicios
     where user_id = v_coach
       and (lower(alias) in (lower(e.trainerize), lower(e.en)) or lower(nombre) in (lower(e.trainerize), lower(e.es)))
     order by coalesce(archivado, false), created_at limit 1;
    if v_ej is null then
      insert into ejercicios (user_id, nombre, alias, tipo, segmento, patron, equipo, unilateral, nivel, tags, musculos_primarios)
      values (v_coach, e.es, e.en, 'rehabilitacion', 'tren_superior', null, array['banda'], true, 'principiante', array['rehabilitacion', 'codo'], array['antebrazo'])
      returning id into v_ej;
    end if;

    -- Inglés grande, español debajo, su video de Proet. La descripción y los
    -- músculos solo si no tenía.
    update ejercicios
       set alias = e.en, nombre = e.es,
           video_fuente = 'youtube', video_ref = e.video, video_url = 'https://www.youtube.com/watch?v=' || e.video,
           video_inicio_seg = null, poster_url = null,
           descripcion = coalesce(nullif(btrim(descripcion), ''), e.como),
           musculos_primarios = case when coalesce(array_length(musculos_primarios, 1), 0) = 0 then array['antebrazo'] else musculos_primarios end,
           equipo = case when coalesce(array_length(equipo, 1), 0) = 0 or equipo = array['mancuerna'] then array['banda'] else equipo end,
           updated_at = now()
     where id = v_ej;
    -- Que el buscador la siga encontrando por su nombre de Trainerize.
    if hay_busqueda then
      execute 'update ejercicios set busqueda = btrim(concat_ws('' '', busqueda, $1)) where id = $2 and coalesce(busqueda, '''') not ilike ''%'' || $1 || ''%'''
        using e.trainerize, v_ej;
    end if;
    -- Video elegido por el coach: ninguna carga lo vuelve a pisar.
    if hay_elegido then
      execute 'update ejercicios set video_elegido_at = now() where id = $1' using v_ej;
    end if;

    -- En la rutina, en su orden, 3 × 6-8.
    if not exists (select 1 from rutina_ejercicios where rutina_id = v_rut and ejercicio_id = v_ej) then
      insert into rutina_ejercicios (rutina_id, ejercicio_id, orden, series, reps, descanso_seg)
      values (v_rut, v_ej, e.n, 3, '6-8', 30);
      k := k + 1;
    end if;
  end loop;
  raise notice 'Elbow Recovery: % ejercicio(s) añadidos.', k;
end $sf$;

-- Cómo quedó.
select r.nombre as rutina, f.nombre as ciclo, re.orden, e.alias as en_ingles, e.nombre as en_espanol,
       re.series || ' × ' || re.reps as series, 'https://youtu.be/' || e.video_ref as video
  from rutinas r
  join fases f on f.id = r.fase_id
  join clientes c on c.id = r.cliente_id
  join rutina_ejercicios re on re.rutina_id = r.id
  join ejercicios e on e.id = re.ejercicio_id
 where c.nombre ilike '%santiago f%' and r.nombre = 'Elbow Recovery'
 order by re.orden;

commit;

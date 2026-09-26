-- ════════════════════════════════════════════════════════════════════════
-- CALENDARIO REAL Y PROCEDENCIA DE LAS SESIONES
-- ════════════════════════════════════════════════════════════════════════
-- Dónde correrlo:  Supabase del CRM → SQL Editor.
-- Es idempotente: correrlo dos veces no cambia nada la segunda.
--
-- Arregla tres cosas que se descubrieron juntas:
--
--   A. `sesiones.origen` — hoy no hay forma de saber si una sesión la marcó
--      el cliente en su app o la trajo la importación de Trainerize. El CRM
--      las cuenta igual y te dice "lo marcó en su app" sobre historial
--      importado, que es mentira.
--
--   B. `rutinas.dias_semana` — una rutina solo podía caer en UN día. Pero
--      medio roster entrena A-B-A-B: Andrea tiene 2 rutinas repartidas en 4
--      días. Eso no se podía ni guardar.
--
--   C. Los días nunca se importaron. `carga-rutinas-trainerize.sql` trajo
--      `dia_orden` (un orden), nunca un día de la semana, así que el
--      calendario de las 10 fases sale vacío. Se reconstruyen del propio
--      historial: cada sesión dice qué rutina se hizo qué día.
--
-- El orden de las partes importa: C necesita la columna que crea B.
-- ════════════════════════════════════════════════════════════════════════

begin;

-- ════════════════════════════════════════════════════════════════════════
-- A · DE DÓNDE SALIÓ CADA SESIÓN
-- ════════════════════════════════════════════════════════════════════════

alter table sesiones
  add column if not exists origen text not null default 'cliente';

-- El check va aparte y con guarda: `add constraint if not exists` no existe
-- en Postgres, y repetir un `add constraint` a secas revienta la segunda
-- corrida.
do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'sesiones_origen_ck'
  ) then
    alter table sesiones add constraint sesiones_origen_ck
      check (origen in ('cliente', 'importada', 'coach'));
  end if;
end $$;

comment on column sesiones.origen is
  'cliente = la marcó en su app · importada = vino de Trainerize · coach = la metiste tú';

-- ---- Marcar las importadas ----
-- La huella es exacta: la importación escribió `finalizada_en` como las
-- 12:00:00 UTC clavadas del mismo día. Una sesión cerrada de verdad lleva
-- `now()` con milisegundos, así que nunca coincide por accidente.
update sesiones
   set origen = 'importada'
 where origen = 'cliente'
   and finalizada_en = ((fecha + time '12:00') at time zone 'UTC');

-- ════════════════════════════════════════════════════════════════════════
-- B · UNA RUTINA PUEDE CAER EN VARIOS DÍAS
-- ════════════════════════════════════════════════════════════════════════
-- `dia_semana` (texto, un día) se queda donde está: no se borra nada. La
-- que manda a partir de ahora es `dias_semana`, y el valor viejo se copia
-- para que ninguna rutina ya fijada pierda su día.

alter table rutinas
  add column if not exists dias_semana text[] not null default '{}';

comment on column rutinas.dias_semana is
  'Días en que cae esta rutina: L M X J V S D. Vacío = la reparte dia_orden.';

update rutinas
   set dias_semana = array[dia_semana]
 where dia_semana is not null
   and dia_semana <> ''
   and cardinality(dias_semana) = 0;

-- Y la fase también la declara, por si alguna no la tenía.
alter table fases
  add column if not exists dias_semana text[] not null default '{}';

-- ════════════════════════════════════════════════════════════════════════
-- C · RECONSTRUIR EL CALENDARIO DESDE EL HISTORIAL
-- ════════════════════════════════════════════════════════════════════════
-- El dato estaba ahí todo el tiempo: cada sesión completada sabe su rutina
-- y su fecha. El día de la semana de esa fecha ES el día de esa rutina.
--
-- `to_char(fecha,'ID')` da 1=lunes … 7=domingo, que es justo el orden de
-- 'LMXJVSD'. `extract(dow)` NO sirve: numera el domingo como 0 y correría
-- la semana entera un día.
--
-- Solo se tocan las rutinas que hoy no tienen días. Si ya fijaste uno a
-- mano, manda el tuyo.

-- El `distinct` va en la subconsulta y no en el `array_agg`: agregando con
-- `array_agg(distinct letra order by letra)` los días salen en orden
-- alfabético —"J M" en vez de "M J"— porque ordena la letra, no el día.
-- Guardando también el número se ordena por él y la semana queda derecha.
with dias_reales as (
  select rutina_id, array_agg(letra order by n) as dias
    from (
      select distinct s.rutina_id,
             to_char(s.fecha, 'ID')::int as n,
             substr('LMXJVSD', to_char(s.fecha, 'ID')::int, 1) as letra
        from sesiones s
       where s.rutina_id is not null
         and s.estado = 'completada'
    ) t
   group by rutina_id
)
update rutinas r
   set dias_semana = d.dias
  from dias_reales d
 where r.id = d.rutina_id
   and cardinality(r.dias_semana) = 0;

-- La fase declara la unión de los días de sus rutinas. Es lo que usa el
-- calendario para saber en qué días de la semana se entrena en ese bloque.
with dias_fase as (
  select fase_id, array_agg(d order by strpos('LMXJVSD', d)) as dias
    from (
      select distinct r.fase_id, d
        from rutinas r, unnest(r.dias_semana) as d
       where r.fase_id is not null
         and coalesce(r.archivada, false) = false
    ) t
   group by fase_id
)
update fases f
   set dias_semana = d.dias
  from dias_fase d
 where f.id = d.fase_id
   and cardinality(f.dias_semana) = 0;

-- ════════════════════════════════════════════════════════════════════════
-- QUÉ PASÓ
-- ════════════════════════════════════════════════════════════════════════
do $$
declare
  v_imp int; v_cli int; v_rut int; v_fas int; v_huerf int;
begin
  select count(*) into v_imp from sesiones where origen = 'importada';
  select count(*) into v_cli from sesiones where origen = 'cliente';
  select count(*) into v_rut from rutinas where cardinality(dias_semana) > 0;
  select count(*) into v_fas from fases   where cardinality(dias_semana) > 0;
  select count(*) into v_huerf
    from rutinas where cardinality(dias_semana) = 0
     and coalesce(archivada, false) = false;

  raise notice '--------------------------------------------------';
  raise notice 'Sesiones importadas de Trainerize : %', v_imp;
  raise notice 'Sesiones marcadas por el cliente  : %', v_cli;
  raise notice 'Rutinas que ya tienen sus días    : %', v_rut;
  raise notice 'Fases que ya declaran sus días    : %', v_fas;
  raise notice 'Rutinas SIN días (ponlos tú)      : %', v_huerf;
  raise notice '--------------------------------------------------';
end $$;

-- Las que quedaron sin días: son las que nunca se entrenaron, así que no
-- había de dónde sacarlos. Sale la lista para que las pongas en el CRM.
select c.nombre as cliente, f.nombre as fase, r.nombre as rutina, r.dia_orden
  from rutinas r
  join fases f    on f.id = r.fase_id
  join clientes c on c.id = r.cliente_id
 where cardinality(r.dias_semana) = 0
   and coalesce(r.archivada, false) = false
 order by c.nombre, r.dia_orden;

commit;

-- ════════════════════════════════════════════════════════════════════════
-- PARA MIRARLO DESPUÉS
-- ════════════════════════════════════════════════════════════════════════
-- El calendario que quedó, cliente por cliente:
--
--   select c.nombre, f.nombre as fase, r.nombre as rutina,
--          array_to_string(r.dias_semana, ' ') as dias
--     from rutinas r
--     join fases f on f.id = r.fase_id
--     join clientes c on c.id = r.cliente_id
--    where coalesce(r.archivada,false) = false
--    order by c.nombre, r.dia_orden;
--
-- Para corregir una a mano:
--
--   update rutinas set dias_semana = '{L,X,V}' where id = '...';
-- ════════════════════════════════════════════════════════════════════════

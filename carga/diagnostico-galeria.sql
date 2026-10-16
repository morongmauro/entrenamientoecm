-- ════════════════════════════════════════════════════════════════════════
-- DIAGNÓSTICO DE LA GALERÍA · qué información falta, campo por campo
-- ════════════════════════════════════════════════════════════════════════
-- Dónde: Supabase del CRM → SQL Editor → pegar todo → Run.
-- SOLO LEE: no cambia nada. Sale una tabla: por cada dato, cuántas fichas
-- lo tienen vacío entre las que usan hoy tus clientes y las «en análisis».
-- ════════════════════════════════════════════════════════════════════════
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
fases_hoy as (select id from vigentes union select id from ultima),
en_uso as (
  select distinct re.ejercicio_id as id from rutina_ejercicios re join rutinas r on r.id = re.rutina_id
   where r.fase_id in (select id from fases_hoy) and coalesce(r.archivada, false) = false
),
e as (
  select x.*, (x.id in (select id from en_uso)) as uso,
         lower(btrim(coalesce(x.alias, ''))) = '' or lower(btrim(x.alias)) = lower(btrim(x.nombre)) as sin_ingles
    from ejercicios x where not coalesce(x.archivado, false)
),
f as (
  select uso, 1 as orden, 'Nombre en inglés (Trainerize)' as dato, sin_ingles as falta from e
  union all select uso, 2, 'Nombre en español', lower(btrim(coalesce(nombre, ''))) = '' or lower(btrim(nombre)) = lower(btrim(coalesce(alias, ''))) from e
  union all select uso, 3, 'Video', coalesce(video_fuente, 'ninguno') = 'ninguno' from e
  union all select uso, 4, 'Músculos principales', coalesce(cardinality(musculos_primarios), 0) = 0 from e
  union all select uso, 5, 'Músculos secundarios', coalesce(cardinality(musculos_secundarios), 0) = 0 from e
  union all select uso, 6, 'Equipo', coalesce(cardinality(equipo), 0) = 0 from e
  union all select uso, 7, 'Tipo', coalesce(tipo, '') = '' from e
  union all select uso, 8, 'Segmento (tren superior/inferior/core)', coalesce(segmento, '') = '' from e
  union all select uso, 9, 'Patrón (push/pull/rodilla…)', coalesce(patron, '') = '' from e
  union all select uso, 10, 'Lugar (gym/casa/aire libre)', coalesce(cardinality(lugar), 0) = 0 from e
  union all select uso, 11, 'Descripción (la ve el cliente)', btrim(coalesce(descripcion, '')) = '' from e
  union all select uso, 12, 'Claves técnicas (la ve el cliente)', coalesce(cardinality(claves_tecnicas), 0) = 0 from e
)
select dato,
       count(*) filter (where uso and falta)     as vacios_en_uso_hoy,
       count(*) filter (where not uso and falta) as vacios_en_analisis,
       count(*) filter (where falta)             as vacios_total,
       (select count(*) from e)                  as fichas_en_galeria
  from f
 group by dato, orden
 order by orden;

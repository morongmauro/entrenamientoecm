-- ════════════════════════════════════════════════════════════════════════
-- DESHACER · solo si quieres volver atrás nombres-en-analisis.sql
-- ════════════════════════════════════════════════════════════════════════
-- Devuelve el nombre de los que ese SQL cambió (si después editaste alguno en
-- el CRM, ese se queda) y quita la marca de duplicado que puso. No borra nada.
-- ════════════════════════════════════════════════════════════════════════
begin;

with r as (
  select distinct on (ejercicio_id) * from ejercicios_nombre_respaldo
   where motivo = 'nombres-analisis-2026-10-16' order by ejercicio_id, guardado_at asc
)
update ejercicios e
   set alias = r.alias, nombre = r.nombre, busqueda = r.busqueda, updated_at = now()
  from r
 where e.id = r.ejercicio_id and e.alias is not distinct from r.puesto_alias and e.nombre = r.puesto_nombre;

update ejercicios e set duplicado_de = null, updated_at = now()
  from (select distinct ejercicio_id from ejercicios_nombre_respaldo where motivo = 'nombres-analisis-2026-10-16-duplicado') r
 where e.id = r.ejercicio_id;

commit;

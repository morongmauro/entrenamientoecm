-- ════════════════════════════════════════════════════════════════════════
-- DESHACER · vuelve a poner el video que tenían antes de videos-en-analisis.sql
-- ════════════════════════════════════════════════════════════════════════
-- Dónde: Supabase del CRM → SQL Editor → pegar todo → Run.
-- Solo devuelve el video de los ejercicios que ese SQL cambió y que SIGUEN con
-- el video que él puso (si después cambiaste alguno en el CRM, ese se queda).
-- No borra nada: el respaldo se queda guardado.
-- ════════════════════════════════════════════════════════════════════════
begin;

with r as (
  select distinct on (ejercicio_id) * from ejercicios_video_respaldo
   where motivo = 'en-analisis-2026-10'
   order by ejercicio_id, guardado_at asc
)
update ejercicios e
   set video_fuente     = r.video_fuente,
       video_ref        = r.video_ref,
       video_url        = r.video_url,
       video_inicio_seg = r.video_inicio_seg,
       video_path       = r.video_path,
       poster_path      = r.poster_path,
       poster_url       = r.poster_url,
       video_elegido_at = r.video_elegido_at,
       updated_at       = now()
  from r
 where e.id = r.ejercicio_id
   and e.video_fuente = 'youtube'
   and e.video_ref = r.puesto_ref;

select count(*) as ejercicios_con_respaldo from (select distinct ejercicio_id from ejercicios_video_respaldo where motivo = 'en-analisis-2026-10') x;

commit;

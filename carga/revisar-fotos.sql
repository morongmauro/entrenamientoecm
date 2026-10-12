-- ═══════════════════════════════════════════════════════════════════════
-- FOTOS DEL PREVIEW · por qué la de un ejercicio puede no ser la suya
-- ═══════════════════════════════════════════════════════════════════════
-- Dónde: Supabase del CRM → SQL Editor → pegar → Run.
-- SOLO LEE: no cambia nada. Es para saber la causa; la corrección ya está en
-- la app y el CRM (y la revisión, en Galería → «🖼 Revisar fotos»).
--
-- La foto que ve el cliente antes de abrir un ejercicio es una de las 4
-- imágenes que YouTube saca del video (portada, ¼, mitad, ¾). Lo que la
-- puede equivocar, y lo que dice la columna `por_que`:
--   · «foto de OTRO video»: se eligió una imagen para el video de antes y
--     luego se le cambió el video. Ya no pasa: la app la ignora y el CRM la
--     borra al cambiar el video.
--   · «el video empieza en el segundo N»: el video trae varios ejercicios;
--     las imágenes automáticas son del video entero, o sea de otro. Ahora la
--     app no muestra ninguna hasta que elijas la buena.
--   · «mismo video que …»: varios ejercicios con el mismo video. A veces es
--     correcto (el mismo movimiento); si no, uno de los dos tiene el video
--     equivocado.
--   · «imagen automática»: la del medio del video. Casi siempre es el
--     ejercicio; si no lo es, solo se ve mirándola (Revisar fotos).
-- Primero salen los dos que viste (Dip y Landmine Half-Kneeling Single Arm
-- Press), luego los demás con un motivo de duda.
-- ═══════════════════════════════════════════════════════════════════════

with e as (
  select id, coalesce(nullif(alias, ''), nombre) as ejercicio, nombre, video_fuente, video_ref,
         video_inicio_seg, poster_url,
         substring(poster_url from '^https://i\.ytimg\.com/vi/([^/]+)/') as video_de_la_foto
    from ejercicios
   where coalesce(archivado, false) = false
),
compartidos as (
  select video_ref, string_agg(ejercicio, ' · ' order by ejercicio) as con, count(*) as n
    from e where video_fuente = 'youtube' and video_ref is not null
   group by video_ref having count(*) > 1
)
select e.ejercicio, e.nombre as en_espanol, e.video_ref, e.video_inicio_seg, e.poster_url,
       case
         when e.video_de_la_foto is not null and e.video_de_la_foto is distinct from e.video_ref then 'foto de OTRO video (' || e.video_de_la_foto || ')'
         when coalesce(e.video_inicio_seg, 0) > 0 and e.poster_url is null then 'el video empieza en el segundo ' || e.video_inicio_seg || ': trae varios ejercicios'
         when c.n is not null then 'mismo video que: ' || c.con
         when e.poster_url is not null then 'imagen elegida a mano'
         when e.video_fuente = 'youtube' then 'imagen automática (mitad del video)'
         else 'sin video de YouTube'
       end as por_que,
       case when e.video_ref is not null then 'https://www.youtube.com/watch?v=' || e.video_ref
            || case when coalesce(e.video_inicio_seg, 0) > 0 then '&t=' || e.video_inicio_seg || 's' else '' end end as ver_video
  from e left join compartidos c on c.video_ref = e.video_ref
 where e.ejercicio in ('Dip', 'Landmine Half-Kneeling Single Arm Press')
    or (e.video_de_la_foto is not null and e.video_de_la_foto is distinct from e.video_ref)
    or (coalesce(e.video_inicio_seg, 0) > 0 and e.poster_url is null)
    or c.n is not null
 order by (e.ejercicio in ('Dip', 'Landmine Half-Kneeling Single Arm Press')) desc, por_que, e.ejercicio;

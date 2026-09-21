-- ════════════════════════════════════════════════════════════════════════
-- VIDEOS DE YOUTUBE  ·  primera tanda (20 ejercicios)
-- ════════════════════════════════════════════════════════════════════════
-- Dónde correrlo:  Supabase del CRM → SQL Editor.
-- Es idempotente y CONSERVADOR: solo toca los ejercicios que hoy NO tienen
-- video. Si ya le pusiste uno a mano, este archivo no se lo pisa.
--
-- ⚠ LÉEME ANTES DE CORRERLO
-- -------------------------
-- Estos videos salieron de buscar cada ejercicio en YouTube por su nombre.
-- NO los he visto: no puedo ver video, solo leer títulos y descripciones.
-- Los elegí por relevancia del título y por ser canales que se dedican a
-- técnica, pero eso no garantiza que la ejecución sea la que TÚ enseñas.
--
-- Tu nombre va en esa app. Revísalos antes de enviarles la fase al cliente:
-- CRM → Entrenamiento → Galería → botón 👁 Ficha. El video sale ahí mismo,
-- y si alguno no te gusta lo cambias en el editor en diez segundos.
--
-- Son los 20 ejercicios que MÁS se repiten en las rutinas de tus 10
-- clientes (entre 42 y 139 series cada uno). Cubren la mayor parte de lo
-- que van a ver esta fase.
-- ════════════════════════════════════════════════════════════════════════

-- ---- 1. Los candidatos ----
-- Todo va dentro de UNA transacción a propósito. Sin el `begin`, psql trata
-- cada sentencia como su propia transacción y la tabla temporal se borraría
-- entre el CREATE y el UPDATE («relation "_videos" does not exist»). El
-- editor de Supabase envuelve el script, pero dejarlo explícito hace que el
-- archivo también funcione desde psql o desde cualquier otro cliente.
begin;

create temp table if not exists _videos (nombre text primary key, ref text);
truncate _videos;

insert into _videos (nombre, ref) values
  -- Pecho y hombro
  ('Press inclinado con mancuernas',              'sL6xN9EVDfE'),
  ('Aperturas en máquina',                        'WKfTStqIXrw'),
  ('Elevación lateral en polea',                   'zkP3tV_NwnY'),
  ('Deslizamientos en pared con banda',            'Rc_0kfsjafw'),
  -- Espalda
  ('Dominada lastrada agarre ancho',               'e4PtS-6SOSE'),
  ('Remo a una mano con banda',                    'P4H2XSKJcF4'),
  ('Colgarse de la barra',                         'F7bhhjpsdOs'),
  -- Brazo
  ('Curl martillo con mancuernas',                 'mPvlpDWIoDA'),
  ('Curl predicador en máquina',                   '4WXfuiZkN0Y'),
  ('Curl predicador con barra Z',                  '1wBSN5xLzt0'),
  ('Curl de bíceps en polea',                      'Ox0KaS9pGH4'),
  ('Extensión de tríceps en polea alta',           'CqKVxZNchH4'),
  ('Extensión de tríceps sobre la cabeza en polea','Z8Qmv4ByV14'),
  -- Pierna y glúteo
  ('Extensión de cuádriceps en máquina',           'ndnA6yvGoqQ'),
  ('Aductores en máquina',                         'pNCnlDA-Kdk'),
  ('Abducción de cadera tumbado con banda',        'dILxTvY88uI'),
  ('Hip thrust en máquina',                        'c2iJjdXpt1U'),
  ('Gemelo sentado en máquina',                    '6KKDFgOKZY0'),
  -- Core
  ('Press Pallof',                                 'W8Yf1uyUnoM'),
  ('Elevación de rodillas en paralelas',           'rmCayLWGpzY');

-- ---- 2. Aplicarlos ----
-- `video_fuente = 'ninguno'` o NULL = no tiene video. Esa es la condición:
-- nunca se sobrescribe uno que ya esté puesto.
update ejercicios e
   set video_fuente = 'youtube',
       video_ref    = v.ref,
       video_url    = 'https://www.youtube.com/watch?v=' || v.ref,
       updated_at   = now()
  from _videos v
 where e.nombre = v.nombre
   and coalesce(e.video_fuente, 'ninguno') = 'ninguno';

-- ---- 3. Qué pasó ----
do $$
declare v_puestos int; v_ya int; v_faltan text;
begin
  select count(*) into v_puestos
    from ejercicios e join _videos v on e.nombre = v.nombre
   where e.video_ref = v.ref;

  select count(*) into v_ya
    from ejercicios e join _videos v on e.nombre = v.nombre
   where e.video_ref is distinct from v.ref and e.video_fuente = 'youtube';

  select string_agg(v.nombre, ', ') into v_faltan
    from _videos v left join ejercicios e on e.nombre = v.nombre
   where e.id is null;

  raise notice 'Videos puestos: %', v_puestos;
  if v_ya > 0 then
    raise notice '% ya tenían otro video y NO se tocaron.', v_ya;
  end if;
  if v_faltan is not null then
    raise notice 'Estos nombres no existen en tu galería (revisa si los renombraste): %', v_faltan;
  end if;
end $$;

-- Lo último antes de cerrar: la lista para revisarlos. Sale en la pestaña de
-- resultados del editor, con el enlace de cada uno listo para abrir.
select e.nombre, 'https://youtu.be/' || e.video_ref as ver
  from ejercicios e join _videos v on e.nombre = v.nombre
 order by e.nombre;

drop table _videos;
commit;

-- ════════════════════════════════════════════════════════════════════════
-- REVISARLOS
-- ════════════════════════════════════════════════════════════════════════
-- El propio archivo ya los lista al final, con el enlace de cada uno. Para
-- volver a verlos después:
--
--   select nombre, 'https://youtu.be/' || video_ref as ver
--     from ejercicios
--    where video_fuente = 'youtube' and archivado = false
--    order by nombre;
--
-- Para quitarle el video a uno que no te convenza:
--
--   update ejercicios
--      set video_fuente = 'ninguno', video_ref = null, video_url = null
--    where nombre = 'Press Pallof';
--
-- Para saber cuántos siguen sin video:
--
--   select count(*) from ejercicios
--    where archivado = false and coalesce(video_fuente,'ninguno') = 'ninguno';
-- ════════════════════════════════════════════════════════════════════════

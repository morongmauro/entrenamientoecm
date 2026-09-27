-- ════════════════════════════════════════════════════════════════════════
-- VIDEOS DE YOUTUBE · tanda 3 · los 29 ejercicios que seguían sin video
-- ════════════════════════════════════════════════════════════════════════
-- Dónde: Supabase del CRM → SQL Editor → pegar todo → Run.
-- Idempotente y CONSERVADOR: solo toca ejercicios SIN video.
--
-- Con esto, todo el catálogo cargado desde Trainerize (y la rutina de Mauro)
-- queda con video. Los marcados «REVISAR» son aproximados: el movimiento
-- exacto no está en YouTube con ese nombre. Mira el enlace de la tabla final.
--
-- Al final salen TODOS los ejercicios de tu galería que aún no tienen video
-- (por ejemplo, los que creaste a mano en el CRM). En el CRM: Galería →
-- filtro «Sin video», y en la ficha, «Buscar este ejercicio en PROET».
-- ════════════════════════════════════════════════════════════════════════
begin;

create temp table if not exists _videos (alias text, nombre text, ref text, canal text);
truncate _videos;

insert into _videos (alias, nombre, ref, canal) values
  ('Bodyweight Squat To Hinge', 'De sentadilla a bisagra', 'YoCYUV8KgUY', 'The Hinge to Squat Exercise'),
  ('Squat to Hinge', 'De sentadilla a bisagra', 'YoCYUV8KgUY', 'The Hinge to Squat Exercise'),
  ('Dynamic Hip Opening Flow', 'Flujo dinámico de apertura de cadera', 'OKgG7FFgc6s', 'HEF Training · REVISAR'),
  ('Lateral Lunge to T-Rotation', 'Zancada lateral con rotación en T', 'JHKlLc7TMDM', 'Lateral Lunge to Thoracic Rotation'),
  ('1/2 Kneel to Lateral Bound', 'Salto lateral desde media rodilla', 'Il7NKifn10U', 'Half Kneeling Lateral Bound'),
  ('Bosu Lateral Bounce to Squat Jump', 'Rebote lateral en BOSU a salto', 'Mda3UItKr4Y', 'Kai Wheeler'),
  ('BOSU Alternating Lateral Squat Shuffle', 'Desplazamiento lateral en BOSU', 'yFdkJ4JMpLQ', 'Lateral BOSU Shuffle'),
  ('Running', 'Carrera continua', 'wCVSv7UxB2E', 'Coach USATF/Lydiard'),
  ('Suspension Low Back Stretch', 'Estiramiento lumbar en suspensión', 'ywpUcJrE2RQ', 'TRX Stretching'),
  ('1/2 Kneel to High Knee Hop', 'Salto de rodilla alta desde media rodilla', 'mVo_vusy5OM', 'Live Lean TV · REVISAR: es el salto desde rodillas, no el mismo'),
  ('Bear Squat to Spinal Wave', 'Sentadilla de oso con onda espinal', 'dnGbobw7fEM', 'REVISAR: solo la sentadilla de oso'),
  ('90-90 to Hip Raise', '90-90 con elevación de cadera', 'DVDBBYeGLsg', 'Tangelo Health'),
  ('Hinge to T-Rotation', 'Bisagra con rotación en T', 'aMmJ7gdBVt0', 'Hip Hinge Thoracic Rotation'),
  ('Trunk Rotation', 'Rotación de tronco', 'haWuH3LRFI4', 'Standing Trunk Twists'),
  ('Adductor Stretch with Thoracic Twist', 'Estiramiento de aductor con giro torácico', '8FhPrK0QjhE', 'Adductor Rock Back + Thoracic Rotation'),
  ('Band Anchored Pistol Squat to Row', 'Sentadilla a una pierna con remo en banda', 'bX_iYAyi408', 'REVISAR: sentadilla a dos piernas con remo'),
  ('SuperBand Anchored Pistol Squat to Row', 'Sentadilla a una pierna con remo en superbanda', 'bX_iYAyi408', 'REVISAR: sentadilla a dos piernas con remo'),
  ('Banded Sprinter', 'Sprint en el sitio con banda', 'k4PoVR-RrQk', 'Band Resisted Running in Place'),
  ('Clamshell with Hip Thrust', 'Almeja con empuje de cadera', 'eQ7iMPsKPg4', 'REVISAR: short de glute bridge + almeja'),
  ('Extensión muñeca', 'Extensión de muñeca', 'a5rXt7U-phg', 'Live Lean TV'),
  ('Mini Band Bent Arm Pull Apart', 'Apertura con banda y codos flexionados', 'LoBBo1dtY6I', 'REVISAR: pull apart con brazos casi rectos'),
  ('Mini Band Bus Drivers', 'Volante con banda', 'm6jbDGU0VOQ', 'Mini Band Bus Drivers'),
  ('Mini Band Delt Raises', 'Elevación de deltoides con banda', 'CL8PgkkjIIs', 'Mini Band Front Raise'),
  ('Pilates - Oblique Twists with Ball', 'Giros de oblicuos con balón', 'rFIa4C7arAs', 'Pilates con balón'),
  ('Prayer Squat', 'Sentadilla profunda en oración', '8mdtpUGVPco', 'Mobility Prayer Squat'),
  ('Scapular Pushups from Elbows', 'Flexión escapular desde codos', '3EfZ9Jt6UsU', 'Annie Miller'),
  ('SuperBand Deadlift', 'Peso muerto con superbanda', 'DDA5qTu1b58', 'Superband Deadlift'),
  ('Superman Around the World', 'Superman con círculos de brazos', 'mNptPKV1xIM', 'REVISAR: superman alterno; el «around the world» no está en YouTube'),
  ('Table Top Full Arm Thoracic Rotation', 'Rotación torácica con brazo extendido en cuadrupedia', 'z-UUhj3ejro', 'Quadruped Reach & Rotate');

update ejercicios e
   set video_fuente = 'youtube',
       video_ref    = v.ref,
       video_url    = 'https://www.youtube.com/watch?v=' || v.ref,
       updated_at   = now()
  from _videos v
 where (e.alias = v.alias or lower(e.nombre) = lower(v.nombre))
   and coalesce(e.video_fuente, 'ninguno') = 'ninguno';

-- 1) Lo de esta tanda, con su enlace para revisarlo.
select v.nombre, v.canal,
       case when e.id is null then 'NO ESTÁ EN TU GALERÍA'
            when e.video_ref = v.ref then 'puesto'
            else 'ya tenía otro video: no se tocó' end as estado,
       'https://youtu.be/' || v.ref as ver
  from _videos v
  left join lateral (
    select id, video_ref from ejercicios x
     where x.alias = v.alias or lower(x.nombre) = lower(v.nombre)
     limit 1) e on true
 order by 3, v.nombre;

drop table _videos;
commit;

-- 2) Lo que TODAVÍA no tiene video en toda tu galería. Debería salir vacío.
select nombre, alias, tipo
  from ejercicios
 where coalesce(video_fuente, 'ninguno') = 'ninguno'
   and coalesce(archivado, false) = false
 order by tipo, nombre;

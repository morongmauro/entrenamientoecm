-- ════════════════════════════════════════════════════════════════════════
-- VIDEOS DE YOUTUBE · tanda 2 · 64 ejercicios PARA REVISAR ANTES
-- ════════════════════════════════════════════════════════════════════════
-- Dónde: Supabase del CRM → SQL Editor → pegar todo → Run.
-- Idempotente y CONSERVADOR: solo toca ejercicios SIN video. Si ya le pusiste
-- uno a mano, no se lo pisa.
--
-- ⚠ Estos NO son de una biblioteca reconocible: eran el mejor resultado para
-- ejercicios poco comunes, pero el canal no se pudo identificar. Abre cada
-- enlace de la lista ANTES de correr este archivo. Si alguno no te gusta,
-- borra su línea del bloque «insert» y luego corre el archivo.
--
-- Se busca cada ejercicio por su nombre en español O por su nombre original de
-- Trainerize (alias), así da igual si renombraste la ficha.
-- ════════════════════════════════════════════════════════════════════════
begin;

create temp table if not exists _videos (alias text, nombre text, ref text, canal text);
truncate _videos;

insert into _videos (alias, nombre, ref, canal) values
  ('Mini Band Wall Sit with Abductions', 'Sentadilla isométrica en pared con abducción', 'uscCkRUU0Bs', 'REVISAR'),
  ('Bench Plank Single Arm Row', 'Remo a una mano en plancha sobre banco', 'A9BMGtYbFgI', 'REVISAR'),
  ('Bench V Sit Leg Raise', 'Elevación de piernas en V sobre banco', 'eDLVcGOdoCU', 'REVISAR'),
  ('Dumbbell Incline Alternating Curl', 'Curl inclinado alterno', 'B4HGtMhGI2s', 'REVISAR'),
  ('Dumbbell Burpee Clean to Press', 'Burpee con cargada y press', 'RY24woqAt9M', 'REVISAR'),
  ('Dumbbell Single Leg Calf Raise', 'Elevación de talón a una pierna con mancuerna', 'uhLjADhUxFM', 'REVISAR'),
  ('Band Deadlift', 'Peso muerto con banda', 'nHqSuHb8WUI', 'REVISAR'),
  ('Smith Machine Incline Bench Press', 'Press inclinado en multipower', 'yFQshytandQ', 'REVISAR'),
  ('Dumbbell Isometric Bicep Curl', 'Curl isométrico con mancuernas', '10T4-2c6108', 'REVISAR'),
  ('Dumbbell Glute Bridge Chest Press', 'Press de pecho en puente de glúteo', 'ouqgfFQ51S8', 'REVISAR'),
  ('Landmine Rotational Clean and Press', 'Cargada y press rotacional con landmine', 'DOPZH7XYKik', 'REVISAR'),
  ('Kettlebell Alternating Bent Over Row', 'Remo inclinado alterno con kettlebell', 'd6dp8bJpEvE', 'REVISAR'),
  ('Machine Seated Reverse Fly', 'Pájaro en máquina', 'p4JYxOddrQk', 'REVISAR'),
  ('Machine Seated Shoulder Press', 'Press de hombro sentado en máquina', 'e5gJP7quyGk', 'REVISAR'),
  ('Machine Seated Parallel Grip Shoulder Press', 'Press de hombro agarre paralelo en máquina', 'e5gJP7quyGk', 'REVISAR'),
  ('Bulgarian Pulses', 'Rebotes en búlgara', 'tfE1_XA6BOc', 'REVISAR'),
  ('Cable Seated Wide Grip Row', 'Remo sentado agarre ancho en polea', 'eabXHcpFQx4', 'REVISAR'),
  ('Leg Press Machine Calf Raise', 'Gemelo en prensa', 'kVZWSKyVDzk', 'REVISAR'),
  ('Wide Grip Pull Up', 'Dominada agarre ancho', '9A6NPVPzkqQ', 'REVISAR'),
  ('Lateral Shuttle Run', 'Desplazamiento lateral', 'mziPKITnPeQ', 'REVISAR'),
  ('Dumbbell Burpee with Curl to Press', 'Burpee con curl y press', '5_Y_oud1Ny0', 'REVISAR'),
  ('Band Anchored Single Arm Tricep Kickback', 'Patada de tríceps a una mano con banda', '0_GQljmMA48', 'REVISAR'),
  ('Half Kneeling SuperBand Single Arm Row', 'Remo a una mano con banda de rodillas', 'Fr9-JqkG4BQ', 'REVISAR'),
  ('Landmine Half-Kneeling Single Arm Press', 'Press a una mano de rodillas con landmine', 'CA6tkn3Qilc', 'REVISAR'),
  ('Barbell Preacher Curl', 'Curl predicador con barra', 'Fl8C_-E0Pig', 'REVISAR'),
  ('Cable Single Arm Bicep Curl', 'Curl de bíceps a una mano en polea', 'njLoCel5lUI', 'REVISAR'),
  ('Smith Machine Bench Press', 'Press banca en multipower', '7FyJdsXeta8', 'REVISAR'),
  ('Medicine Ball Slam with Squat Jump', 'Golpe de balón medicinal con salto', 'EsAhU1jHpiQ', 'REVISAR'),
  ('90-90 Hip Switch', 'Cambio de cadera 90-90', 'HUZimFZJZWU', 'REVISAR'),
  ('Chest to wall handstand', 'Pino de cara a la pared', 'nuuvRjGpNKA', 'REVISAR'),
  ('Bodyweight Spiderman Lunge To Rotation', 'Zancada spiderman con rotación', '1g7as3OKN7I', 'REVISAR'),
  ('Machine Seated Chest Press', 'Press de pecho sentado en máquina', 'lRo9zZ7EwpM', 'REVISAR'),
  ('Jump Squat to Reverse Lunge', 'Sentadilla con salto a zancada atrás', 'GN1tY2vkbyc', 'REVISAR'),
  ('Barbell Rear Shrug', 'Encogimiento de hombros con barra por detrás', 'ptBvX0z_in4', 'REVISAR'),
  ('Kettlebell Windmill', 'Molino con kettlebell', 'XJBU-IfiKY8', 'REVISAR'),
  ('Decline Plank to Pike', 'Plancha declinada a pica', 'e5pEJuv1cao', 'REVISAR'),
  ('Plank To Push Up', 'De plancha a flexión', 'xl8DfHxWdOE', 'REVISAR'),
  ('Dumbbell Seated Front Raise', 'Elevación frontal sentado', 'GBPA2OFO1_0', 'REVISAR'),
  ('Box Pistol Squat', 'Sentadilla a una pierna al cajón', 'Huy0Le3k_Ak', 'REVISAR'),
  ('Bench Knee Tuck to V Up', 'Rodillas al pecho a V-up en banco', 'V32HqR2g7-k', 'REVISAR'),
  ('Dumbbell Laying Tricep Extension to Press', 'Extensión de tríceps tumbado a press', 'R6SdxvZGK5s', 'REVISAR'),
  ('Half Burpee with Dumbbell', 'Medio burpee con mancuernas', 'AfWOlcb1_u0', 'REVISAR'),
  ('Cable Glute Crossover Kickback', 'Patada de glúteo cruzada en polea', 'AI6_2GYzEq0', 'REVISAR'),
  ('Split Squat Pulse', 'Rebotes en zancada', 'p9O2EOcoJZk', 'REVISAR'),
  ('Seated Hip Twist', 'Giro de cadera sentado', 'JoU3fOvT_88', 'REVISAR'),
  ('Band Anchored Single Arm Incline Curl', 'Curl inclinado a una mano con banda', 'v1qoXUkuYw8', 'REVISAR'),
  ('Dragon flag tuck eccentric', 'Dragon flag agrupado excéntrico', '93YYoqYN3vE', 'REVISAR'),
  ('Glute Side Circle', 'Círculos de glúteo en cuadrupedia', 'xke_FGQjMEM', 'REVISAR'),
  ('Quadruped Hip Circles', 'Círculos de cadera en cuadrupedia', 'xke_FGQjMEM', 'REVISAR'),
  ('Cossack Squat to T-Spine Reach', 'Sentadilla cosaco con alcance torácico', 'jtLerhZvsBw', 'REVISAR'),
  ('Cobra', 'Cobra', 'bQfkvBe5Z10', 'REVISAR'),
  ('Pilates - Swan', 'Cisne (pilates)', 'bQfkvBe5Z10', 'REVISAR'),
  ('Superband Pull Apart', 'Apertura con superbanda', 'bYsgk9SrJ48', 'REVISAR'),
  ('Kick Throughs', 'Patada cruzada desde cuadrupedia', 'Q9n6eDzQoRk', 'REVISAR'),
  ('Bear to Step Through', 'Posición de oso con paso cruzado', 'CqjAzv8e0P0', 'REVISAR'),
  ('Downward Dog to Scorpion', 'Perro boca abajo a escorpión', 'XzeoaDv4KNY', 'REVISAR'),
  ('Reverse nordic curl band assisted', 'Nórdico inverso asistido con banda', 'q6d-qN9Or3o', 'REVISAR'),
  ('Prone Scorpion Alternating', 'Escorpión alterno boca abajo', 'NimMqYPUcM8', 'REVISAR'),
  ('Alternating Leg Drop', 'Descenso alterno de pierna', 'TyDQnlylnB0', 'REVISAR'),
  ('Bench Twist Crunches', 'Crunch con giro en banco', 'k35iMFTF_-o', 'REVISAR'),
  ('Half Lord of the Fishes', 'Torsión sentada (media torsión espinal)', 'yJhCI5VEPCg', 'REVISAR'),
  ('Mini Band Standing I''s', 'I''s de pie con banda', 'DhhGAeVbsRs', 'REVISAR'),
  ('Bodyweight Deadlift', 'Peso muerto sin carga', 'P9akD4PyOXk', 'REVISAR'),
  ('Mini Band Bent Over Y''s', 'Y con banda inclinado', 'iYTwpKOau2k', 'REVISAR');

update ejercicios e
   set video_fuente = 'youtube',
       video_ref    = v.ref,
       video_url    = 'https://www.youtube.com/watch?v=' || v.ref,
       updated_at   = now()
  from _videos v
 where (e.alias = v.alias or lower(e.nombre) = lower(v.nombre))
   and coalesce(e.video_fuente, 'ninguno') = 'ninguno';

-- Lo que quedó: un enlace por ejercicio para revisarlo, y cuáles no se
-- encontraron en tu galería.
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

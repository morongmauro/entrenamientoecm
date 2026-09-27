-- ════════════════════════════════════════════════════════════════════════
-- VIDEOS DE YOUTUBE · tanda 2 · 128 ejercicios de bibliotecas profesionales
-- ════════════════════════════════════════════════════════════════════════
-- Dónde: Supabase del CRM → SQL Editor → pegar todo → Run.
-- Idempotente y CONSERVADOR: solo toca ejercicios SIN video. Si ya le pusiste
-- uno a mano, no se lo pisa.
--
-- De dónde salen: bibliotecas de demostración profesionales, en inglés, cortas
-- y al grano — Live Lean TV (serie «Exercise Demonstration Video and Guide»),
-- NASM, Nuffield Health, «Proper Form & Technique [4K]», Catalyst Athletics,
-- OPEX, MedBridge, HASfit, Kettlebell Kings, CrossFit Invictus, Rogue, Onnit,
-- Team Evolve, Joanna Soh, Ask Doctor Jo y parecidas (el canal va en cada fila).
-- El canal se identificó por el título. NO se vieron los videos (desde el
-- entorno de trabajo YouTube está bloqueado): revisa en la ficha del CRM los
-- que marco con nota en la lista.
--
-- Se busca cada ejercicio por su nombre en español O por su nombre original de
-- Trainerize (alias), así da igual si renombraste la ficha.
-- ════════════════════════════════════════════════════════════════════════
begin;

create temp table if not exists _videos (alias text, nombre text, ref text, canal text);
truncate _videos;

insert into _videos (alias, nombre, ref, canal) values
  ('Bicycle Crunch', 'Bicicleta abdominal', 'uNmNvaNsu7w', 'Live Lean TV'),
  ('High Plank Jacks', 'Plancha alta con saltos', 'lV5ZkEXVlTk', 'Live Lean TV'),
  ('Seated Machine Ab Crunch', 'Crunch abdominal en máquina', 'CNHS2OoUi30', 'Live Lean TV'),
  ('Dumbbell Bench Press', 'Press banca con mancuernas', '1Qi4IzoyRP4', 'Nuffield Health'),
  ('Cable Rope Face Pull', 'Face pull con cuerda', 'eTCBSFlCJ_s', 'NASM'),
  ('Dip Machine Straight Leg Raise', 'Elevación de piernas rectas en paralelas', 'nBsP27-x7LU', 'Live Lean TV'),
  ('Dumbbell Straight Leg Deadlift', 'Peso muerto piernas rectas con mancuernas', 'R6KXyhU4nTY', 'Live Lean TV'),
  ('Cable Seated Close Grip Row', 'Remo sentado agarre cerrado en polea', 'xjlz8lRXOOI', 'Live Lean TV'),
  ('Dip', 'Fondos en paralelas', 'U7HeutDqS_w', 'Live Lean TV'),
  ('Dumbbell Single Arm Row', 'Remo a una mano con mancuerna', '6KNmHxw-SpE', 'Nuffield Health'),
  ('Cable V-Bar Overhead Tricep Extension', 'Extensión de tríceps sobre la cabeza en polea', 'jioCqlKKrJc', 'Live Lean TV'),
  ('Plate Hip Thrust', 'Hip thrust con disco', 'N4JVnHFOq50', '4K Proper Form'),
  ('Ab Roller Wheel Abdominal Roll Out', 'Rueda abdominal', 'NbudTqiwguk', '4K Proper Form'),
  ('SuperBand Anchored Tricep Pushdown', 'Extensión de tríceps con banda anclada', 'Qenwe2_7IHE', 'Onnit'),
  ('Dumbbell Front Squat', 'Sentadilla frontal con mancuernas', 'hZI8Yy5elZs', 'NASM'),
  ('Angled Machine Leg Press', 'Prensa inclinada', 'cDGOn-yfKJA', 'NASM'),
  ('Dumbbell Sumo Deadlift', 'Peso muerto sumo con mancuerna', 'I-5x_YvwPY4', 'Live Lean TV'),
  ('Machine Lateral Raise', 'Elevación lateral en máquina', 'dTwa2piwU-A', 'Live Lean TV'),
  ('Dumbbell Seated Arnold Press', 'Press Arnold sentado', 'FgaNMli_3y0', 'Live Lean TV'),
  ('Body Weight Calf Raise', 'Elevación de talones sin carga', 'ndQc4mz4mBU', '4K Proper Form'),
  ('Dumbbell Incline Bench High Row', 'Remo alto en banco inclinado', '0-DXJiceG-0', 'OPEX'),
  ('Wide Grip Lat Pulldown', 'Jalón al pecho agarre ancho', 'sM6RaxyXMwE', 'Live Lean TV'),
  ('Plate Weighted Dip', 'Fondos lastrados', '1B3oiijYllQ', 'Live Lean TV'),
  ('Cable Standing Crossover Chest Fly', 'Cruce de poleas de pie', '7Sb0HtOfCaI', 'Live Lean TV'),
  ('Smith Machine Sumo Deadlift', 'Peso muerto sumo en multipower', 'H0ntIJE3lpI', 'Team Evolve'),
  ('Horizontal Cable Rotation', 'Rotación horizontal en polea', 'he4IhLc1d5k', 'Live Lean TV'),
  ('Cable Straight Bar Tricep Pushdown', 'Extensión de tríceps con barra recta en polea', '9is5WxWZoSo', 'Live Lean TV'),
  ('Dumbbell Bulgarian Split Squat', 'Sentadilla búlgara con mancuernas', 'bZD05-6_yH4', 'Live Lean TV'),
  ('Dumbbell Floor Press', 'Press de pecho en suelo', 'qHCI9rK7HqM', 'Live Lean TV'),
  ('Cross Body Mountain Climber', 'Escalador cruzado', 'HWJfdGnqFA8', 'Nuffield Health'),
  ('Dumbbell Shrug', 'Encogimiento de trapecio con mancuernas', '8lP_eJvClSA', 'Bodybuilding.com'),
  ('Dumbbell Alternating Lateral Raise to Front Raise', 'Elevación lateral a frontal alterna', '7FYVO57z_ns', 'Team Evolve'),
  ('Seated Dumbbell Front Raise to Lateral Raise', 'Elevación frontal a lateral sentado', '7FYVO57z_ns', 'Team Evolve'),
  ('Seated Leg Press', 'Prensa sentado', '30N6fKpuTNo', 'Life Fitness'),
  ('Dumbbell Deadlift', 'Peso muerto con mancuernas', 'gLogcYIvgRA', 'Live Lean TV'),
  ('Machine Seated Single Arm Neutral Grip Row', 'Remo a una mano en máquina agarre neutro', 'QYpLCDTry0g', 'My PT Hub'),
  ('Mountain Climber', 'Escalador', 'sB0DQ-aElF8', 'Joanna Soh'),
  ('Machine Lying Leg Curl', 'Curl femoral tumbado en máquina', 'lUH80pneL5w', 'NASM'),
  ('Machine Seated Leg Curl', 'Curl femoral sentado en máquina', '_2Kd0d-JEUM', 'NASM'),
  ('Barbell Hip Thrust', 'Hip thrust con barra', '4hYRM_60BD4', 'Coach Kelly Cues'),
  ('Smith Machine Shrug', 'Encogimiento de trapecio en multipower', 'g00nZdE6_Ro', 'Live Lean TV'),
  ('Smith Machine Seated Shoulder Press', 'Press de hombro sentado en multipower', 'aKWQrB8afy0', 'Live Lean TV'),
  ('Dumbbell Glute Bridge', 'Puente de glúteo con mancuerna', 'PSMW7iSi2BU', 'Women''s Strength Nation'),
  ('Hollow Body Hold Flutter Kicks', 'Hollow hold con tijeras', 'SnoeNEynaXo', 'Live Lean TV'),
  ('Superband Squat', 'Sentadilla con superbanda', 'duP-UZsfOaQ', 'Chris Freytag'),
  ('Dumbbell Alternating Bicep Curl', 'Curl de bíceps alterno', 'w7hl4IbHMtY', 'Live Lean TV'),
  ('Dumbbell Bicep Curl', 'Curl de bíceps con mancuernas', 'w7hl4IbHMtY', 'Live Lean TV'),
  ('Dumbbell Walking Lunge', 'Zancada caminando con mancuernas', 'I_rMQRrwseI', 'Live Lean TV'),
  ('Smith Machine Back Squat', 'Sentadilla trasera en multipower', '8TEK4DPVVPs', 'Live Lean TV'),
  ('Kettlebell Single Arm Clean and Press', 'Cargada y press a una mano con kettlebell', 'E7WRJtfsiO4', 'Kettlebell Kings'),
  ('Kettlebell High Pull', 'Cargada alta con kettlebell', 'x8S_uzpWex4', 'Kettlebell Kings'),
  ('Mini Band Alternating Hip Abduction', 'Abducción de cadera alterna con banda', '4qr26RNU3EQ', 'Live Lean TV'),
  ('Fire Hydrant Standing', 'Abducción de cadera de pie', '4qr26RNU3EQ', 'Live Lean TV'),
  ('Kettlebell Alternating Halo with Chest Press', 'Halo alterno con press de pecho (kettlebell)', 'CAPdpcbqs5E', 'Live Lean TV'),
  ('Kettlebell Alternating Halo', 'Halo alterno con kettlebell', 'CAPdpcbqs5E', 'Live Lean TV'),
  ('Dumbbell Calf Raise', 'Gemelo de pie con mancuerna', 'wxwY7GXxL4k', 'Bodybuilding.com'),
  ('Spiderman Push Up', 'Flexión spiderman', 'eYLTNLAdTeY', 'Live Lean TV'),
  ('Push Up', 'Flexión de brazos', 'WDIpL0pjun0', 'NASM'),
  ('Clapping Push Up', 'Flexión con palmada', 'MH4gcTKQiEc', 'NASM'),
  ('Bench Plyo Push Ups', 'Flexiones pliométricas en banco', 'MH4gcTKQiEc', 'NASM'),
  ('Elevated Pike Push-Up', 'Flexión en pica con pies elevados', '2b5t0Cu2nQI', 'NASM'),
  ('Dumbbell Incline Bicep Curl', 'Curl inclinado con mancuernas', '5uAAU3sUURA', 'Live Lean TV'),
  ('Bodyweight Walking Lunge', 'Zancada caminando sin peso', '_GqxkGp7NAA', 'Live Lean TV'),
  ('Cable Tricep Kickback', 'Patada de tríceps en polea', 'ZvF4Oi_6Vtg', 'Live Lean TV'),
  ('Pull Up', 'Dominada', '9yVGh3XbJ34', 'NASM'),
  ('Cable Shrug', 'Encogimiento de trapecio en polea', '12g2avOv7so', 'Live Lean TV'),
  ('Machine Standing Calf Raise', 'Gemelo de pie en máquina', 'ndQc4mz4mBU', '4K Proper Form'),
  ('SuperBand Push Up', 'Flexión con superbanda', 'Hzhyjhq9tQo', 'Live Lean TV'),
  ('Lying Hip Abductions', 'Abducción de cadera tumbado', 'bGtZQovM--Q', 'Live Lean TV'),
  ('Dumbbell Alternating Hammer Curl', 'Curl martillo alterno', 'xaxyePfdBlc', 'Live Lean TV'),
  ('Seated Dumbbell Hammer Curl to Neutral Press', 'Curl martillo sentado a press neutro', 'uYYc5GK4-eM', 'Live Lean TV'),
  ('Glute Bridge', 'Puente de glúteo', 'gzYpgnpDjZA', 'Live Lean TV'),
  ('Landmine RDL', 'Peso muerto rumano con landmine', '59YRCxCtJ_s', 'Live Lean TV'),
  ('Band Internal Shoulder Rotation (90 degrees)', 'Rotación interna de hombro con banda (90°)', 'BElxYD7KkQ4', 'MedBridge'),
  ('Knee to Elbow Crunch', 'Crunch rodilla al codo', 'lEW6v1A_B5Y', 'Live Lean TV'),
  ('Dumbbell Reverse Lunge', 'Zancada atrás con mancuernas', 'UoQcIFYTN_o', 'Live Lean TV'),
  ('Plate Russian Twist', 'Giro ruso con disco', '8ohhG1Y4tzU', 'Live Lean TV'),
  ('Bodyweight Deadbug', 'Dead bug', 'xtTIb6dC-vI', 'MedBridge'),
  ('Dumbbell Seated Overhead Tricep Extension', 'Extensión de tríceps sobre la cabeza sentado', 'dxdr8iSRLA8', 'OPEX'),
  ('Dumbbell Seated Shoulder Press', 'Press de hombro sentado con mancuernas', '8kwDkC8JhdY', 'Live Lean TV'),
  ('Barbell Romanian Deadlift', 'Peso muerto rumano con barra', 'lKLYvNGz6mk', '4K Proper Form'),
  ('Child''s Pose', 'Postura del niño', '8MGZRJjVDM4', 'Live Lean TV'),
  ('Dumbbell External Rotation on Side', 'Rotación externa tumbado de lado', 'YvNMmBZ-8dY', 'Live Lean TV'),
  ('Dumbbell Hip Thrust', 'Hip thrust con mancuerna', 'N4JVnHFOq50', '4K Proper Form'),
  ('Dumbbell Standing Shoulder External Rotations', 'Rotación externa de hombro de pie', 'jQ4TKUEVDoc', 'HASfit'),
  ('Static Pigeon Stretch', 'Estiramiento de paloma', 'hvlvwwoMW5Q', 'Live Lean TV'),
  ('Cat to Cow', 'Gato-camello', 'MgDn34q4Hm8', 'Live Lean TV'),
  ('Bodyweight Single Leg Calf Raise', 'Gemelo a una pierna sin peso', 'u1Yc75YdiJA', 'Dr. Brian Damhoff (fisioterapeuta)'),
  ('Bodyweight Bent Knee Single Leg Calf Raise', 'Gemelo a una pierna con rodilla flexionada', 'u1Yc75YdiJA', 'Dr. Brian Damhoff (fisioterapeuta)'),
  ('Bodyweight Alternating Cossack Squat', 'Sentadilla cosaco alterna', 'd4IPCXI8GQc', 'School of Calisthenics'),
  ('Bodyweight Cossack Squat', 'Sentadilla cosaco', 'd4IPCXI8GQc', 'School of Calisthenics'),
  ('Squat Jump', 'Sentadilla con salto', '3bSbksBXIwI', 'Live Lean TV'),
  ('Squat to Squat Jump', 'Sentadilla a sentadilla con salto', '3bSbksBXIwI', 'Live Lean TV'),
  ('Cable Seated Close Row', 'Remo sentado agarre estrecho en polea', 'XaHV_8Nbyug', 'Team Evolve'),
  ('Cable Single Arm Standing Overhead Tricep Extension', 'Extensión de tríceps a una mano en polea', 'TdU3PyRqoU8', 'Catalyst Athletics'),
  ('Machine Assisted Wide Grip Pull Up', 'Dominada asistida agarre ancho', 'lgjgDfiKGZw', 'Coach Kelly Cues'),
  ('Machine Assisted Parallel Grip Pull Up', 'Dominada asistida agarre paralelo', 'lgjgDfiKGZw', 'Coach Kelly Cues'),
  ('Machine Assisted Dip', 'Fondos asistidos en máquina', 'lgjgDfiKGZw', 'Coach Kelly Cues'),
  ('Dumbbell Lateral Raise', 'Elevación lateral con mancuernas', 'U3Atcn3wFjY', 'Live Lean TV'),
  ('Dumbbell Curl to Shoulder Press', 'Curl y press de hombro con mancuernas', '-IOZiL1Ojv4', 'Live Lean TV'),
  ('Dumbbell Stationary Lunge', 'Zancada estática con mancuernas', '5VG4UnfA7Bk', 'Proper Form & Technique [4K]'),
  ('Bench Single Leg Hip Thrust', 'Hip thrust a una pierna en banco', 'kpkg8r7dex4', 'Live Lean TV'),
  ('Box Jump', 'Salto al cajón', 'mMR2SksN_ao', 'Live Lean TV'),
  ('Burpee Broad Jump', 'Burpee con salto horizontal', '_2OrGjk2r9g', 'Rogue Fitness'),
  ('Burpee', 'Burpee', 'qLBImHhCXSw', 'Well+Good'),
  ('Bench Hip Thrust', 'Hip thrust en banco', 'LZWQgMxryDc', 'Catalyst Athletics'),
  ('Smith Machine Deadlift', 'Peso muerto en multipower', 'ONRRAgNLVac', 'Live Lean TV'),
  ('Body Weight Single Leg Deadlift', 'Peso muerto a una pierna sin peso', 'nH101oaL-HU', 'Live Lean TV'),
  ('Broad Jump', 'Salto horizontal', '7Du1KbwCdUk', 'Live Lean TV'),
  ('Dumbbell Clean to Press', 'Cargada y press con mancuernas', '8G-jnVP_f2s', 'Live Lean TV'),
  ('Landmine Deadlift', 'Peso muerto con landmine', '3QmesK2a2Fg', 'Ben Bruno'),
  ('Kettlebell Lateral Step Up', 'Subida lateral al cajón con kettlebell', 'z6WChpJB08Q', 'Live Lean TV'),
  ('Kettlebell Alternating Press', 'Press alterno con kettlebell', 'uvbzF4owlAA', 'Catalyst Athletics'),
  ('Bench Hopover Burpee', 'Burpee saltando el banco', 'TAWSoJHTkzA', 'Live Lean TV'),
  ('Bench Side Plank Hip Dip', 'Plancha lateral en banco con descenso de cadera', 'BWQRVB4LyFI', 'Joanna Soh'),
  ('Alternating Lunge Hops', 'Saltos de zancada alternos', 'WfPJ8jaw4Fc', 'Onnit'),
  ('Kettlebell Alternating Stationary Cossack Squat', 'Sentadilla cosaco alterna con kettlebell', '6hCJJ5ePdDw', 'Kettlebell Kings'),
  ('Cable External Rotation', 'Rotación externa en polea', 'T_WCU7wjn4Y', 'HASfit'),
  ('Muscle Up', 'Muscle up', '6v6IsZcvqCA', 'Barstarzz'),
  ('Shuttle Run', 'Ida y vuelta corta', 'eQw7jWxH8dE', 'Live Lean TV'),
  ('Table Top Half Arm Thoracic Rotation', 'Rotación torácica en cuadrupedia', 'snzLuyYgbVI', 'Ask Doctor Jo'),
  ('SuperBand Dislocates', 'Dislocaciones de hombro con banda', 'nikVq2pMVg4', 'Tom Morrison'),
  ('Mini Band Wall Sit', 'Sentadilla isométrica en pared con banda', 'JjWs0cwqxEk', 'HASfit'),
  ('Alternating Spiderman lunge to hip lift', 'Zancada spiderman con elevación de cadera', 'ZMLKrs0bqmY', 'Live Lean TV'),
  ('Squat Pulse', 'Rebotes en sentadilla', 'N4fzbBv4BFI', 'Joanna Soh'),
  ('Quadruped Scapular Push Up', 'Flexión escapular en cuadrupedia', 'iQP1BBmwAgg', 'Live Lean TV'),
  ('Bodyweight Kang Squat', 'Kang squat sin peso', 'LpDXYVqy8L4', 'CrossFit Invictus'),
  ('Pronación muñeca con banda elástica', 'Pronación de muñeca con banda', 'gHxGA4ZDOMo', 'Ask Doctor Jo');

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

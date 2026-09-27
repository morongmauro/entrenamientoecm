-- ════════════════════════════════════════════════════════════════════════
-- MÚSCULOS DE TODOS LOS EJERCICIOS DE FUERZA (principales y secundarios)
-- ════════════════════════════════════════════════════════════════════════
-- Dónde: Supabase del CRM → SQL Editor → pegar todo → Run. No hay que
-- pegar ningún ID: se cruza por el nombre del ejercicio.
--
-- Es lo que pinta la silueta en la ficha del cliente: en naranja fuerte lo
-- PRINCIPAL, en naranja suave lo SECUNDARIO. Son los 188 ejercicios de
-- fuerza, core, potencia y pliometría de las rutinas cargadas.
--
-- Qué pisa y qué no:
--   · Si el ejercicio NO tiene músculos → se los pone.
--   · Si tiene principales pero NO secundarios (lo que dejó la importación
--     de Trainerize, que los mezclaba todos en una lista) → los reemplaza
--     por la versión separada.
--   · Si ya tiene principales Y secundarios (los pusiste tú en el CRM) →
--     no lo toca.
-- Idempotente: correrlo dos veces no cambia nada la segunda.
--
-- Al final salen los ejercicios de fuerza que AÚN no tienen músculos (los
-- que creaste a mano con otro nombre). Debería salir vacío o casi.
-- ════════════════════════════════════════════════════════════════════════
begin;

create temp table if not exists _musculos (alias text, nombre text, prim text[], sec text[]);
truncate _musculos;

insert into _musculos (alias, nombre, prim, sec) values
  ('1/2 Kneel to High Knee Hop', 'Salto de rodilla alta desde media rodilla', array['cuadriceps','gluteo_mayor']::text[], array['gemelos','psoas']::text[]),
  ('1/2 Kneel to Lateral Bound', 'Salto lateral desde media rodilla', array['gluteo_mayor','gluteo_medio','cuadriceps']::text[], array['abductores','gemelos']::text[]),
  ('Ab Roller Wheel Abdominal Roll Out', 'Rueda abdominal', array['recto_abdominal','transverso']::text[], array['dorsal_ancho','oblicuos']::text[]),
  ('Alternating Leg Drop', 'Descenso alterno de pierna', array['recto_abdominal','psoas']::text[], array['transverso']::text[]),
  ('Alternating Lunge Hops', 'Saltos de zancada alternos', array['cuadriceps','gluteo_mayor']::text[], array['isquiotibiales','gemelos']::text[]),
  ('Angled Machine Leg Press', 'Prensa inclinada', array['cuadriceps','gluteo_mayor']::text[], array['aductores','isquiotibiales']::text[]),
  ('Band Anchored Pistol Squat to Row', 'Sentadilla a una pierna con remo en banda', array['cuadriceps','gluteo_mayor','dorsal_ancho']::text[], array['biceps','trapecio_medio','transverso']::text[]),
  ('Band Anchored Single Arm Incline Curl', 'Curl inclinado a una mano con banda', array['biceps']::text[], array['braquial']::text[]),
  ('Band Anchored Single Arm Tricep Kickback', 'Patada de tríceps a una mano con banda', array['triceps']::text[], array['deltoide_posterior']::text[]),
  ('Band Deadlift', 'Peso muerto con banda', array['gluteo_mayor','isquiotibiales']::text[], array['erectores','aductores']::text[]),
  ('Bar Hang', 'Colgarse de la barra', array['antebrazo','dorsal_ancho']::text[], array['trapecio_inferior','transverso']::text[]),
  ('Barbell Hip Thrust', 'Hip thrust con barra', array['gluteo_mayor']::text[], array['isquiotibiales','aductores']::text[]),
  ('Barbell Preacher Curl', 'Curl predicador con barra', array['biceps']::text[], array['braquial']::text[]),
  ('Barbell Rear Shrug', 'Encogimiento de hombros con barra por detrás', array['trapecio_superior']::text[], array['trapecio_medio','antebrazo']::text[]),
  ('Barbell Romanian Deadlift', 'Peso muerto rumano con barra', array['isquiotibiales','gluteo_mayor']::text[], array['erectores','antebrazo']::text[]),
  ('Bench Hip Thrust', 'Hip thrust en banco', array['gluteo_mayor']::text[], array['isquiotibiales']::text[]),
  ('Bench Hopover Burpee', 'Burpee saltando el banco', array['cuadriceps','gluteo_mayor']::text[], array['pectoral_mayor','deltoide_anterior','gemelos','recto_abdominal']::text[]),
  ('Bench Knee Tuck to V Up', 'Rodillas al pecho a V-up en banco', array['recto_abdominal','psoas']::text[], array['oblicuos']::text[]),
  ('Bench Plank Single Arm Row', 'Remo a una mano en plancha sobre banco', array['dorsal_ancho','trapecio_medio']::text[], array['recto_abdominal','oblicuos','biceps']::text[]),
  ('Bench Plyo Push Ups', 'Flexiones pliométricas en banco', array['pectoral_mayor','triceps']::text[], array['deltoide_anterior']::text[]),
  ('Bench Side Plank Hip Dip', 'Plancha lateral en banco con descenso de cadera', array['oblicuos']::text[], array['recto_abdominal','gluteo_medio']::text[]),
  ('Bench Single Leg Hip Thrust', 'Hip thrust a una pierna en banco', array['gluteo_mayor']::text[], array['isquiotibiales','gluteo_medio']::text[]),
  ('Bench Twist Crunches', 'Crunch con giro en banco', array['recto_abdominal','oblicuos']::text[], '{}'::text[]),
  ('Bench V Sit Leg Raise', 'Elevación de piernas en V sobre banco', array['recto_abdominal','psoas']::text[], '{}'::text[]),
  ('Bicycle Crunch', 'Bicicleta abdominal', array['recto_abdominal','oblicuos']::text[], array['psoas']::text[]),
  ('Body Weight Calf Raise', 'Elevación de talones sin carga', array['gemelos']::text[], '{}'::text[]),
  ('Body Weight Single Leg Deadlift', 'Peso muerto a una pierna sin peso', array['isquiotibiales','gluteo_mayor']::text[], array['gluteo_medio','erectores']::text[]),
  ('Bodyweight Bent Knee Single Leg Calf Raise', 'Gemelo a una pierna con rodilla flexionada', array['gemelos']::text[], '{}'::text[]),
  ('Bodyweight Deadbug', 'Dead bug', array['recto_abdominal','transverso']::text[], array['psoas']::text[]),
  ('Bodyweight Deadlift', 'Peso muerto sin carga', array['gluteo_mayor','isquiotibiales']::text[], array['erectores']::text[]),
  ('Bodyweight Single Leg Calf Raise', 'Gemelo a una pierna sin peso', array['gemelos']::text[], '{}'::text[]),
  ('Bodyweight Walking Lunge', 'Zancada caminando sin peso', array['cuadriceps','gluteo_mayor']::text[], array['isquiotibiales','aductores','gemelos']::text[]),
  ('Bosu Lateral Bounce to Squat Jump', 'Rebote lateral en BOSU a salto', array['cuadriceps','gluteo_mayor']::text[], array['gluteo_medio','abductores','gemelos']::text[]),
  ('Box Jump', 'Salto al cajón', array['cuadriceps','gluteo_mayor']::text[], array['isquiotibiales','gemelos']::text[]),
  ('Box Pistol Squat', 'Sentadilla a una pierna al cajón', array['cuadriceps','gluteo_mayor']::text[], array['gluteo_medio','gemelos']::text[]),
  ('Broad Jump', 'Salto horizontal', array['gluteo_mayor','cuadriceps']::text[], array['isquiotibiales','gemelos']::text[]),
  ('Bulgarian Pulses', 'Rebotes en búlgara', array['cuadriceps','gluteo_mayor']::text[], array['aductores','gluteo_medio']::text[]),
  ('Burpee', 'Burpee', array['cuadriceps','gluteo_mayor']::text[], array['pectoral_mayor','deltoide_anterior','recto_abdominal']::text[]),
  ('Burpee Broad Jump', 'Burpee con salto horizontal', array['gluteo_mayor','cuadriceps']::text[], array['isquiotibiales','gemelos','pectoral_mayor','deltoide_anterior']::text[]),
  ('Cable Bicep Curl', 'Curl de bíceps en polea', array['biceps']::text[], array['braquial','antebrazo']::text[]),
  ('Cable Glute Crossover Kickback', 'Patada de glúteo cruzada en polea', array['gluteo_mayor','gluteo_medio']::text[], array['abductores']::text[]),
  ('Cable Lateral Raise', 'Elevación lateral en polea', array['deltoide_lateral']::text[], array['trapecio_superior']::text[]),
  ('Cable Rope Face Pull', 'Face pull con cuerda', array['deltoide_posterior','trapecio_medio']::text[], array['romboides','manguito_rotador','trapecio_superior']::text[]),
  ('Cable Seated Close Grip Row', 'Remo sentado agarre cerrado en polea', array['dorsal_ancho','trapecio_medio']::text[], array['romboides','biceps','deltoide_posterior']::text[]),
  ('Cable Seated Close Row', 'Remo sentado agarre estrecho en polea', array['dorsal_ancho','trapecio_medio']::text[], array['romboides','biceps']::text[]),
  ('Cable Seated Wide Grip Row', 'Remo sentado agarre ancho en polea', array['trapecio_medio','dorsal_ancho']::text[], array['deltoide_posterior','romboides','biceps']::text[]),
  ('Cable Shrug', 'Encogimiento de trapecio en polea', array['trapecio_superior']::text[], array['trapecio_medio']::text[]),
  ('Cable Single Arm Bicep Curl', 'Curl de bíceps a una mano en polea', array['biceps']::text[], array['braquial']::text[]),
  ('Cable Single Arm Standing Overhead Tricep Extension', 'Extensión de tríceps a una mano en polea', array['triceps']::text[], '{}'::text[]),
  ('Cable Standing Crossover Chest Fly', 'Cruce de poleas de pie', array['pectoral_mayor']::text[], array['deltoide_anterior']::text[]),
  ('Cable Straight Bar Tricep Pushdown', 'Extensión de tríceps con barra recta en polea', array['triceps']::text[], '{}'::text[]),
  ('Cable Tricep Kickback', 'Patada de tríceps en polea', array['triceps']::text[], array['deltoide_posterior']::text[]),
  ('Cable V Bar Tricep Pushdown', 'Extensión de tríceps en polea alta', array['triceps']::text[], '{}'::text[]),
  ('Cable V-Bar Overhead Tricep Extension', 'Extensión de tríceps sobre la cabeza en polea', array['triceps']::text[], '{}'::text[]),
  ('Chest to wall handstand', 'Pino de cara a la pared', array['deltoide_anterior','triceps']::text[], array['trapecio_superior','recto_abdominal','transverso']::text[]),
  ('Clamshell with Hip Thrust', 'Almeja con empuje de cadera', array['gluteo_medio','gluteo_mayor']::text[], array['abductores','oblicuos']::text[]),
  ('Clapping Push Up', 'Flexión con palmada', array['pectoral_mayor','triceps']::text[], array['deltoide_anterior']::text[]),
  ('Cross Body Mountain Climber', 'Escalador cruzado', array['recto_abdominal','oblicuos']::text[], array['psoas','deltoide_anterior']::text[]),
  ('Decline Plank to Pike', 'Plancha declinada a pica', array['recto_abdominal','deltoide_anterior']::text[], array['transverso','triceps']::text[]),
  ('Dip', 'Fondos en paralelas', array['pectoral_mayor','triceps']::text[], array['deltoide_anterior']::text[]),
  ('Dip Machine Bent Leg Raise', 'Elevación de rodillas en paralelas', array['recto_abdominal','psoas']::text[], array['oblicuos']::text[]),
  ('Dip Machine Straight Leg Raise', 'Elevación de piernas rectas en paralelas', array['recto_abdominal','psoas']::text[], array['oblicuos']::text[]),
  ('Dragon flag tuck eccentric', 'Dragon flag agrupado excéntrico', array['recto_abdominal','transverso']::text[], array['dorsal_ancho','oblicuos']::text[]),
  ('Dumbbell Alternating Bicep Curl', 'Curl de bíceps alterno', array['biceps']::text[], array['braquial','antebrazo']::text[]),
  ('Dumbbell Alternating Hammer Curl', 'Curl martillo alterno', array['braquial','biceps']::text[], array['antebrazo']::text[]),
  ('Dumbbell Alternating Lateral Raise to Front Raise', 'Elevación lateral a frontal alterna', array['deltoide_lateral','deltoide_anterior']::text[], array['trapecio_superior']::text[]),
  ('Dumbbell Bench Press', 'Press banca con mancuernas', array['pectoral_mayor']::text[], array['triceps','deltoide_anterior']::text[]),
  ('Dumbbell Bicep Curl', 'Curl de bíceps con mancuernas', array['biceps']::text[], array['braquial','antebrazo']::text[]),
  ('Dumbbell Bulgarian Split Squat', 'Sentadilla búlgara con mancuernas', array['cuadriceps','gluteo_mayor']::text[], array['aductores','isquiotibiales','gluteo_medio']::text[]),
  ('Dumbbell Burpee Clean to Press', 'Burpee con cargada y press', array['cuadriceps','gluteo_mayor','deltoide_anterior']::text[], array['pectoral_mayor','triceps','isquiotibiales','trapecio_superior']::text[]),
  ('Dumbbell Burpee with Curl to Press', 'Burpee con curl y press', array['cuadriceps','gluteo_mayor','deltoide_anterior']::text[], array['biceps','pectoral_mayor','triceps']::text[]),
  ('Dumbbell Calf Raise', 'Gemelo de pie con mancuerna', array['gemelos']::text[], '{}'::text[]),
  ('Dumbbell Clean to Press', 'Cargada y press con mancuernas', array['gluteo_mayor','isquiotibiales','deltoide_anterior']::text[], array['cuadriceps','trapecio_superior','triceps']::text[]),
  ('Dumbbell Curl to Shoulder Press', 'Curl y press de hombro con mancuernas', array['biceps','deltoide_anterior']::text[], array['deltoide_lateral','triceps']::text[]),
  ('Dumbbell Deadlift', 'Peso muerto con mancuernas', array['gluteo_mayor','isquiotibiales']::text[], array['erectores','cuadriceps','antebrazo']::text[]),
  ('Dumbbell Floor Press', 'Press de pecho en suelo', array['pectoral_mayor','triceps']::text[], array['deltoide_anterior']::text[]),
  ('Dumbbell Front Squat', 'Sentadilla frontal con mancuernas', array['cuadriceps','gluteo_mayor']::text[], array['aductores','recto_abdominal','erectores']::text[]),
  ('Dumbbell Glute Bridge', 'Puente de glúteo con mancuerna', array['gluteo_mayor']::text[], array['isquiotibiales']::text[]),
  ('Dumbbell Glute Bridge Chest Press', 'Press de pecho en puente de glúteo', array['pectoral_mayor','gluteo_mayor']::text[], array['triceps','isquiotibiales']::text[]),
  ('Dumbbell Hammer Curl', 'Curl martillo con mancuernas', array['braquial','biceps']::text[], array['antebrazo']::text[]),
  ('Dumbbell Hip Thrust', 'Hip thrust con mancuerna', array['gluteo_mayor']::text[], array['isquiotibiales','aductores']::text[]),
  ('Dumbbell Incline Alternating Curl', 'Curl inclinado alterno', array['biceps']::text[], array['braquial']::text[]),
  ('Dumbbell Incline Bench High Row', 'Remo alto en banco inclinado', array['trapecio_medio','deltoide_posterior']::text[], array['romboides','trapecio_superior','biceps']::text[]),
  ('Dumbbell Incline Bench Press', 'Press inclinado con mancuernas', array['pectoral_superior','deltoide_anterior']::text[], array['pectoral_mayor','triceps']::text[]),
  ('Dumbbell Incline Bicep Curl', 'Curl inclinado con mancuernas', array['biceps']::text[], array['braquial']::text[]),
  ('Dumbbell Isometric Bicep Curl', 'Curl isométrico con mancuernas', array['biceps']::text[], array['braquial','antebrazo']::text[]),
  ('Dumbbell Lateral Raise', 'Elevación lateral con mancuernas', array['deltoide_lateral']::text[], array['trapecio_superior','deltoide_anterior']::text[]),
  ('Dumbbell Laying Tricep Extension to Press', 'Extensión de tríceps tumbado a press', array['triceps']::text[], array['pectoral_mayor','deltoide_anterior']::text[]),
  ('Dumbbell Reverse Lunge', 'Zancada atrás con mancuernas', array['cuadriceps','gluteo_mayor']::text[], array['aductores','isquiotibiales']::text[]),
  ('Dumbbell Seated Arnold Press', 'Press Arnold sentado', array['deltoide_anterior','deltoide_lateral']::text[], array['triceps','trapecio_superior','deltoide_posterior']::text[]),
  ('Dumbbell Seated Front Raise', 'Elevación frontal sentado', array['deltoide_anterior']::text[], array['deltoide_lateral','pectoral_superior']::text[]),
  ('Dumbbell Seated Overhead Tricep Extension', 'Extensión de tríceps sobre la cabeza sentado', array['triceps']::text[], '{}'::text[]),
  ('Dumbbell Seated Shoulder Press', 'Press de hombro sentado con mancuernas', array['deltoide_anterior','deltoide_lateral']::text[], array['triceps','trapecio_superior']::text[]),
  ('Dumbbell Shrug', 'Encogimiento de trapecio con mancuernas', array['trapecio_superior']::text[], array['trapecio_medio','antebrazo']::text[]),
  ('Dumbbell Single Arm Row', 'Remo a una mano con mancuerna', array['dorsal_ancho','trapecio_medio']::text[], array['biceps','deltoide_posterior','romboides']::text[]),
  ('Dumbbell Single Leg Calf Raise', 'Elevación de talón a una pierna con mancuerna', array['gemelos']::text[], '{}'::text[]),
  ('Dumbbell Stationary Lunge', 'Zancada estática con mancuernas', array['cuadriceps','gluteo_mayor']::text[], array['aductores','isquiotibiales']::text[]),
  ('Dumbbell Straight Leg Deadlift', 'Peso muerto piernas rectas con mancuernas', array['isquiotibiales','gluteo_mayor']::text[], array['erectores']::text[]),
  ('Dumbbell Sumo Deadlift', 'Peso muerto sumo con mancuerna', array['gluteo_mayor','aductores']::text[], array['isquiotibiales','cuadriceps','erectores']::text[]),
  ('Dumbbell Walking Lunge', 'Zancada caminando con mancuernas', array['cuadriceps','gluteo_mayor']::text[], array['aductores','isquiotibiales','gemelos']::text[]),
  ('EZ Bar Preacher Curl', 'Curl predicador con barra Z', array['biceps']::text[], array['braquial']::text[]),
  ('Elevated Pike Push-Up', 'Flexión en pica con pies elevados', array['deltoide_anterior','triceps']::text[], array['trapecio_superior','pectoral_superior','recto_abdominal']::text[]),
  ('Glute Bridge', 'Puente de glúteo', array['gluteo_mayor']::text[], array['isquiotibiales']::text[]),
  ('Half Burpee with Dumbbell', 'Medio burpee con mancuernas', array['cuadriceps','gluteo_mayor']::text[], array['pectoral_mayor','deltoide_anterior','erectores']::text[]),
  ('Half Kneeling SuperBand Single Arm Row', 'Remo a una mano con banda de rodillas', array['dorsal_ancho','trapecio_medio']::text[], array['biceps','deltoide_posterior','oblicuos']::text[]),
  ('High Plank Jacks', 'Plancha alta con saltos', array['recto_abdominal','abductores']::text[], array['deltoide_anterior','gemelos']::text[]),
  ('Hip Thrust Machine', 'Hip thrust en máquina', array['gluteo_mayor']::text[], array['isquiotibiales']::text[]),
  ('Hollow Body Hold Flutter Kicks', 'Hollow hold con tijeras', array['recto_abdominal','psoas']::text[], array['transverso']::text[]),
  ('Horizontal Cable Rotation', 'Rotación horizontal en polea', array['oblicuos']::text[], array['recto_abdominal','transverso']::text[]),
  ('Jump Squat to Reverse Lunge', 'Sentadilla con salto a zancada atrás', array['cuadriceps','gluteo_mayor']::text[], array['isquiotibiales','gemelos']::text[]),
  ('Kettlebell Alternating Bent Over Row', 'Remo inclinado alterno con kettlebell', array['dorsal_ancho','trapecio_medio']::text[], array['deltoide_posterior','biceps','erectores']::text[]),
  ('Kettlebell Alternating Halo with Chest Press', 'Halo alterno con press de pecho (kettlebell)', array['pectoral_mayor','deltoide_anterior']::text[], array['recto_abdominal','triceps','oblicuos']::text[]),
  ('Kettlebell Alternating Press', 'Press alterno con kettlebell', array['deltoide_anterior','deltoide_lateral']::text[], array['triceps','trapecio_superior']::text[]),
  ('Kettlebell Alternating Stationary Cossack Squat', 'Sentadilla cosaco alterna con kettlebell', array['cuadriceps','gluteo_mayor','aductores']::text[], array['isquiotibiales','abductores']::text[]),
  ('Kettlebell High Pull', 'Cargada alta con kettlebell', array['trapecio_superior','deltoide_lateral']::text[], array['gluteo_mayor','isquiotibiales','deltoide_posterior']::text[]),
  ('Kettlebell Lateral Step Up', 'Subida lateral al cajón con kettlebell', array['cuadriceps','gluteo_mayor']::text[], array['gluteo_medio','abductores','isquiotibiales']::text[]),
  ('Kettlebell Single Arm Clean and Press', 'Cargada y press a una mano con kettlebell', array['gluteo_mayor','deltoide_anterior']::text[], array['isquiotibiales','cuadriceps','triceps','trapecio_superior']::text[]),
  ('Knee to Elbow Crunch', 'Crunch rodilla al codo', array['recto_abdominal','oblicuos']::text[], array['psoas']::text[]),
  ('Landmine Deadlift', 'Peso muerto con landmine', array['gluteo_mayor','isquiotibiales']::text[], array['erectores','cuadriceps']::text[]),
  ('Landmine Half-Kneeling Single Arm Press', 'Press a una mano de rodillas con landmine', array['deltoide_anterior','pectoral_superior']::text[], array['triceps','oblicuos']::text[]),
  ('Landmine RDL', 'Peso muerto rumano con landmine', array['isquiotibiales','gluteo_mayor']::text[], array['erectores']::text[]),
  ('Landmine Rotational Clean and Press', 'Cargada y press rotacional con landmine', array['gluteo_mayor','deltoide_anterior','oblicuos']::text[], array['cuadriceps','isquiotibiales','triceps']::text[]),
  ('Leg Press Machine Calf Raise', 'Gemelo en prensa', array['gemelos']::text[], '{}'::text[]),
  ('Lying Hip Abductions', 'Abducción de cadera tumbado', array['gluteo_medio']::text[], array['abductores','gluteo_mayor']::text[]),
  ('Machine Assisted Dip', 'Fondos asistidos en máquina', array['pectoral_mayor','triceps']::text[], array['deltoide_anterior']::text[]),
  ('Machine Assisted Parallel Grip Pull Up', 'Dominada asistida agarre paralelo', array['dorsal_ancho','biceps']::text[], array['trapecio_medio','braquial']::text[]),
  ('Machine Assisted Wide Grip Pull Up', 'Dominada asistida agarre ancho', array['dorsal_ancho']::text[], array['biceps','trapecio_medio','trapecio_inferior']::text[]),
  ('Machine Lateral Raise', 'Elevación lateral en máquina', array['deltoide_lateral']::text[], array['deltoide_posterior','trapecio_superior']::text[]),
  ('Machine Lying Leg Curl', 'Curl femoral tumbado en máquina', array['isquiotibiales']::text[], array['gemelos']::text[]),
  ('Machine Preacher Curl', 'Curl predicador en máquina', array['biceps']::text[], array['braquial']::text[]),
  ('Machine Seated Calf Raise', 'Gemelo sentado en máquina', array['gemelos']::text[], '{}'::text[]),
  ('Machine Seated Chest Fly', 'Aperturas en máquina', array['pectoral_mayor']::text[], array['deltoide_anterior']::text[]),
  ('Machine Seated Chest Press', 'Press de pecho sentado en máquina', array['pectoral_mayor']::text[], array['deltoide_anterior','triceps']::text[]),
  ('Machine Seated Hip Adduction', 'Aductores en máquina', array['aductores']::text[], '{}'::text[]),
  ('Machine Seated Leg Curl', 'Curl femoral sentado en máquina', array['isquiotibiales']::text[], '{}'::text[]),
  ('Machine Seated Leg Extension', 'Extensión de cuádriceps en máquina', array['cuadriceps']::text[], '{}'::text[]),
  ('Machine Seated Parallel Grip Shoulder Press', 'Press de hombro agarre paralelo en máquina', array['deltoide_anterior','deltoide_lateral']::text[], array['triceps']::text[]),
  ('Machine Seated Reverse Fly', 'Pájaro en máquina', array['deltoide_posterior','trapecio_medio']::text[], array['romboides']::text[]),
  ('Machine Seated Shoulder Press', 'Press de hombro sentado en máquina', array['deltoide_anterior','deltoide_lateral']::text[], array['triceps','trapecio_superior']::text[]),
  ('Machine Seated Single Arm Neutral Grip Row', 'Remo a una mano en máquina agarre neutro', array['dorsal_ancho','trapecio_medio']::text[], array['biceps','deltoide_posterior']::text[]),
  ('Machine Standing Calf Raise', 'Gemelo de pie en máquina', array['gemelos']::text[], '{}'::text[]),
  ('Medicine Ball Slam with Squat Jump', 'Golpe de balón medicinal con salto', array['cuadriceps','gluteo_mayor','dorsal_ancho']::text[], array['recto_abdominal','deltoide_anterior','gemelos']::text[]),
  ('Mini Band Alternating Hip Abduction', 'Abducción de cadera alterna con banda', array['gluteo_medio']::text[], array['abductores','gluteo_mayor']::text[]),
  ('Mini Band Bent Over Y''s', 'Y con banda inclinado', array['trapecio_inferior','deltoide_posterior']::text[], array['trapecio_medio','deltoide_lateral','erectores']::text[]),
  ('Mini Band Delt Raises', 'Elevación de deltoides con banda', array['deltoide_lateral','deltoide_anterior']::text[], array['trapecio_superior','manguito_rotador']::text[]),
  ('Mini Band Side Lying Hip Abduction', 'Abducción de cadera tumbado con banda', array['gluteo_medio']::text[], array['abductores']::text[]),
  ('Mini Band Wall Sit', 'Sentadilla isométrica en pared con banda', array['cuadriceps','gluteo_mayor']::text[], array['abductores','gluteo_medio']::text[]),
  ('Mini Band Wall Sit with Abductions', 'Sentadilla isométrica en pared con abducción', array['cuadriceps','gluteo_medio']::text[], array['abductores','gluteo_mayor']::text[]),
  ('Mountain Climber', 'Escalador', array['recto_abdominal','psoas']::text[], array['deltoide_anterior','cuadriceps']::text[]),
  ('Muscle Up', 'Muscle up', array['dorsal_ancho','pectoral_mayor','triceps']::text[], array['biceps','deltoide_anterior','recto_abdominal']::text[]),
  ('Pallof Press', 'Press Pallof', array['oblicuos','transverso']::text[], array['recto_abdominal','deltoide_anterior']::text[]),
  ('Pilates - Oblique Twists with Ball', 'Giros de oblicuos con balón', array['oblicuos']::text[], array['recto_abdominal']::text[]),
  ('Plank To Push Up', 'De plancha a flexión', array['recto_abdominal','triceps']::text[], array['pectoral_mayor','deltoide_anterior']::text[]),
  ('Plate Hip Thrust', 'Hip thrust con disco', array['gluteo_mayor']::text[], array['isquiotibiales']::text[]),
  ('Plate Russian Twist', 'Giro ruso con disco', array['oblicuos']::text[], array['recto_abdominal','psoas']::text[]),
  ('Plate Weighted Dip', 'Fondos lastrados', array['pectoral_mayor','triceps']::text[], array['deltoide_anterior']::text[]),
  ('Plate Weighted Wide Grip Pull Up', 'Dominada lastrada agarre ancho', array['dorsal_ancho','biceps']::text[], array['trapecio_medio','deltoide_posterior','antebrazo']::text[]),
  ('Pull Up', 'Dominada', array['dorsal_ancho','biceps']::text[], array['trapecio_medio','deltoide_posterior','antebrazo']::text[]),
  ('Push Up', 'Flexión de brazos', array['pectoral_mayor','triceps']::text[], array['deltoide_anterior','recto_abdominal']::text[]),
  ('Reverse nordic curl band assisted', 'Nórdico inverso asistido con banda', array['cuadriceps']::text[], array['psoas','recto_abdominal']::text[]),
  ('Scapular Pushups from Elbows', 'Flexión escapular desde codos', array['deltoide_anterior']::text[], array['recto_abdominal','trapecio_medio','transverso']::text[]),
  ('Seated Dumbbell Front Raise to Lateral Raise', 'Elevación frontal a lateral sentado', array['deltoide_anterior','deltoide_lateral']::text[], array['trapecio_superior']::text[]),
  ('Seated Dumbbell Hammer Curl to Neutral Press', 'Curl martillo sentado a press neutro', array['biceps','deltoide_anterior']::text[], array['braquial','triceps']::text[]),
  ('Seated Hip Twist', 'Giro de cadera sentado', array['oblicuos']::text[], array['recto_abdominal','erectores']::text[]),
  ('Seated Leg Press', 'Prensa sentado', array['cuadriceps','gluteo_mayor']::text[], array['isquiotibiales','aductores']::text[]),
  ('Seated Machine Ab Crunch', 'Crunch abdominal en máquina', array['recto_abdominal']::text[], array['oblicuos']::text[]),
  ('Smith Machine Back Squat', 'Sentadilla trasera en multipower', array['cuadriceps','gluteo_mayor']::text[], array['isquiotibiales','aductores']::text[]),
  ('Smith Machine Bench Press', 'Press banca en multipower', array['pectoral_mayor']::text[], array['triceps','deltoide_anterior']::text[]),
  ('Smith Machine Deadlift', 'Peso muerto en multipower', array['gluteo_mayor','isquiotibiales']::text[], array['erectores','trapecio_medio','antebrazo']::text[]),
  ('Smith Machine Incline Bench Press', 'Press inclinado en multipower', array['pectoral_superior']::text[], array['deltoide_anterior','triceps']::text[]),
  ('Smith Machine Seated Shoulder Press', 'Press de hombro sentado en multipower', array['deltoide_anterior','deltoide_lateral']::text[], array['triceps']::text[]),
  ('Smith Machine Shrug', 'Encogimiento de trapecio en multipower', array['trapecio_superior']::text[], array['trapecio_medio']::text[]),
  ('Smith Machine Sumo Deadlift', 'Peso muerto sumo en multipower', array['gluteo_mayor','aductores']::text[], array['isquiotibiales','erectores','trapecio_medio']::text[]),
  ('Spiderman Push Up', 'Flexión spiderman', array['pectoral_mayor','triceps']::text[], array['oblicuos','deltoide_anterior','psoas']::text[]),
  ('Split Squat Pulse', 'Rebotes en zancada', array['cuadriceps','gluteo_mayor']::text[], array['aductores','isquiotibiales']::text[]),
  ('Squat Jump', 'Sentadilla con salto', array['cuadriceps','gluteo_mayor']::text[], array['isquiotibiales','gemelos']::text[]),
  ('Squat Pulse', 'Rebotes en sentadilla', array['cuadriceps','gluteo_mayor']::text[], array['aductores','isquiotibiales']::text[]),
  ('Squat to Squat Jump', 'Sentadilla a sentadilla con salto', array['cuadriceps','gluteo_mayor']::text[], array['isquiotibiales','gemelos']::text[]),
  ('SuperBand Anchored Pistol Squat to Row', 'Sentadilla a una pierna con remo en superbanda', array['cuadriceps','gluteo_mayor','dorsal_ancho']::text[], array['biceps','trapecio_medio','transverso']::text[]),
  ('SuperBand Anchored Tricep Pushdown', 'Extensión de tríceps con banda anclada', array['triceps']::text[], '{}'::text[]),
  ('SuperBand Deadlift', 'Peso muerto con superbanda', array['gluteo_mayor','isquiotibiales']::text[], array['erectores']::text[]),
  ('SuperBand Push Up', 'Flexión con superbanda', array['pectoral_mayor','triceps']::text[], array['deltoide_anterior','recto_abdominal']::text[]),
  ('SuperBand Single Arm Row', 'Remo a una mano con banda', array['dorsal_ancho']::text[], array['trapecio_medio','biceps','deltoide_posterior']::text[]),
  ('Superband Pull Apart', 'Apertura con superbanda', array['deltoide_posterior','trapecio_medio']::text[], array['romboides','trapecio_superior']::text[]),
  ('Superband Squat', 'Sentadilla con superbanda', array['cuadriceps','gluteo_mayor']::text[], array['isquiotibiales','aductores']::text[]),
  ('Superman Around the World', 'Superman con círculos de brazos', array['erectores','gluteo_mayor']::text[], array['deltoide_posterior','trapecio_medio','trapecio_superior','isquiotibiales']::text[]),
  ('Wide Grip Lat Pulldown', 'Jalón al pecho agarre ancho', array['dorsal_ancho']::text[], array['biceps','trapecio_medio','trapecio_inferior']::text[]),
  ('Wide Grip Pull Up', 'Dominada agarre ancho', array['dorsal_ancho']::text[], array['biceps','trapecio_medio','trapecio_inferior']::text[]);

update ejercicios e
   set musculos_primarios   = m.prim,
       musculos_secundarios = m.sec,
       updated_at = now()
  from _musculos m
 where (lower(e.alias) = lower(m.alias) or lower(e.nombre) = lower(m.nombre) or lower(e.nombre) = lower(m.alias))
   and (coalesce(cardinality(e.musculos_primarios), 0) = 0
        or coalesce(cardinality(e.musculos_secundarios), 0) = 0)
   and (e.musculos_primarios is distinct from m.prim or e.musculos_secundarios is distinct from m.sec);

-- 1) Cuántos de la lista quedaron con su silueta.
select count(*) filter (where e.id is not null)                 as en_tu_galeria,
       count(*) filter (where e.id is null)                     as no_estan_en_tu_galeria,
       count(*) filter (where e.musculos_primarios = m.prim)    as con_esta_version
  from _musculos m
  left join lateral (
    select id, musculos_primarios from ejercicios x
     where lower(x.alias) = lower(m.alias) or lower(x.nombre) = lower(m.nombre) or lower(x.nombre) = lower(m.alias)
     limit 1) e on true;

drop table _musculos;
commit;

-- 2) Ejercicios de fuerza que TODAVÍA no tienen músculos. Ábrelos en el CRM
--    (Galería → ficha → Qué trabaja) y márcalos a mano.
select nombre, alias, tipo
  from ejercicios
 where tipo in ('fuerza', 'core', 'potencia', 'pliometrico')
   and coalesce(cardinality(musculos_primarios), 0) = 0
   and coalesce(archivado, false) = false
 order by nombre;

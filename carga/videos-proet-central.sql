-- ════════════════════════════════════════════════════════════════════════
-- VIDEOS: PROET PRIMERO, CENTRAL ATHLETE DESPUÉS
-- ════════════════════════════════════════════════════════════════════════
-- Dónde: Supabase del CRM → SQL Editor → pegar todo → Run.
-- Se puede correr dos veces: la segunda no cambia nada.
--
-- Canales revisados (todos sus videos, 4.188 en total):
--   · PROET Ejercicio Terapéutico  youtube.com/@proetejercicioterapeutico5675  (976)
--   · Central Athlete ATX          youtube.com/@CentralAthleteatx              (3.212)
-- Los dos muestran solo el ejercicio: sin hablar, sin intro, 10-30 s.
--
-- PARTE 1 · Los ejercicios de tus rutinas. ESTA PARTE SÍ REEMPLAZA el video
-- que tengan («si sustituye a los que ya están, no importa»).
--   94 con PROET (incluye los 57 de la vez pasada, menos 2 que ahora tienen
--      uno exacto en Central Athlete) · 63 con Central Athlete.
--   Orden de preferencia: 1) Proet, el mismo ejercicio; 2) Proet, el mismo
--   movimiento con otra carga (p. ej. sin mancuernas o con barra libre en vez
--   de multipower), con nota; 3) Central Athlete, el mismo ejercicio.
--   Si ninguno de los dos canales tiene el ejercicio, se queda el que ya tenía
--   (combinados, flujos de movilidad, máquinas asistidas, BOSU, landmine…).
--
-- PARTE 2 · El resto de la galería: 88 fichas cuyo nombre es EXACTAMENTE
-- el de un video de Central Athlete. Esta parte NO pisa nada: solo llena las
-- que todavía no tienen video.
--
-- Los que llevan nota salen PRIMERO en la tabla del final. Si alguno no te
-- convence, borra su línea del «insert» antes de correrlo, o cámbialo luego en
-- el CRM (Galería → «🎬 Video»).
-- ════════════════════════════════════════════════════════════════════════
begin;

create temp table _v (alias text, nombre text, canal text, ref text, titulo text, nota text) on commit drop;
insert into _v (alias, nombre, canal, ref, titulo, nota) values
  ('Ab Roller Wheel Abdominal Roll Out', 'Rueda abdominal', 'proet', 'qCPB3h2U1eY', '535. Abdominales con roller', null),
  ('Alternating Leg Drop', 'Descenso alterno de pierna', 'proet', 'jGX3bxjv5Eg', '775. Bajada alterna de una pierna flexionada en 90º', 'con las rodillas flexionadas a 90°'),
  ('Alternating Lunge Hops', 'Saltos de zancada alternos', 'proet', 'ee9tzWsEFmY', '588. Salto vertical desde zancada y cruzando piernas', null),
  ('Band Anchored Single Arm Tricep Kickback', 'Patada de tríceps a una mano con banda', 'proet', 'NStmfn7IhIw', '780. Patadas de triceps con banda elástica', null),
  ('Band Internal Shoulder Rotation (90 degrees)', 'Rotación interna de hombro con banda (90°)', 'proet', 'BNb1r36_sww', '978. Rotación interna de hombro con banda elástica', null),
  ('Barbell Romanian Deadlift', 'Peso muerto rumano con barra', 'proet', 'ueg9QHdnGbo', '391. Peso muerto rumano o con piernas estiradas', null),
  ('Bench V Sit Leg Raise', 'Elevación de piernas en V sobre banco', 'proet', 'OnOOGaz7GGg', '959. Encogimiento en V sentado', 'en el suelo, no en el banco'),
  ('Bicycle Crunch', 'Bicicleta abdominal', 'proet', 'r4tewUf5CRs', '590. Flexión de caderas alternas hacia el codo contrario', null),
  ('Body Weight Calf Raise', 'Elevación de talones sin carga', 'proet', '3DW2rm90F6A', '768. Elevación de gemelos', null),
  ('Body Weight Single Leg Deadlift', 'Peso muerto a una pierna sin peso', 'proet', 'KfdKCCYBpIo', '905. Peso muerto a una pierna con mancuernas', 'con mancuernas'),
  ('Bodyweight Deadbug', 'Dead bug', 'proet', 'XkTtXA3-IqU', '825. Dead bug o Bicho muerto', null),
  ('Bodyweight Deadlift', 'Peso muerto sin carga', 'proet', 'FcKJ29VgTd8', '577. Peso muerto con mancuernas', 'con mancuernas'),
  ('Box Jump', 'Salto al cajón', 'proet', 'fc8Vd-HB5Ug', '13. Salto pies juntos sobre banco', 'salto a un banco'),
  ('Broad Jump', 'Salto horizontal', 'proet', 'aKJs5bHTiXY', '36. Salto adelante a pies juntos', null),
  ('Burpee', 'Burpee', 'proet', 'cWEs3-ZEXVc', '600. Burpee', null),
  ('Cable Bicep Curl', 'Curl de bíceps en polea', 'proet', '7jrHATAqHDA', '517. Curl de biceps con cable polea de pie', null),
  ('Cable External Rotation', 'Rotación externa en polea', 'proet', 'm5t2BqBJW9w', '507. Rotación externa de hombro con cable-polea', null),
  ('Cable Shrug', 'Encogimiento de trapecio en polea', 'proet', '9A_kfZ8kzJc', '654. Encogimiento de hombros con mancuernas', 'con mancuernas, no en polea'),
  ('Cable Single Arm Bicep Curl', 'Curl de bíceps a una mano en polea', 'proet', 'FBU0aOU0ang', '486. Curl de biceps a una mano con cable polea de pie', null),
  ('Cable Standing Crossover Chest Fly', 'Cruce de poleas de pie', 'proet', 'GPvvixV6Q-g', '457. Cruces con poleas de pie', null),
  ('Cable Straight Bar Tricep Pushdown', 'Extensión de tríceps con barra recta en polea', 'proet', 'k65GOhLjeco', '464. Extensión de tríceps con cable polea de pie', null),
  ('Cable V Bar Tricep Pushdown', 'Extensión de tríceps en polea alta', 'proet', 'k65GOhLjeco', '464. Extensión de tríceps con cable polea de pie', null),
  ('Cat to Cow', 'Gato-camello', 'proet', '-zfItYp9Mic', '1070. Yoga: Postura del gato y vaca', null),
  ('Child''s Pose', 'Postura del niño', 'proet', '0yldJRcnJbk', '1067. Yoga: Postura del niño', null),
  ('Clapping Push Up', 'Flexión con palmada', 'proet', 'jDrEYN-x_pA', '539. Flexiones de brazos con palmada', null),
  ('Cobra', 'Cobra', 'proet', 'aPCyseqROLU', '1066. Yoga: Postura de la Cobra', null),
  ('Dumbbell Alternating Bicep Curl', 'Curl de bíceps alterno', 'proet', 'MHF9VflB7MI', '204. Curl de biceps alterno de pie con mancuernas y giro', null),
  ('Dumbbell Alternating Hammer Curl', 'Curl martillo alterno', 'proet', 'uL_8n0_QmSQ', '208. Curl de biceps alterno con mancuernas de pie agarre tipo martillo', null),
  ('Dumbbell Bench Press', 'Press banca con mancuernas', 'proet', '5mSgcopzGo4', '199. Press pectoral con mancuernas', null),
  ('Dumbbell Bicep Curl', 'Curl de bíceps con mancuernas', 'proet', '0j6rItm15YI', '209. Curl de biceps con mancuernas de pie y giro', 'con giro de muñeca'),
  ('Dumbbell Bulgarian Split Squat', 'Sentadilla búlgara con mancuernas', 'proet', 'vFC4azOUdW8', '27. Zancada con la otra pierna elevada o sentadilla bulgara', 'sin mancuernas en el video'),
  ('Dumbbell Calf Raise', 'Gemelo de pie con mancuerna', 'proet', '1BL4681pIz4', '697. Elevación de gemelos de pie con mancuernas', null),
  ('Dumbbell Deadlift', 'Peso muerto con mancuernas', 'proet', 'FcKJ29VgTd8', '577. Peso muerto con mancuernas', null),
  ('Dumbbell External Rotation on Side', 'Rotación externa tumbado de lado', 'proet', 'f77gqIajNw4', '859. Rotación externa de hombros tumbado de lado', null),
  ('Dumbbell Floor Press', 'Press de pecho en suelo', 'proet', 'y9XAsTx3XxQ', '452. Press pectoral con mancuernas tumbado en el suelo', null),
  ('Dumbbell Glute Bridge', 'Puente de glúteo con mancuerna', 'proet', 'wACebloZ1Nk', '1047. Puente de gluteos', 'sin mancuerna'),
  ('Dumbbell Hammer Curl', 'Curl martillo con mancuernas', 'proet', 'qyEPpBgQ7Gc', '207. Curl de biceps con mancuernas de pie agarre tipo martillo', null),
  ('Dumbbell Incline Alternating Curl', 'Curl inclinado alterno', 'proet', 'rnAYOdcn83s', '829. Curl de biceps alterno con mancuernas en banco inclinado', null),
  ('Dumbbell Incline Bench High Row', 'Remo alto en banco inclinado', 'proet', '736dt_Cx2Aw', '834 Remo con mancuernas en banco inclinado', null),
  ('Dumbbell Incline Bench Press', 'Press inclinado con mancuernas', 'proet', 'KLeK1101U1w', '343. Press pectoral con mancuernas en banco inclinado', null),
  ('Dumbbell Incline Bicep Curl', 'Curl inclinado con mancuernas', 'proet', 'eSADGjh6Wf8', '383. Curl de biceps con mancuernas en banco inclinado', null),
  ('Dumbbell Lateral Raise', 'Elevación lateral con mancuernas', 'proet', 'Gqd7wZANxVo', '443. Elevación lateral de hombros con mancuernas de pie', null),
  ('Dumbbell Reverse Lunge', 'Zancada atrás con mancuernas', 'proet', 'wF96HPOuf7E', '824. Zancada inversa', 'sin mancuernas'),
  ('Dumbbell Seated Arnold Press', 'Press Arnold sentado', 'proet', 'gta2WJkPdhE', '1094. Press Arnold', null),
  ('Dumbbell Seated Front Raise', 'Elevación frontal sentado', 'proet', '8w-SHN1eKg0', '164. Elevación frontal de hombros con mancuernas sentado agarre en pronación', null),
  ('Dumbbell Seated Overhead Tricep Extension', 'Extensión de tríceps sobre la cabeza sentado', 'proet', 'dxLlYmNOr-E', '147. Extensión de tríceps a dos manos con mancuerna sentado', null),
  ('Dumbbell Seated Shoulder Press', 'Press de hombro sentado con mancuernas', 'proet', '96xeqjYXkT4', '159. Press de hombros con mancuernas sentado', null),
  ('Dumbbell Shrug', 'Encogimiento de trapecio con mancuernas', 'proet', '9A_kfZ8kzJc', '654. Encogimiento de hombros con mancuernas', null),
  ('Dumbbell Single Arm Row', 'Remo a una mano con mancuerna', 'proet', 'P4_xxq_Im_w', '151. Remo con mancuerna con rodilla apoyada', null),
  ('Dumbbell Stationary Lunge', 'Zancada estática con mancuernas', 'proet', 'p44JX2_Xstw', '433. Sentadilla estática en posición de zancada', 'sin mancuernas'),
  ('Dumbbell Straight Leg Deadlift', 'Peso muerto piernas rectas con mancuernas', 'proet', 'ueg9QHdnGbo', '391. Peso muerto rumano o con piernas estiradas', 'con barra'),
  ('Extensión muñeca', 'Extensión de muñeca', 'proet', 'Gce3fZnXLFQ', '125. Extensión de muñeca con mancuerna en pronación', null),
  ('Fire Hydrant Standing', 'Abducción de cadera de pie', 'proet', 'c3FB6RQRnyE', '298. Rotación externa de cadera de pie con rodilla levantada', null),
  ('Glute Bridge', 'Puente de glúteo', 'proet', 'wACebloZ1Nk', '1047. Puente de gluteos', null),
  ('High Plank Jacks', 'Plancha alta con saltos', 'proet', 'qb1rvKezVBc', '842. Jumping jack en plancha', null),
  ('Hollow Body Hold Flutter Kicks', 'Hollow hold con tijeras', 'proet', '0SzVVZGDIF8', '718. Tijeras tumbado supino', 'tijeras sin la posición hollow'),
  ('Horizontal Cable Rotation', 'Rotación horizontal en polea', 'proet', '2umsiyK7LQk', '475. Rotación de tronco de pie con cable polea a dos manos', null),
  ('Kettlebell Alternating Press', 'Press alterno con kettlebell', 'proet', 'pY0MGs4M0fQ', '915. Kettlebell Press de hombros', 'no alterno en el video'),
  ('Kettlebell High Pull', 'Cargada alta con kettlebell', 'proet', 'qH2RN82vUzE', '913. Kettlebell:peso muerto y remo al cuello', null),
  ('Kettlebell Windmill', 'Molino con kettlebell', 'proet', 'FzzMq9XYO3s', '912. Kettlebell : El molino', null),
  ('Knee to Elbow Crunch', 'Crunch rodilla al codo', 'proet', 'WSh7tO0Ndl4', '43. Encogimientos codo contrario busca rodilla flex', null),
  ('Lying Hip Abductions', 'Abducción de cadera tumbado', 'proet', 'uqJlSyPIEoA', '1048. Abducción cadera tumbado', null),
  ('Machine Seated Chest Fly', 'Aperturas en máquina', 'proet', 'gP2fcpYRrJM', '182. Contractor pectoral con poleas sentado', 'máquina de poleas'),
  ('Machine Seated Leg Extension', 'Extensión de cuádriceps en máquina', 'proet', 'WAMwZLxhGd4', '214. Extension de piernas en maquina', null),
  ('Machine Seated Parallel Grip Shoulder Press', 'Press de hombro agarre paralelo en máquina', 'proet', 'p5v_REt274k', '572. Press frontal de hombros en máquina sentado y agarre neutro', null),
  ('Machine Seated Shoulder Press', 'Press de hombro sentado en máquina', 'proet', 'p5v_REt274k', '572. Press frontal de hombros en máquina sentado y agarre neutro', 'agarre neutro'),
  ('Mini Band Side Lying Hip Abduction', 'Abducción de cadera tumbado con banda', 'proet', '2oV_JTdrMak', '1061. Abductores con miniband tumbado', null),
  ('Mountain Climber', 'Escalador', 'proet', 'L3i_8RTKmtc', '736. Mountain climber', null),
  ('Pallof Press', 'Press Pallof', 'proet', 'CxjQR4sbn5s', '1091. Press Pallof', null),
  ('Pilates - Swan', 'Cisne (pilates)', 'proet', 'hn7jumSH69Q', '904. Extensión de tronco tumbado prono', 'versión básica'),
  ('Plank To Push Up', 'De plancha a flexión', 'proet', 'N-QuHdr0yHM', '717. Plancha y flexión de brazos', null),
  ('Pronación muñeca con banda elástica', 'Pronación de muñeca con banda', 'proet', 'SYx26hPIDXw', '794. Pronación de  muñeca con banda elástica', null),
  ('Pull Up', 'Dominada', 'proet', 'bIFpgQhoRpU', '222. Dominadas', null),
  ('Push Up', 'Flexión de brazos', 'proet', 'NiElkGUcAPY', '152. Flexiones de brazos', null),
  ('Reverse nordic curl band assisted', 'Nórdico inverso asistido con banda', 'proet', 'DUIJAhEaMm4', '1100. Curl Nórdico Invertido', 'sin la banda'),
  ('Running', 'Carrera continua', 'proet', 'UzLS7Jy2sO0', '66. Correr', null),
  ('Seated Leg Press', 'Prensa sentado', 'proet', 'Ys3DUOTOuSU', '256. Prensa horizontal en maquina', null),
  ('Smith Machine Back Squat', 'Sentadilla trasera en multipower', 'proet', 'fnTAsFzVcr4', '532. Sentadilla completa con barra', 'con barra libre, no en multipower'),
  ('Smith Machine Bench Press', 'Press banca en multipower', 'proet', 'bCqiGmP3k1g', '169. Press de banca con barra', 'con barra libre, no en multipower'),
  ('Smith Machine Deadlift', 'Peso muerto en multipower', 'proet', '5JkbF4TCWAU', '34. Peso muerto con barra o tradicional', 'con barra libre, no en multipower'),
  ('Smith Machine Incline Bench Press', 'Press inclinado en multipower', 'proet', 'HzRAOqSvYBQ', '346. Press pectoral con barra banco inclinado', 'con barra libre, no en multipower'),
  ('Smith Machine Seated Shoulder Press', 'Press de hombro sentado en multipower', 'proet', 'CBaRO3zuh0A', '177. Press frontal de hombro sentado con barra', 'con barra libre, no en multipower'),
  ('Smith Machine Shrug', 'Encogimiento de trapecio en multipower', 'proet', 'k8aFSbaOVio', '235. Encogimiento de hombros de pie con barra', 'con barra libre, no en multipower'),
  ('Smith Machine Sumo Deadlift', 'Peso muerto sumo en multipower', 'proet', 'JUFtAU80YqQ', '725. Peso muerto sumo con barra', 'con barra libre, no en multipower'),
  ('Spiderman Push Up', 'Flexión spiderman', 'proet', '57dcZ5z0uK4', '145. Flexiones de brazos con flexión de cadera', null),
  ('Squat Jump', 'Sentadilla con salto', 'proet', 'AouYYKNTUeA', '582. Salto desde media sentadilla con brazos cruzados', 'brazos cruzados'),
  ('Squat to Squat Jump', 'Sentadilla a sentadilla con salto', 'proet', 'NPKbf6RzU44', '342. Media sentadilla y salto vertical con manos en la nuca', null),
  ('SuperBand Anchored Tricep Pushdown', 'Extensión de tríceps con banda anclada', 'proet', 'iWHdoUZv-_o', '976. Extensión de triceps con goma elástica', null),
  ('Superband Pull Apart', 'Apertura con superbanda', 'proet', 'sf1csHW-0R4', '107. Aperturas de hombros con banda elástica de pie', null),
  ('Superband Squat', 'Sentadilla con superbanda', 'proet', 'VvAtc1j0Feg', '1119. Media sentadilla con gomas', null),
  ('Superman Around the World', 'Superman con círculos de brazos', 'proet', 'sWZMzeppZVI', '965. Superman alterno', 'superman alterno, sin el balón'),
  ('Table Top Half Arm Thoracic Rotation', 'Rotación torácica en cuadrupedia', 'proet', 'iWxGRsCGURM', '868. Rotación torácica en cuadrupedia', null),
  ('Wide Grip Lat Pulldown', 'Jalón al pecho agarre ancho', 'proet', 'JFLJq4Ah23A', '275. Jalón en polea alta agarre ancho prono', null),
  ('Wide Grip Pull Up', 'Dominada agarre ancho', 'proet', 'bIFpgQhoRpU', '222. Dominadas', 'agarre estándar'),
  ('90-90 Hip Switch', 'Cambio de cadera 90-90', 'central', 'afk4Q-5wPsA', '90/90 Switch Level 1', null),
  ('Angled Machine Leg Press', 'Prensa inclinada', 'central', 'IqjbBRNqJps', 'Leg Press', null),
  ('Band Anchored Single Arm Incline Curl', 'Curl inclinado a una mano con banda', 'central', 'PjBYgBrQCvY', 'Single Arm Banded Incline Bicep Curl', null),
  ('Band Deadlift', 'Peso muerto con banda', 'central', 'lHt4JIGQvNM', 'Banded Deadlift', null),
  ('Bar Hang', 'Colgarse de la barra', 'central', 'HSQlHf_9dYk', 'Active Bar Hang', null),
  ('Barbell Hip Thrust', 'Hip thrust con barra', 'central', 'OgDxMvKDiZY', 'Barbell Hip Thrust on Bench', null),
  ('Barbell Preacher Curl', 'Curl predicador con barra', 'central', 'cI9D3d9WmsM', 'Scott Narrow Grip Barbell Curl', null),
  ('Bench Hip Thrust', 'Hip thrust en banco', 'central', '_14XBc-ui-Y', 'Shoulder Elevated Hip Thrust', null),
  ('Bench Plank Single Arm Row', 'Remo a una mano en plancha sobre banco', 'central', 'MoUBn1NOMdo', 'Bench Plank Dumbbell Row', null),
  ('Bench Single Leg Hip Thrust', 'Hip thrust a una pierna en banco', 'central', 'gQQuBBkv2eE', 'Shoulders Elevated Single Leg Hip Bridge', null),
  ('Bodyweight Alternating Cossack Squat', 'Sentadilla cosaco alterna', 'central', 'sFnwqhbOMu0', 'Cossack Squat', null),
  ('Bodyweight Bent Knee Single Leg Calf Raise', 'Gemelo a una pierna con rodilla flexionada', 'central', '0F347Sbd458', 'Knee Over Toe Single Leg Calf Raise', null),
  ('Bodyweight Cossack Squat', 'Sentadilla cosaco', 'central', 'sFnwqhbOMu0', 'Cossack Squat', null),
  ('Bodyweight Kang Squat', 'Kang squat sin peso', 'central', 'C53oY2cF1wQ', 'Bodyweight Kang Squat', null),
  ('Bodyweight Single Leg Calf Raise', 'Gemelo a una pierna sin peso', 'central', 'uRyk_ZN2ya0', 'Single Leg Calf Raise', null),
  ('Bodyweight Walking Lunge', 'Zancada caminando sin peso', 'central', 'zsy1vvEPyik', 'Walking Lunge', null),
  ('Burpee Broad Jump', 'Burpee con salto horizontal', 'central', 'kkOSqoYOePg', 'Burpee Broad Jump', null),
  ('Cable Seated Close Grip Row', 'Remo sentado agarre cerrado en polea', 'central', 'o3vNBc-cYqM', 'Seated Rope Cable Row', 'con cuerda'),
  ('Cable Seated Close Row', 'Remo sentado agarre estrecho en polea', 'central', 'o3vNBc-cYqM', 'Seated Rope Cable Row', 'con cuerda'),
  ('Cable Seated Wide Grip Row', 'Remo sentado agarre ancho en polea', 'central', 'ohI-kn5lKfw', 'Wide Grip Seated Cable Row', null),
  ('Cable V-Bar Overhead Tricep Extension', 'Extensión de tríceps sobre la cabeza en polea', 'central', 'ws8zL-PAzOA', 'Seated Overhead Cable Tricep Extension', 'sentado'),
  ('Chest to wall handstand', 'Pino de cara a la pared', 'central', 'h2z0Y0NAetM', 'Wall Facing Handstand Hold', null),
  ('Dip', 'Fondos en paralelas', 'central', 'LQf-8PANawo', 'Pause Dip', 'con pausa abajo'),
  ('Dip Machine Straight Leg Raise', 'Elevación de piernas rectas en paralelas', 'central', 'YWu-RmqiJGI', 'Parallel Bar Straight Leg Raise', null),
  ('Dumbbell Clean to Press', 'Cargada y press con mancuernas', 'central', 'ZWAO47gSx3Q', 'Dumbbell Clean + Press', null),
  ('Dumbbell Curl to Shoulder Press', 'Curl y press de hombro con mancuernas', 'central', '0SVuq3mKBII', 'Standing Dumbbell Curl to Press', null),
  ('Dumbbell Front Squat', 'Sentadilla frontal con mancuernas', 'central', 'N6yAcqDbv7o', 'Heels Elevated Dumbbell Front Squat', 'con talones elevados'),
  ('Dumbbell Glute Bridge Chest Press', 'Press de pecho en puente de glúteo', 'central', 'dxxx-kB6tYM', 'Dumbbell Glute Bridge Floor Press', null),
  ('Dumbbell Hip Thrust', 'Hip thrust con mancuerna', 'central', 'Z4dYsS5RxME', 'Dumbbell Hip Thrust', null),
  ('Dumbbell Single Leg Calf Raise', 'Elevación de talón a una pierna con mancuerna', 'central', 'Bm4gNwc0YjY', 'Standing Single Leg Dumbbell Calf Raise', null),
  ('Dumbbell Standing Shoulder External Rotations', 'Rotación externa de hombro de pie', 'central', 'jocoGEpV3OY', 'Standing Dumbbell External Rotation', null),
  ('Dumbbell Sumo Deadlift', 'Peso muerto sumo con mancuerna', 'central', 'vK2b4IMom0E', 'Dumbbell Sumo Deadlift', null),
  ('Dumbbell Walking Lunge', 'Zancada caminando con mancuernas', 'central', 'JRbBMTBDV3g', 'Dumbbell Walking Lunge', null),
  ('Kettlebell Alternating Bent Over Row', 'Remo inclinado alterno con kettlebell', 'central', 'CIg3ERVCUmo', 'Alternating Kettlebell Bent Over Row', null),
  ('Kettlebell Lateral Step Up', 'Subida lateral al cajón con kettlebell', 'central', 'UHz8azpZg3Y', 'Banded Lateral Step Up', 'con banda, no con kettlebell'),
  ('Kettlebell Single Arm Clean and Press', 'Cargada y press a una mano con kettlebell', 'central', 'uNBizwaazCk', 'Single Arm Kettlebell Clean + Press', null),
  ('Kick Throughs', 'Patada cruzada desde cuadrupedia', 'central', 'GSOW4LFGHZQ', 'Beast to Alternating Leg Through', null),
  ('Landmine RDL', 'Peso muerto rumano con landmine', 'central', 'q77gVO6khx4', 'Landmine Romanian Deadlift', null),
  ('Lateral Shuttle Run', 'Desplazamiento lateral', 'central', 'dgZmOvgVJ6k', 'Lateral Shuffle', null),
  ('Leg Press Machine Calf Raise', 'Gemelo en prensa', 'central', 'c3S0UQdb_4M', 'Calf Raise on Leg Press', null),
  ('Machine Lying Leg Curl', 'Curl femoral tumbado en máquina', 'central', 'Zhnhz1r_u-Y', 'Prone Machine Hamstring Curl', null),
  ('Machine Seated Calf Raise', 'Gemelo sentado en máquina', 'central', 'Df7XjoeVrIA', 'Seated Calf Raise', null),
  ('Machine Seated Chest Press', 'Press de pecho sentado en máquina', 'central', 'QrnVDLSBdMo', 'Seated Chest Press', null),
  ('Machine Seated Hip Adduction', 'Aductores en máquina', 'central', 'CfTZfTILu3U', 'Seated Hip Adduction', null),
  ('Machine Seated Single Arm Neutral Grip Row', 'Remo a una mano en máquina agarre neutro', 'central', 'mstC6eav7YY', 'Single Arm Seated Row', null),
  ('Machine Standing Calf Raise', 'Gemelo de pie en máquina', 'central', 'ELCimJnir4M', 'Standing Calf Raise', null),
  ('Mini Band Alternating Hip Abduction', 'Abducción de cadera alterna con banda', 'central', 'DTI8bmilzjY', 'Standing Banded Abduction', null),
  ('Mini Band Wall Sit', 'Sentadilla isométrica en pared con banda', 'central', 'nq--l-LwzJg', 'Theraband Wall Sit', null),
  ('Mini Band Wall Sit with Abductions', 'Sentadilla isométrica en pared con abducción', 'central', '5yp2lV7v5jg', 'Wall Sit with Banded Abduction', null),
  ('Muscle Up', 'Muscle up', 'central', '21mAbr_o1p8', 'Muscle-Up', null),
  ('Plate Russian Twist', 'Giro ruso con disco', 'central', 'T6J5SKor1kY', 'Russian Twist', null),
  ('Plate Weighted Dip', 'Fondos lastrados', 'central', 'qEmCuapE3M0', 'Weighted Dip', null),
  ('Prayer Squat', 'Sentadilla profunda en oración', 'central', 'qjfNJWGOrhc', 'Deep Squat Hold', 'sentadilla profunda sostenida'),
  ('Prone Scorpion Alternating', 'Escorpión alterno boca abajo', 'central', 'DnAG3Nhpwvw', 'Scorpion', null),
  ('Quadruped Hip Circles', 'Círculos de cadera en cuadrupedia', 'central', 'FWi-Dz6nXzA', 'Quadruped Hip Circle', null),
  ('Quadruped Scapular Push Up', 'Flexión escapular en cuadrupedia', 'central', 'iYADQFlV_J8', 'Quadruped Scapular Push-Up', null),
  ('Scapular Pushups from Elbows', 'Flexión escapular desde codos', 'central', 'CoV-nz0_OYc', 'Scapular Push-Up on Elbows', null),
  ('Shuttle Run', 'Ida y vuelta corta', 'central', '7gxdoc3ACoU', 'Shuttle Run', null),
  ('Split Squat Pulse', 'Rebotes en zancada', 'central', '5QWHp-SR4yc', 'Pulse Prisoner Split Squat', 'manos en la nuca'),
  ('Squat Pulse', 'Rebotes en sentadilla', 'central', '9WK5YZnGFiI', 'Pulse Air Squat', null),
  ('SuperBand Deadlift', 'Peso muerto con superbanda', 'central', 'lHt4JIGQvNM', 'Banded Deadlift', null),
  ('SuperBand Dislocates', 'Dislocaciones de hombro con banda', 'central', 'ddGqVY8mdKE', 'Banded Dislocate', null),
  ('SuperBand Push Up', 'Flexión con superbanda', 'central', '62IYRzkncSo', 'Banded Push-Up', null);

-- Parte 1: llena los que no tienen video (ya no reemplaza).
update ejercicios e
   set video_fuente = 'youtube',
       video_ref    = v.ref,
       video_url    = 'https://www.youtube.com/watch?v=' || v.ref,
       video_inicio_seg = null,
       updated_at   = now()
  from _v v
 where (e.alias = v.alias or lower(e.nombre) = lower(v.nombre) or lower(e.nombre) = lower(v.alias))
   -- Solo llena ejercicios SIN video: nunca reemplaza uno que ya está puesto
   -- (puede haberlo elegido el coach en el CRM; ver migracion-videos-protegidos.sql).
   and coalesce(e.video_fuente, 'ninguno') = 'ninguno';

create temp table _g (nombre text, ref text, titulo text) on commit drop;
insert into _g (nombre, ref, titulo) values
  ('American Kettlebell Swing', 'ExboSxTGIEM', 'American Kettlebell Swing'),
  ('Anchored Reverse Crunch', '6MuGXqMr7I0', 'Anchored Reverse Crunch'),
  ('Arm Circle', 'hH9Y3UoapS8', 'Arm Circle'),
  ('Band Pull Through', 't9_DBEA7wsM', 'Band Pull Through'),
  ('Band-Assisted Glute-Ham Raise', 'TgeiXPgrx3Q', 'Band Assisted Glute Ham Raise'),
  ('Barbell Bench Press', 'iBdF89xBAxA', 'Barbell Bench Press'),
  ('Barbell Curtsy Lunge', '_SVhZ2EnA4Y', 'Barbell Curtsy Lunge'),
  ('Barbell Forward Lunge', 'k-E4onRcLkY', 'Barbell Forward Lunge'),
  ('Barbell Good Morning', '6_6S0O-TebU', 'Barbell Good Morning'),
  ('Barbell Overhead Squat', 'GsMNm9GGlE8', 'Barbell Overhead Squat'),
  ('Barbell Reverse Lunge', '8tNuP-1aQgg', 'Barbell Reverse Lunge'),
  ('Barbell Shrug', 'vVfClNqwHNA', 'Barbell Shrug'),
  ('Barbell Side Bend', 'LM4P1u5rcNg', 'Barbell Side Bend'),
  ('Barbell Step Up', '6gbWIjOa98Y', 'Barbell Step-Up'),
  ('Barbell Thruster', 'Pb_tUPpU-UA', 'Barbell Thruster'),
  ('Barbell Upright Row', 'Dux7qHaa_6w', 'Barbell Upright Row'),
  ('Bear Crawl', '63IBkFSR6PY', 'Bear Crawl'),
  ('Bird Dog', 'c0D51CL69-g', 'Bird-Dog'),
  ('Burpee to Target', 'FToMxgFU3v8', 'Burpee to Target'),
  ('Burpee to Tuck Jump', 'YSXSjeDzqxo', 'Burpee to Tuck Jump'),
  ('Butt Kickers', 'TMqkEDlSfzk', 'Butt Kickers'),
  ('Butterfly Pull Up', 'l8AFbHsA2xQ', 'Butterfly Pull-Up'),
  ('Clamshell', 'ShOPQe5FDXo', 'Clamshell'),
  ('Crab Walk', '4F0ay0dw_u0', 'Crab Walk'),
  ('Diamond Push Up', '6K5n0Lja4Uc', 'Diamond Push-Up'),
  ('Downward Dog', 'f0wDagdWGl8', 'Downward Dog'),
  ('Duck Walk', 'MftHDUQKWgw', 'Duck Walk'),
  ('Dumbbell 6-Way Shoulder Raise', 'mhZrfCIOlbM', 'Dumbbell 6 Way Shoulder Raise'),
  ('Dumbbell Forward Lunge', 'XNiKpU_WIpE', 'Dumbbell Forward Lunge'),
  ('Dumbbell Front Rack Walking Lunge', 'BWJ2wY9WfZU', 'Dumbbell Front Rack Walking Lunge'),
  ('Dumbbell Hang Power Clean', 'KLtDgLLlhCU', 'Dumbbell Hang Power Clean'),
  ('Dumbbell Pullover', 'UZ5K1-iTawA', 'Dumbbell Pullover'),
  ('Dumbbell Romanian Deadlift', 'mpg_qmBdmxc', 'Dumbbell Romanian Deadlift'),
  ('Dumbbell Split Squat', 'lza02GzUC9g', 'Dumbbell Split Squat'),
  ('Dumbbell Squat Clean', 'F15-8Q4BFYc', 'Dumbbell Squat Clean'),
  ('Dumbbell Squat Snatch', '0ztUyuqXOIg', 'Dumbbell Squat Snatch'),
  ('Dumbbell Thruster', 'OXn2s-6vCz0', 'Dumbbell Thruster'),
  ('Dumbbell Tricep Press', 'cLisDskxj0o', 'Dumbbell Tricep Press'),
  ('Dumbbell Turkish Get-Up', '-NTwcpD3ZBI', 'Dumbbell Turkish Get-Up'),
  ('Fire Hydrant', '9Urj31VEWUc', 'Fire Hydrant'),
  ('Forward Leg Swing', '25ET51u9oAc', 'Forward Leg Swing'),
  ('Forward Sled Drag', 'zcJrOB2DoFo', 'Forward Sled Drag'),
  ('GHD Back Extension', 'n5mZkx0daJc', 'GHD Back Extension'),
  ('GHD Hip Extension', 'dizQOJZwTDw', 'GHD Hip Extension'),
  ('GHD Sit-Up', 'A6LyWwuBHK4', 'GHD Sit-Up'),
  ('Glute-Ham Raise', 'KeHz_pcv84k', 'Glute Ham Raise'),
  ('Groiner', 'rkVadNuQ6_U', 'Groiner'),
  ('Hack Squat', '6teL-OyXuQs', 'Hack Squat'),
  ('Hanging Leg Raise', 'cqN6dmNSDcg', 'Hanging Leg Raise'),
  ('High Knees', 'gh4OeFlkJp8', 'High Knees'),
  ('Hip Airplane', 'gXdmb7yrvlU', 'Hip Airplane'),
  ('Hollow Body Hold', 'IEPL464V4_4', 'Hollow Body Hold'),
  ('Jump Rope', 'Fyc5QqXEEQE', 'Jump Rope'),
  ('Jumping Pull Up', 'JZ2AyFCr9hA', 'Jumping Pull up'),
  ('Kettlebell Floor Press', '1FiTH-pD6N0', 'Kettlebell Floor Press'),
  ('Kettlebell Glute Bridge', 'PPDwNOjqD1Q', 'Kettlebell Glute Bridge'),
  ('Kettlebell Snatch', 'QEEupLkPq_c', 'Kettlebell Snatch'),
  ('Kettlebell Sumo Deadlift', 'mHsrKouaXNU', 'Kettlebell Sumo Deadlift'),
  ('Kettlebell Upright Row', 'vBw5Nc0Z-kg', 'Kettlebell Upright Row'),
  ('Kipping Pull Up', 'hH1m5B90TBs', 'Kipping Pull-up'),
  ('Landmine Romanian Deadlift', 'q77gVO6khx4', 'Landmine Romanian Deadlift'),
  ('Landmine Split Squat', 'JrJOv5Exp94', 'Landmine Split Squat'),
  ('Landmine Split Squat', 'JrJOv5Exp94', 'Landmine Split Squat'),
  ('Lateral Leg Swing', 'NTN3e6m7uLg', 'Lateral Leg Swing'),
  ('Medicine Ball Push Up', 'qZ1L0jhSHRc', 'Medicine Ball Push-Up'),
  ('Medicine Ball Reverse Lunge', 'WgD6ATXH2eQ', 'Medicine Ball Reverse Lunge'),
  ('Medicine Ball Slam', 'G01nrJGJEc4', 'Medicine Ball Slam'),
  ('Prisoner Squat', '0wBCL7aZFEg', 'Prisoner Squat'),
  ('Reverse Crunch', 'DHxCkq4C20o', 'Reverse Crunch'),
  ('Reverse Lunge', 'gWLFloUhzKo', 'Reverse Lunge'),
  ('Ring L-Sit', 'bdjw4c6GWyo', 'Ring L-Sit'),
  ('Rope Climb', 'Se25OdqKdj8', 'Rope Climb'),
  ('Russian Twist', 'T6J5SKor1kY', 'Russian Twist'),
  ('Sandbag Bent Over Row', 'wD4GyreTQGc', 'Sandbag Bent Over Row'),
  ('Sandbag Front Squat', 'AtbmEGX7SFI', 'Sandbag Front Squat'),
  ('Scapular Pull Up', 'IVAZ4gnPcu4', 'Scapular Pull-Up'),
  ('Side Plank', 'S-6NhdAJ-Mc', 'Side Plank'),
  ('Single Arm Trap 3 Raise', 'bB2kbVG-s-g', 'Single Arm Trap 3 Raise'),
  ('Single Leg Glute Bridge', 'V1SRy5CcIbA', 'Single Leg Glute Bridge'),
  ('Ski Erg', 'O4AuL2FUMFM', 'Ski Erg'),
  ('Sled Push', '-eNCsR2FCW4', 'Sled Push'),
  ('Sled Row', 'TlT_5sl7H2A', 'Sled Row'),
  ('T Push Up', 'NW86tPhCWTc', 'T Push up'),
  ('T-Bar Row', 'AgxCPp37waQ', 'T Bar Row'),
  ('Trap 3 Raise', 'sh-tM_LmYhc', 'Trap-3 Raise'),
  ('Trap Bar Deadlift', 'lcaWjAw75vw', 'Trap Bar Deadlift'),
  ('V Up', 'B4_vvNzWaNQ', 'V-Up'),
  ('Wall Sit', 'DggraO72_hU', 'Wall Sit');

-- Parte 2: solo las fichas SIN video.
update ejercicios e
   set video_fuente = 'youtube',
       video_ref    = g.ref,
       video_url    = 'https://www.youtube.com/watch?v=' || g.ref,
       video_inicio_seg = null,
       updated_at   = now()
  from _g g
 where (lower(e.nombre) = lower(g.nombre) or lower(e.alias) = lower(g.nombre))
   and coalesce(e.video_fuente, 'ninguno') = 'ninguno'
   and e.video_ref is null;

-- Lo que quedó en tus rutinas: de qué canal, con nota y su enlace para verlo.
select v.nombre, case v.canal when 'proet' then 'PROET' else 'Central Athlete' end as canal,
       v.titulo as video, coalesce(v.nota, '') as nota,
       case when e.id is null then 'NO ESTÁ EN TU GALERÍA' else 'puesto' end as estado,
       'https://youtu.be/' || v.ref as ver
  from _v v
  left join lateral (
    select id from ejercicios x
     where x.alias = v.alias or lower(x.nombre) = lower(v.nombre) or lower(x.nombre) = lower(v.alias)
     limit 1) e on true
 order by (v.nota is null), v.canal desc, v.nombre;

commit;

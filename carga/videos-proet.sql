-- ════════════════════════════════════════════════════════════════════════
-- VIDEOS DE PROET EJERCICIO TERAPÉUTICO · 57 ejercicios
-- ════════════════════════════════════════════════════════════════════════
-- Dónde: Supabase del CRM → SQL Editor → pegar todo → Run.
--
-- Se revisaron los 976 videos del canal (youtube.com/@proetejercicioterapeutico5675)
-- contra tus ejercicios. Aquí van SOLO los que son el mismo ejercicio. A
-- diferencia de las otras tandas, ESTE SÍ REEMPLAZA el video que ya tenga el
-- ejercicio: así lo pediste («así ya los hayas puesto, sustituir»).
--
-- Los que llevan nota son casi iguales (otra posición o sin el material);
-- salen primero en la tabla del final. Si alguno no te convence, borra su
-- línea del «insert» antes de correrlo.
--
-- Movilidad: 10 de los 47 están en el canal. Los demás (cosaco, 90-90,
-- spiderman, paloma, dislocaciones con banda…) no los tiene; se quedan con el
-- video que ya tenían.
-- ════════════════════════════════════════════════════════════════════════
begin;

create temp table if not exists _proet (alias text, nombre text, ref text, titulo text, nota text);
truncate _proet;

insert into _proet (alias, nombre, ref, titulo, nota) values
  ('Band Internal Shoulder Rotation (90 degrees)', 'Rotación interna de hombro con banda (90°)', 'BNb1r36_sww', '978. Rotación interna de hombro con banda elástica', null),
  ('Cable External Rotation', 'Rotación externa en polea', 'm5t2BqBJW9w', '507. Rotación externa de hombro con cable-polea', null),
  ('Cat to Cow', 'Gato-camello', '-zfItYp9Mic', '1070. Yoga: Postura del gato y vaca', null),
  ('Child''s Pose', 'Postura del niño', '0yldJRcnJbk', '1067. Yoga: Postura del niño', null),
  ('Cobra', 'Cobra', 'aPCyseqROLU', '1066. Yoga: Postura de la Cobra', null),
  ('Dumbbell External Rotation on Side', 'Rotación externa tumbado de lado', 'f77gqIajNw4', '859. Rotación externa de hombros tumbado de lado', null),
  ('Kettlebell Windmill', 'Molino con kettlebell', 'FzzMq9XYO3s', '912. Kettlebell : El molino', null),
  ('Pronación muñeca con banda elástica', 'Pronación de muñeca con banda', 'SYx26hPIDXw', '794. Pronación de  muñeca con banda elástica', null),
  ('Table Top Half Arm Thoracic Rotation', 'Rotación torácica en cuadrupedia', 'iWxGRsCGURM', '868. Rotación torácica en cuadrupedia', null),
  ('Quadruped Scapular Push Up', 'Flexión escapular en cuadrupedia', 'zbVUBByJRqY', '903. Retracción y protracción escapular en posición de plancha', 'en plancha, no en cuadrupedia'),
  ('Band Anchored Single Arm Tricep Kickback', 'Patada de tríceps a una mano con banda', 'NStmfn7IhIw', '780. Patadas de triceps con banda elástica', null),
  ('Barbell Romanian Deadlift', 'Peso muerto rumano con barra', 'ueg9QHdnGbo', '391. Peso muerto rumano o con piernas estiradas', null),
  ('Bodyweight Deadbug', 'Dead bug', 'XkTtXA3-IqU', '825. Dead bug o Bicho muerto', null),
  ('Burpee', 'Burpee', 'cWEs3-ZEXVc', '600. Burpee', null),
  ('Cable Bicep Curl', 'Curl de bíceps en polea', '7jrHATAqHDA', '517. Curl de biceps con cable polea de pie', null),
  ('Cable Single Arm Bicep Curl', 'Curl de bíceps a una mano en polea', 'FBU0aOU0ang', '486. Curl de biceps a una mano con cable polea de pie', null),
  ('Cable Standing Crossover Chest Fly', 'Cruce de poleas de pie', 'GPvvixV6Q-g', '457. Cruces con poleas de pie', null),
  ('Cable Straight Bar Tricep Pushdown', 'Extensión de tríceps con barra recta en polea', 'k65GOhLjeco', '464. Extensión de tríceps con cable polea de pie', null),
  ('Cable V Bar Tricep Pushdown', 'Extensión de tríceps en polea alta', 'k65GOhLjeco', '464. Extensión de tríceps con cable polea de pie', null),
  ('Clapping Push Up', 'Flexión con palmada', 'jDrEYN-x_pA', '539. Flexiones de brazos con palmada', null),
  ('Dumbbell Alternating Bicep Curl', 'Curl de bíceps alterno', 'MHF9VflB7MI', '204. Curl de biceps alterno de pie con mancuernas y giro', null),
  ('Dumbbell Alternating Hammer Curl', 'Curl martillo alterno', 'uL_8n0_QmSQ', '208. Curl de biceps alterno con mancuernas de pie agarre tipo martillo', null),
  ('Dumbbell Bench Press', 'Press banca con mancuernas', '5mSgcopzGo4', '199. Press pectoral con mancuernas', null),
  ('Dumbbell Bicep Curl', 'Curl de bíceps con mancuernas', '0j6rItm15YI', '209. Curl de biceps con mancuernas de pie y giro', 'con giro de muñeca'),
  ('Dumbbell Bulgarian Split Squat', 'Sentadilla búlgara con mancuernas', 'vFC4azOUdW8', '27. Zancada con la otra pierna elevada o sentadilla bulgara', 'sin mancuernas en el video'),
  ('Dumbbell Calf Raise', 'Gemelo de pie con mancuerna', '1BL4681pIz4', '697. Elevación de gemelos de pie con mancuernas', null),
  ('Dumbbell Deadlift', 'Peso muerto con mancuernas', 'FcKJ29VgTd8', '577. Peso muerto con mancuernas', null),
  ('Glute Bridge', 'Puente de glúteo', 'wACebloZ1Nk', '1047. Puente de gluteos', null),
  ('Dumbbell Hammer Curl', 'Curl martillo con mancuernas', 'qyEPpBgQ7Gc', '207. Curl de biceps con mancuernas de pie agarre tipo martillo', null),
  ('Dumbbell Incline Alternating Curl', 'Curl inclinado alterno', 'rnAYOdcn83s', '829. Curl de biceps alterno con mancuernas en banco inclinado', null),
  ('Dumbbell Incline Bicep Curl', 'Curl inclinado con mancuernas', 'eSADGjh6Wf8', '383. Curl de biceps con mancuernas en banco inclinado', null),
  ('Dumbbell Incline Bench Press', 'Press inclinado con mancuernas', 'KLeK1101U1w', '343. Press pectoral con mancuernas en banco inclinado', null),
  ('Dumbbell Incline Bench High Row', 'Remo alto en banco inclinado', '736dt_Cx2Aw', '834 Remo con mancuernas en banco inclinado', null),
  ('Dumbbell Lateral Raise', 'Elevación lateral con mancuernas', 'Gqd7wZANxVo', '443. Elevación lateral de hombros con mancuernas de pie', null),
  ('Dumbbell Seated Arnold Press', 'Press Arnold sentado', 'gta2WJkPdhE', '1094. Press Arnold', null),
  ('Dumbbell Seated Front Raise', 'Elevación frontal sentado', '8w-SHN1eKg0', '164. Elevación frontal de hombros con mancuernas sentado agarre en pronación', null),
  ('Dumbbell Seated Overhead Tricep Extension', 'Extensión de tríceps sobre la cabeza sentado', 'dxLlYmNOr-E', '147. Extensión de tríceps a dos manos con mancuerna sentado', null),
  ('Dumbbell Seated Shoulder Press', 'Press de hombro sentado con mancuernas', '96xeqjYXkT4', '159. Press de hombros con mancuernas sentado', null),
  ('Dumbbell Shrug', 'Encogimiento de trapecio con mancuernas', '9A_kfZ8kzJc', '654. Encogimiento de hombros con mancuernas', null),
  ('Dumbbell Single Arm Row', 'Remo a una mano con mancuerna', 'P4_xxq_Im_w', '151. Remo con mancuerna con rodilla apoyada', null),
  ('Kettlebell Alternating Press', 'Press alterno con kettlebell', 'pY0MGs4M0fQ', '915. Kettlebell Press de hombros', 'no alterno en el video'),
  ('Lying Hip Abductions', 'Abducción de cadera tumbado', 'uqJlSyPIEoA', '1048. Abducción cadera tumbado', null),
  ('Mini Band Side Lying Hip Abduction', 'Abducción de cadera tumbado con banda', '2oV_JTdrMak', '1061. Abductores con miniband tumbado', null),
  ('Machine Seated Leg Extension', 'Extensión de cuádriceps en máquina', 'WAMwZLxhGd4', '214. Extension de piernas en maquina', null),
  ('Machine Seated Parallel Grip Shoulder Press', 'Press de hombro agarre paralelo en máquina', 'p5v_REt274k', '572. Press frontal de hombros en máquina sentado y agarre neutro', null),
  ('Machine Lying Leg Curl', 'Curl femoral tumbado en máquina', 'Bb9N_wOt7Wg', '253. Curl femoral con maquina declinada', 'máquina declinada'),
  ('Mountain Climber', 'Escalador', 'L3i_8RTKmtc', '736. Mountain climber', null),
  ('Pallof Press', 'Press Pallof', 'CxjQR4sbn5s', '1091. Press Pallof', null),
  ('Pull Up', 'Dominada', 'bIFpgQhoRpU', '222. Dominadas', null),
  ('Push Up', 'Flexión de brazos', 'NiElkGUcAPY', '152. Flexiones de brazos', null),
  ('Wide Grip Lat Pulldown', 'Jalón al pecho agarre ancho', 'JFLJq4Ah23A', '275. Jalón en polea alta agarre ancho prono', null),
  ('Superman Around the World', 'Superman con círculos de brazos', 'sWZMzeppZVI', '965. Superman alterno', 'superman alterno, sin el balón'),
  ('Reverse nordic curl band assisted', 'Nórdico inverso asistido con banda', 'DUIJAhEaMm4', '1100. Curl Nórdico Invertido', 'sin la banda'),
  ('Seated Leg Press', 'Prensa sentado', 'Ys3DUOTOuSU', '256. Prensa horizontal en maquina', null),
  ('Body Weight Calf Raise', 'Elevación de talones sin carga', '3DW2rm90F6A', '768. Elevación de gemelos', null),
  ('SuperBand Anchored Tricep Pushdown', 'Extensión de tríceps con banda anclada', 'iWHdoUZv-_o', '976. Extensión de triceps con goma elástica', null),
  ('Plank To Push Up', 'De plancha a flexión', 'N-QuHdr0yHM', '717. Plancha y flexión de brazos', null);

update ejercicios e
   set video_fuente = 'youtube',
       video_ref    = p.ref,
       video_url    = 'https://www.youtube.com/watch?v=' || p.ref,
       video_inicio_seg = null,
       updated_at   = now()
  from _proet p
 where (e.alias = p.alias or lower(e.nombre) = lower(p.nombre) or lower(e.nombre) = lower(p.alias))
   and e.video_ref is distinct from p.ref;

-- Lo que quedó, con su enlace para verlo.
select p.nombre, p.titulo as video_proet, coalesce(p.nota, '') as nota,
       case when e.id is null then 'NO ESTÁ EN TU GALERÍA' else 'puesto' end as estado,
       'https://youtu.be/' || p.ref as ver
  from _proet p
  left join lateral (
    select id from ejercicios x
     where x.alias = p.alias or lower(x.nombre) = lower(p.nombre) or lower(x.nombre) = lower(p.alias)
     limit 1) e on true
 order by (p.nota is null), p.nombre;

drop table _proet;
commit;

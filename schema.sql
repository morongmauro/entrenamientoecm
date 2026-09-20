-- ================================================================
-- ESQUEMA SUPABASE · MÓDULO DE ENTRENAMIENTO · EntrenaConMétodo
--
-- ⚠ ESTE ARCHIVO SE PEGA EN EL SUPABASE DEL *CRM*, no en uno nuevo.
--    Supabase (proyecto del CRM) → SQL Editor → New query → Run.
--
-- Por qué en el CRM y no en una base aparte: el CRM ya es la fuente de
-- verdad de `clientes` (ver api/authorize.js del mealtracker). Las rutinas
-- las creas tú desde el CRM, así que viven donde ya estás autenticado —
-- sin puentes, sin sincronizar dos bases, y la adherencia de entreno
-- (`seguimientos`) se puede calcular sola desde las sesiones reales.
--
-- La app cliente NO habla directo con estas tablas: lee y escribe por
-- endpoints serverless con la service_role key, filtrando por cliente_id
-- (mismo patrón que /api/adherence.js y /api/sync.js del mealtracker).
-- Por eso las políticas RLS de abajo son para TU sesión de coach.
--
-- Es idempotente: se puede volver a correr sin romper nada.
-- ================================================================

-- ================================================================
-- 1. VOCABULARIO DE MÚSCULOS
-- ================================================================
-- Catálogo pequeño y cerrado. El `slug` es EL CONTRATO con el dibujo del
-- cuerpo: cada <path id="..."> del SVG anatómico (frente y espalda) debe
-- llamarse igual que un slug de aquí. Así, marcar el músculo trabajado es
-- pintar por id — sin tabla de traducción ni ifs en el código.
-- `cara` dice en cuál de los dos dibujos aparece ('ambas' = en los dos).

create table if not exists musculos (
  slug text primary key,
  nombre text not null,              -- etiqueta visible: "Bíceps braquial"
  corto text not null,               -- etiqueta compacta para chips: "Bíceps"
  grupo text not null,               -- pecho|espalda|hombro|brazo|pierna|gluteo|core|otro
  cara text not null default 'frente', -- frente | espalda | ambas
  orden int default 100
);

insert into musculos (slug, nombre, corto, grupo, cara, orden) values
  ('pectoral_mayor',    'Pectoral mayor',            'Pecho',        'pecho',   'frente',  10),
  ('pectoral_superior', 'Pectoral superior (clavicular)', 'Pecho sup.', 'pecho', 'frente',  11),
  ('deltoide_anterior', 'Deltoide anterior',         'Deltoide ant.','hombro',  'frente',  20),
  ('deltoide_lateral',  'Deltoide lateral',          'Deltoide lat.','hombro',  'ambas',   21),
  ('deltoide_posterior','Deltoide posterior',        'Deltoide post.','hombro', 'espalda', 22),
  ('biceps',            'Bíceps braquial',           'Bíceps',       'brazo',   'frente',  30),
  ('braquial',          'Braquial anterior',         'Braquial',     'brazo',   'frente',  31),
  ('triceps',           'Tríceps braquial',          'Tríceps',      'brazo',   'espalda', 32),
  ('antebrazo',         'Antebrazo',                 'Antebrazo',    'brazo',   'ambas',   33),
  ('dorsal_ancho',      'Dorsal ancho',              'Dorsales',     'espalda', 'espalda', 40),
  ('trapecio_superior', 'Trapecio superior',         'Trapecio sup.','espalda', 'ambas',   41),
  ('trapecio_medio',    'Trapecio medio',            'Trapecio medio','espalda','espalda', 42),
  ('trapecio_inferior', 'Trapecio inferior',         'Trapecio inf.','espalda', 'espalda', 43),
  ('romboides',         'Romboides',                 'Romboides',    'espalda', 'espalda', 44),
  ('redondo_mayor',     'Redondo mayor',             'Redondo',      'espalda', 'espalda', 45),
  ('erectores',         'Erectores espinales',       'Lumbares',     'espalda', 'espalda', 46),
  ('recto_abdominal',   'Recto abdominal',           'Abdomen',      'core',    'frente',  50),
  ('oblicuos',          'Oblicuos',                  'Oblicuos',     'core',    'frente',  51),
  ('transverso',        'Transverso abdominal',      'Transverso',   'core',    'frente',  52),
  ('cuadriceps',        'Cuádriceps',                'Cuádriceps',   'pierna',  'frente',  60),
  ('isquiotibiales',    'Isquiotibiales',            'Isquios',      'pierna',  'espalda', 61),
  ('gluteo_mayor',      'Glúteo mayor',              'Glúteo',       'gluteo',  'espalda', 62),
  ('gluteo_medio',      'Glúteo medio',              'Glúteo medio', 'gluteo',  'espalda', 63),
  ('aductores',         'Aductores',                 'Aductores',    'pierna',  'frente',  64),
  ('abductores',        'Abductores',                'Abductores',   'pierna',  'ambas',   65),
  ('gemelos',           'Gemelos / sóleo',           'Gemelos',      'pierna',  'espalda', 66),
  ('tibial_anterior',   'Tibial anterior',           'Tibial',       'pierna',  'frente',  67),
  ('psoas',             'Psoas ilíaco',              'Psoas',        'core',    'frente',  68),
  ('manguito_rotador',  'Manguito rotador',          'Manguito',     'hombro',  'espalda', 69),
  ('cuerpo_completo',   'Cuerpo completo',           'Full body',    'otro',    'ambas',   90)
on conflict (slug) do nothing;

-- ================================================================
-- 2. BIBLIOTECA DE EJERCICIOS  (la "galería" del constructor)
-- ================================================================
-- Una sola biblioteca tuya, reutilizable en todas las rutinas de todos los
-- clientes. Nunca se duplica un ejercicio al copiar una rutina: las rutinas
-- APUNTAN aquí. Corregir un video o una descripción arregla, de una vez,
-- todas las rutinas que lo usan.
--
-- Los campos de clasificación son los filtros de la galería. Se guardan
-- como text/text[] y no como enums a propósito: agregar una categoría nueva
-- no debe exigir una migración. Los valores esperados van en cada comentario
-- y se validan en la UI.

create table if not exists ejercicios (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users on delete cascade,

  nombre text not null,
  alias text,                        -- otro nombre por el que lo buscas ("peso muerto rumano" / "RDL")

  -- ---- Lo que VE EL CLIENTE ----
  descripcion text,                  -- cómo se ejecuta, en lenguaje de cliente
  claves_tecnicas text[] default '{}', -- 2-4 bullets cortos ("rodilla en línea con el pie")

  -- ---- Lo que ves SOLO TÚ en el constructor ----
  notas_coach text,                  -- criterios de progresión, cuándo NO usarlo, etc.
                                     -- NUNCA se envía a la app del cliente.

  -- ---- Clasificación / filtros de la galería ----
  patron text,                       -- push | pull | rodilla | cadera | core | carry | locomocion
  segmento text,                     -- tren_superior | tren_inferior | core | full_body
  tipo text default 'fuerza',        -- fuerza | hipertrofia | potencia | movilidad | pliometrico
                                     -- agilidad | estiramiento_pasivo | estiramiento_activo
                                     -- cardio | core | rehabilitacion | calentamiento
  musculos_primarios text[] default '{}',   -- slugs de `musculos` → pintan FUERTE en el dibujo
  musculos_secundarios text[] default '{}', -- slugs de `musculos` → pintan SUAVE
  equipo text[] default '{}',        -- barra | mancuerna | kettlebell | polea | maquina
                                     -- banda | trx | balon | peso_corporal | banco | caja
  lugar text[] default '{}',         -- gym | casa | aire_libre  (cruza con clientes.lugar_entreno)
  nivel text default 'intermedio',   -- principiante | intermedio | avanzado
  unilateral boolean default false,  -- si es a un lado: la UI pide reps por lado
  tags text[] default '{}',          -- etiquetas libres, para lo que no cabe arriba

  -- ---- Video: SUBIDO o LINK DE YOUTUBE (los dos caminos, ver §2.1) ----
  video_fuente text default 'ninguno', -- youtube | vimeo | archivo | ninguno
  video_url text,                    -- link original pegado (youtube/vimeo)
  video_ref text,                    -- id extraído del link (p.ej. 'dQw4w9WgXcQ') para
                                     -- construir el embed sin re-parsear en cada render
  video_path text,                   -- ruta en Supabase Storage si TÚ subiste el archivo
  video_inicio_seg int,              -- opcional: arrancar el video en el segundo N
  poster_url text,                   -- miniatura para la galería (si no hay, se usa la de YouTube)

  archivado boolean default false,   -- se oculta de la galería sin romper rutinas viejas
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ---- §2.1 · Cómo conviven los dos tipos de video --------------------------
-- video_fuente = 'youtube'  → guarda video_url + video_ref. La app cliente
--   monta un <iframe> de youtube-nocookie. Costo cero para ti, y es lo que
--   conviene por defecto.
-- video_fuente = 'archivo'  → guarda video_path apuntando al bucket
--   'ejercicios' de Supabase Storage. Úsalo para lo que grabas tú y no
--   quieres público en YouTube. Ojo: el egress de Storage se paga; para
--   demos cortas sube mp4 de pocos segundos, no clases completas.
-- video_fuente = 'ninguno'  → la ficha se muestra sin reproductor. Válido:
--   un estiramiento puede no necesitarlo.
--
-- El bucket hay que crearlo UNA vez a mano (Storage → New bucket):
--   nombre: ejercicios · público: NO. La app lo sirve por URL firmada desde
--   el endpoint serverless, así el material no queda indexable.
-- ---------------------------------------------------------------------------

-- Búsqueda por texto en la galería (nombre + alias + descripción)
create index if not exists ejercicios_busqueda_idx on ejercicios
  using gin (to_tsvector('spanish', coalesce(nombre,'') || ' ' || coalesce(alias,'') || ' ' || coalesce(descripcion,'')));
-- Filtros por array (músculo, equipo, tags): GIN los resuelve sin escanear todo
create index if not exists ejercicios_musculos_idx on ejercicios using gin (musculos_primarios);
create index if not exists ejercicios_equipo_idx   on ejercicios using gin (equipo);
create index if not exists ejercicios_tags_idx     on ejercicios using gin (tags);
create index if not exists ejercicios_filtros_idx  on ejercicios (user_id, archivado, tipo, segmento, patron);

-- ================================================================
-- 3. FASES  (bloques de X semanas para un cliente)
-- ================================================================
-- Una fase es "este bloque dura X semanas y se entrena estos días".
-- De aquí sale el CALENDARIO del cliente: fecha_inicio + semanas +
-- dias_semana genera las sesiones esperadas, sin tener que crear filas por
-- adelantado para cada día.
--
-- Una fase con cliente_id NULL es una PLANTILLA de fase: un mesociclo tuyo
-- que puedes clonar a cualquier cliente (ver copiar_fase más abajo).

create table if not exists fases (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  cliente_id uuid references clientes(id) on delete cascade,  -- NULL = plantilla de biblioteca

  nombre text not null,              -- "Fase 1 · Adaptación anatómica"
  objetivo text,                     -- qué se busca en este bloque
  notas_coach text,

  semanas int default 4,             -- ← "esta rutina dura X semanas"
  fecha_inicio date,
  dias_semana text[] default '{}',   -- ['L','X','V'] — mismo código que clientes.dias_entreno
  orden int default 1,               -- Fase 1, Fase 2… dentro del proceso del cliente
  estado text default 'borrador',    -- borrador | activa | finalizada | archivada

  -- ---- Visibilidad para el cliente (ver también carga/migracion-visibilidad.sql) ----
  -- `estado` es el estado de TRABAJO de la fase; esto es otra cosa: si el
  -- cliente la ve o no en su app. Son decisiones distintas — puedes tener una
  -- fase activa que aún estás afinando y no quieres que vea, y una finalizada
  -- que sigue visible. Arranca en false: nada se publica solo.
  visible_cliente boolean not null default false,
  publicada_en  timestamptz,                                  -- cuándo se envió la 1ª vez
  publicada_por uuid references auth.users on delete set null,

  origen_fase_id uuid references fases(id) on delete set null, -- de dónde se copió
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index if not exists fases_cliente_idx on fases (user_id, cliente_id, orden);

-- Para bases que YA tenían estas tablas de antes: `create table if not
-- exists` no toca una tabla existente, así que las columnas de visibilidad
-- no llegarían nunca y el índice de abajo fallaría con «column
-- visible_cliente does not exist». Esto las añade cuando faltan y no hace
-- nada cuando ya están. (Es lo mismo que hace carga/migracion-visibilidad.sql;
-- se repite aquí para que este archivo funcione solo, en cualquier orden.)
alter table fases
  add column if not exists visible_cliente boolean not null default false,
  add column if not exists publicada_en    timestamptz,
  add column if not exists publicada_por   uuid references auth.users on delete set null;

create index if not exists fases_visibles_idx on fases (cliente_id, visible_cliente);

-- fecha_fin calculada: no se guarda para que no se desincronice al mover
-- fecha_inicio o cambiar la duración.
create or replace function fase_fecha_fin(f fases) returns date
  language sql immutable as $$
    select case when f.fecha_inicio is null then null
                else f.fecha_inicio + (coalesce(f.semanas,0) * 7 - 1) end;
  $$;

-- ================================================================
-- 4. RUTINAS  (los "días" de entreno)
-- ================================================================
-- cliente_id NULL y fase_id NULL  → PLANTILLA de biblioteca ("Full body A").
-- Con fase_id                     → rutina real dentro de la fase de un cliente.
-- Siempre se copia, nunca se comparte: editar la rutina de Juan jamás debe
-- tocar la de María. La trazabilidad la da origen_rutina_id.

create table if not exists rutinas (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  cliente_id uuid references clientes(id) on delete cascade,
  fase_id uuid references fases(id) on delete cascade,

  nombre text not null,              -- "Día A · Empuje"
  descripcion text,                  -- lo lee el cliente al abrir la rutina
  notas_coach text,                  -- solo tú

  dia_orden int default 1,           -- Día 1, 2, 3… dentro de la fase
  dia_semana text,                   -- 'L'…'D' — si la fijas a un día concreto; NULL = libre
  duracion_estimada_min int,
  tipo_sesion text default 'fuerza', -- fuerza | cardio | movilidad | mixta | descanso_activo

  -- NULL = hereda la visibilidad de su fase (lo normal). Ponerlo a false
  -- oculta SOLO esta rutina dentro de una fase ya enviada (el día que aún
  -- estás armando); true la muestra aunque la fase no esté enviada.
  visible_cliente boolean,

  es_plantilla boolean generated always as (cliente_id is null and fase_id is null) stored,
  origen_rutina_id uuid references rutinas(id) on delete set null,
  archivada boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Misma red de seguridad que en `fases`, para bases que ya existían.
alter table rutinas add column if not exists visible_cliente boolean;

create index if not exists rutinas_fase_idx      on rutinas (fase_id, dia_orden);
create index if not exists rutinas_plantilla_idx on rutinas (user_id, es_plantilla, archivada);

-- ---- Bloques: superseries y circuitos ----
-- Un bloque agrupa ejercicios que se ejecutan juntos. Una rutina simple
-- puede no tener ninguno (los ejercicios van sueltos, bloque_id NULL).
create table if not exists rutina_bloques (
  id uuid primary key default gen_random_uuid(),
  rutina_id uuid not null references rutinas(id) on delete cascade,
  nombre text,                       -- "A", "Circuito final"
  tipo text default 'normal',        -- normal | superserie | circuito | emom | amrap
  vueltas int,                       -- para circuito/emom
  descanso_seg int,                  -- descanso ENTRE vueltas del bloque
  orden int default 1,
  notas text
);

create index if not exists rutina_bloques_idx on rutina_bloques (rutina_id, orden);

-- ---- Los ejercicios dentro de la rutina (lo que arma el constructor) ----
create table if not exists rutina_ejercicios (
  id uuid primary key default gen_random_uuid(),
  rutina_id uuid not null references rutinas(id) on delete cascade,
  bloque_id uuid references rutina_bloques(id) on delete set null,
  ejercicio_id uuid not null references ejercicios(id) on delete restrict,
  orden int default 1,

  -- Prescripción. `reps` y `peso_objetivo` son TEXTO a propósito: "8-10",
  -- "AMRAP", "30s por lado", "al fallo", "70% RM" son todas respuestas
  -- legítimas que un número no admite.
  series int default 3,
  reps text default '10',
  peso_objetivo text,
  rir int,                           -- reps en reserva (0-5)
  tempo text,                        -- "3-1-1-0"
  descanso_seg int default 90,
  notas text,                        -- indicación para el cliente en ESTA rutina
  notas_coach text,                  -- solo tú

  created_at timestamptz default now()
);

create index if not exists rutina_ejercicios_idx on rutina_ejercicios (rutina_id, orden);

-- ================================================================
-- 5. EJECUCIÓN  (lo que el cliente marca en la app)
-- ================================================================
create table if not exists sesiones (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users on delete cascade, -- el coach dueño
  cliente_id uuid not null references clientes(id) on delete cascade,
  rutina_id uuid references rutinas(id) on delete set null,
  fase_id uuid references fases(id) on delete set null,

  fecha date not null default current_date,
  semana_num int,                    -- semana 1..N dentro de la fase
  semana_iso text,                   -- YYYY-Www — cruza con `seguimientos` del CRM

  estado text default 'en_curso',    -- en_curso | completada | saltada
  iniciada_en timestamptz default now(),
  finalizada_en timestamptz,
  duracion_seg int,

  rpe int,                           -- esfuerzo percibido 1-10, lo pone el cliente
  notas_cliente text,                -- "me molestó el hombro"
  vista_por_coach boolean default false,

  created_at timestamptz default now()
);

-- Una sola sesión por cliente/rutina/fecha: si el cliente sale de la app y
-- vuelve, retoma la misma en vez de abrir una duplicada.
create unique index if not exists sesiones_unica_idx
  on sesiones (cliente_id, rutina_id, fecha)
  where rutina_id is not null;
create index if not exists sesiones_cliente_idx on sesiones (cliente_id, fecha desc);

-- ---- Series marcadas ----
-- ejercicio_id se guarda DUPLICADO (además de rutina_ejercicio_id) a
-- propósito: el historial "cuánto levanté en press banca" debe sobrevivir a
-- que borres o edites la rutina que lo originó.
create table if not exists series_log (
  id uuid primary key default gen_random_uuid(),
  sesion_id uuid not null references sesiones(id) on delete cascade,
  rutina_ejercicio_id uuid references rutina_ejercicios(id) on delete set null,
  ejercicio_id uuid not null references ejercicios(id) on delete restrict,

  serie_num int not null,
  reps int,
  peso numeric,
  unidad text default 'kg',          -- kg | lb
  lado text,                         -- izq | der | NULL (para unilaterales)
  rir int,
  completada boolean default true,
  notas text,
  created_at timestamptz default now()
);

create index if not exists series_log_sesion_idx    on series_log (sesion_id);
-- Índice del "récord personal": historial de UN ejercicio de UN cliente
create index if not exists series_log_progreso_idx  on series_log (ejercicio_id, created_at desc);

-- ================================================================
-- 6. COPIAR Y PEGAR  (cliente→cliente, fase→fase, plantilla→cliente)
-- ================================================================
-- Estas funciones son el corazón de "importar rutinas". Van con
-- SECURITY INVOKER (el default): corren con TUS permisos, así RLS sigue
-- mandando y nunca podrías copiar la rutina de otra cuenta.

-- ---- 6.1 · Copiar UNA rutina ----
-- destino_fase_id NULL → la copia queda como PLANTILLA de biblioteca.
-- Con destino_fase_id  → la copia entra en la fase de ese cliente.
-- Devuelve el id de la rutina nueva.
create or replace function copiar_rutina(
  p_rutina_id uuid,
  p_destino_fase_id uuid default null,
  p_nombre_nuevo text default null
) returns uuid
language plpgsql
as $$
declare
  v_nueva_id uuid;
  v_cliente_id uuid;
  v_bloque record;
  v_mapa_bloques jsonb := '{}'::jsonb;
begin
  -- El cliente destino se deduce de la fase; si no hay fase, es plantilla.
  select cliente_id into v_cliente_id from fases where id = p_destino_fase_id;

  insert into rutinas (
    user_id, cliente_id, fase_id, nombre, descripcion, notas_coach,
    dia_orden, dia_semana, duracion_estimada_min, tipo_sesion, origen_rutina_id
  )
  select
    user_id, v_cliente_id, p_destino_fase_id,
    coalesce(p_nombre_nuevo, nombre), descripcion, notas_coach,
    dia_orden, dia_semana, duracion_estimada_min, tipo_sesion, id
  from rutinas where id = p_rutina_id
  returning id into v_nueva_id;

  if v_nueva_id is null then
    raise exception 'Rutina % no encontrada o sin permiso', p_rutina_id;
  end if;

  -- Bloques primero, guardando viejo_id → nuevo_id para reenganchar
  -- los ejercicios a SU bloque y no a otro.
  for v_bloque in
    select * from rutina_bloques where rutina_id = p_rutina_id order by orden
  loop
    declare v_bloque_nuevo uuid;
    begin
      insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, orden, notas)
      values (v_nueva_id, v_bloque.nombre, v_bloque.tipo, v_bloque.vueltas,
              v_bloque.descanso_seg, v_bloque.orden, v_bloque.notas)
      returning id into v_bloque_nuevo;
      v_mapa_bloques := v_mapa_bloques || jsonb_build_object(v_bloque.id::text, v_bloque_nuevo::text);
    end;
  end loop;

  insert into rutina_ejercicios (
    rutina_id, bloque_id, ejercicio_id, orden, series, reps, peso_objetivo,
    rir, tempo, descanso_seg, notas, notas_coach
  )
  select
    v_nueva_id,
    case when re.bloque_id is null then null
         else (v_mapa_bloques ->> re.bloque_id::text)::uuid end,
    re.ejercicio_id, re.orden, re.series, re.reps, re.peso_objetivo,
    re.rir, re.tempo, re.descanso_seg, re.notas, re.notas_coach
  from rutina_ejercicios re
  where re.rutina_id = p_rutina_id
  order by re.orden;

  return v_nueva_id;
end;
$$;

-- ---- 6.2 · Copiar una FASE COMPLETA a otro cliente ----
-- Este es el "importar de un cliente a otro": clona la fase y todas sus
-- rutinas. p_cliente_destino NULL → la deja como plantilla de fase.
-- No copia el historial: las sesiones y series son del cliente original.
create or replace function copiar_fase(
  p_fase_id uuid,
  p_cliente_destino uuid default null,
  p_fecha_inicio date default null,
  p_nombre_nuevo text default null
) returns uuid
language plpgsql
as $$
declare
  v_nueva_id uuid;
  v_rutina record;
  v_orden int;
begin
  -- La fase nueva se pone al final del proceso del cliente destino.
  select coalesce(max(orden), 0) + 1 into v_orden
  from fases where cliente_id is not distinct from p_cliente_destino;

  insert into fases (
    user_id, cliente_id, nombre, objetivo, notas_coach, semanas,
    fecha_inicio, dias_semana, orden, estado, origen_fase_id
  )
  select
    user_id, p_cliente_destino, coalesce(p_nombre_nuevo, nombre), objetivo,
    notas_coach, semanas, coalesce(p_fecha_inicio, fecha_inicio), dias_semana,
    v_orden, 'borrador', id
  from fases where id = p_fase_id
  returning id into v_nueva_id;

  if v_nueva_id is null then
    raise exception 'Fase % no encontrada o sin permiso', p_fase_id;
  end if;

  for v_rutina in
    select id from rutinas where fase_id = p_fase_id and not archivada order by dia_orden
  loop
    perform copiar_rutina(v_rutina.id, v_nueva_id, null);
  end loop;

  return v_nueva_id;
end;
$$;

-- ---- 6.3 · Duplicar una rutina dentro de la MISMA fase ----
-- El "copiar y pegar" de un día para editarlo como variante.
create or replace function duplicar_rutina(p_rutina_id uuid) returns uuid
language plpgsql
as $$
declare
  v_fase uuid; v_nombre text; v_nueva uuid; v_orden int;
begin
  select fase_id, nombre into v_fase, v_nombre from rutinas where id = p_rutina_id;
  v_nueva := copiar_rutina(p_rutina_id, v_fase, v_nombre || ' (copia)');
  select coalesce(max(dia_orden), 0) + 1 into v_orden
    from rutinas where fase_id is not distinct from v_fase;
  update rutinas set dia_orden = v_orden where id = v_nueva;
  return v_nueva;
end;
$$;

-- ================================================================
-- 7. RLS
-- ================================================================
-- Encendida desde el día uno. La app cliente entra por la service_role key
-- (que ignora RLS a propósito, igual que /api/sync.js del mealtracker) y
-- filtra por cliente_id en el endpoint. Esto protege TU sesión de coach.

alter table musculos          enable row level security;
alter table ejercicios        enable row level security;
alter table fases             enable row level security;
alter table rutinas           enable row level security;
alter table rutina_bloques    enable row level security;
alter table rutina_ejercicios enable row level security;
alter table sesiones          enable row level security;
alter table series_log        enable row level security;

-- El catálogo de músculos es vocabulario compartido: lectura para todos.
drop policy if exists musculos_lectura on musculos;
create policy musculos_lectura on musculos for select using (true);

-- Tablas con user_id propio: cada coach ve y toca solo lo suyo.
do $$
declare t text;
begin
  foreach t in array array['ejercicios','fases','rutinas','sesiones'] loop
    execute format('drop policy if exists %I_propias on %I', t, t);
    execute format(
      'create policy %I_propias on %I for all using (user_id = auth.uid()) with check (user_id = auth.uid())',
      t, t);
  end loop;
end $$;

-- Tablas hijas: heredan el permiso de su padre.
drop policy if exists rutina_bloques_propias on rutina_bloques;
create policy rutina_bloques_propias on rutina_bloques for all
  using (exists (select 1 from rutinas r where r.id = rutina_id and r.user_id = auth.uid()))
  with check (exists (select 1 from rutinas r where r.id = rutina_id and r.user_id = auth.uid()));

drop policy if exists rutina_ejercicios_propias on rutina_ejercicios;
create policy rutina_ejercicios_propias on rutina_ejercicios for all
  using (exists (select 1 from rutinas r where r.id = rutina_id and r.user_id = auth.uid()))
  with check (exists (select 1 from rutinas r where r.id = rutina_id and r.user_id = auth.uid()));

drop policy if exists series_log_propias on series_log;
create policy series_log_propias on series_log for all
  using (exists (select 1 from sesiones s where s.id = sesion_id and s.user_id = auth.uid()))
  with check (exists (select 1 from sesiones s where s.id = sesion_id and s.user_id = auth.uid()));

-- ================================================================
-- 8. VISTA DE ADHERENCIA  (cierra el círculo con el mealtracker)
-- ================================================================
-- Hoy llenas a mano dias_planeados / dias_asistidos en `seguimientos` y
-- /api/adherence.js del mealtracker los lee para el tablero "Mi Semana".
-- Con las sesiones reales eso se calcula solo. La vista NO escribe en
-- `seguimientos`: te deja el dato listo para que decidas si lo adoptas.

create or replace view adherencia_entreno as
select
  s.cliente_id,
  s.semana_iso                                            as semana,
  count(*) filter (where s.estado = 'completada')          as dias_asistidos,
  max(coalesce(array_length(f.dias_semana, 1), 0))         as dias_planeados,
  round(avg(s.rpe) filter (where s.rpe is not null), 1)    as rpe_promedio,
  sum(s.duracion_seg) filter (where s.estado = 'completada') as segundos_totales
from sesiones s
left join fases f on f.id = s.fase_id
where s.semana_iso is not null
group by s.cliente_id, s.semana_iso;

-- ================================================================
-- 9. MIGRACIONES
-- ================================================================
-- Todo lo que se agregó DESPUÉS de la primera versión vive aquí, con
-- `if not exists`. Así este archivo sigue siendo uno solo: sirve igual para
-- una instalación nueva y para actualizar una que ya está corriendo. No hay
-- que llevar cuenta de qué versión tienes — vuelves a correrlo y ya.

-- ---- Miniatura del video subido ----
-- Los videos de YouTube ya traen miniatura gratis (i.ytimg.com). Los que
-- subes tú no, así que el CRM captura un fotograma al subirlos y lo guarda
-- en el mismo bucket. Va en `poster_path` (ruta en Storage, necesita firma)
-- y no en `poster_url`, que es para imágenes públicas.
alter table ejercicios add column if not exists poster_path text;

-- ---- Descanso entre ejercicios dentro de un bloque ----
-- En un circuito hay DOS descansos distintos y confundirlos arruina la
-- sesión: el corto entre una estación y la siguiente, y el largo al
-- terminar la vuelta completa.
--   rutina_bloques.descanso_seg        → entre VUELTAS (el largo)
--   rutina_bloques.descanso_entre_seg  → entre EJERCICIOS (el corto)
alter table rutina_bloques add column if not exists descanso_entre_seg int;

-- ================================================================
-- 10. HISTORIAL DE UN EJERCICIO
-- ================================================================
-- "La vez pasada levantaste 30 kg × 10, 10, 9, 8" — el dato que convierte
-- marcar pesos en progresión visible. Se resuelve en el servidor porque
-- hacerlo desde la app son dos viajes encadenados (buscar la última sesión,
-- luego sus series) justo cuando el cliente está en medio del entreno.
--
-- Devuelve las series de la ÚLTIMA sesión completada en que ese cliente hizo
-- ese ejercicio. Vacío si nunca lo ha hecho: primera vez, sin referencia.
create or replace function ultimas_series(
  p_cliente_id uuid,
  p_ejercicio_id uuid
) returns table (
  fecha date,
  serie_num int,
  reps int,
  peso numeric,
  unidad text,
  rir int
)
language sql stable
as $$
  with ultima as (
    select s.id, s.fecha
    from sesiones s
    join series_log sl on sl.sesion_id = s.id
    where s.cliente_id = p_cliente_id
      and sl.ejercicio_id = p_ejercicio_id
      and s.estado = 'completada'
    order by s.fecha desc
    limit 1
  )
  select u.fecha, sl.serie_num, sl.reps, sl.peso, sl.unidad, sl.rir
  from ultima u
  join series_log sl on sl.sesion_id = u.id
  where sl.ejercicio_id = p_ejercicio_id
    and sl.completada
  order by sl.serie_num;
$$;

-- Récord: el peso más alto que ese cliente ha movido en ese ejercicio, y
-- cuándo. Sirve para celebrarlo cuando lo supere.
create or replace function record_ejercicio(
  p_cliente_id uuid,
  p_ejercicio_id uuid
) returns table (peso numeric, reps int, unidad text, fecha date)
language sql stable
as $$
  select sl.peso, sl.reps, sl.unidad, s.fecha
  from series_log sl
  join sesiones s on s.id = sl.sesion_id
  where s.cliente_id = p_cliente_id
    and sl.ejercicio_id = p_ejercicio_id
    and sl.completada
    and sl.peso is not null
  order by sl.peso desc, sl.reps desc
  limit 1;
$$;

-- ================================================================
-- FIN. Corre esto en el SQL Editor del Supabase del CRM.
-- Después: Storage → New bucket → nombre `ejercicios`, público NO.
-- ================================================================

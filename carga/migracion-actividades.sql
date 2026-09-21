-- ════════════════════════════════════════════════════════════════════════
-- ACTIVIDAD COMPLEMENTARIA  ·  cardio, deportes, caminatas
-- ════════════════════════════════════════════════════════════════════════
-- Dónde correrlo:  Supabase del CRM → SQL Editor.
-- Es idempotente: se puede correr dos veces.
--
-- CORRE PRIMERO  carga/migracion-eventos.sql.  Este archivo apunta a
-- `eventos` con una clave foránea de verdad, así que sin esa tabla no puede
-- crearse. Si te falta, el bloque de abajo te lo dice con todas las letras
-- en vez del críptico «relation "eventos" does not exist».
--
-- QUÉ PROBLEMA RESUELVE
-- --------------------
-- El cliente hace cosas que no son la rutina de fuerza: veinte minutos de
-- caminadora al terminar, correr en la calle el domingo, natación, tenis.
-- Eso es la mitad de su gasto semanal y hasta ahora no se registraba en
-- ningún sitio: ni él tenía dónde marcarlo ni el coach dónde verlo.
--
-- DOS TABLAS, Y POR QUÉ NO UNA
-- ----------------------------
--   `eventos`      → lo PROGRAMADO. "Los lunes y miércoles hace natación".
--   `actividades`  → lo QUE PASÓ.   "El lunes 12 nadó 40 min, suave".
--
-- No es lo mismo y mezclarlo se paga caro. Un cliente puede tener natación
-- programada los lunes y hacerla un martes; puede hacer una caminata que
-- nadie programó; y puede saltarse la natación del lunes. Con una sola tabla
-- habría que inventar filas "programadas pero no hechas", que es justo el
-- error que ensucia la adherencia.
--
-- `actividades.evento_id` une las dos cuando la actividad venía programada.
-- Cuando es NULL, el cliente la registró por su cuenta — que es lo normal y
-- lo que debe ser fácil.
--
-- DÓNDE ENCAJA `evento_registros`
-- -------------------------------
-- Esa tabla (de migracion-eventos.sql) queda SOLO para los eventos que no
-- son actividad: marcar hecha una medición, una cita, una nota. Una natación
-- hecha se registra en `actividades`, con sus minutos, no como un booleano.
-- ════════════════════════════════════════════════════════════════════════

-- ---- 0. Lo que hace falta antes ----
do $$
begin
  if to_regclass('public.eventos') is null then
    raise exception
      'Falta la tabla "eventos". Corre primero carga/migracion-eventos.sql y vuelve a correr este archivo.';
  end if;
end $$;

-- ---- 1. El catálogo ----
-- Vive en la base, y no como una lista en el código, porque el cliente elige
-- de aquí y el coach tiene que poder añadir "pádel" sin que nadie despliegue
-- nada. Los slugs son el contrato con `actividades.tipo` y con el JS.
create table if not exists actividades_catalogo (
  slug text primary key,
  nombre text not null,
  categoria text not null,      -- cardio | deporte | movilidad | otro
  icono text,
  -- true = de las que se hacen AL TERMINAR la fuerza, no como sesión aparte.
  -- Cambia dónde se ofrece: estas aparecen al cerrar la rutina.
  remate boolean not null default false,
  -- Qué campos tiene sentido pedir. Preguntar kilómetros en yoga es ruido.
  pide_distancia boolean not null default false,
  orden int not null default 100,
  activo boolean not null default true
);

insert into actividades_catalogo (slug, nombre, categoria, icono, remate, pide_distancia, orden) values
  -- Cardio de gimnasio: casi siempre remate de la sesión de fuerza
  ('cinta',        'Caminadora',        'cardio',    '🏃', true,  true,  10),
  ('eliptica',     'Elíptica',          'cardio',    '🌀', true,  false, 20),
  ('remo_maquina', 'Remo (máquina)',    'cardio',    '🚣', true,  true,  30),
  ('escaladora',   'Escaladora',        'cardio',    '🪜', true,  false, 40),
  ('bici_estatica','Bicicleta estática','cardio',    '🚲', true,  true,  50),
  -- Cardio fuera del gimnasio: sesión propia
  ('running',      'Running en calle',  'cardio',    '👟', false, true,  60),
  ('caminata',     'Caminata',          'cardio',    '🚶', false, true,  70),
  ('ciclismo',     'Ciclismo',          'cardio',    '🚴', false, true,  80),
  ('trote_trail',  'Trail / montaña',   'cardio',    '⛰️', false, true,  90),
  -- Deportes
  ('natacion',     'Natación',          'deporte',   '🏊', false, true,  100),
  ('tenis',        'Tenis',             'deporte',   '🎾', false, false, 110),
  ('padel',        'Pádel',             'deporte',   '🏓', false, false, 120),
  ('futbol',       'Fútbol',            'deporte',   '⚽', false, false, 130),
  ('baloncesto',   'Baloncesto',        'deporte',   '🏀', false, false, 140),
  ('voleibol',     'Voleibol',          'deporte',   '🏐', false, false, 150),
  ('boxeo',        'Boxeo',             'deporte',   '🥊', false, false, 160),
  ('crossfit',     'CrossFit / funcional','deporte', '🤸', false, false, 170),
  ('baile',        'Baile',             'deporte',   '💃', false, false, 180),
  -- Movilidad y recuperación
  ('yoga',         'Yoga',              'movilidad', '🧘', false, false, 200),
  ('pilates',      'Pilates',           'movilidad', '🤍', false, false, 210),
  ('estiramiento', 'Estiramiento',      'movilidad', '🙆', true,  false, 220),
  ('movilidad',    'Movilidad',         'movilidad', '🔄', true,  false, 230),
  ('otro',         'Otra actividad',    'otro',      '✨', false, false, 900)
on conflict (slug) do update set
  nombre = excluded.nombre,
  categoria = excluded.categoria,
  icono = excluded.icono,
  remate = excluded.remate,
  pide_distancia = excluded.pide_distancia,
  orden = excluded.orden;
-- El `do update` es a propósito: volver a correr el archivo corrige un
-- nombre o un icono sin borrar nada. Lo que el coach añada a mano y no esté
-- en esta lista se queda como está.

-- ---- 2. Lo que el cliente registró ----
create table if not exists actividades (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  cliente_id uuid not null references clientes(id) on delete cascade,

  fecha date not null default current_date,
  tipo text not null references actividades_catalogo(slug),
  titulo text,                  -- solo si tipo = 'otro'

  duracion_min int,
  distancia_km numeric(6,2),
  intensidad text,              -- suave | moderada | fuerte
  rpe int check (rpe is null or rpe between 1 and 10),
  notas text,

  -- Si venía programada, de qué evento. NULL = la registró por su cuenta.
  evento_id uuid references eventos(id) on delete set null,
  -- Si la hizo al terminar una rutina, cuál. Sirve para "20 min de cinta
  -- después del Push", que es distinto de una sesión de cardio aparte.
  sesion_id uuid references sesiones(id) on delete set null,

  origen text not null default 'cliente',   -- cliente | coach
  created_at timestamptz default now()
);

create index if not exists actividades_cliente_idx on actividades (cliente_id, fecha desc);
create index if not exists actividades_tipo_idx    on actividades (cliente_id, tipo, fecha desc);

-- ---- 3. Permisos ----
alter table actividades_catalogo enable row level security;
alter table actividades          enable row level security;

-- El catálogo es vocabulario compartido, igual que `musculos`: lectura para
-- todos, escritura solo desde el SQL editor.
drop policy if exists actividades_catalogo_lectura on actividades_catalogo;
create policy actividades_catalogo_lectura on actividades_catalogo for select using (true);

drop policy if exists actividades_propias on actividades;
create policy actividades_propias on actividades for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ---- 4. El resumen que lee el perfil del cliente ----
-- Por semana ISO, para cruzar con `seguimientos` del CRM y con la semana del
-- mealtracker. Es la fila que responde "¿cuánto se movió además de la
-- fuerza?" sin recorrer registro por registro.
create or replace view actividad_semanal as
  select a.cliente_id,
         to_char(a.fecha, 'IYYY-"W"IW') as semana_iso,
         count(*)                        as veces,
         sum(coalesce(a.duracion_min, 0)) as minutos,
         sum(coalesce(a.distancia_km, 0)) as km,
         count(*) filter (where c.categoria = 'cardio')    as veces_cardio,
         count(*) filter (where c.categoria = 'deporte')   as veces_deporte,
         count(*) filter (where c.categoria = 'movilidad') as veces_movilidad,
         string_agg(distinct c.nombre, ', ' order by c.nombre) as que_hizo
    from actividades a
    join actividades_catalogo c on c.slug = a.tipo
   group by a.cliente_id, to_char(a.fecha, 'IYYY-"W"IW');

-- ════════════════════════════════════════════════════════════════════════
-- COMPROBAR QUE QUEDÓ
-- ════════════════════════════════════════════════════════════════════════
--   select count(*) from actividades_catalogo;   -- 23
--   select * from actividad_semanal limit 5;     -- vacío hasta que registren
-- ════════════════════════════════════════════════════════════════════════

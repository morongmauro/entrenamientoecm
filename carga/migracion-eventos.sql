-- ════════════════════════════════════════════════════════════════════════
-- EVENTOS DEL CALENDARIO  ·  lo que NO es una rutina
-- ════════════════════════════════════════════════════════════════════════
-- Dónde correrlo:  Supabase del CRM → SQL Editor  (el ÚNICO Supabase que
-- hay; entrenamiento vive en la misma base, por eso `fases` apunta a
-- `clientes` con una FK de verdad).
--
-- Es idempotente: se puede correr dos veces sin romper nada.
--
-- POR QUÉ HACE FALTA
-- ------------------
-- Hasta ahora el calendario solo sabía de rutinas. Pero media planificación
-- de un cliente no son rutinas: "los lunes y miércoles hace natación",
-- "el día 15 toca medición de peso", "esa semana está de viaje". Meter eso
-- como rutinas falsas ensuciaría el historial de entreno — una rutina que
-- nadie ejecuta cuenta como rutina no hecha, y la adherencia sale mal.
--
-- Así que son su propia tabla, con dos formas de caer en el calendario:
--
--   · `fecha`        → una sola vez, ese día. "Medición 15 de octubre".
--   · `dias_semana`  → se repite esos días mientras dure la fase.
--                      "Natación lunes y miércoles".
--
-- La segunda necesita una fase, que es quien pone el rango (fecha_inicio +
-- semanas). Sin fase no hay dónde repetir, y por eso está el CHECK.
-- ════════════════════════════════════════════════════════════════════════

-- ---- 0. Lo que este archivo da por hecho ----
-- `eventos_visibles` (abajo) hereda la visibilidad de la fase, así que
-- necesita `fases.visible_cliente`. Esa columna la trae
-- carga/migracion-visibilidad.sql, pero si corres los archivos en otro orden
-- —cosa normal— esto fallaría con «column f.visible_cliente does not exist»
-- y el error no dice cuál es el archivo que falta. Así que se asegura sola:
-- si la columna ya está, no hace nada.
alter table fases
  add column if not exists visible_cliente boolean not null default false,
  add column if not exists publicada_en    timestamptz,
  add column if not exists publicada_por   uuid references auth.users on delete set null;

alter table rutinas add column if not exists visible_cliente boolean;

-- ---- 1. La tabla ----
create table if not exists eventos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  cliente_id uuid not null references clientes(id) on delete cascade,
  fase_id uuid references fases(id) on delete cascade,   -- NULL = suelto en el calendario

  tipo text not null default 'actividad',
  -- actividad  natación, fútbol, caminata…  (algo que HACE)
  -- medicion   pesarse, medidas, fotos      (algo que REGISTRA)
  -- cita       consulta, control médico
  -- nota       recordatorio sin acción      ("de viaje", "semana de descarga")
  -- descanso   día libre marcado a propósito

  titulo text not null,
  detalle text,
  hora time,
  duracion_min int,

  -- ---- Cuándo ----
  fecha date,                          -- una vez
  dias_semana text[] default '{}',     -- o se repite: ['L','X'] — mismo código que fases
  semanas int[],                       -- NULL = todas las semanas de la fase; [1,3] = solo esas

  -- Misma puerta que las rutinas: NULL hereda de la fase (lo normal), false
  -- lo oculta aunque la fase esté enviada, true lo muestra aunque no lo esté.
  -- Un evento sin fase y sin decidir NO se muestra: nada se publica solo.
  visible_cliente boolean,

  color text,                          -- opcional, para distinguirlo de un vistazo
  created_at timestamptz default now(),
  updated_at timestamptz default now(),

  -- O cae en un día concreto, o se repite dentro de una fase. Sin una de las
  -- dos el evento no sabría en qué casilla pintarse y quedaría invisible:
  -- mejor que la base lo rechace a que el coach lo cree y no aparezca nunca.
  constraint eventos_cuando_ck check (
    fecha is not null
    or (coalesce(array_length(dias_semana, 1), 0) > 0 and fase_id is not null)
  )
);

create index if not exists eventos_cliente_idx on eventos (user_id, cliente_id, fecha);
create index if not exists eventos_fase_idx    on eventos (fase_id);

-- ---- 2. Lo que el cliente marcó de cada evento ----
-- Un evento que se repite no tiene un solo "hecho": tiene uno por fecha. Por
-- eso el registro lleva su propia fecha y no un booleano en `eventos`.
create table if not exists evento_registros (
  id uuid primary key default gen_random_uuid(),
  evento_id uuid not null references eventos(id) on delete cascade,
  cliente_id uuid not null references clientes(id) on delete cascade,
  fecha date not null,
  estado text not null default 'hecho',   -- hecho | saltado
  nota text,
  valor numeric,                          -- para las mediciones: el peso que puso
  created_at timestamptz default now(),
  unique (evento_id, fecha)
);

create index if not exists evento_registros_cliente_idx
  on evento_registros (cliente_id, fecha desc);

-- ---- 3. Permisos ----
alter table eventos          enable row level security;
alter table evento_registros enable row level security;

drop policy if exists eventos_propios on eventos;
create policy eventos_propios on eventos for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Hija: hereda el permiso de su evento.
drop policy if exists evento_registros_propios on evento_registros;
create policy evento_registros_propios on evento_registros for all
  using (exists (select 1 from eventos e where e.id = evento_id and e.user_id = auth.uid()))
  with check (exists (select 1 from eventos e where e.id = evento_id and e.user_id = auth.uid()));

-- ---- 4. Las fechas reales de un evento ----
-- Expande el evento a la lista de días en que cae. Un evento con `fecha` es
-- un solo día; uno con `dias_semana` se recorre semana a semana dentro de la
-- fase. Se calcula aquí y no en el navegador para que el CRM y la app del
-- cliente pinten EXACTAMENTE los mismos días.
create or replace function evento_fechas(p_evento_id uuid)
returns table (fecha date)
language sql stable as $$
  with e as (select * from eventos where id = p_evento_id),
       f as (select fa.fecha_inicio, fa.semanas
               from fases fa join e on fa.id = e.fase_id)
  -- caso 1: día suelto
  select e.fecha from e where e.fecha is not null
  union all
  -- caso 2: se repite dentro de la fase
  select (f.fecha_inicio + (s.n - 1) * 7 + d.off)::date
    from e
    join f on true
    cross join generate_series(1, coalesce(f.semanas, 0)) as s(n)
    cross join lateral (
      select case dia
               when 'L' then 0 when 'M' then 1 when 'X' then 2 when 'J' then 3
               when 'V' then 4 when 'S' then 5 when 'D' then 6 end as off
        from unnest(e.dias_semana) as dia
    ) d
   where e.fecha is null
     and f.fecha_inicio is not null
     and d.off is not null
     and (e.semanas is null or s.n = any(e.semanas));
$$;

-- ---- 5. Lo que ve el cliente ----
-- Misma regla que `rutinas_visibles`: el evento se ve si él lo dice, y si no
-- dice nada, hereda de su fase. Un evento suelto (sin fase) sin decidir NO
-- se ve — nada se publica solo.
create or replace view eventos_visibles as
  select e.*
    from eventos e
    left join fases f on f.id = e.fase_id
   where coalesce(e.visible_cliente, f.visible_cliente, false);

-- ════════════════════════════════════════════════════════════════════════
-- COMPROBAR QUE QUEDÓ
-- ════════════════════════════════════════════════════════════════════════
--   select count(*) from eventos;                    -- 0, recién creada
--   select * from evento_fechas('<id de un evento>'); -- sus días
-- ════════════════════════════════════════════════════════════════════════

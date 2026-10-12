-- ═══════════════════════════════════════════════════════════════════════
-- FUERZA DE UN SOLO DÍA · lo que cambia el coach desde el calendario
-- ═══════════════════════════════════════════════════════════════════════
-- Dónde: Supabase del CRM → SQL Editor → pegar todo → Run. Se puede correr
-- dos veces.
--
-- Hasta ahora, en el calendario del CRM la fuerza solo se cambiaba por día
-- de la semana («Push todos los lunes»). Con esto también se puede tocar UNA
-- fecha («este lunes no», «este jueves pásalo al miércoles», «este sábado
-- ponle Lower»), sin cambiar el plan de las otras semanas:
--
--   · mover un día          → `rutina_movimientos` con origen 'coach'
--                              (la tabla ya existía; el cliente la usa igual)
--   · poner un día libre     → `rutina_extras` con origen 'coach'
--   · quitar un día          → `rutina_dias_quitados` (NUEVA)
--
-- La app lo pinta como el plan del coach: sin «la moviste» ni «la añadiste
-- tú», y el cliente no puede quitar lo que puso el coach.
--
-- QUÉ HACE
--   0. Si todavía no existen (migracion-mover-dia.sql y
--      migracion-rutina-extra.sql sin correr), crea `rutina_movimientos` y
--      `rutina_extras`, vacías. Si ya existen, no las toca.
--   1. Crea `rutina_dias_quitados` (vacía).
--   2. Añade `rutina_extras.origen` ('cliente' para todo lo que ya había: lo
--      que el cliente añadió sigue siendo suyo).
--
-- NO borra ni cambia ninguna rutina, sesión, serie ni marca del cliente.
-- Sin este SQL todo sigue funcionando como antes; el CRM solo avisa que
-- falta cuando intentas cambiar un solo día.
-- ═══════════════════════════════════════════════════════════════════════

begin;

-- 0. Las dos tablas de antes, por si faltan (igual que en sus SQL).
create table if not exists rutina_movimientos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  cliente_id uuid not null references clientes(id) on delete cascade,
  fase_id uuid references fases(id) on delete cascade,
  rutina_id uuid not null references rutinas(id) on delete cascade,
  desde date not null,
  hasta date not null,
  origen text not null default 'cliente',   -- cliente | coach
  created_at timestamptz default now(),
  constraint rutina_movimientos_distinto check (desde <> hasta)
);
create index if not exists rutina_movimientos_cliente_idx on rutina_movimientos (cliente_id, desde, hasta);
alter table rutina_movimientos enable row level security;
drop policy if exists rutina_movimientos_propios on rutina_movimientos;
create policy rutina_movimientos_propios on rutina_movimientos for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create table if not exists rutina_extras (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  cliente_id uuid not null references clientes(id) on delete cascade,
  fase_id uuid references fases(id) on delete cascade,
  rutina_id uuid not null references rutinas(id) on delete cascade,
  fecha date not null,
  created_at timestamptz default now(),
  constraint rutina_extras_un_dia unique (cliente_id, fecha)
);
create index if not exists rutina_extras_fase_idx on rutina_extras (fase_id, fecha);
alter table rutina_extras enable row level security;
drop policy if exists rutina_extras_propias on rutina_extras;
create policy rutina_extras_propias on rutina_extras for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- 1. Los días quitados.
create table if not exists rutina_dias_quitados (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  cliente_id uuid not null references clientes(id) on delete cascade,
  fase_id uuid references fases(id) on delete cascade,
  fecha date not null,
  -- la rutina que había ese día (solo para mostrarlo; si la rutina se borra,
  -- el día sigue sin fuerza)
  rutina_id uuid references rutinas(id) on delete set null,
  created_at timestamptz default now(),
  constraint rutina_dias_quitados_un_dia unique (cliente_id, fecha)
);

create index if not exists rutina_dias_quitados_fase_idx on rutina_dias_quitados (fase_id, fecha);

alter table rutina_dias_quitados enable row level security;

-- Igual que `rutina_movimientos` y `rutina_extras`: el coach ve y edita lo
-- de sus clientes. La app solo lee (con la llave de servicio).
drop policy if exists rutina_dias_quitados_propios on rutina_dias_quitados;
create policy rutina_dias_quitados_propios on rutina_dias_quitados for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

comment on table rutina_dias_quitados is
  'Días en que el coach quitó la rutina de fuerza SOLO esa fecha. El plan semanal no cambia.';

-- Quién puso cada rutina añadida a un día libre. Lo que ya había lo añadió
-- el cliente desde su app.
alter table rutina_extras add column if not exists origen text not null default 'cliente';

comment on column rutina_extras.origen is
  'cliente (la añadió desde su app y la puede quitar) | coach (la puso el coach desde el CRM: es su plan).';

commit;

-- Comprobar:
--   select count(*) from rutina_dias_quitados;                         -- 0
--   select origen, count(*) from rutina_extras group by origen;        -- todo 'cliente'

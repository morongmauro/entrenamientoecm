-- ════════════════════════════════════════════════════════════════════════
-- EL CLIENTE AÑADE UNA RUTINA A UN DÍA LIBRE
-- ════════════════════════════════════════════════════════════════════════
-- Dónde correrlo:  Supabase del CRM → SQL Editor. Es idempotente.
--
-- «Este sábado quiero hacer otra vez el Push.» Desde su calendario, el
-- cliente toca un día libre de ESTA semana y elige una rutina de su ciclo.
-- Queda guardado aquí, para esa fecha nada más:
--
--   · No toca `rutinas.dias_semana`: el plan que armaste sigue igual.
--   · Solo en días sin rutina y solo en la semana en curso.
--   · Lo puede quitar mientras no lo haya entrenado.
--
-- Sin esta tabla la app sigue funcionando: simplemente no deja añadir
-- (dice «no disponible»).
-- ════════════════════════════════════════════════════════════════════════

begin;

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

-- Igual que `rutina_movimientos`: el coach ve y edita lo de sus clientes. La
-- app escribe con la llave de servicio desde /api/training.
drop policy if exists rutina_extras_propias on rutina_extras;
create policy rutina_extras_propias on rutina_extras for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

comment on table rutina_extras is
  'Rutinas que el cliente añadió a un día libre de su semana. Cada fila es UNA fecha; el plan semanal no cambia.';

commit;

-- ════════════════════════════════════════════════════════════════════════
-- EL CLIENTE MUEVE UNA RUTINA DE DÍA
-- ════════════════════════════════════════════════════════════════════════
-- Dónde correrlo:  Supabase del CRM → SQL Editor.
-- Es idempotente: correrlo dos veces no cambia nada la segunda.
--
-- «El martes no puedo, lo paso al jueves.» El cliente arrastra la rutina en
-- su calendario y queda guardado AQUÍ, como un cambio de UNA fecha:
--
--   · No toca `rutinas.dias_semana`. El plan semanal que armaste sigue
--     igual; la semana siguiente todo vuelve a su sitio.
--   · Si el día de destino ya tenía rutina, las dos se intercambian (igual
--     que cuando arrastras en el CRM): nunca quedan dos rutinas apiladas.
--   · Solo se mueven días de hoy en adelante: el pasado es registro.
--
-- La app lo lee al pintar la semana y el mes. Sin esta tabla la app sigue
-- funcionando: simplemente no deja mover (dice «no disponible»).
-- ════════════════════════════════════════════════════════════════════════

begin;

create table if not exists rutina_movimientos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  cliente_id uuid not null references clientes(id) on delete cascade,
  fase_id uuid references fases(id) on delete cascade,
  rutina_id uuid not null references rutinas(id) on delete cascade,
  desde date not null,          -- el día en que tocaba
  hasta date not null,          -- el día al que la movió
  origen text not null default 'cliente',   -- cliente | coach
  created_at timestamptz default now(),
  constraint rutina_movimientos_distinto check (desde <> hasta)
);

create index if not exists rutina_movimientos_cliente_idx
  on rutina_movimientos (cliente_id, desde, hasta);

alter table rutina_movimientos enable row level security;

-- Igual que `actividades`: el coach ve y edita lo de sus clientes. La app
-- escribe con la llave de servicio desde /api/training.
drop policy if exists rutina_movimientos_propios on rutina_movimientos;
create policy rutina_movimientos_propios on rutina_movimientos for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

comment on table rutina_movimientos is
  'Cambios de día que hizo el cliente en su calendario. Cada fila mueve UNA fecha; el plan semanal no cambia.';

commit;

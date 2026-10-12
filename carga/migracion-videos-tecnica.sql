-- ═══════════════════════════════════════════════════════════════════════
-- VIDEOS DE TÉCNICA · los que le pides a cada cliente y cómo le fue
-- ═══════════════════════════════════════════════════════════════════════
-- Dónde: Supabase del CRM → SQL Editor → pegar todo → Run. Se puede correr
-- dos veces.
--
-- «Mándame video de la sentadilla y del peso muerto.» Cada pedido es una
-- fila: qué ejercicio, cuándo lo pediste y cómo quedó al revisarlo:
--   pedido    → se lo pediste y no ha llegado
--   recibido  → llegó y falta revisarlo
--   bien      → lo hizo bien
--   mejorar   → hay que corregir algo (la nota dice qué) y volver a pedirlo
-- Al volver a pedir uno, la fila nueva apunta a la anterior (pedido_de), y
-- así queda la historia de cada ejercicio.
--
-- Lo ves en Entrenamiento → el cliente → «🎥 Videos de técnica» y en
-- Seguimiento. Solo lo ve el coach: la app del cliente no lo lee.
--
-- NO borra ni cambia nada de lo que ya hay: es una tabla nueva.
-- ═══════════════════════════════════════════════════════════════════════

begin;

create table if not exists videos_tecnica (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  cliente_id uuid not null references clientes(id) on delete cascade,
  ejercicio_id uuid references ejercicios(id) on delete set null,
  ejercicio_nombre text not null,            -- el nombre, por si el ejercicio se archiva
  pedido_en date not null default current_date,
  estado text not null default 'pedido'
    constraint videos_tecnica_estado_ck check (estado in ('pedido', 'recibido', 'bien', 'mejorar')),
  nota text,                                  -- qué corregir (o qué estuvo bien)
  revisado_en date,
  pedido_de uuid references videos_tecnica(id) on delete set null,   -- el pedido anterior del mismo ejercicio
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index if not exists videos_tecnica_cliente_idx on videos_tecnica (cliente_id, pedido_en desc);

alter table videos_tecnica enable row level security;

drop policy if exists videos_tecnica_propios on videos_tecnica;
create policy videos_tecnica_propios on videos_tecnica for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

comment on table videos_tecnica is
  'Videos de técnica que el coach le pide a cada cliente y cómo quedaron al revisarlos (pedido, recibido, bien, mejorar).';

commit;

-- Comprobar:  select count(*) from videos_tecnica;   -- 0

-- ═══════════════════════════════════════════════════════════════════════
-- VIDEOS DE TÉCNICA · 2 · el estado «nada bien»
-- ═══════════════════════════════════════════════════════════════════════
-- Dónde: Supabase del CRM → SQL Editor → pegar todo → Run. Se puede correr
-- dos veces, y también si nunca corriste migracion-videos-tecnica.sql (crea
-- la tabla si no está).
--
-- Los estados de cada pedido:
--   pedido    → se lo pediste y no ha llegado
--   recibido  → llegó y falta revisarlo
--   bien      → lo hizo bien
--   mejorar   → hay que corregir algo (la nota dice qué) y volver a pedirlo
--   mal       → nada bien: lo hizo mal (la nota dice qué) y hay que repetirlo
--
-- Lo ves en Entrenamiento → el cliente → Rutinas (la etiqueta en cada
-- ejercicio), «Lo que entrenó» y «Videos de técnica»; en Seguimiento; y en
-- la lista de clientes de Entrenamiento, todo lo pendiente de todos.
--
-- NO borra ni cambia nada de lo que ya hay: solo amplía los estados posibles.
-- ═══════════════════════════════════════════════════════════════════════

begin;

create table if not exists videos_tecnica (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  cliente_id uuid not null references clientes(id) on delete cascade,
  ejercicio_id uuid references ejercicios(id) on delete set null,
  ejercicio_nombre text not null,
  pedido_en date not null default current_date,
  estado text not null default 'pedido',
  nota text,
  revisado_en date,
  pedido_de uuid references videos_tecnica(id) on delete set null,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- El estado nuevo entra en la regla de la columna (la de antes no lo dejaba).
alter table videos_tecnica drop constraint if exists videos_tecnica_estado_ck;
alter table videos_tecnica add constraint videos_tecnica_estado_ck
  check (estado in ('pedido', 'recibido', 'bien', 'mejorar', 'mal'));

create index if not exists videos_tecnica_cliente_idx on videos_tecnica (cliente_id, pedido_en desc);

alter table videos_tecnica enable row level security;

drop policy if exists videos_tecnica_propios on videos_tecnica;
create policy videos_tecnica_propios on videos_tecnica for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

comment on table videos_tecnica is
  'Videos de técnica que el coach le pide a cada cliente y cómo quedaron al revisarlos (pedido, recibido, bien, mejorar, mal).';

commit;

-- Comprobar (solo lee):
--   select estado, count(*) from videos_tecnica group by 1;

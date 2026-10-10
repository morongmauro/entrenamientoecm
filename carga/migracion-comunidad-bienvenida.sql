-- ================================================================
-- MIGRACIÓN · Bienvenida a la Comunidad (visual nueva)
-- ================================================================
-- Dónde se corre: Supabase del CRM → SQL Editor → pegar todo → Run.
-- Es idempotente: correrlo dos veces no rompe nada ni duplica nada.
-- Solo AGREGA una tabla nueva: no toca clientes, publicaciones, videos ni
-- nada de lo que ya tienes.
--
-- El mensaje de bienvenida que le sale a cada persona la primera vez que
-- entra a la app nueva (una sola vez). Lo escribes y lo editas desde el
-- CRM → Comunidad → «Mensaje de bienvenida». Uno por coach.
--
-- La app lo lee a través de su API (service_role); el coach, desde el CRM,
-- lo crea y lo edita.
-- ================================================================

create table if not exists comunidad_bienvenida (
  user_id uuid primary key default auth.uid() references auth.users on delete cascade,
  titulo text not null default 'Bienvenido a la comunidad' check (length(trim(titulo)) between 1 and 80),
  texto text not null check (length(trim(texto)) between 1 and 1200),
  activa boolean not null default true,
  editado_en timestamptz not null default now()
);

alter table comunidad_bienvenida enable row level security;

drop policy if exists comunidad_bienvenida_propia on comunidad_bienvenida;
create policy comunidad_bienvenida_propia on comunidad_bienvenida for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

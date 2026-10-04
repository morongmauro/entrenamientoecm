-- ================================================================
-- MIGRACIÓN · Relojes y anillos (Fitbit, Oura, Whoop, Polar, Garmin…)
-- ================================================================
-- Dónde se corre: Supabase del CRM → SQL Editor → pegar todo → Run.
-- Es idempotente.
--
--   relojes_conexiones — qué reloj conectó cada cliente y sus llaves de
--                        acceso. Las llaves (access_token, refresh_token)
--                        solo las lee la API del servidor: el CRM no puede
--                        verlas, ni siquiera el coach.
--   relojes_dias       — lo que trae el reloj, un renglón por día: pasos,
--                        sueño, pulso en reposo, calorías activas, HRV,
--                        recuperación y los entrenos que registró.
-- ================================================================

create table if not exists relojes_conexiones (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  cliente_id uuid not null references clientes(id) on delete cascade,
  proveedor text not null check (proveedor in ('fitbit', 'oura', 'whoop', 'polar', 'garmin', 'apple')),
  estado text not null default 'conectado' check (estado in ('conectado', 'vencido', 'desconectado')),
  access_token text,
  refresh_token text,
  expira_en timestamptz,
  proveedor_usuario text,
  ultima_sync timestamptz,
  conectado_en timestamptz not null default now(),
  unique (cliente_id, proveedor)
);

create table if not exists relojes_dias (
  cliente_id uuid not null references clientes(id) on delete cascade,
  user_id uuid not null references auth.users on delete cascade,
  fecha date not null,
  proveedor text not null,
  pasos integer,
  sueno_min integer,
  fc_reposo integer,
  calorias_activas integer,
  hrv numeric,
  recuperacion integer,
  entrenos jsonb,
  actualizado_en timestamptz not null default now(),
  primary key (cliente_id, fecha, proveedor)
);
create index if not exists relojes_dias_coach_idx on relojes_dias (user_id, fecha desc);

alter table relojes_conexiones enable row level security;
alter table relojes_dias enable row level security;

drop policy if exists relojes_conexiones_coach on relojes_conexiones;
create policy relojes_conexiones_coach on relojes_conexiones for select using (user_id = auth.uid());
drop policy if exists relojes_dias_coach on relojes_dias;
create policy relojes_dias_coach on relojes_dias for select using (user_id = auth.uid());

-- Las llaves no salen hacia el CRM: se le quita al rol del navegador el
-- permiso de leer esas dos columnas.
do $$
begin
  if exists (select 1 from pg_roles where rolname = 'authenticated') then
    execute 'revoke select on relojes_conexiones from authenticated';
    execute 'grant select (id, user_id, cliente_id, proveedor, estado, expira_en, proveedor_usuario, ultima_sync, conectado_en) on relojes_conexiones to authenticated';
  end if;
  if exists (select 1 from pg_roles where rolname = 'anon') then
    execute 'revoke all on relojes_conexiones from anon';
  end if;
end $$;

select case when to_regclass('public.relojes_conexiones') is not null and to_regclass('public.relojes_dias') is not null
       then 'relojes listos' else 'FALTA algo' end as estado;

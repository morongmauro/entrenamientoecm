-- ================================================================
-- MIGRACIÓN · Bandeja del coach, notas del cliente, medidas y cierre automático
-- ================================================================
-- Dónde se corre: Supabase del CRM → SQL Editor → pegar todo → Run.
-- Es idempotente: correrlo dos veces no rompe nada ni duplica nada.
--
-- Qué agrega:
--   1. notas_entreno            — lo que el cliente te escribe sobre una rutina o
--                                 un ejercicio desde su app.
--   2. sesiones.cerrada_auto    — la sesión la cerró el sistema porque el cliente
--                                 marcó series y no pulsó «Terminar».
--      sesiones.records         — los récords que batió en esa sesión (para que la
--                                 Bandeja los enseñe sin recalcular todo).
--   3. mediciones_corporales.origen — 'cliente' cuando la registró él desde la app.
--   4. Índices para que la Bandeja lea los últimos días de TODOS los clientes
--      de una vez sin recorrer tablas enteras.
--
-- La app funciona igual si esto aún no se corrió (cada escritura tiene su
-- respaldo), pero las notas del cliente NO se pueden guardar sin el punto 1.
-- ================================================================

-- ---- 1. Notas del cliente ----
create table if not exists notas_entreno (
  id uuid primary key default gen_random_uuid(),
  -- El coach dueño. La API lo pone explícito: escribe con la service_role,
  -- que no tiene usuario, y auth.uid() ahí vale null.
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  cliente_id uuid not null references clientes(id) on delete cascade,
  fecha date not null default current_date,

  -- Sobre qué es. Todo opcional: una nota puede ser de la rutina entera, de
  -- un ejercicio concreto o general ("esta semana viajo").
  rutina_id uuid references rutinas(id) on delete set null,
  rutina_ejercicio_id uuid references rutina_ejercicios(id) on delete set null,
  ejercicio_id uuid references ejercicios(id) on delete set null,
  sesion_id uuid references sesiones(id) on delete set null,

  texto text not null check (length(trim(texto)) > 0),
  leida_en timestamptz,               -- null = el coach aún no la marcó como leída
  created_at timestamptz default now()
);

create index if not exists notas_entreno_coach_idx on notas_entreno (user_id, created_at desc);
create index if not exists notas_entreno_cliente_idx on notas_entreno (cliente_id, created_at desc);

alter table notas_entreno enable row level security;
drop policy if exists notas_entreno_propias on notas_entreno;
create policy notas_entreno_propias on notas_entreno for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ---- 2. Sesiones ----
alter table sesiones add column if not exists cerrada_auto boolean default false;
alter table sesiones add column if not exists records jsonb;

-- La Bandeja pide "todo lo de los últimos 14 días"; sin este índice recorre
-- la tabla entera de sesiones de todos los clientes.
create index if not exists sesiones_coach_fecha_idx on sesiones (user_id, fecha desc);

-- ---- 3. Mediciones que registra el cliente ----
-- La tabla la creó el CRM y no está en ningún .sql de los repos: por eso va
-- dentro de un bloque que primero mira si existe, en vez de fallar.
do $$
begin
  if to_regclass('public.mediciones_corporales') is not null then
    execute 'alter table mediciones_corporales add column if not exists origen text';
    execute 'create index if not exists mediciones_cliente_fecha_idx on mediciones_corporales (cliente_id, fecha desc)';
  else
    raise notice 'No existe mediciones_corporales: el cliente no podrá registrar medidas hasta que exista.';
  end if;
end $$;

-- ---- 4. Actividad complementaria ----
do $$
begin
  if to_regclass('public.actividades') is not null then
    execute 'create index if not exists actividades_fecha_idx on actividades (user_id, fecha desc)';
  end if;
end $$;

-- ---- 5. Récord de un ejercicio, con kg y lb mezclados ----
-- La app ya deja marcar cada ejercicio en kg o en lb (cada gimnasio es
-- distinto). Esta función ordenaba por `peso` a secas: 120 lb le ganaba a
-- 60 kg. Ahora compara en kg; devuelve la serie tal cual se marcó.
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
  order by (case when sl.unidad = 'lb' then sl.peso * 0.45359237 else sl.peso end) desc, sl.reps desc
  limit 1;
$$;

-- ---- Comprobación ----
-- Debe devolver 4 filas con "sí".
select 'notas_entreno' as que, case when to_regclass('public.notas_entreno') is not null then 'sí' else 'NO' end as existe
union all
select 'sesiones.cerrada_auto', case when exists (select 1 from information_schema.columns where table_name = 'sesiones' and column_name = 'cerrada_auto') then 'sí' else 'NO' end
union all
select 'sesiones.records', case when exists (select 1 from information_schema.columns where table_name = 'sesiones' and column_name = 'records') then 'sí' else 'NO' end
union all
select 'mediciones_corporales.origen', case when exists (select 1 from information_schema.columns where table_name = 'mediciones_corporales' and column_name = 'origen') then 'sí' else 'NO (falta la tabla)' end;

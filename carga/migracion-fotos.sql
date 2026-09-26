-- ════════════════════════════════════════════════════════════════════════
-- FOTOS DE PROGRESO
-- ════════════════════════════════════════════════════════════════════════
-- Dónde correrlo:  Supabase del CRM → SQL Editor.
-- Es idempotente: correrlo dos veces no cambia nada la segunda.
--
-- ⚠ LEE ESTO ANTES DE ACTIVARLO
-- ─────────────────────────────
-- Esto son fotos del cuerpo de tus clientes. Es el dato más sensible que va
-- a haber en toda la app, y no se parece a un peso o a una serie:
--
--   · El bucket es PRIVADO. No hay ninguna URL que funcione sin firmar.
--   · Nadie ve las fotos de nadie: cada cliente ve las suyas y tú ves las de
--     tus clientes. No hay pantalla que las liste todas juntas.
--   · Los enlaces para verlas caducan en 5 minutos. Si alguien copia uno y
--     lo manda por WhatsApp, a los 5 minutos no abre.
--   · Cuando borras un cliente, sus fotos se borran con él (`on delete
--     cascade`) — pero el archivo del bucket hay que borrarlo aparte, y eso
--     lo hace la app cuando el cliente borra la foto. Si borras un cliente
--     desde el SQL, los archivos quedan huérfanos: al final de este archivo
--     está la consulta para encontrarlos.
--
-- Díselo a tus clientes antes de pedirles la primera foto. Que sepan dónde
-- quedan, quién las ve y que pueden borrarlas cuando quieran.
-- ════════════════════════════════════════════════════════════════════════

begin;

-- ---- 1. El bucket, privado ----
-- `public = false` es lo único que impide que la URL directa abra el archivo
-- para cualquiera que la tenga. No lo cambies.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('progreso', 'progreso', false, 10485760,
        array['image/jpeg','image/png','image/webp','image/heic'])
on conflict (id) do update
  set public = false,                       -- por si alguna vez se abrió
      file_size_limit = 10485760,
      allowed_mime_types = array['image/jpeg','image/png','image/webp','image/heic'];

-- ---- 2. La tabla ----
create table if not exists fotos_progreso (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid,                                   -- el coach
  cliente_id  uuid not null references clientes(id) on delete cascade,
  fecha       date not null default current_date,
  -- Las tres de siempre. Comparar una foto de frente con una de lado no dice
  -- nada, así que la pose se guarda para poder emparejarlas.
  pose        text not null default 'frente'
              check (pose in ('frente', 'lado', 'espalda', 'otra')),
  ruta        text not null unique,                   -- la ruta dentro del bucket
  peso_kg     numeric,
  nota        text,
  created_at  timestamptz not null default now()
);

comment on table fotos_progreso is
  'Fotos de progreso. El archivo vive en el bucket privado `progreso`; aquí solo la ruta.';
comment on column fotos_progreso.ruta is
  'Ruta dentro del bucket. Nunca se le da al navegador tal cual: siempre firmada y con caducidad.';

create index if not exists fotos_progreso_cliente_idx
  on fotos_progreso (cliente_id, fecha desc);

-- ---- 3. Quién puede leerlas ----
-- La app del cliente entra por /api/training con la service_role key, que se
-- salta RLS: ahí el candado es que el endpoint acota TODO al cliente_id de
-- quien pregunta. Estas políticas son para el CRM, que entra como tú.
alter table fotos_progreso enable row level security;

drop policy if exists fotos_progreso_coach on fotos_progreso;
create policy fotos_progreso_coach on fotos_progreso
  for all
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

commit;

-- ════════════════════════════════════════════════════════════════════════
-- PARA DESPUÉS
-- ════════════════════════════════════════════════════════════════════════
-- Cuántas fotos tiene cada cliente:
--
--   select c.nombre, count(*) as fotos, min(f.fecha) as primera, max(f.fecha) as ultima
--     from fotos_progreso f join clientes c on c.id = f.cliente_id
--    group by c.nombre order by c.nombre;
--
-- Archivos huérfanos en el bucket (quedan si borras un cliente desde el SQL
-- en vez de desde la app). Hay que borrarlos a mano desde Storage:
--
--   select o.name
--     from storage.objects o
--    where o.bucket_id = 'progreso'
--      and not exists (select 1 from fotos_progreso f where f.ruta = o.name);
--
-- Para borrarle TODAS las fotos a un cliente (la app borra también el
-- archivo; esto solo borra la fila, así que úsalo con la consulta de arriba):
--
--   delete from fotos_progreso
--    where cliente_id = (select id from clientes where nombre ilike '%nombre%');
-- ════════════════════════════════════════════════════════════════════════

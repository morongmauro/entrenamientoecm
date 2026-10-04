-- ================================================================
-- MIGRACIÓN · Comunidad (visual nueva)
-- ================================================================
-- Dónde se corre: Supabase del CRM → SQL Editor → pegar todo → Run.
-- Es idempotente: correrlo dos veces no rompe nada ni duplica nada.
--
-- Solo el coach publica (desde el CRM); los clientes leen en su app,
-- reaccionan con un toque y comentan. Los comentarios los leen todos los del
-- programa, pero solo le avisan al coach (a nadie más le llega nada). El
-- coach puede responder, editar lo suyo y borrar el comentario que no le
-- guste.
--
--   comunidad_posts        — lo que publica el coach (texto, y si quiere una
--                            imagen o un enlace). Se puede fijar arriba.
--   comunidad_reacciones   — quién reaccionó a qué (una por tipo y persona).
--   comunidad_vistas       — quién lo vio (para el alcance en el CRM).
--   comunidad_comentarios  — lo que comentan (cliente_id) o responde el
--                            coach (cliente_id vacío). Borrar = borrado_en.
--
-- Si ya la habías corrido antes, córrela otra vez: agrega lo nuevo
-- (comentarios y la edición) sin tocar lo que ya hay.
--
-- Los clientes leen y escriben a través de la API de la app (service_role);
-- el coach, desde el CRM, ve y borra lo suyo.
-- ================================================================

create table if not exists comunidad_posts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  texto text not null check (length(trim(texto)) > 0),
  imagen_url text,
  enlace_url text,
  fijado boolean not null default false,
  publicado_en timestamptz not null default now(),
  editado_en timestamptz,
  borrado_en timestamptz
);
alter table comunidad_posts add column if not exists editado_en timestamptz;
create index if not exists comunidad_posts_coach_idx on comunidad_posts (user_id, publicado_en desc);

create table if not exists comunidad_reacciones (
  post_id uuid not null references comunidad_posts(id) on delete cascade,
  cliente_id uuid not null references clientes(id) on delete cascade,
  tipo text not null check (tipo in ('fuego', 'fuerza', 'aplauso', 'corazon')),
  creado_en timestamptz not null default now(),
  primary key (post_id, cliente_id, tipo)
);

create table if not exists comunidad_vistas (
  post_id uuid not null references comunidad_posts(id) on delete cascade,
  cliente_id uuid not null references clientes(id) on delete cascade,
  visto_en timestamptz not null default now(),
  primary key (post_id, cliente_id)
);

create table if not exists comunidad_comentarios (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references comunidad_posts(id) on delete cascade,
  cliente_id uuid references clientes(id) on delete cascade,   -- vacío = el coach
  texto text not null check (length(trim(texto)) between 1 and 600),
  creado_en timestamptz not null default now(),
  borrado_en timestamptz
);
create index if not exists comunidad_comentarios_post_idx on comunidad_comentarios (post_id, creado_en);

alter table comunidad_posts enable row level security;
alter table comunidad_comentarios enable row level security;
alter table comunidad_reacciones enable row level security;
alter table comunidad_vistas enable row level security;

drop policy if exists comunidad_posts_propios on comunidad_posts;
create policy comunidad_posts_propios on comunidad_posts for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- El coach ve las reacciones y vistas de SUS publicaciones (no las escribe).
drop policy if exists comunidad_reacciones_coach on comunidad_reacciones;
create policy comunidad_reacciones_coach on comunidad_reacciones for select
  using (exists (select 1 from comunidad_posts p where p.id = post_id and p.user_id = auth.uid()));
drop policy if exists comunidad_vistas_coach on comunidad_vistas;
create policy comunidad_vistas_coach on comunidad_vistas for select
  using (exists (select 1 from comunidad_posts p where p.id = post_id and p.user_id = auth.uid()));

-- Comentarios: el coach ve los de SUS publicaciones, responde como coach
-- (sin cliente) y borra cualquiera (marcándolo borrado). Los clientes
-- comentan a través de la API de la app.
drop policy if exists comunidad_comentarios_ver on comunidad_comentarios;
create policy comunidad_comentarios_ver on comunidad_comentarios for select
  using (exists (select 1 from comunidad_posts p where p.id = post_id and p.user_id = auth.uid()));
drop policy if exists comunidad_comentarios_responder on comunidad_comentarios;
create policy comunidad_comentarios_responder on comunidad_comentarios for insert
  with check (cliente_id is null and exists (select 1 from comunidad_posts p where p.id = post_id and p.user_id = auth.uid()));
drop policy if exists comunidad_comentarios_moderar on comunidad_comentarios;
create policy comunidad_comentarios_moderar on comunidad_comentarios for update
  using (exists (select 1 from comunidad_posts p where p.id = post_id and p.user_id = auth.uid()))
  with check (exists (select 1 from comunidad_posts p where p.id = post_id and p.user_id = auth.uid()));

-- Revisión: debe decir «comunidad lista».
select case when to_regclass('public.comunidad_posts') is not null
             and to_regclass('public.comunidad_reacciones') is not null
             and to_regclass('public.comunidad_vistas') is not null
             and to_regclass('public.comunidad_comentarios') is not null
       then 'comunidad lista' else 'FALTA algo' end as estado;

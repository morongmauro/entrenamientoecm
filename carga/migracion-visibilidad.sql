-- ═══════════════════════════════════════════════════════════════════════
-- VISIBILIDAD: "enviar al cliente"
-- ═══════════════════════════════════════════════════════════════════════
--
-- El problema: hasta ahora una fase podía estar en `borrador` o `activa`,
-- pero eso es su ESTADO DE TRABAJO, no una decisión de publicación. Hacen
-- falta las dos cosas por separado: una rutina puede estar activa y aún así
-- no querer que el cliente la vea (la estás ajustando), y al revés, una fase
-- ya enviada sigue enviada aunque la marques como finalizada.
--
-- Esto añade el interruptor explícito: `visible_cliente`. Arranca en FALSE,
-- así que todo lo que ya existe y todo lo que se cargue queda invisible
-- hasta que tú le des a "Enviar al cliente".
--
-- Se puede correr dos veces sin problema.
-- ═══════════════════════════════════════════════════════════════════════

begin;

alter table fases
  add column if not exists visible_cliente boolean not null default false,
  add column if not exists publicada_en    timestamptz,
  add column if not exists publicada_por   uuid references auth.users on delete set null;

comment on column fases.visible_cliente is
  'true = el cliente ve esta fase y sus rutinas en su app. Lo enciende el botón "Enviar al cliente" del CRM, nunca se enciende solo.';
comment on column fases.publicada_en is
  'Cuándo se envió por primera vez. Se conserva aunque luego se oculte, para saber desde cuándo la tiene.';

-- Una rutina suelta también puede ocultarse dentro de una fase ya enviada
-- (p. ej. el día 4 todavía a medias). NULL = hereda lo que diga la fase.
alter table rutinas
  add column if not exists visible_cliente boolean;

comment on column rutinas.visible_cliente is
  'NULL = hereda de la fase (lo normal). false = ocultar SOLO esta rutina aunque la fase esté enviada. true = mostrarla aunque la fase no lo esté.';

create index if not exists fases_visibles_idx on fases (cliente_id, visible_cliente);

-- ── Lo que debe leer la app del cliente ─────────────────────────────────
-- Una sola fuente de verdad: si la app consulta esta vista, es imposible
-- que se le escape una rutina en borrador. NO incluye `notas_coach` ni de
-- la fase ni de la rutina ni de los ejercicios: eso no sale de aquí.
create or replace view rutinas_visibles as
  select r.id, r.cliente_id, r.fase_id, r.nombre, r.descripcion,
         r.dia_orden, r.dia_semana, r.duracion_estimada_min, r.tipo_sesion,
         f.nombre       as fase_nombre,
         f.fecha_inicio as fase_inicio,
         f.semanas      as fase_semanas,
         f.publicada_en
    from rutinas r
    join fases f on f.id = r.fase_id
   where coalesce(r.visible_cliente, f.visible_cliente) = true
     and r.archivada = false
     and f.estado <> 'archivada';

-- ── Enviar / retirar en una sola llamada ────────────────────────────────
-- Devuelve cuántas rutinas quedan visibles para el cliente, que es lo que
-- el CRM enseña en el aviso de confirmación.
create or replace function publicar_fase(p_fase_id uuid, p_visible boolean default true)
returns int language plpgsql security invoker as $$
declare v_n int;
begin
  update fases
     set visible_cliente = p_visible,
         -- la primera publicación deja fecha; retirar y volver a enviar no la pisa
         publicada_en  = case when p_visible and publicada_en is null then now() else publicada_en end,
         publicada_por = case when p_visible then auth.uid() else publicada_por end,
         -- enviar una fase que seguía en borrador la pasa a activa: si el
         -- cliente ya la está viendo, "borrador" dejó de ser verdad
         estado = case when p_visible and estado = 'borrador' then 'activa' else estado end,
         updated_at = now()
   where id = p_fase_id;

  if not found then
    raise exception 'No existe la fase % (o no es tuya).', p_fase_id;
  end if;

  select count(*) into v_n from rutinas_visibles where fase_id = p_fase_id;
  return v_n;
end $$;

commit;

-- ── COMPROBACIÓN ────────────────────────────────────────────────────────
--   select c.nombre, f.nombre, f.estado, f.visible_cliente, f.publicada_en,
--          (select count(*) from rutinas_visibles v where v.fase_id = f.id) as rutinas_visibles
--     from fases f join clientes c on c.id = f.cliente_id
--    order by c.nombre;

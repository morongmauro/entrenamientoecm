-- ═══════════════════════════════════════════════════════════════════════
-- FIN DE CICLO · composición corporal y registro fotográfico, para todos
-- ═══════════════════════════════════════════════════════════════════════
-- Dónde: Supabase del CRM → SQL Editor → pegar todo → Run. Se puede correr
-- dos veces.
--
-- El PRIMER DÍA DE LA ÚLTIMA SEMANA de cada ciclo, en el calendario de cada
-- cliente (lo ven él y tú):
--   · «Actualizar composición corporal»   (peso y % de grasa o medidas)
--   · «Registro fotográfico»               (frente, perfil y espalda)
-- En su app le sale en «Hoy te toca» / «También hoy» con su botón, y en
-- RECORDATORIOS del Dash queda activo HASTA QUE REGISTRE su composición.
--
-- QUÉ HACE
--   1. Añade `eventos.auto` (vacío en todos los eventos que ya hay: ninguno
--      cambia). Marca los que pone el sistema: 'cierre_composicion' y
--      'cierre_fotos'.
--   2. Los crea YA en los ciclos activos y en borrador (con fecha de inicio
--      y semanas). Los ciclos finalizados no se tocan.
--   3. Para los ciclos nuevos (o si les cambias la fecha o las semanas) se
--      crean o se corren solos.
--
-- NO borra ni cambia ningún evento, registro, medición ni foto del cliente.
-- ═══════════════════════════════════════════════════════════════════════

begin;

-- 1. La marca.
alter table eventos add column if not exists auto text;
comment on column eventos.auto is
  'Lo puso el sistema: cierre_composicion | cierre_fotos (primer día de la última semana del ciclo). NULL = lo puso el coach.';
create unique index if not exists eventos_auto_un on eventos (fase_id, auto) where auto is not null;

-- 2 y 3. Una función que deja los dos de un ciclo en su fecha.
create or replace function eventos_cierre_ciclo(p_fase fases) returns void
language plpgsql
as $$
declare f date;
begin
  if p_fase.cliente_id is null or p_fase.fecha_inicio is null or coalesce(p_fase.semanas, 0) < 1 then return; end if;
  f := p_fase.fecha_inicio + ((p_fase.semanas - 1) * 7);
  insert into eventos (user_id, cliente_id, fase_id, tipo, titulo, detalle, fecha, dias_semana, visible_cliente, auto)
  values
    (p_fase.user_id, p_fase.cliente_id, p_fase.id, 'medidas', 'Actualizar composición corporal',
     'Última semana del ciclo: registra tu peso y % de grasa (o tus medidas).', f, '{}', null, 'cierre_composicion'),
    (p_fase.user_id, p_fase.cliente_id, p_fase.id, 'fotos', 'Registro fotográfico',
     'Última semana del ciclo: frente, perfil y espalda.', f, '{}', null, 'cierre_fotos')
  on conflict (fase_id, auto) where auto is not null
  do update set fecha = excluded.fecha, updated_at = now();
end;
$$;

create or replace function fases_cierre_ciclo() returns trigger
language plpgsql
as $$
begin
  perform eventos_cierre_ciclo(new);
  return new;
end;
$$;

drop trigger if exists fases_cierre_ciclo on fases;
create trigger fases_cierre_ciclo
  after insert or update of fecha_inicio, semanas, cliente_id on fases
  for each row execute function fases_cierre_ciclo();

-- Los ciclos de hoy (activos y en borrador).
select eventos_cierre_ciclo(f) from fases f
 where f.estado in ('activa', 'borrador') and f.cliente_id is not null
   and f.fecha_inicio is not null and coalesce(f.semanas, 0) >= 1;

commit;

-- Cómo quedó: un renglón por ciclo, con su fecha de cierre.
select c.nombre as cliente, f.nombre as ciclo, f.estado, e.fecha as cierre, string_agg(e.titulo, ' + ' order by e.titulo) as que
  from eventos e join fases f on f.id = e.fase_id join clientes c on c.id = e.cliente_id
 where e.auto in ('cierre_composicion', 'cierre_fotos')
 group by c.nombre, f.nombre, f.estado, e.fecha
 order by e.fecha, c.nombre;

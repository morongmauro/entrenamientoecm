-- ═══════════════════════════════════════════════════════════════════════
-- SANTIAGO F · «Elbow Recovery» como bloque complementario, todos los días
-- ═══════════════════════════════════════════════════════════════════════
-- Dónde: Supabase del CRM → SQL Editor → pegar todo → Run. DESPUÉS de
-- migracion-bloques-complementarios.sql (y de santiago-elbow-recovery.sql).
-- Se puede correr dos veces.
--
-- Qué hace: marca su rutina «Elbow Recovery» como bloque complementario y
-- la pone de lunes a domingo. En su app sale TODOS los días debajo de su
-- rutina de fuerza («También hoy»), y los días sin fuerza sale sola. No
-- cuenta como día de fuerza en su Dash.
--
-- No toca sus rutinas de fuerza, sus días, sus sesiones ni sus series.
-- ═══════════════════════════════════════════════════════════════════════

begin;

do $sf$
declare n int;
begin
  if not exists (select 1 from information_schema.columns where table_name = 'rutinas' and column_name = 'complementaria') then
    raise exception 'Falta correr antes migracion-bloques-complementarios.sql.';
  end if;
  update rutinas r
     set complementaria = true, dias_semana = array['L','M','X','J','V','S','D'], dia_semana = null, updated_at = now()
    from clientes c
   where c.id = r.cliente_id and c.nombre ilike '%santiago f%'
     and r.nombre = 'Elbow Recovery' and not r.archivada;
  get diagnostics n = row_count;
  if n = 0 then raise exception 'No encuentro la rutina «Elbow Recovery» de Santiago F: corre antes santiago-elbow-recovery.sql.'; end if;
  raise notice 'Elbow Recovery: bloque complementario de lunes a domingo (% rutina).', n;
end $sf$;

-- Cómo quedó: su semana (la fuerza y el bloque).
select r.nombre, r.complementaria as bloque, r.dias_semana as dias, f.nombre as ciclo
  from rutinas r
  join fases f on f.id = r.fase_id
  join clientes c on c.id = r.cliente_id
 where c.nombre ilike '%santiago f%' and not r.archivada and f.id = (
   select id from fases where cliente_id = c.id
    order by (estado = 'activa' and coalesce(visible_cliente, false)) desc, (estado = 'activa') desc, orden desc nulls last, created_at desc limit 1)
 order by r.complementaria, r.dia_orden;

commit;

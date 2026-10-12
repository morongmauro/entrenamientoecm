-- ═══════════════════════════════════════════════════════════════════════
-- EVENTOS · quitar o mover UN día de una actividad que se repite
-- ═══════════════════════════════════════════════════════════════════════
-- Dónde: Supabase del CRM → SQL Editor → pegar todo → Run. Se puede correr
-- dos veces.
--
-- «Caminata de lunes a domingo, pero el jueves no.» Hasta ahora, a una
-- actividad que se repite solo se le podía borrar la serie entera, y borrar
-- la fila se llevaba también lo que el cliente ya había marcado como hecho.
-- Esto añade la lista de días QUITADOS: el evento sigue siendo uno solo, con
-- sus marcas, y simplemente deja de caer en esos días.
--
-- QUÉ HACE
--   1. Añade `eventos.fechas_excluidas` (vacía en todos: no cambia nada de
--      lo que ya hay hasta que quites un día desde el CRM).
--   2. Actualiza `evento_fechas()` para que no devuelva esos días.
--
-- NO borra ni cambia ningún evento ni ninguna marca del cliente.
-- ═══════════════════════════════════════════════════════════════════════

begin;

alter table eventos add column if not exists fechas_excluidas date[] not null default '{}';

comment on column eventos.fechas_excluidas is
  'Días en que un evento que se repite NO cae (los quitaste o los moviste desde el CRM). El CRM, la app y evento_fechas() los saltan.';

create or replace function evento_fechas(p_evento_id uuid)
returns table (fecha date)
language sql stable as $$
  with e as (select * from eventos where id = p_evento_id),
       f as (select fa.fecha_inicio, fa.semanas
               from fases fa join e on fa.id = e.fase_id)
  -- caso 1: día suelto
  select e.fecha from e where e.fecha is not null
  union all
  -- caso 2: se repite dentro de la fase, menos los días quitados
  select (f.fecha_inicio + (s.n - 1) * 7 + d.off)::date
    from e
    join f on true
    cross join generate_series(1, coalesce(f.semanas, 0)) as s(n)
    cross join lateral (
      select case dia
               when 'L' then 0 when 'M' then 1 when 'X' then 2 when 'J' then 3
               when 'V' then 4 when 'S' then 5 when 'D' then 6 end as off
        from unnest(e.dias_semana) as dia
    ) d
   where e.fecha is null
     and f.fecha_inicio is not null
     and d.off is not null
     and (e.semanas is null or s.n = any(e.semanas))
     and not ((f.fecha_inicio + (s.n - 1) * 7 + d.off)::date = any(coalesce(e.fechas_excluidas, '{}')));
$$;

commit;

-- Comprobar:  select column_name from information_schema.columns
--              where table_name = 'eventos' and column_name = 'fechas_excluidas';

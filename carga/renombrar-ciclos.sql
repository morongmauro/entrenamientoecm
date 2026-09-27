-- ════════════════════════════════════════════════════════════════════════
-- «CYCLE» → «CICLO» en los nombres de las fases
-- ════════════════════════════════════════════════════════════════════════
-- Dónde: Supabase del CRM → SQL Editor → pegar todo → Run.
-- Las fases que vinieron de Trainerize se llaman «Cycle 1», «Cycle 2»… Esto
-- las deja en español («Ciclo 1», «Ciclo 2»), en el CRM y en la app. La app
-- ya lo muestra así aunque no lo corras; esto lo deja bien también en la base.
-- Idempotente: la segunda vez no encuentra nada que cambiar.
-- ════════════════════════════════════════════════════════════════════════
begin;

update fases
   set nombre = regexp_replace(nombre, '\mcycle\M', 'Ciclo', 'gi')
 where nombre ~* '\mcycle\M';

select nombre, count(*) as fases from fases where nombre ~* '\mciclo\M' group by nombre order by nombre;

commit;

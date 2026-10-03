-- ════════════════════════════════════════════════════════════════════════
-- QUITAR «Bloque importado de Trainerize…» DEL OBJETIVO DE LAS FASES
-- ════════════════════════════════════════════════════════════════════════
-- Dónde: Supabase del CRM → SQL Editor → pegar todo → Run.
-- Al pasar las rutinas, cada fase quedó con el objetivo «Bloque importado de
-- Trainerize — la rutina que ya venía haciendo.», y el cliente lo veía en
-- Entrenamiento. Esto lo borra (queda vacío; si quieres, escribe tú el
-- objetivo real desde el CRM). La nota interna del coach (notas_coach) no se
-- toca: esa el cliente nunca la ve.
-- La app ya no muestra ese texto aunque no lo corras; esto lo deja limpio
-- también en el CRM. Idempotente.
-- ════════════════════════════════════════════════════════════════════════
begin;

update fases
   set objetivo = null
 where objetivo ~* '(trainerize|importad)';

select count(*) as fases_que_aun_lo_dicen from fases where objetivo ~* '(trainerize|importad)';

commit;

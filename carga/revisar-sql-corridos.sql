-- ¿Qué SQL ya corrí? Pegar en Supabase (CRM) → SQL Editor → Run. Solo lee, no cambia nada.
-- Cada columna dice «sí» si ese archivo ya está aplicado, o «FALTA».
select
  case when exists (select 1 from ejercicios where video_ref = 'qCPB3h2U1eY') then 'sí' else 'FALTA' end as "1 · videos Proet/Central",
  case when exists (select 1 from information_schema.columns where table_name = 'ejercicios' and column_name = 'busqueda') then 'sí' else 'FALTA' end as "2 · nombres inglés/español",
  case when not exists (select 1 from fases where objetivo ~* '(trainerize|importad)') then 'sí' else 'FALTA' end as "3 · sin «importado de Trainerize»",
  case when not exists (select 1 from fases where nombre ~* '\mcycle\M') then 'sí' else 'FALTA' end as "4 · «Cycle» → «Ciclo»";

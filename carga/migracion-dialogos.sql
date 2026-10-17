-- ════════════════════════════════════════════════════════════════════════
-- DIÁLOGOS · «Cómo le digo» y tus plantillas editadas
-- ════════════════════════════════════════════════════════════════════════
-- Dónde: Supabase del CRM → SQL Editor → pegar todo → Run.
-- Solo agrega dos columnas. No borra ni cambia nada. Se puede correr dos veces.
--
--   clientes.trato     → cómo le dices a cada cliente («Andre», «Juanse»).
--                        Sale en los diálogos de WhatsApp. Vacío = su primer
--                        nombre.
--   settings.dialogos  → los diálogos que edites o crees en el CRM.
--                        Sin esta columna la galería funciona igual, solo que
--                        sin guardar tus cambios.
-- ════════════════════════════════════════════════════════════════════════
alter table clientes add column if not exists trato text;
alter table settings add column if not exists dialogos jsonb;

select
  (select count(*) from information_schema.columns where table_name = 'clientes' and column_name = 'trato')    as columna_trato,
  (select count(*) from information_schema.columns where table_name = 'settings' and column_name = 'dialogos') as columna_dialogos;

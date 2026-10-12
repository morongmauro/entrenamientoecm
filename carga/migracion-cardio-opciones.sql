-- ═══════════════════════════════════════════════════════════════════════
-- CARDIO A ELEGIR · «caminadora trotando o con inclinación o bicicleta»
-- ═══════════════════════════════════════════════════════════════════════
-- Dónde: Supabase del CRM → SQL Editor → pegar todo → Run. Se puede correr
-- dos veces.
--
-- En el CRM, al poner una actividad («Cardio después de entrenar»), puedes
-- marcar «Varias opciones · el cliente elige una»: las opciones, los tiempos
-- sugeridos (10, 15, 20, 25 o 30 min) y la intensidad (moderada). En la app
-- el cliente las ve una al lado de la otra con «o» entre ellas y, al marcar
-- «Ya lo hice», toca cuál hizo y cuánto tiempo.
--
-- QUÉ HACE: añade la columna `eventos.opciones` (vacía en todos los eventos
-- que ya hay: ninguno cambia).
--   { "lista": ["Caminadora trotando", "Caminadora caminando con inclinación", "Bicicleta"],
--     "minutos": [10, 15, 20, 25, 30], "intensidad": "moderada" }
--
-- NO borra ni cambia ningún evento, actividad ni registro del cliente.
-- Sin este SQL el CRM guarda lo mismo en el detalle, en palabras.
-- ═══════════════════════════════════════════════════════════════════════

begin;

alter table eventos add column if not exists opciones jsonb;

comment on column eventos.opciones is
  'Cardio a elegir: { lista: [opciones], minutos: [sugeridos], intensidad: suave|moderada|alta }. El cliente hace UNA.';

commit;

-- Comprobar:  select count(*) from eventos where opciones is not null;   -- 0

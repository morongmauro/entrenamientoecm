-- Tiempos reales del entreno: la hora en que el cliente marcó cada serie en
-- su teléfono (aunque haya subido después, sin señal). Con eso el CRM muestra
-- cuánto tardó en cada ejercicio, en los descansos y en la rutina entera.
-- Solo AGREGA una columna vacía. No borra ni cambia nada de lo que ya hay.
alter table series_log add column if not exists marcada_en timestamptz;

-- Comprobación: debe salir 1.
select count(*) as columna_marcada_en
from information_schema.columns
where table_name = 'series_log' and column_name = 'marcada_en';

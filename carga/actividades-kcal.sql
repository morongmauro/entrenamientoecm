-- Calorías de una actividad (opcional): las que marcó el reloj del cliente.
-- Se puede correr más de una vez; no borra nada.
alter table public.actividades add column if not exists kcal integer;

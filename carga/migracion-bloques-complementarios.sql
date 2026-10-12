-- ═══════════════════════════════════════════════════════════════════════
-- BLOQUES COMPLEMENTARIOS · varias rutinas el mismo día
-- ═══════════════════════════════════════════════════════════════════════
-- Dónde: Supabase del CRM → SQL Editor → pegar todo → Run. Se puede correr
-- dos veces.
--
-- Un recovery, una movilidad diaria, algo especial («Elbow Recovery» de
-- Santiago): una rutina APARTE que va el mismo día que la fuerza, sin tener
-- que ver con ella. Se marca en el constructor del CRM («Bloque
-- complementario») y se le eligen sus días.
--
-- En la app del cliente:
--   · la rutina de fuerza del día sigue siendo la protagonista: va primero
--     y es la que abre «Hoy te toca»;
--   · el bloque sale DEBAJO, más chico («También hoy»), en Hoy te toca, en
--     Tu semana y en el Calendario;
--   · un bloque hecho no cuenta como día de fuerza en el Dash (si no, un
--     recovery diario volvería el «3 de 3» un «10 de 3») ni como «ya
--     entrenaste hoy» en el aviso de la noche.
--
-- QUÉ HACE
--   1. Añade `rutinas.complementaria` (false para TODAS las que ya hay: nada
--      de lo de hoy cambia).
--   2. Que las copias (copiar ciclo, traer de otro cliente, duplicar) se
--      lleven la marca: la copia la hereda de la rutina de la que salió.
--
-- NO borra ni cambia ninguna rutina, sesión, serie ni marca del cliente.
-- Sin este SQL todo sigue funcionando como antes.
-- ═══════════════════════════════════════════════════════════════════════

begin;

-- 1. La marca.
alter table rutinas add column if not exists complementaria boolean not null default false;

comment on column rutinas.complementaria is
  'Bloque complementario (recovery, movilidad, algo especial): va el mismo día que la fuerza, debajo de ella, en los días de dias_semana. No ocupa el día de la fuerza.';

-- 2. Las copias se la llevan. copiar_rutina (y con ella copiar_fase y
--    duplicar_rutina) apunta `origen_rutina_id` a la original: de ahí sale.
create or replace function rutinas_hereda_complementaria() returns trigger
language plpgsql
as $$
begin
  if new.origen_rutina_id is not null and not coalesce(new.complementaria, false) then
    select coalesce(o.complementaria, false) into new.complementaria
      from rutinas o where o.id = new.origen_rutina_id;
    new.complementaria := coalesce(new.complementaria, false);
  end if;
  return new;
end;
$$;

drop trigger if exists rutinas_hereda_complementaria on rutinas;
create trigger rutinas_hereda_complementaria
  before insert on rutinas
  for each row execute function rutinas_hereda_complementaria();

commit;

-- Comprobar:
--   select complementaria, count(*) from rutinas group by complementaria;   -- todo false

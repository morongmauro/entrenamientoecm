-- ═══════════════════════════════════════════════════════════════════════════
-- VIDEOS PROTEGIDOS: lo que el coach elige en el CRM no lo pisa ningún SQL
-- ═══════════════════════════════════════════════════════════════════════════
-- Problema: algunos SQL de carga de videos (videos-proet.sql y
-- videos-proet-central.sql) REEMPLAZAN el video de un ejercicio cuando es
-- distinto al suyo. No sabían cuáles había elegido el coach a mano, así que
-- al volver a correrlos devolvían los videos viejos.
--
-- Solución, en la base de datos (así vale para cualquier SQL, viejo o nuevo):
--   · columna `video_elegido_at`: el CRM la llena cada vez que el coach elige
--     o cambia el video de un ejercicio;
--   · un guardián (trigger): si un ejercicio ya tiene video elegido y llega un
--     cambio de video que NO viene del CRM (no trae un `video_elegido_at`
--     nuevo), el video se queda como estaba. El resto de la fila sí se
--     actualiza (nombre, músculos, etc.).
--   · al correr esta migración, TODOS los videos que hoy están puestos quedan
--     protegidos: desde ahora solo se cambian desde el CRM. Los SQL de carga
--     solo pueden llenar ejercicios que no tienen video.
--
-- Se puede correr varias veces sin problema. Para soltar un video y dejar que
-- un SQL lo vuelva a llenar: update ejercicios set video_elegido_at = null
-- where id = '…';
-- ═══════════════════════════════════════════════════════════════════════════

alter table ejercicios add column if not exists video_elegido_at timestamptz;

-- Los videos que ya están puestos quedan protegidos desde ya.
update ejercicios
   set video_elegido_at = coalesce(updated_at, now())
 where video_elegido_at is null
   and coalesce(video_fuente, 'ninguno') <> 'ninguno';

create or replace function proteger_video_elegido() returns trigger
language plpgsql as $$
begin
  -- Solo importa si ya había un video elegido y este cambio no lo trae
  -- el CRM (que siempre manda un video_elegido_at nuevo).
  if old.video_elegido_at is not null
     and new.video_elegido_at is not distinct from old.video_elegido_at
     and (new.video_fuente     is distinct from old.video_fuente
       or new.video_ref        is distinct from old.video_ref
       or new.video_url        is distinct from old.video_url
       or new.video_inicio_seg is distinct from old.video_inicio_seg
       or new.video_path       is distinct from old.video_path
       or new.poster_path      is distinct from old.poster_path) then
    new.video_fuente     := old.video_fuente;
    new.video_ref        := old.video_ref;
    new.video_url        := old.video_url;
    new.video_inicio_seg := old.video_inicio_seg;
    new.video_path       := old.video_path;
    new.poster_path      := old.poster_path;
  end if;
  return new;
end $$;

drop trigger if exists ejercicios_proteger_video on ejercicios;
create trigger ejercicios_proteger_video
  before update on ejercicios
  for each row execute function proteger_video_elegido();

-- Para revisar: cuántos videos quedaron protegidos.
select count(*) filter (where video_elegido_at is not null) as videos_protegidos,
       count(*) filter (where coalesce(video_fuente, 'ninguno') = 'ninguno') as sin_video
  from ejercicios;

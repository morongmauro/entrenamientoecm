-- ════════════════════════════════════════════════════════════════════════
-- DUPLICAR UN CICLO SIN PERDER LOS DÍAS
-- ════════════════════════════════════════════════════════════════════════
-- Dónde: Supabase del CRM → SQL Editor → pegar todo → Run. Es idempotente.
--
-- El arreglo: al copiar una fase (o una rutina), la copia salía SIN sus
-- días de la semana. `copiar_rutina` se escribió antes de que existiera
-- `rutinas.dias_semana` y solo copiaba el campo viejo de un solo día.
-- También se perdía el descanso entre ejercicios de los circuitos
-- (`rutina_bloques.descanso_entre_seg`).
--
-- Ahora la copia lleva los días TAL COMO TÚ LOS ARMASTE en el ciclo. Lo que
-- el cliente movió en su app (tabla `rutina_movimientos`) NO se copia: eso
-- lo analiza el CRM al duplicar y te pregunta si lo quieres aplicar.
-- ════════════════════════════════════════════════════════════════════════
begin;

create or replace function copiar_rutina(
  p_rutina_id uuid,
  p_destino_fase_id uuid default null,
  p_nombre_nuevo text default null
) returns uuid
language plpgsql
as $$
declare
  v_nueva_id uuid;
  v_cliente_id uuid;
  v_bloque record;
  v_mapa_bloques jsonb := '{}'::jsonb;
begin
  -- El cliente destino se deduce de la fase; si no hay fase, es plantilla.
  select cliente_id into v_cliente_id from fases where id = p_destino_fase_id;

  insert into rutinas (
    user_id, cliente_id, fase_id, nombre, descripcion, notas_coach,
    dia_orden, dia_semana, dias_semana, duracion_estimada_min, tipo_sesion, origen_rutina_id
  )
  select
    user_id, v_cliente_id, p_destino_fase_id,
    coalesce(p_nombre_nuevo, nombre), descripcion, notas_coach,
    dia_orden, dia_semana, dias_semana, duracion_estimada_min, tipo_sesion, id
  from rutinas where id = p_rutina_id
  returning id into v_nueva_id;

  if v_nueva_id is null then
    raise exception 'Rutina % no encontrada o sin permiso', p_rutina_id;
  end if;

  -- Bloques primero, guardando viejo_id → nuevo_id para reenganchar
  -- los ejercicios a SU bloque y no a otro.
  for v_bloque in
    select * from rutina_bloques where rutina_id = p_rutina_id order by orden
  loop
    declare v_bloque_nuevo uuid;
    begin
      insert into rutina_bloques (rutina_id, nombre, tipo, vueltas, descanso_seg, descanso_entre_seg, orden, notas)
      values (v_nueva_id, v_bloque.nombre, v_bloque.tipo, v_bloque.vueltas,
              v_bloque.descanso_seg, v_bloque.descanso_entre_seg, v_bloque.orden, v_bloque.notas)
      returning id into v_bloque_nuevo;
      v_mapa_bloques := v_mapa_bloques || jsonb_build_object(v_bloque.id::text, v_bloque_nuevo::text);
    end;
  end loop;

  insert into rutina_ejercicios (
    rutina_id, bloque_id, ejercicio_id, orden, series, reps, peso_objetivo,
    rir, tempo, descanso_seg, notas, notas_coach
  )
  select
    v_nueva_id,
    case when re.bloque_id is null then null
         else (v_mapa_bloques ->> re.bloque_id::text)::uuid end,
    re.ejercicio_id, re.orden, re.series, re.reps, re.peso_objetivo,
    re.rir, re.tempo, re.descanso_seg, re.notas, re.notas_coach
  from rutina_ejercicios re
  where re.rutina_id = p_rutina_id
  order by re.orden;

  return v_nueva_id;
end;
$$;

commit;

-- Para comprobarlo: duplica un ciclo en el CRM y mira que cada rutina
-- conserve sus días (L, X, V…) en la tarjeta de la fase nueva.

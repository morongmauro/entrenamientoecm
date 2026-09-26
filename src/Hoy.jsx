// ─────────────────────────────────────────────────────────────────────────
// HOY · y tu semana
//
// La pantalla que se abre primero. Una sola pregunta que responder: ¿qué me
// toca hoy? Todo lo demás está debajo.
//
// LA FUERZA MANDA. La rutina de hoy es la tarjeta grande, en oliva, con el
// botón. El cardio y los deportes de hoy van debajo en gris, tocables pero
// callados: si compiten por la atención, el cliente entra a marcar la
// caminata y se le olvida que tenía Push.
// ─────────────────────────────────────────────────────────────────────────
import React, { useEffect, useState } from 'react';
import { api, hoyLocal, DIAS_LARGO } from './datos.js';
import Actividad, { ChipActividad } from './Actividad.jsx';
import { Card, Boton, Chip, Titulo, Seccion, Cargando, Fallo, Vacio, Marca,
         ACCENT, ACCENT_DARK, ACCENT_LIGHT, SURFACE_2, BORDER, BORDER_SOFT,
         TEXT, TEXT_MUTED, TEXT_LIGHT, SUCCESS } from './ui.jsx';

export default function Hoy({ nombre, alEntrenar }) {
  const [plan, setPlan] = useState(null);
  const [mes, setMes] = useState(null);       // para la actividad de hoy
  const [error, setError] = useState(null);
  const [registrando, setRegistrando] = useState(false);

  const cargar = async () => {
    setError(null);
    const hoy = hoyLocal();
    const [p, m] = await Promise.all([api.plan(nombre), api.mes(nombre, hoy.slice(0, 7))]);
    if (!p.ok) { setError(p.motivo || 'error'); return; }
    setPlan(p);
    if (m.ok) setMes(m);
  };
  useEffect(() => { cargar(); /* eslint-disable-next-line */ }, [nombre]);

  if (error) return <Fallo motivo={error} alReintentar={cargar} />;
  if (!plan) return <Cargando />;

  const hoy = plan.dias?.find(d => d.es_hoy);
  const diaMes = mes?.dias?.find(d => d.fecha === plan.hoy);
  const actividadesHoy = diaMes?.actividades || [];
  const eventosHoy = diaMes?.eventos || [];

  return (
    <div>
      <Titulo>Hoy</Titulo>
      <div style={{ color: TEXT_MUTED, fontSize: 13.5, marginBottom: 2 }}>
        {hoy ? DIAS_LARGO[hoy.dia] : ''}
        {plan.fase?.semana_actual ? ` · semana ${plan.fase.semana_actual} de ${plan.fase.semanas}` : ''}
      </div>

      {/* ── La rutina de hoy: lo único que importa arriba ── */}
      {!plan.fase && (
        <Vacio
          icono="🗓"
          titulo="Todavía no tienes plan"
          texto="Cuando tu coach te envíe tu rutina, aparecerá aquí."
        />
      )}

      {plan.fase && hoy?.rutina && (
        <Card style={{
          marginTop: 14, background: ACCENT, color: '#fff',
          border: 'none', padding: 20,
        }}>
          <div style={{ fontSize: 11, fontWeight: 800, letterSpacing: '.09em', textTransform: 'uppercase', opacity: .8 }}>
            {hoy.hecha ? 'Ya lo hiciste' : hoy.en_curso ? 'Lo dejaste a medias' : 'Te toca'}
          </div>
          <div style={{ fontSize: 23, fontWeight: 800, lineHeight: 1.2, margin: '5px 0 3px' }}>
            {hoy.rutina.nombre}
          </div>
          <div style={{ fontSize: 13.5, opacity: .85 }}>
            {hoy.rutina.ejercicios} ejercicio{hoy.rutina.ejercicios === 1 ? '' : 's'}
            {hoy.rutina.minutos ? ` · unos ${hoy.rutina.minutos} min` : ''}
          </div>
          <div style={{ marginTop: 16 }}>
            <Boton ancho style={{ background: '#fff', color: ACCENT_DARK }}
                   onClick={() => alEntrenar(hoy.rutina.id)}>
              {hoy.hecha ? 'Ver lo que hiciste' : hoy.en_curso ? 'Seguir' : 'Empezar'}
            </Boton>
          </div>
        </Card>
      )}

      {plan.fase && hoy && !hoy.rutina && (
        <Card style={{ marginTop: 14, textAlign: 'center', padding: '26px 20px' }}>
          <div style={{ fontSize: 26, marginBottom: 6 }}>😌</div>
          <div style={{ fontWeight: 800, fontSize: 16 }}>Hoy descansas</div>
          <div style={{ fontSize: 13.5, color: TEXT_MUTED, marginTop: 4, lineHeight: 1.5 }}>
            Descansar es parte del plan. Si te mueves por tu cuenta, márcalo abajo.
          </div>
        </Card>
      )}

      {/* ── Lo complementario: presente, pero en voz baja ── */}
      <Seccion accion={
        <button onClick={() => setRegistrando(true)} style={{
          border: 'none', background: 'transparent', padding: 0, cursor: 'pointer',
          fontSize: 12.5, fontWeight: 700, color: ACCENT_DARK, fontFamily: 'inherit',
        }}>+ Registrar</button>
      }>Además de la fuerza</Seccion>

      {eventosHoy.length > 0 && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 6, marginBottom: 8 }}>
          {eventosHoy.map(ev => (
            <div key={ev.id} style={{
              display: 'flex', alignItems: 'center', gap: 8,
              border: `1px dashed ${BORDER}`, borderRadius: 12, padding: '9px 12px',
            }}>
              <span style={{ fontSize: 12.5, color: TEXT_MUTED, flex: 1 }}>
                {ev.hora ? <b>{String(ev.hora).slice(0, 5)} </b> : null}
                {ev.titulo}
              </span>
              <Chip tono="suave">de tu coach</Chip>
            </div>
          ))}
        </div>
      )}

      {actividadesHoy.length > 0 ? (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
          {actividadesHoy.map(a => <ChipActividad key={a.id} actividad={a} />)}
        </div>
      ) : (
        <button onClick={() => setRegistrando(true)} style={{
          width: '100%', border: `1px dashed ${BORDER}`, background: 'transparent',
          borderRadius: 14, padding: '14px 16px', cursor: 'pointer',
          color: TEXT_LIGHT, fontSize: 13, fontFamily: 'inherit', textAlign: 'left',
        }}>
          ¿Caminaste, nadaste, hiciste cardio? Márcalo aquí.
        </button>
      )}

      {/* ── Tu semana ── */}
      {plan.fase && (
        <>
          <Seccion>Tu semana</Seccion>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 7 }}>
            {plan.dias.map(d => <DiaSemana key={d.dia} dia={d} alEntrenar={alEntrenar} />)}
          </div>

          {plan.sueltas?.length > 0 && (
            <>
              <Seccion>Otras rutinas de tu plan</Seccion>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 7 }}>
                {plan.sueltas.map(r => (
                  <Card key={r.id} onClick={() => alEntrenar(r.id)} style={{ padding: '12px 14px' }}>
                    <b style={{ fontSize: 14 }}>{r.nombre}</b>
                    <div style={{ fontSize: 12.5, color: TEXT_LIGHT }}>{r.ejercicios} ejercicios</div>
                  </Card>
                ))}
              </div>
            </>
          )}
        </>
      )}

      <Actividad
        abierta={registrando}
        nombre={nombre}
        alCerrar={() => setRegistrando(false)}
        alGuardar={() => { setRegistrando(false); cargar(); }}
      />
    </div>
  );
}

function DiaSemana({ dia, alEntrenar }) {
  const esHoy = dia.es_hoy;
  return (
    <div
      onClick={dia.rutina ? () => alEntrenar(dia.rutina.id) : undefined}
      role={dia.rutina ? 'button' : undefined}
      style={{
        display: 'flex', alignItems: 'center', gap: 11,
        background: esHoy ? ACCENT_LIGHT : 'transparent',
        border: `1px solid ${esHoy ? ACCENT : BORDER_SOFT}`,
        borderRadius: 13, padding: '10px 13px',
        cursor: dia.rutina ? 'pointer' : 'default',
      }}>
      <div style={{
        width: 30, flexShrink: 0, textAlign: 'center',
        fontSize: 11, fontWeight: 800, letterSpacing: '.05em',
        color: esHoy ? ACCENT_DARK : TEXT_LIGHT,
      }}>{DIAS_LARGO[dia.dia].slice(0, 3).toUpperCase()}</div>

      <div style={{ flex: 1, minWidth: 0 }}>
        {dia.rutina ? (
          <>
            <div style={{ fontSize: 14, fontWeight: 700, color: TEXT, lineHeight: 1.3 }}>{dia.rutina.nombre}</div>
            <div style={{ fontSize: 11.5, color: TEXT_LIGHT }}>
              {dia.rutina.ejercicios} ejercicios{dia.rutina.minutos ? ` · ${dia.rutina.minutos} min` : ''}
            </div>
          </>
        ) : (
          <div style={{ fontSize: 13, color: TEXT_LIGHT }}>Descanso</div>
        )}
      </div>

      {dia.hecha && <Marca estado="completada" />}
      {!dia.hecha && dia.en_curso && <Marca estado="en_curso" />}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────────
// EJECUTAR LA RUTINA
//
// El flujo: Empezar → marcar cada serie → Terminar → ¿cómo te fue?
//
// TRES DECISIONES QUE SE NOTAN
//
// 1. Cada serie se guarda SOLA al marcarla, no al final. Nadie va a recordar
//    pulsar "guardar" después de una sentadilla pesada, y si la app se cierra
//    a mitad (una llamada, la pantalla que se bloquea) no se pierde nada: al
//    volver se retoma la misma sesión con lo ya marcado.
//
// 2. Los campos vienen PRE-LLENADOS con lo que levantó la última vez, no con
//    lo prescrito. Lo prescrito es "8-10 reps"; lo que de verdad sirve al
//    cargar la barra es "la semana pasada moviste 62,5". Si nunca lo ha
//    hecho, se usa el peso objetivo del coach.
//
// 3. Terminar pide el RPE, y se puede saltar. Obligar a puntuar el esfuerzo
//    para poder cerrar la sesión hace que la gente ponga cualquier número
//    con tal de salir — y un RPE inventado es peor que ninguno.
// ─────────────────────────────────────────────────────────────────────────
import React, { useEffect, useMemo, useState } from 'react';
import { api } from './datos.js';
import Ejercicio from './Ejercicio.jsx';
import Actividad from './Actividad.jsx';
import { Card, Boton, Chip, Hoja, Cargando, Fallo, Barra, Titulo,
         ACCENT, ACCENT_DARK, ACCENT_LIGHT, SURFACE, SURFACE_2, BORDER, BORDER_SOFT,
         TEXT, TEXT_MUTED, TEXT_LIGHT, SUCCESS } from './ui.jsx';
import { miniatura } from './datos.js';

export default function Ejecutar({ nombre, rutinaId, alSalir }) {
  const [datos, setDatos] = useState(null);
  const [error, setError] = useState(null);
  const [sesion, setSesion] = useState(null);
  const [series, setSeries] = useState({});     // `${reId}:${n}` → { reps, peso, guardada }
  const [abriendo, setAbriendo] = useState(false);
  const [ficha, setFicha] = useState(null);     // el ejercicio cuya hoja está abierta
  const [cerrando, setCerrando] = useState(false);
  const [remate, setRemate] = useState(false);  // registrar cardio al terminar

  const cargar = async () => {
    setError(null);
    const r = await api.rutina(nombre, rutinaId);
    if (!r.ok) { setError(r.motivo || 'error'); return; }
    setDatos(r);
  };
  useEffect(() => { cargar(); /* eslint-disable-next-line */ }, [rutinaId]);

  // Salir de la pantalla sin cerrar la sesión (el botón Volver, o cambiar de
  // sección) tiene que soltar la bandera. Si se quedara puesta, la app no
  // volvería a auto-actualizarse nunca más en ese teléfono.
  useEffect(() => () => {
    try { localStorage.removeItem('ecm:sesionEnCurso'); } catch (e) {}
  }, []);

  // ── Empezar ────────────────────────────────────────────────────────────
  const empezar = async () => {
    setAbriendo(true);
    const r = await api.abrir(nombre, rutinaId);
    setAbriendo(false);
    if (!r.ok) { setError(r.motivo || 'error'); return; }
    setSesion(r.sesion);
    // La bandera que main.jsx mira antes de auto-actualizar la app. Sin
    // ponerla, un deploy nuevo podía recargar el iframe a media sentadilla y
    // el cliente perdía lo que llevaba marcado. Se quita al cerrar.
    try { localStorage.setItem('ecm:sesionEnCurso', r.sesion?.id || '1'); } catch (e) {}
    // Al retomar, lo ya marcado vuelve a la pantalla tal como quedó.
    const previas = {};
    (r.series || []).forEach(s => {
      const re = s.rutina_ejercicio_id;
      if (!re) return;
      previas[`${re}:${s.serie_num}`] = {
        reps: s.reps ?? '', peso: s.peso ?? '', guardada: !!s.completada,
      };
    });
    setSeries(previas);
  };

  const marcar = async (item, n, valores) => {
    const clave = `${item.id}:${n}`;
    setSeries(s => ({ ...s, [clave]: { ...valores, guardando: true } }));
    const r = await api.serie(nombre, {
      sesion_id: sesion.id,
      rutina_ejercicio_id: item.id,
      ejercicio_id: item.ejercicio.id,
      serie_num: n,
      reps: valores.reps, peso: valores.peso,
      completada: true,
    });
    setSeries(s => ({ ...s, [clave]: { ...valores, guardada: r.ok, error: !r.ok } }));
  };

  const desmarcar = (item, n) => {
    const clave = `${item.id}:${n}`;
    setSeries(s => ({ ...s, [clave]: { ...(s[clave] || {}), guardada: false } }));
  };

  const ejercicios = datos?.rutina?.ejercicios || [];
  const totalSeries = useMemo(
    () => ejercicios.reduce((a, x) => a + (Number(x.series) || 0), 0), [ejercicios]);
  const hechas = useMemo(
    () => Object.values(series).filter(s => s.guardada).length, [series]);

  if (error) return <Fallo motivo={error} alReintentar={cargar} />;
  if (!datos) return <Cargando texto="Abriendo tu rutina…" />;

  const r = datos.rutina;
  const bloques = r.bloques || [];

  return (
    <div>
      <button onClick={alSalir} style={atras}>‹ Volver</button>
      <Titulo>{r.nombre}</Titulo>
      <div style={{ color: TEXT_MUTED, fontSize: 13.5, marginBottom: 4 }}>
        {ejercicios.length} ejercicio{ejercicios.length === 1 ? '' : 's'}
        {r.minutos ? ` · unos ${r.minutos} min` : ''}
      </div>
      {r.descripcion && (
        <p style={{ fontSize: 13.5, color: TEXT_MUTED, lineHeight: 1.55, margin: '8px 0 0' }}>{r.descripcion}</p>
      )}

      {/* ── Antes de empezar ── */}
      {!sesion && (
        <Card style={{ marginTop: 18, textAlign: 'center' }}>
          <div style={{ fontSize: 14, color: TEXT_MUTED, marginBottom: 12, lineHeight: 1.55 }}>
            Al empezar podrás ir marcando el peso y las repeticiones de cada serie.
          </div>
          <Boton ancho onClick={empezar} disabled={abriendo || !ejercicios.length}>
            {abriendo ? 'Abriendo…' : 'Empezar'}
          </Boton>
        </Card>
      )}

      {/* ── Progreso, mientras entrena ── */}
      {sesion && (
        <div style={{
          position: 'sticky', top: 0, zIndex: 20, background: SURFACE,
          borderRadius: 14, border: `1px solid ${BORDER}`, padding: '10px 14px',
          margin: '16px 0 4px',
        }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 12.5, marginBottom: 6 }}>
            <b>{hechas} de {totalSeries} series</b>
            <span style={{ color: TEXT_LIGHT }}>{totalSeries ? Math.round(hechas / totalSeries * 100) : 0}%</span>
          </div>
          <Barra valor={hechas} total={totalSeries} />
        </div>
      )}

      {/* ── Los ejercicios ── */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 12, marginTop: 16 }}>
        {ejercicios.map((item, i) => (
          <FilaEjercicio
            key={item.id}
            item={item} indice={i + 1}
            bloque={bloques.find(b => b.id === item.bloque_id)}
            enCurso={!!sesion}
            series={series}
            alMarcar={marcar}
            alDesmarcar={desmarcar}
            alAbrirFicha={() => setFicha(item)}
          />
        ))}
      </div>

      {/* ── Terminar ── */}
      {sesion && (
        <div style={{ marginTop: 20 }}>
          <Boton ancho variante="marca" onClick={() => setCerrando(true)}>
            Terminar entrenamiento
          </Boton>
        </div>
      )}

      <Ejercicio item={ficha} abierto={!!ficha} alCerrar={() => setFicha(null)} />

      <Cierre
        abierto={cerrando}
        alCerrar={() => setCerrando(false)}
        hechas={hechas}
        total={totalSeries}
        alConfirmar={async ({ rpe, notas, estado }) => {
          await api.cerrar(nombre, { sesion_id: sesion.id, rpe, notas, estado });
          try { localStorage.removeItem('ecm:sesionEnCurso'); } catch (e) {}
          setCerrando(false);
          // Justo al terminar la fuerza es cuando se hace la caminadora. Se
          // ofrece aquí, que es el único momento en que la persona lo tiene
          // en la mano; buscarlo después en otra pantalla no lo hace nadie.
          if (estado !== 'saltada') setRemate(true);
          else alSalir();
        }}
      />

      <Actividad
        abierta={remate}
        nombre={nombre}
        sesionId={sesion?.id}
        soloRemate
        titulo="¿Hiciste algo de cardio al terminar?"
        alCerrar={() => { setRemate(false); alSalir(); }}
        alGuardar={() => { setRemate(false); alSalir(); }}
      />
    </div>
  );
}

// ── Una fila de ejercicio, con sus series ───────────────────────────────
function FilaEjercicio({ item, indice, bloque, enCurso, series, alMarcar, alDesmarcar, alAbrirFicha }) {
  const e = item.ejercicio;
  const thumb = miniatura(e);
  const n = Number(item.series) || 0;

  // Lo que levantó la última vez manda sobre lo prescrito: es el número que
  // se mira al cargar la barra.
  const sugerido = (serie) => {
    const ult = item.ultima_vez?.series?.find(s => s.serie === serie);
    if (ult) return { reps: ult.reps ?? '', peso: ult.peso ?? '' };
    const pesoPlan = String(item.peso_objetivo || '').match(/[\d.,]+/);
    return { reps: '', peso: pesoPlan ? pesoPlan[0].replace(',', '.') : '' };
  };

  return (
    <Card style={{ padding: 0, overflow: 'hidden' }}>
      {bloque && (
        <div style={{
          background: '#EFEAF6', color: '#5B3FA0', fontSize: 11, fontWeight: 800,
          letterSpacing: '.06em', textTransform: 'uppercase', padding: '5px 14px',
        }}>
          {bloque.nombre || bloque.tipo}{bloque.vueltas ? ` · ${bloque.vueltas} vueltas` : ''}
        </div>
      )}

      <div style={{ display: 'flex', gap: 12, padding: 14, alignItems: 'flex-start' }}>
        {/* La miniatura del video es el botón para abrir la ficha: es lo que
            la gente toca cuando no se acuerda de un ejercicio. */}
        <button onClick={alAbrirFicha} aria-label={`Ver ${e.nombre}`} style={{
          flexShrink: 0, width: 74, height: 54, borderRadius: 10, overflow: 'hidden',
          border: 'none', padding: 0, cursor: 'pointer', background: SURFACE_2,
          position: 'relative', display: 'block',
        }}>
          {thumb
            ? <img src={thumb} alt="" loading="lazy" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
            : <span style={{ fontSize: 20, lineHeight: '54px', display: 'block', opacity: .5 }}>🏋️</span>}
          {thumb && (
            <span style={{
              position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center',
              background: 'rgba(31,31,31,0.22)', color: '#fff', fontSize: 15,
            }}>▶</span>
          )}
        </button>

        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontWeight: 800, fontSize: 14.5, lineHeight: 1.3 }}>
            {indice}. {e.nombre}
          </div>
          <div style={{ display: 'flex', gap: 5, flexWrap: 'wrap', marginTop: 5 }}>
            <Chip tono="marca">{item.series} × {item.reps || '—'}</Chip>
            {item.peso_objetivo && <Chip>{item.peso_objetivo}</Chip>}
            {item.descanso_seg != null && <Chip tono="suave">{item.descanso_seg}s</Chip>}
          </div>
          <button onClick={alAbrirFicha} style={{
            marginTop: 7, border: `1px solid ${BORDER}`, background: 'transparent',
            borderRadius: 999, padding: '3px 11px', fontSize: 11.5, fontWeight: 700,
            color: TEXT_MUTED, cursor: 'pointer', fontFamily: 'inherit',
          }}>Características</button>
        </div>
      </div>

      {item.notas && (
        <div style={{
          margin: '0 14px 12px', background: ACCENT_LIGHT, color: ACCENT_DARK,
          borderRadius: 10, padding: '8px 11px', fontSize: 12.5, lineHeight: 1.5,
        }}>{item.notas}</div>
      )}

      {enCurso && n > 0 && (
        <div style={{ borderTop: `1px solid ${BORDER_SOFT}`, padding: '10px 14px 14px' }}>
          {Array.from({ length: n }, (_, i) => i + 1).map(s => (
            <Serie
              key={s} num={s}
              estado={series[`${item.id}:${s}`]}
              sugerido={sugerido(s)}
              alMarcar={(v) => alMarcar(item, s, v)}
              alDesmarcar={() => alDesmarcar(item, s)}
            />
          ))}
        </div>
      )}
    </Card>
  );
}

// ── Una serie ────────────────────────────────────────────────────────────
function Serie({ num, estado, sugerido, alMarcar, alDesmarcar }) {
  const [peso, setPeso] = useState(estado?.peso ?? '');
  const [reps, setReps] = useState(estado?.reps ?? '');
  const guardada = !!estado?.guardada;

  // Al retomar una sesión, los valores llegan después del primer render.
  useEffect(() => {
    if (estado?.peso !== undefined) setPeso(estado.peso);
    if (estado?.reps !== undefined) setReps(estado.reps);
  }, [estado?.peso, estado?.reps]);

  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 8, padding: '5px 0',
      opacity: guardada ? 0.75 : 1,
    }}>
      <div style={{
        width: 22, flexShrink: 0, fontSize: 12, fontWeight: 800,
        color: guardada ? SUCCESS : TEXT_LIGHT,
      }}>{num}</div>

      <Campo valor={peso} alCambiar={setPeso} sufijo="kg"
             marcador={sugerido.peso !== '' ? String(sugerido.peso) : 'peso'} bloqueado={guardada} />
      <span style={{ color: TEXT_LIGHT, fontSize: 12 }}>×</span>
      <Campo valor={reps} alCambiar={setReps} sufijo="reps"
             marcador={sugerido.reps !== '' ? String(sugerido.reps) : 'reps'} bloqueado={guardada} />

      <button
        onClick={() => (guardada ? alDesmarcar() : alMarcar({ peso, reps }))}
        aria-label={guardada ? `Desmarcar serie ${num}` : `Marcar serie ${num}`}
        style={{
          marginLeft: 'auto', flexShrink: 0, width: 36, height: 34, borderRadius: 10,
          border: `1px solid ${guardada ? SUCCESS : BORDER}`,
          background: guardada ? SUCCESS : 'transparent',
          color: guardada ? '#fff' : TEXT_LIGHT,
          fontSize: 15, fontWeight: 800, cursor: 'pointer',
        }}>
        {estado?.guardando ? '·' : '✓'}
      </button>
    </div>
  );
}

function Campo({ valor, alCambiar, marcador, sufijo, bloqueado }) {
  return (
    <div style={{ position: 'relative', flex: 1, minWidth: 0 }}>
      <input
        // `decimal` y no `numeric`: en iOS el teclado numérico puro no trae
        // el punto, y medio kilo (62.5) es imposible de teclear.
        inputMode="decimal"
        value={valor}
        disabled={bloqueado}
        onChange={(e) => alCambiar(e.target.value.replace(',', '.'))}
        placeholder={marcador}
        aria-label={sufijo}
        style={{
          width: '100%', border: `1px solid ${BORDER}`, borderRadius: 10,
          // 16px exactos: por debajo de eso Safari hace zoom al enfocar y
          // descoloca la pantalla a media serie.
          padding: '7px 30px 7px 10px', fontSize: 16, fontFamily: 'inherit',
          background: bloqueado ? SURFACE_2 : SURFACE, color: TEXT,
          WebkitAppearance: 'none',
        }} />
      <span style={{
        position: 'absolute', right: 9, top: '50%', transform: 'translateY(-50%)',
        fontSize: 10.5, color: TEXT_LIGHT, pointerEvents: 'none',
      }}>{sufijo}</span>
    </div>
  );
}

// ── Cerrar la sesión ─────────────────────────────────────────────────────
function Cierre({ abierto, alCerrar, alConfirmar, hechas, total }) {
  const [rpe, setRpe] = useState(null);
  const [notas, setNotas] = useState('');
  const [enviando, setEnviando] = useState(false);

  const mandar = async (estado) => {
    setEnviando(true);
    await alConfirmar({ rpe, notas: notas.trim() || null, estado });
    setEnviando(false);
  };

  return (
    <Hoja abierta={abierto} alCerrar={alCerrar} titulo="¿Cómo te fue?" alto="72vh">
      <div style={{ fontSize: 13.5, color: TEXT_MUTED, marginBottom: 16 }}>
        Marcaste {hechas} de {total} series.
        {hechas < total && ' No pasa nada si no completaste todo.'}
      </div>

      <div style={{
        fontSize: 11, fontWeight: 800, letterSpacing: '.08em', textTransform: 'uppercase',
        color: TEXT_LIGHT, marginBottom: 8,
      }}>Qué tan duro se sintió</div>
      {/* Diez en una sola fila con `grid`: con `flex-wrap` el 10 se caía a una
          segunda línea y la escala dejaba de leerse como una escala. */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(10, 1fr)', gap: 4 }}>
        {Array.from({ length: 10 }, (_, i) => i + 1).map(n => (
          <button key={n} onClick={() => setRpe(n === rpe ? null : n)} style={{
            width: '100%', height: 40, borderRadius: 9, cursor: 'pointer', padding: 0,
            border: `1px solid ${n === rpe ? ACCENT : BORDER}`,
            background: n === rpe ? ACCENT : 'transparent',
            color: n === rpe ? '#fff' : TEXT, fontWeight: 800, fontSize: 13,
            fontFamily: 'inherit',
          }}>{n}</button>
        ))}
      </div>
      <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 11, color: TEXT_LIGHT, marginTop: 5 }}>
        <span>1 · muy suave</span><span>10 · al límite</span>
      </div>

      <div style={{
        fontSize: 11, fontWeight: 800, letterSpacing: '.08em', textTransform: 'uppercase',
        color: TEXT_LIGHT, margin: '18px 0 8px',
      }}>Algo que contarle a tu coach</div>
      <textarea
        value={notas} onChange={(e) => setNotas(e.target.value)} rows={3}
        placeholder="Me molestó el hombro derecho en el press…"
        style={{
          width: '100%', border: `1px solid ${BORDER}`, borderRadius: 12,
          padding: '10px 12px', fontSize: 16, fontFamily: 'inherit',
          resize: 'vertical', color: TEXT, background: SURFACE,
        }} />

      <div style={{ display: 'flex', flexDirection: 'column', gap: 9, marginTop: 18 }}>
        <Boton ancho variante="marca" disabled={enviando} onClick={() => mandar('completada')}>
          {enviando ? 'Guardando…' : 'Listo, terminé'}
        </Boton>
        <Boton ancho variante="suave" disabled={enviando} onClick={() => mandar('saltada')}>
          No pude entrenar hoy
        </Boton>
      </div>
      <div style={{ fontSize: 11.5, color: TEXT_LIGHT, textAlign: 'center', marginTop: 10, lineHeight: 1.5 }}>
        Puedes dejar el esfuerzo en blanco. Es mejor no poner nada que poner un número al azar.
      </div>
    </Hoja>
  );
}

const atras = {
  border: 'none', background: 'transparent', padding: '0 0 8px', cursor: 'pointer',
  fontSize: 13.5, color: TEXT_MUTED, fontFamily: 'inherit', fontWeight: 600,
};

// ─────────────────────────────────────────────────────────────────────────
// MÓDULO DE ENTRENAMIENTO DEL CLIENTE
//
// Cuatro secciones y una regla que las gobierna todas: LA FUERZA MANDA.
//
//   Hoy       lo que toca hoy, y la semana debajo
//   Mes       el calendario, para ver si está cumpliendo
//   Rutinas   el plan completo, informativo
//   Resumen   entrenamiento + alimentación de la semana
//
// Encima de cualquiera se abre "ejecutar rutina", que es una pantalla y no
// una sección: se entra desde el día que toca y se sale al terminar.
//
// EL CONTRATO CON LA APP PADRE (no tocar sin leer el README)
//   1. el fondo calza con el de la app (BG + BG_STAINS, sin costura)
//   2. la identidad llega por ?mt_user / ?mt_name
//   3. NADA fijo abajo: el padre monta el iframe 64px más corto y le pinta
//      un degradado de 96px encima. Una barra inferior propia quedaría
//      tapada por la barra ovalada de la app — por eso la navegación de
//      este módulo va ARRIBA y no abajo.
//   4. cero scroll horizontal
// ─────────────────────────────────────────────────────────────────────────
import React, { useEffect, useMemo, useState } from 'react';
import { BG, BG_STAINS, SURFACE, BORDER, TEXT, TEXT_MUTED, TEXT_LIGHT,
         ACCENT, ACCENT_DARK, ACCENT_LIGHT, SHADOW_CARD, FONT_DISPLAY } from './theme.js';
import { readIdentity, setIdentityManual, clearIdentity, isEmbedded } from './identity.js';
import Hoy from './Hoy.jsx';
import Mes from './Mes.jsx';
import Rutinas from './Rutinas.jsx';
import Resumen from './Resumen.jsx';
import Ejecutar from './Ejecutar.jsx';

const FADE_TOP = 46;      // degradado superior que pinta la app padre
const FADE_BOTTOM = 96;   // degradado inferior + barra ovalada

const SECCIONES = [
  ['hoy', 'Hoy'],
  ['mes', 'Mes'],
  ['rutinas', 'Rutinas'],
  ['resumen', 'Resumen'],
];

export default function App() {
  const [identity, setIdentity] = useState(() => readIdentity());
  const [nombreInput, setNombreInput] = useState('');
  const [seccion, setSeccion] = useState('hoy');
  const [rutinaAbierta, setRutinaAbierta] = useState(null);
  const embedded = useMemo(() => isEmbedded(), []);

  useEffect(() => {
    if (!embedded && identity.name) document.title = `Entrenamiento · ${identity.name}`;
  }, [embedded, identity.name]);

  // Al cambiar de sección se sube. Sin esto, saltar de un Mes largo a Hoy te
  // deja a media página en un sitio que ya no existe.
  useEffect(() => { window.scrollTo({ top: 0 }); }, [seccion, rutinaAbierta]);

  const sinIdentidad = !identity.name && !identity.userId;
  const nombre = identity.name;

  return (
    <div style={{ minHeight: '100dvh', background: BG, color: TEXT, position: 'relative' }}>
      {/* Mismas manchas del fondo que la app padre: al entrar al módulo el
          fondo no cambia, solo cambia el contenido. */}
      <div style={{ position: 'fixed', inset: 0, background: BG_STAINS, pointerEvents: 'none' }} />

      <div style={{
        position: 'relative',
        maxWidth: 560, margin: '0 auto', padding: '0 20px',
        paddingTop: `calc(${FADE_TOP}px + env(safe-area-inset-top, 0px) + 12px)`,
        paddingBottom: `calc(${FADE_BOTTOM}px + env(safe-area-inset-bottom, 0px))`,
      }}>

        {!embedded && !sinIdentidad && (
          <div style={{
            display: 'flex', alignItems: 'baseline', justifyContent: 'space-between',
            gap: 10, marginBottom: 14,
          }}>
            <div style={{
              fontFamily: FONT_DISPLAY, fontSize: 22, letterSpacing: '0.04em',
              textTransform: 'uppercase', lineHeight: 1, color: ACCENT_DARK,
            }}>Entrenamiento</div>
            <button
              onClick={() => { clearIdentity(); setIdentity(readIdentity()); setNombreInput(''); }}
              style={{
                border: 'none', background: 'transparent', padding: 0, cursor: 'pointer',
                fontSize: 11.5, color: TEXT_LIGHT, fontFamily: 'inherit',
              }}>{identity.name} · cambiar</button>
          </div>
        )}

        {sinIdentidad ? (
          <PedirNombre
            valor={nombreInput}
            alCambiar={setNombreInput}
            alEnviar={() => {
              const next = setIdentityManual(nombreInput);
              if (next) setIdentity(next);
            }}
          />
        ) : rutinaAbierta ? (
          <Ejecutar
            nombre={nombre}
            rutinaId={rutinaAbierta}
            alSalir={() => setRutinaAbierta(null)}
          />
        ) : (
          <>
            {/* La navegación va ARRIBA: abajo la tapa la barra de la app padre. */}
            <nav style={{
              display: 'flex', gap: 3, background: 'rgba(255,255,255,0.72)',
              backdropFilter: 'blur(8px)', WebkitBackdropFilter: 'blur(8px)',
              border: `1px solid ${BORDER}`, borderRadius: 999, padding: 3,
              marginBottom: 20, position: 'sticky', top: 8, zIndex: 30,
            }}>
              {SECCIONES.map(([id, lab]) => (
                <button key={id} onClick={() => setSeccion(id)} style={{
                  flex: 1, border: 'none', borderRadius: 999, padding: '9px 6px',
                  background: seccion === id ? ACCENT : 'transparent',
                  color: seccion === id ? '#fff' : TEXT_MUTED,
                  fontSize: 13, fontWeight: 700, cursor: 'pointer', fontFamily: 'inherit',
                  transition: 'background .14s, color .14s',
                }}>{lab}</button>
              ))}
            </nav>

            {seccion === 'hoy' && <Hoy nombre={nombre} alEntrenar={setRutinaAbierta} />}
            {seccion === 'mes' && <Mes nombre={nombre} alEntrenar={setRutinaAbierta} />}
            {seccion === 'rutinas' && <Rutinas nombre={nombre} alEntrenar={setRutinaAbierta} />}
            {seccion === 'resumen' && <Resumen nombre={nombre} />}
          </>
        )}
      </div>
    </div>
  );
}

// Solo aparece abriendo el módulo suelto, para probarlo. Embebido, la
// identidad llega siempre en la URL.
function PedirNombre({ valor, alCambiar, alEnviar }) {
  return (
    <div style={{
      background: SURFACE, borderRadius: 18, padding: 20, boxShadow: SHADOW_CARD,
    }}>
      <div style={{ fontSize: 16, fontWeight: 800, marginBottom: 6 }}>¿Quién eres?</div>
      <p style={{ fontSize: 13.5, color: TEXT_MUTED, lineHeight: 1.55, margin: '0 0 14px' }}>
        Abriste el módulo suelto, sin venir desde la app. Escribe tu nombre tal
        como lo tiene tu coach.
      </p>
      <form onSubmit={(e) => { e.preventDefault(); alEnviar(); }} style={{ display: 'flex', gap: 8 }}>
        <input
          value={valor}
          onChange={(e) => alCambiar(e.target.value)}
          placeholder="Nombre y apellido"
          autoComplete="off"
          style={{
            flex: 1, padding: '11px 13px', borderRadius: 12,
            border: `1px solid ${BORDER}`, background: SURFACE,
            // 16px: por debajo, Safari hace zoom al enfocar.
            fontSize: 16, color: TEXT, outline: 'none', fontFamily: 'inherit',
          }} />
        <button type="submit" style={{
          padding: '11px 18px', borderRadius: 12, border: 0,
          background: TEXT, color: '#fff', fontSize: 14.5,
          fontWeight: 700, cursor: 'pointer', fontFamily: 'inherit',
        }}>Entrar</button>
      </form>
    </div>
  );
}

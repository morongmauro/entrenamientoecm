import React, { useEffect, useMemo, useState } from 'react';
import { Dumbbell, Calendar, User, AlertCircle } from 'lucide-react';
import { BG, BG_STAINS, SURFACE, BORDER, TEXT, TEXT_MUTED, TEXT_LIGHT,
         ACCENT, ACCENT_DARK, SHADOW_CARD, FONT_DISPLAY } from './theme.js';
import { readIdentity, setIdentityManual, clearIdentity, isEmbedded } from './identity.js';

// ─────────────────────────────────────────────────────────────────────────
// CASCARÓN DEL MÓDULO DE ENTRENAMIENTO
//
// Esta primera versión existe para UNA cosa: verificar en el teléfono que el
// módulo calza dentro del iframe de la app principal antes de construirle
// funcionalidad encima. Comprueba las cuatro reglas del contrato:
//
//   1. el fondo calza con el de la app padre (BG, sin costura visible)
//   2. la identidad llega por ?mt_user / ?mt_name y se reconoce sola
//   3. NADA fijo abajo: el padre monta el iframe 64px más corto y le pinta
//      un degradado de 96px encima — una barra inferior propia quedaría
//      tapada por la barra ovalada de la app
//   4. cero scroll horizontal
//
// El calendario, el constructor y la ejecución de rutinas se montan encima
// de esto una vez confirmado. -- ver README.md
// ─────────────────────────────────────────────────────────────────────────

const FADE_TOP = 46;      // degradado superior que pinta la app padre
const FADE_BOTTOM = 96;   // degradado inferior + barra ovalada

export default function App() {
  const [identity, setIdentity] = useState(() => readIdentity());
  const [nombreInput, setNombreInput] = useState('');
  const embedded = useMemo(() => isEmbedded(), []);

  // Título de la pestaña solo importa cuando se abre suelta.
  useEffect(() => {
    if (!embedded && identity.name) document.title = `Entrenamiento · ${identity.name}`;
  }, [embedded, identity.name]);

  const sinIdentidad = !identity.name && !identity.userId;

  return (
    <div style={{ minHeight: '100dvh', background: BG, color: TEXT, position: 'relative' }}>
      {/* Mismas manchas orgánicas del fondo que la app padre: al entrar al
          módulo el fondo no cambia, solo cambia el contenido. */}
      <div style={{
        position: 'fixed', inset: 0, background: BG_STAINS, pointerEvents: 'none',
      }} />

      <div style={{
        position: 'relative',
        maxWidth: 560, margin: '0 auto', padding: '0 20px',
        // El aire de arriba y abajo NO es estético: es el espacio que la app
        // padre tapa con sus degradados. Sin esto, el contenido de los
        // extremos se lee a medias dentro del iframe.
        paddingTop: `calc(${FADE_TOP}px + env(safe-area-inset-top, 0px) + 12px)`,
        paddingBottom: `calc(${FADE_BOTTOM}px + env(safe-area-inset-bottom, 0px))`,
      }}>

        {/* Cabecera propia SOLO cuando se abre suelta: embebido, la app
            padre ya pinta su píldora justo encima de esta franja. */}
        {!embedded && (
          <div style={{ marginBottom: 20 }}>
            <div style={{
              fontFamily: FONT_DISPLAY, fontSize: 30, letterSpacing: '0.04em',
              textTransform: 'uppercase', lineHeight: 1, color: ACCENT_DARK,
            }}>Entrenamiento</div>
            <div style={{ fontSize: 13, color: TEXT_MUTED, marginTop: 4 }}>
              Entrena con Método
            </div>
          </div>
        )}

        {sinIdentidad ? (
          <Tarjeta>
            <Fila icono={<User size={18} color={ACCENT} />} titulo="¿Quién eres?" />
            <p style={{ fontSize: 13, color: TEXT_MUTED, lineHeight: 1.5, margin: '0 0 14px' }}>
              Abriste el módulo suelto, sin venir desde la app. Escribe tu nombre
              tal como está en el CRM para probarlo.
            </p>
            <form
              onSubmit={(e) => {
                e.preventDefault();
                const next = setIdentityManual(nombreInput);
                if (next) setIdentity(next);
              }}
              style={{ display: 'flex', gap: 8 }}
            >
              <input
                value={nombreInput}
                onChange={(e) => setNombreInput(e.target.value)}
                placeholder="Nombre y apellido"
                autoComplete="off"
                style={{
                  flex: 1, padding: '10px 12px', borderRadius: 10,
                  border: `1px solid ${BORDER}`, background: SURFACE,
                  fontSize: 15, color: TEXT, outline: 'none',
                }}
              />
              <button type="submit" style={{
                padding: '10px 16px', borderRadius: 10, border: 0,
                background: '#1F1F1F', color: '#fff', fontSize: 14,
                fontWeight: 600, cursor: 'pointer',
              }}>Entrar</button>
            </form>
          </Tarjeta>
        ) : (
          <>
            <Tarjeta>
              <Fila icono={<User size={18} color={ACCENT} />} titulo={identity.name || 'Cliente sin nombre'} />
              <Dato etiqueta="Identidad" valor={
                identity.origen === 'url' ? 'recibida de la app'
                : identity.origen === 'guardada' ? 'guardada en este teléfono'
                : 'escrita a mano'} />
              <Dato etiqueta="mt_user" valor={identity.userId || '— (no llegó)'} mono />
              <Dato etiqueta="Contexto" valor={embedded ? 'embebido en la app' : 'abierto suelto'} />
              {!embedded && (
                <button
                  onClick={() => { clearIdentity(); setIdentity(readIdentity()); setNombreInput(''); }}
                  style={{
                    marginTop: 12, padding: '7px 12px', borderRadius: 8,
                    border: `1px solid ${BORDER}`, background: 'transparent',
                    fontSize: 12, color: TEXT_MUTED, cursor: 'pointer',
                  }}>Cambiar de cliente</button>
              )}
            </Tarjeta>

            <Tarjeta>
              <Fila icono={<Calendar size={18} color={ACCENT} />} titulo="Tu calendario" />
              <Vacio texto="Aún no hay fases asignadas. Cuando el coach cargue tu primera fase desde el CRM, aquí aparecen tus días de entreno." />
            </Tarjeta>

            <Tarjeta>
              <Fila icono={<Dumbbell size={18} color={ACCENT} />} titulo="Rutina de hoy" />
              <Vacio texto="Nada programado para hoy." />
            </Tarjeta>
          </>
        )}

        {/* Sello del build. Por ahora el módulo se usa SUELTO (todavía no se
            embebe en la app de los clientes), así que esto sirve para saber
            qué versión estás viendo tras cada deploy a Vercel. */}
        <div style={{
          marginTop: 8, padding: '10px 12px', borderRadius: 10,
          border: `1px dashed ${BORDER}`, display: 'flex', gap: 8,
          alignItems: 'flex-start',
        }}>
          <AlertCircle size={15} color={TEXT_LIGHT} style={{ flexShrink: 0, marginTop: 1 }} />
          <div style={{ fontSize: 11, color: TEXT_LIGHT, lineHeight: 1.5 }}>
            Build {typeof __BUILD_VERSION__ !== 'undefined' ? __BUILD_VERSION__ : 'dev'}
            {' · '}modo {embedded ? 'embebido' : 'suelto'}.
          </div>
        </div>
      </div>
    </div>
  );
}

// ── piezas visuales, mismo lenguaje que la app padre ──────────────────────

const Tarjeta = ({ children }) => (
  <div style={{
    background: SURFACE, borderRadius: 16, padding: 16,
    boxShadow: SHADOW_CARD, marginBottom: 14,
  }}>{children}</div>
);

const Fila = ({ icono, titulo }) => (
  <div style={{ display: 'flex', alignItems: 'center', gap: 9, marginBottom: 10 }}>
    {icono}
    <div style={{ fontSize: 15, fontWeight: 700, letterSpacing: '-0.01em' }}>{titulo}</div>
  </div>
);

const Dato = ({ etiqueta, valor, mono }) => (
  <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12, padding: '5px 0' }}>
    <span style={{ fontSize: 12, color: TEXT_MUTED, flexShrink: 0 }}>{etiqueta}</span>
    <span style={{
      fontSize: 12, color: TEXT, textAlign: 'right', wordBreak: 'break-all',
      fontFamily: mono ? 'ui-monospace, SFMono-Regular, Menlo, monospace' : 'inherit',
    }}>{valor}</span>
  </div>
);

const Vacio = ({ texto }) => (
  <p style={{ fontSize: 13, color: TEXT_MUTED, lineHeight: 1.55, margin: 0 }}>{texto}</p>
);

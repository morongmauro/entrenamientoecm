// ─────────────────────────────────────────────────────────────────────────
// CAPA DE DATOS · todo pasa por /api/training
//
// El módulo NO habla con Supabase directamente. Habla con un endpoint que
// vive en la app principal (mealtracker/api/training.js) y que:
//   · tiene la service_role key, que nunca puede bajar al navegador
//   · acota TODO al cliente_id de quien pregunta
//   · nunca devuelve `notas_coach` — eso es material del coach
//
// DÓNDE ESTÁ LA API
// -----------------
// Este módulo se despliega en su propio dominio, así que las peticiones
// salen cruzadas. `VITE_API_BASE` apunta al dominio de la app principal:
//
//     VITE_API_BASE=https://app.entrenaconmetodo.com
//
// Sin esa variable se llama a `/api/...` del propio dominio, que es lo
// correcto cuando el módulo se sirve desde la misma app. El endpoint
// responde con CORS solo a los dominios de ALLOWED_ORIGINS.
//
// FAIL-SAFE
// ---------
// Nada de aquí lanza. Ante un error de red o un 500 se devuelve
// `{ ok:false, motivo }` y la pantalla enseña su estado vacío. Un cliente
// en el gimnasio con mala señal tiene que ver "no pude cargar, reintenta",
// no una pantalla en blanco.
// ─────────────────────────────────────────────────────────────────────────

const BASE = (import.meta.env?.VITE_API_BASE || '').replace(/\/$/, '');
const URL_API = `${BASE}/api/training`;

async function pedir(params, { metodo = 'GET' } = {}) {
  try {
    const r = metodo === 'GET'
      ? await fetch(`${URL_API}?${new URLSearchParams(params)}`, { credentials: 'omit' })
      : await fetch(URL_API, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(params),
          credentials: 'omit',
        });
    if (!r.ok) return { ok: false, motivo: `http_${r.status}` };
    return await r.json();
  } catch (e) {
    return { ok: false, motivo: 'sin_red' };
  }
}

export const api = {
  // ---- Lecturas ----
  plan:     (name)         => pedir({ accion: 'plan', name }),
  rutina:   (name, id)     => pedir({ accion: 'rutina', name, id }),
  mes:      (name, ym)     => pedir({ accion: 'mes', name, ym }),
  rutinas:  (name)         => pedir({ accion: 'rutinas', name }),
  resumen:  (name)         => pedir({ accion: 'resumen', name }),
  catalogo: (name)         => pedir({ accion: 'catalogo', name }),

  // ---- Escrituras ----
  abrir:  (name, rutina_id) => pedir({ accion: 'abrir', name, rutina_id }, { metodo: 'POST' }),
  serie:  (name, datos)     => pedir({ accion: 'serie', name, ...datos }, { metodo: 'POST' }),
  cerrar: (name, datos)     => pedir({ accion: 'cerrar', name, ...datos }, { metodo: 'POST' }),
  actividad:        (name, datos) => pedir({ accion: 'actividad', name, ...datos }, { metodo: 'POST' }),
  borrarActividad:  (name, id)    => pedir({ accion: 'borrar_actividad', name, id }, { metodo: 'POST' }),
};

// ─────────────────────────────────────────────────────────────────────────
// CATÁLOGO DE RESPALDO
// ─────────────────────────────────────────────────────────────────────────
// Si la migración de actividades no se ha corrido, el endpoint devuelve el
// catálogo vacío. Antes que dejar al cliente sin nada que marcar, se ofrece
// esta lista corta. Los slugs son los mismos que los de la tabla, así que
// cuando la migración se corra no hay que migrar nada.
export const CATALOGO_MINIMO = [
  { slug: 'cinta',     nombre: 'Caminadora',       categoria: 'cardio',  icono: '🏃', remate: true,  pide_distancia: true },
  { slug: 'eliptica',  nombre: 'Elíptica',         categoria: 'cardio',  icono: '🌀', remate: true,  pide_distancia: false },
  { slug: 'running',   nombre: 'Running en calle', categoria: 'cardio',  icono: '👟', remate: false, pide_distancia: true },
  { slug: 'caminata',  nombre: 'Caminata',         categoria: 'cardio',  icono: '🚶', remate: false, pide_distancia: true },
  { slug: 'natacion',  nombre: 'Natación',         categoria: 'deporte', icono: '🏊', remate: false, pide_distancia: true },
  { slug: 'otro',      nombre: 'Otra actividad',   categoria: 'otro',    icono: '✨', remate: false, pide_distancia: false },
];

// ─────────────────────────────────────────────────────────────────────────
// FECHAS · siempre en local, nunca en UTC
// ─────────────────────────────────────────────────────────────────────────
// `toISOString()` convierte a UTC: en Colombia (UTC-5) a partir de las 7pm
// devolvería el día siguiente, y "la rutina de hoy" cambiaría a media tarde.
export const hoyLocal = () => {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
};
export const aFecha = (iso) => {
  const [y, m, d] = String(iso).slice(0, 10).split('-').map(Number);
  return new Date(y, m - 1, d);
};
export const sumarDias = (iso, n) => {
  const d = aFecha(iso);
  d.setDate(d.getDate() + n);
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
};

export const MESES = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
                      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];
export const DIAS_LARGO = { L: 'Lunes', M: 'Martes', X: 'Miércoles', J: 'Jueves', V: 'Viernes', S: 'Sábado', D: 'Domingo' };
export const DIAS_CORTO = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

export const fechaCorta = (iso) => {
  const d = aFecha(iso);
  return `${d.getDate()} de ${MESES[d.getMonth()]}`;
};

// ─────────────────────────────────────────────────────────────────────────
// VIDEO
// ─────────────────────────────────────────────────────────────────────────
// La miniatura sale del propio video de YouTube. `mqdefault` (320×180) y no
// `maxresdefault`: la grande no existe para todos los videos y cuando falta
// deja un hueco roto en la lista.
export const miniatura = (ej) => {
  if (!ej) return null;
  if (ej.poster_url) return ej.poster_url;
  if (ej.video_fuente === 'youtube' && ej.video_ref) {
    return `https://i.ytimg.com/vi/${ej.video_ref}/mqdefault.jpg`;
  }
  return null;
};

export const urlVideo = (ej) => {
  if (!ej || ej.video_fuente !== 'youtube' || !ej.video_ref) return null;
  const t = Number(ej.video_inicio_seg) || 0;
  return `https://www.youtube.com/embed/${ej.video_ref}?rel=0&modestbranding=1${t ? `&start=${t}` : ''}`;
};

// ─────────────────────────────────────────────────────────────────────────
// IDENTIDAD DEL CLIENTE
//
// Este módulo se abre EMBEBIDO en un iframe desde la app principal, que le
// pasa la identidad en la URL — exactamente el mismo contrato que ya usa el
// centro de recursos ("Aprendizaje"):
//
//     https://<este-modulo>/?mt_user=<uuid>&mt_name=<nombre>
//
// (ver openLearning en mealtracker/src/MealTracker.jsx). No hay segundo
// login: si vienen los parámetros, el cliente ya está adentro.
//
// FALLBACK: sin parámetros (o sea, abriendo la app suelta para desarrollar
// y probar), se pide el nombre a mano y se guarda. Ese modo es el que vas a
// usar todo el desarrollo, antes de engancharlo al iframe.
// ─────────────────────────────────────────────────────────────────────────

const LS_USER = 'ecm:userId';
const LS_NAME = 'ecm:userName';

const lsGet = (k) => { try { return localStorage.getItem(k); } catch (e) { return null; } };
const lsSet = (k, v) => { try { localStorage.setItem(k, v); } catch (e) {} };

// Igual que authorize.js del mealtracker: sin tildes, sin mayúsculas, sin
// espacios de más. Es LA regla de comparación de nombres del ecosistema —
// si aquí difiere, un cliente válido se queda afuera.
export const normalizeName = (str) => String(str || '')
  .toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '')
  .replace(/\s+/g, ' ').trim();

// ¿Estamos dentro del iframe de la app principal, o abiertos sueltos?
// Cambia el layout: embebido no dibujamos cabecera propia (la app padre ya
// pinta su píldora encima) ni pedimos nombre.
export function isEmbedded() {
  try { return window.self !== window.top; } catch (e) { return true; }
}

// Lee la identidad: primero la URL (manda siempre — si la app padre dice
// que es otra persona, esa gana sobre lo guardado), después localStorage.
export function readIdentity() {
  let fromUrl = { userId: null, name: null };
  try {
    const p = new URLSearchParams(window.location.search);
    fromUrl = {
      userId: p.get('mt_user') || null,
      name: p.get('mt_name') || null,
    };
  } catch (e) { /* URL rara: caemos a lo guardado */ }

  // La URL manda. Si trae identidad NUEVA, se persiste y se limpia lo viejo:
  // un teléfono prestado no debe mezclar los datos de dos clientes.
  if (fromUrl.userId || fromUrl.name) {
    const prevId = lsGet(LS_USER);
    if (fromUrl.userId && prevId && prevId !== fromUrl.userId) {
      try { localStorage.removeItem('ecm:sesionEnCurso'); } catch (e) {}
    }
    if (fromUrl.userId) lsSet(LS_USER, fromUrl.userId);
    if (fromUrl.name) lsSet(LS_NAME, fromUrl.name);
    return { userId: fromUrl.userId, name: fromUrl.name, origen: 'url' };
  }

  const savedId = lsGet(LS_USER);
  const savedName = lsGet(LS_NAME);
  if (savedId || savedName) {
    return { userId: savedId, name: savedName, origen: 'guardada' };
  }

  return { userId: null, name: null, origen: 'ninguna' };
}

// Modo desarrollo / app suelta: fijar el nombre a mano.
export function setIdentityManual(name) {
  const clean = String(name || '').trim();
  if (!clean) return null;
  lsSet(LS_NAME, clean);
  return { userId: lsGet(LS_USER), name: clean, origen: 'manual' };
}

export function clearIdentity() {
  try {
    localStorage.removeItem(LS_USER);
    localStorage.removeItem(LS_NAME);
    localStorage.removeItem('ecm:sesionEnCurso');
  } catch (e) {}
}

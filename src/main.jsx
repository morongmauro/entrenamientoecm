import React from 'react';
import ReactDOM from 'react-dom/client';
import './index.css';
// Fuentes self-hosted, igual que la app padre: una hoja remota bloquearía el
// primer pintado y dejaría el iframe en blanco si la red falla.
import '@fontsource/inter/latin-400.css';
import '@fontsource/inter/latin-500.css';
import '@fontsource/inter/latin-600.css';
import '@fontsource/inter/latin-700.css';
import '@fontsource/bebas-neue/latin-400.css';
import App from './App.jsx';

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode><App /></React.StrictMode>
);

// ─── Auto-actualización ───────────────────────────────────────────────────
// Igual que el mealtracker: el sello del build va incrustado en el bundle y
// se compara contra /version.json. Aquí importa MÁS que en la app suelta —
// dentro de un iframe el cliente no tiene barra de URL ni forma natural de
// forzar un refresh, así que un bundle viejo se quedaría pegado para siempre.
if (typeof window !== 'undefined') {
  const BUILD_VERSION = typeof __BUILD_VERSION__ !== 'undefined' ? __BUILD_VERSION__ : null;
  let updateReady = false;

  const checkVersion = async () => {
    if (!BUILD_VERSION) return; // dev server: no hay version.json
    try {
      const r = await fetch(`/version.json?t=${Date.now()}`, { cache: 'no-store' });
      if (!r.ok) return;
      const { version } = await r.json();
      if (version && version !== BUILD_VERSION) updateReady = true;
    } catch (e) { /* sin red: se reintenta luego */ }
  };

  const applyIfReady = () => {
    if (!updateReady) return;
    // Nunca recargar con una sesión de entreno abierta: el cliente perdería
    // las series que lleva marcadas. Se aplica cuando cierre la sesión.
    try { if (localStorage.getItem('ecm:sesionEnCurso')) return; } catch (e) {}
    // Guard anti-bucle por si la caché sigue sirviendo este mismo bundle.
    try {
      if (sessionStorage.getItem('ecm:reloadedForBuild') === BUILD_VERSION) return;
      sessionStorage.setItem('ecm:reloadedForBuild', BUILD_VERSION);
    } catch (e) {}
    window.location.reload();
  };

  checkVersion().then(applyIfReady);
  setInterval(checkVersion, 5 * 60 * 1000);
  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState === 'visible') {
      applyIfReady();
      checkVersion().then(applyIfReady);
    } else {
      applyIfReady();
    }
  });
}

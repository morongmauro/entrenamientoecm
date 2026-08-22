import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// Mismo sello de build que el mealtracker: /version.json + __BUILD_VERSION__
// incrustado en el bundle. Dentro de un iframe el cliente casi nunca recarga
// a mano, así que la auto-actualización importa MÁS aquí, no menos.
const buildVersion = `${Date.now()}`;

function buildVersionPlugin() {
  return {
    name: 'build-version-json',
    apply: 'build',
    generateBundle() {
      this.emitFile({
        type: 'asset',
        fileName: 'version.json',
        source: JSON.stringify({ version: buildVersion, builtAt: new Date().toISOString() }),
      });
    },
  };
}

export default defineConfig({
  plugins: [react(), buildVersionPlugin()],
  define: { __BUILD_VERSION__: JSON.stringify(buildVersion) },
});

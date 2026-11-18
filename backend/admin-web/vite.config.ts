import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// Le site est servi par le serveur Express sous /admin (voir server.js).
// En developpement, les appels /api sont relayes vers le serveur local.
export default defineConfig({
  base: '/admin/',
  plugins: [react()],
  server: {
    port: 5173,
    proxy: {
      '/api': 'http://localhost:3000',
    },
  },
});

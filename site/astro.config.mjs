// @ts-check
import { defineConfig } from 'astro/config';

import tailwindcss from '@tailwindcss/vite';

// El build se escribe directamente en docs/, que es la carpeta que sirve
// GitHub Pages (Settings → Pages → Deploy from a branch → /docs).
// https://astro.build/config
export default defineConfig({
  outDir: '../docs',
  vite: {
    plugins: [tailwindcss()]
  }
});
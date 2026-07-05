// @ts-check
import { defineConfig } from 'astro/config';

import tailwindcss from '@tailwindcss/vite';

// Desplegado en Vercel (Root Directory: site) — outDir por defecto (dist/),
// Vercel lo detecta y sirve solo.
// https://astro.build/config
export default defineConfig({
  vite: {
    plugins: [tailwindcss()]
  }
});
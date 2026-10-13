/// <reference types="vitest/config" />
import { defineConfig, loadEnv } from 'vite'
import react from '@vitejs/plugin-react'

// `base`: ruta desde la que se sirve el panel.
// - En local (npm run dev) es "/".
// - En GitHub Pages es "/<nombre-del-repo>/" (el workflow pasa VITE_BASE=/hoja-del-alba/).
// - "./" también funciona en cualquier carpeta, porque el panel usa rutas con "#".
export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), 'VITE_')
  return {
    base: env.VITE_BASE || process.env.VITE_BASE || './',
    plugins: [react()],
    server: { port: 5174, strictPort: false },
    preview: { port: 5175 },
    build: { outDir: 'dist', sourcemap: false },
    test: { environment: 'node', include: ['src/**/*.test.ts'] },
  }
})

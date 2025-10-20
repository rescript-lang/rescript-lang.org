import { reactRouter } from "@react-router/dev/vite";
import tailwindcss from '@tailwindcss/vite';
import { defineConfig } from "vite";
import env from 'vite-plugin-env-compatible'

export default defineConfig({
  plugins: [
    tailwindcss(),
    reactRouter({
      ssr: true,
    }),
    env({ prefix: 'PUBLIC_' })
  ],
  build: {
    sourcemap: true
  },
  css: {
    transformer: 'lightningcss',
  },
  optimizeDeps: {
    exclude: ["node_modules/.vite"]
  },
  assetsInclude: ['**/resources.json']
});

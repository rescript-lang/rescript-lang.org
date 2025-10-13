import { reactRouter } from "@react-router/dev/vite";
import tailwindcss from '@tailwindcss/vite';
import { defineConfig } from "vite";

export default defineConfig({
  plugins: [
    tailwindcss(),
    reactRouter({
      ssr: true,
    }),
  ],
  build: {
    sourcemap: true
  },
  css: {
    transformer: 'lightningcss',
  },
  optimizeDeps: {
    exclude: ["node_modules/.vite"]
  }
});

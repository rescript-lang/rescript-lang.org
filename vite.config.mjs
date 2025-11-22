// @ts-check

import { reactRouter } from "@react-router/dev/vite";
import tailwindcss from "@tailwindcss/vite";
import { defineConfig } from "vite";
import devtoolsJson from "vite-plugin-devtools-json";
import env from "vite-plugin-env-compatible";
import react from "@vitejs/plugin-react";
import pageReload from "vite-plugin-page-reload";

export default defineConfig({
  plugins: [
    tailwindcss(),
    react({
      include: /\.(mjs|mdx|js|jsx|ts|tsx)$/,
    }),
    reactRouter(),
    env({ prefix: "PUBLIC_" }), // this is to make it so babel doesn't break when trying to acess process.env in the client
    devtoolsJson(),
    pageReload(["./markdown-pages/**/*.mdx"]),
  ],
  build: {
    // Having these on helps with local development
    sourcemap: process.env.NODE_ENV !== "production",
    watch: {
      include: ["**/markdown-pages/**"],
    },
  },
  css: {
    transformer: "lightningcss",
  },
  optimizeDeps: {
    exclude: ["node_modules/.vite/deps/*.js"],
  },
  assetsInclude: ["**/resources.json"],
});

import { reactRouter } from "@react-router/dev/vite";
import tailwindcss from "@tailwindcss/vite";
import react from "@vitejs/plugin-react";
import { defineConfig } from "vite";
import devtoolsJson from "vite-plugin-devtools-json";
import env from "vite-plugin-env-compatible";
import pageReload from "vite-plugin-page-reload";

const excludedFiles = ["lib/**", "**/*.res", "**/*.resi"];

export default defineConfig({
  plugins: [
    tailwindcss(),
    reactRouter(),
    react({
      include: ["**/*.mjs"],
      exclude: excludedFiles,
    }),
    // this is to make it so babel doesn't break when trying to acess process.env in the client
    env({ prefix: "PUBLIC_" }),
    // adds dev scripts for browser devtools
    devtoolsJson(),
    // This plugin enables hot-reloading for server-side rendered pages
    // this is needed to allow for reloads when MDX files are changed
    pageReload(["./markdown-pages/**/*.mdx"]),
  ],
  server: {
    watch: {
      ignored: excludedFiles,
    },
  },
  build: {
    // Having these on helps with local development
    sourcemap: process.env.NODE_ENV !== "production",
  },
  css: {
    transformer: "lightningcss",
  },
  optimizeDeps: {
    exclude: ["node_modules/.vite/deps/*.js"],
  },
  assetsInclude: ["**/resources.json"],
});

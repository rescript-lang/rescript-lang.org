import { reactRouter } from "@react-router/dev/vite";
import tailwindcss from "@tailwindcss/vite";
import { defineConfig } from "vite";
import env from "vite-plugin-env-compatible";
import devtoolsJson from "vite-plugin-devtools-json";

export default defineConfig({
  plugins: [
    tailwindcss(),
    reactRouter(),
    env({ prefix: "PUBLIC_" }), // this is to make it so babel doesn't break when trying to acess process.env in the client
    devtoolsJson(),
  ],
  build: {
    // Having these on helps with local development
    sourcemap: process.env.NODE_ENV !== "production",
  },
  css: {
    transformer: "lightningcss",
    lightningcss: {
      minify: process.env.NODE_ENV === "production",
    },
  },
  optimizeDeps: {
    exclude: ["node_modules/.vite/deps/*.js"],
  },
  assetsInclude: ["**/resources.json"],
});

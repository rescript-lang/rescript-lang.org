import { reactRouter } from "@react-router/dev/vite";
import { playwright } from "@vitest/browser-playwright";
import react from "@vitejs/plugin-react";
import { defineConfig } from "vite";
import env from "vite-plugin-env-compatible";

const excludedFiles = ["lib/**", "**/*.res", "**/*.resi"];
const sharedEditorDeps = [
  "@babel/generator",
  "@babel/parser",
  "@babel/traverse",
  "@babel/types",
  "@codemirror/commands",
  "@codemirror/lang-javascript",
  "@codemirror/language",
  "@codemirror/lint",
  "@codemirror/search",
  "@codemirror/state",
  "@codemirror/view",
  "@lezer/highlight",
  "@replit/codemirror-vim",
  "@rescript/runtime/lib/es6/Belt_Array.mjs",
  "@rescript/runtime/lib/es6/Primitive_int.mjs",
  "@rescript/runtime/lib/es6/Primitive_object.mjs",
  "@rescript/runtime/lib/es6/Primitive_option.mjs",
  "@rescript/runtime/lib/es6/Primitive_string.mjs",
  "@rescript/runtime/lib/es6/Stdlib_Array.mjs",
  "@rescript/runtime/lib/es6/Stdlib_Dict.mjs",
  "@rescript/runtime/lib/es6/Stdlib_Int.mjs",
  "@rescript/runtime/lib/es6/Stdlib_JsExn.mjs",
  "@rescript/runtime/lib/es6/Stdlib_List.mjs",
  "@rescript/runtime/lib/es6/Stdlib_Option.mjs",
  "@tsnobip/rescript-lezer",
  "lz-string",
  "react-markdown",
  "react-router",
  "vfile-matter",
];

export default defineConfig(({ mode }) => {
  const isTest = mode === "test";

  return {
    envDir: "../..",
    plugins: [
      env({ prefix: "PUBLIC_" }),
      ...(isTest ? [] : [reactRouter()]),
      isTest
        ? react()
        : react({
            include: ["**/*.mjs"],
            exclude: excludedFiles,
          }),
    ],
    server: {
      watch: {
        ignored: excludedFiles,
      },
    },
    build: {
      sourcemap: process.env.NODE_ENV !== "production",
    },
    css: {
      transformer: "lightningcss",
    },
    optimizeDeps: {
      include: sharedEditorDeps,
    },
    legacy: {
      inconsistentCjsInterop: true,
    },
    test: {
      include: ["__tests__/*_.test.jsx"],
      setupFiles: ["./vitest.setup.mjs"],
      browser: {
        enabled: true,
        provider: playwright({
          contextOptions: {
            deviceScaleFactor: 1,
          },
        }),
        ui: false,
        instances: [
          {
            browser: "chromium",
            viewport: { width: 1440, height: 900 },
          },
        ],
      },
    },
  };
});

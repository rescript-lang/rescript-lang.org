import { defineConfig } from "vitest/config";
import { playwright } from "@vitest/browser-playwright";
import react from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";

const setupDeps = [
  "highlight.js/lib/core",
  "highlight.js/lib/languages/bash",
  "highlight.js/lib/languages/css",
  "highlight.js/lib/languages/diff",
  "highlight.js/lib/languages/ini",
  "highlight.js/lib/languages/javascript",
  "highlight.js/lib/languages/json",
  "highlight.js/lib/languages/plaintext",
  "highlight.js/lib/languages/typescript",
  "highlight.js/lib/languages/xml",
  "highlightjs-rescript",
];

export default defineConfig({
  envDir: "../..",
  plugins: [react(), tailwindcss()],
  optimizeDeps: {
    include: setupDeps,
  },
  test: {
    include: ["__tests__/*.jsx"],
    setupFiles: ["./vitest.setup.mjs"],
    browser: {
      enabled: true,
      provider: playwright({
        contextOptions: {
          deviceScaleFactor: 1,
        },
      }),
      ui: false,
      // https://vitest.dev/config/browser/playwright
      provider: playwright(),
      instances: [
        {
          browser: "chromium",
          viewport: { width: 1440, height: 900 },
        },
      ],
      expect: {
        toMatchScreenshot: {
          screenshotOptions: {
            scale: "css",
          },
          comparatorOptions: {
            threshold: 0.2,
            allowedMismatchedPixelRatio: 0.05,
          },
        },
      },
    },
  },
});

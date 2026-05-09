import { defineConfig } from "vitest/config";
import { playwright } from "@vitest/browser-playwright";
import react from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";

const isUpdatingSnapshots = process.argv.some(
  (arg) => arg === "-u" || arg === "--update" || arg.startsWith("--update="),
);
const isRunningVisualTests = process.env.VISUAL_TESTS === "1";
const canUpdateVisualBaselines =
  process.env.CI === "true" && process.env.VISUAL_BASELINE_UPDATE === "1";

if (isUpdatingSnapshots && !canUpdateVisualBaselines) {
  throw new Error(
    "Visual screenshot baselines are CI-owned. Run the Update Visual Regression Screenshots GitHub Actions workflow instead.",
  );
}

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
    include: isRunningVisualTests
      ? ["__tests__/visual/*.jsx"]
      : ["__tests__/*.jsx"],
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

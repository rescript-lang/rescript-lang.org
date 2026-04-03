import { defineConfig } from "vitest/config";
import { playwright } from "@vitest/browser-playwright";
import react from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";

export default defineConfig({
  plugins: [react(), tailwindcss()],
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

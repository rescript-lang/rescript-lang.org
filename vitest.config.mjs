import { defineConfig } from "vitest/config";
import { playwright, defineBrowserCommand } from "@vitest/browser-playwright";
import react from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";

export default defineConfig({
  plugins: [react(), tailwindcss()],
  test: {
    include: ["__tests__/*.jsx"],
    setupFiles: ["./vitest.setup.mjs"],
    browser: {
      enabled: true,
      provider: playwright(),
      // https://vitest.dev/config/browser/playwright
      instances: [
        {
          browser: "chromium",
          name: "desktop",
          viewport: { width: 1440, height: 900 },
        },
      ],
    },
  },
});

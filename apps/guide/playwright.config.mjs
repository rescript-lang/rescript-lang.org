import { defineConfig } from "playwright/test";

export default defineConfig({
  testDir: "./e2e",
  use: {
    baseURL: "http://localhost:4174",
    viewport: { width: 1440, height: 900 },
    trace: "retain-on-failure",
  },
  webServer: {
    command:
      "yarn vite preview --outDir build/client --host localhost --port 4174 --strictPort",
    url: "http://localhost:4174",
  },
});

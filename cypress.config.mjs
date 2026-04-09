import { defineConfig } from "cypress";

export default defineConfig({
  allowCypressEnv: false,
  e2e: {
    baseUrl: "http://localhost:8080",
    specPattern: "e2e/**/*.cy.jsx",
    supportFile: "cypress/support/e2e.js",
    video: false,
    screenshotOnRunFailure: false,
    defaultCommandTimeout: 10000,
    pageLoadTimeout: 30000,
  },
});

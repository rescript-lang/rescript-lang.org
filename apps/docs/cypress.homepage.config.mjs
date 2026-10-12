import { defineConfig } from "cypress";
import config from "./cypress.config.mjs";

export default defineConfig({
  ...config,
  viewportWidth: 1440,
  viewportHeight: 900,
  screenshotsFolder: "test-results/cypress/screenshots",
  e2e: {
    ...config.e2e,
    baseUrl: "http://127.0.0.1:4173",
    specPattern: "e2e/homepage/**/*.cy.jsx",
    excludeSpecPattern: [],
    supportFile: "e2e/homepage/HomepageSupport.jsx",
    screenshotOnRunFailure: true,
  },
});

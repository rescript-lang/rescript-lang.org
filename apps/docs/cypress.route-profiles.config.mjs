import { defineConfig } from "cypress";
import config from "./cypress.config.mjs";

export default defineConfig({
  ...config,
  e2e: {
    ...config.e2e,
    specPattern: "e2e/RouteProfiles.cy.jsx",
    excludeSpecPattern: [],
    supportFile: "e2e/RouteProfilesSupport.jsx",
  },
});

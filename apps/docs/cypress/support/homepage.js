import "cypress-real-events/support.js";
import { removeCypressBootstrap } from "./bootstrap.js";

mocha.forbidOnly(!Cypress.config("isInteractive"));

// Unlike the legacy suite, homepage guardrails must fail on hydration errors.
beforeEach(() => {
  cy.then(() =>
    Cypress.automation("remote:debugger:protocol", {
      command: "Network.clearBrowserCache",
    }),
  );
  const consoleSpies = [];
  cy.wrap(consoleSpies, { log: false }).as("consoleSpies");
  cy.on("window:before:load", (window) => {
    expect(
      removeCypressBootstrap(window),
      "removed Cypress bootstrap",
    ).to.equal(true);
    consoleSpies.push(cy.spy(window.console, "error"));
  });
});

afterEach(() => {
  cy.get("@consoleSpies").then((spies) => {
    for (const spy of spies) expect(spy).not.to.have.been.called;
  });
});

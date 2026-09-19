import {
  grantClipboardPermissions,
  headline,
  readClipboard,
} from "./helpers.js";

it("community gallery supports keyboard selection and wraps to the first photo", () => {
  cy.visit("/");
  cy.contains("h1", headline).realClick();
  const first = 'button[aria-label="Show community photo 1"]';
  const third = 'button[aria-label="Show community photo 3"]';
  const next = 'button[aria-label="Next community photo"]';

  cy.get(first).should("have.attr", "aria-pressed", "true");
  cy.get(third).scrollIntoView().focus().realPress("Enter");
  cy.get(third).should("have.attr", "aria-pressed", "true").and("be.focused");
  cy.get('img[alt="ReScript community photo 3"]').should("be.visible");
  cy.get(next).focus().realPress("Space");
  cy.get(first).should("have.attr", "aria-pressed", "true");
  cy.get(next).should("be.focused");
  cy.get('img[alt="ReScript community photo 1"]').should("be.visible");
});

it("clipboard denial can recover and both install commands can be copied repeatedly", () => {
  cy.then(() =>
    Cypress.automation("remote:debugger:protocol", {
      command: "Browser.grantPermissions",
      params: {
        permissions: [],
        origin: new URL(Cypress.config("baseUrl")).origin,
      },
    }),
  );
  cy.visit("/");
  const first = 'button[aria-label="Copy npm install rescript command"]';
  cy.get('[role="status"]').should("have.length", 2);
  cy.get('button [role="status"]').should("not.exist");
  cy.get(first).realClick();
  cy.contains('[role="status"]', "Could not copy. Try again.").should(
    "be.visible",
  );
  cy.get(first).should("be.enabled");
  grantClipboardPermissions();

  for (const command of ["npm install rescript", "npx create-rescript-app"]) {
    const button = `button[aria-label="Copy ${command} command"]`;
    cy.get(button).realClick();
    cy.contains('[role="status"]', "Copied!").should("be.visible");
    cy.get(button).should("be.disabled");
    readClipboard().should("equal", command);
    cy.get(button).should("be.enabled");
    cy.contains("Copied!").should("not.exist");
    cy.get(button).realClick();
    cy.contains("Copied!").should("be.visible");
    cy.get(button).should("be.enabled");
  }
});

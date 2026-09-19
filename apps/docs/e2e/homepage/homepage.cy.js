import {
  grantClipboardPermissions,
  headline,
  readClipboard,
} from "./helpers.js";

it("homepage hydrates with working links and copy feedback", () => {
  cy.intercept({ resourceType: "image" }, (request) => {
    request.on("response", (response) => {
      expect(response.statusCode, request.url).to.be.lessThan(400);
    });
  });
  grantClipboardPermissions();
  cy.visit("/");
  cy.contains("h1", headline).should("be.visible");
  cy.contains("a", "Get started").should(
    "have.attr",
    "href",
    "/docs/manual/installation",
  );
  cy.contains("a", "Edit this example in Playground")
    .should("have.attr", "href")
    .and("match", /\/try\?code=.+/);
  cy.get('button[aria-label="Copy npm install rescript command"]').realClick();
  cy.contains("Copied!").should("be.visible");
  readClipboard().should("equal", "npm install rescript");
  cy.get("main section").each(($section) => cy.wrap($section).scrollIntoView());
  cy.get("img").each(($image) => {
    cy.wrap($image)
      .scrollIntoView()
      .should(($loaded) => {
        expect($loaded[0].complete, $loaded[0].src).to.equal(true);
        expect($loaded[0].naturalWidth, $loaded[0].src).to.be.greaterThan(0);
      });
  });
});

it("homepage and documentation navigation works in both directions", () => {
  cy.visit("/");
  cy.contains("a", /^Docs$/).click();
  cy.location("pathname").should("equal", "/docs/manual/introduction");
  cy.contains("h1", /^ReScript$/).should("be.visible");
  cy.get('a[aria-label="homepage"]').click();
  cy.location("pathname").should("equal", "/");
  cy.contains("h1", headline).should("be.visible");
});

it("mobile navigation opens the packages route", () => {
  cy.viewport(375, 812);
  cy.visit("/");
  cy.get('button[aria-label="Toggle additional menu"]').click();
  cy.contains("a", /^Packages$/)
    .should("be.visible")
    .click();
  cy.location("pathname").should("equal", "/packages");
  cy.contains("h1", "Libraries & Bindings").should("be.visible");
});

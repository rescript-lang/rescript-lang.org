import { headline } from "./helpers.js";

const boldFont = "/fonts/subset-Inter-Bold.woff2";

for (const width of [375, 1023]) {
  it(`homepage at ${width}px does not request the desktop headline font`, () => {
    const fontRequests = [];
    cy.intercept({ resourceType: "font" }, (request) => {
      fontRequests.push(new URL(request.url).pathname);
    });
    cy.viewport(width, 900);
    cy.visit("/");
    cy.contains("h1", headline).should("have.css", "font-weight", "600");
    cy.document()
      .then((document) => document.fonts.ready)
      .then(() => {
        expect(fontRequests).to.include("/fonts/subset-Inter-SemiBold.woff2");
        expect(fontRequests).not.to.include(boldFont);
      });
  });
}

it("the desktop headline font loads at the 1024px breakpoint", () => {
  cy.viewport(1024, 900);
  cy.intercept({ pathname: boldFont }).as("desktopHeadlineFont");
  cy.visit("/");
  cy.contains("h1", headline).should("have.css", "font-weight", "700");
  cy.wait("@desktopHeadlineFont")
    .its("response.statusCode")
    .should("be.within", 200, 299);
});

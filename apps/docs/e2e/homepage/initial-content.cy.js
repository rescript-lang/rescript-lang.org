import { headline } from "./helpers.js";

function visitWithoutHydration(path) {
  // Cypress needs JavaScript itself; empty application modules keep the AUT prerender-only.
  cy.intercept(/\/assets\/[^/]+\.js(?:\?.*)?$/, (request) => {
    if (/\/entry\.client-[^/]+\.js/.test(request.url))
      request.alias = "clientEntry";
    request.reply({
      statusCode: 200,
      headers: { "content-type": "text/javascript" },
      body: "",
    });
  });
  cy.visit(path);
  cy.wait("@clientEntry").its("response.body").should("equal", "");
}

it("homepage paragraphs render without hydration or downloaded fonts", () => {
  cy.intercept(/\.(?:woff2?|ttf|otf)(?:\?|$)/, { forceNetworkError: true });
  visitWithoutHydration("/");
  cy.get("html").should("have.css", "opacity", "1");
  cy.contains(
    "p",
    "ReScript is a strongly typed language that compiles to clean,",
  )
    .should("be.visible")
    .and("have.css", "color", "rgb(105, 107, 125)");
  cy.contains("p", "Its fast compiler and static type system").should(
    "be.visible",
  );
});

for (const path of ["/", "/docs/manual/introduction/"]) {
  it(`${path} remains readable when the shared stylesheet fails`, () => {
    cy.intercept("**/assets/main-*.css", { forceNetworkError: true }).as(
      "sharedStylesheet",
    );
    visitWithoutHydration(path);
    cy.wait("@sharedStylesheet").should("have.property", "error");
    cy.get("html").should("have.css", "opacity", "1");
    cy.contains("h1", path === "/" ? headline : /^ReScript$/).should(
      "be.visible",
    );
  });
}

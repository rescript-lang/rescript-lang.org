import { headline, homepageDocument, initialScriptUrls } from "./helpers.js";
import { installationResults } from "./search-result.js";

const searchChunk = /\/assets\/SearchModal-[^/]+\.js$/;
const search = 'button[aria-label="Search"]';
const input = 'input[placeholder="Search docs"]';
const close = 'button[aria-label="Close search"]';

it("initial homepage assets exclude the search implementation and styles", () => {
  homepageDocument().then((document) => {
    const scripts = initialScriptUrls(document);
    const styles = [
      ...document.querySelectorAll('link[rel="stylesheet"][href]'),
    ].map((element) => element.getAttribute("href"));
    expect(scripts.length).to.be.greaterThan(0);
    expect(styles.length).to.be.greaterThan(0);
    for (const asset of scripts) {
      cy.request(asset).then(({ status, body }) => {
        expect(status, asset).to.equal(200);
        expect(body, asset).not.to.include("search-insights");
        expect(body, asset).not.to.include("DocSearch-Modal");
      });
    }
    for (const asset of styles) {
      cy.request(asset).then(({ status, body }) => {
        expect(status, asset).to.equal(200);
        expect(body, asset).not.to.include(".DocSearch-Modal");
      });
    }
  });
});

it("search loads on activation, stays styled, and supports keyboard reopening", () => {
  const requests = [];
  cy.intercept("**", (request) => {
    if (
      request.url.includes("search-insights") ||
      searchChunk.test(request.url)
    ) {
      requests.push(request.url);
    }
  });
  cy.visit("/");
  cy.get(search).should("be.visible");
  cy.get(input).should("not.exist");
  cy.then(() => expect(requests).to.deep.equal([]));
  cy.get(search).click();
  cy.get(input).should("be.focused");
  cy.then(() =>
    expect(requests.some((url) => searchChunk.test(url))).to.equal(true),
  );
  cy.get(".DocSearch-Container").should("have.css", "position", "fixed");
  cy.get(".DocSearch-Modal")
    .should("have.css", "opacity", "1")
    .and("have.css", "max-width", "768px");
  cy.realPress("Escape");
  cy.get(input).should("not.exist");
  cy.realPress("/");
  cy.get(input).should("be.focused");
  cy.realPress("/");
  cy.get(input).should("have.value", "/");
  cy.realPress("Escape");
  cy.get(input).should("have.value", "").and("be.focused");
  cy.realPress("Escape");
  cy.get(input).should("not.exist");
  cy.realPress(["Control", "k"]);
  cy.get(input).should("be.focused");
  cy.realPress("Escape");
  cy.get(input).should("not.exist");
});

it("lazy search results navigate into documentation", () => {
  cy.intercept(
    { hostname: /\.(algolia\.net|algolianet\.com)$/, pathname: /\/queries$/ },
    {
      statusCode: 200,
      body: installationResults,
    },
  );
  cy.visit("/");
  cy.get(search).click();
  cy.get(input).type("installation");
  cy.get(".DocSearch-Modal")
    .contains("a", /^Installation$/)
    .click();
  cy.location("pathname").should("equal", "/docs/manual/installation");
  cy.contains("h1", /^Installation$/).should("be.visible");
  cy.get(input).should("not.exist");
});

it("a pending search load can be closed without opening the modal afterward", () => {
  const download = Promise.withResolvers();
  cy.on("fail", (error) => {
    download.resolve();
    throw error;
  });
  cy.intercept(searchChunk, () => download.promise).as("searchChunk");
  cy.visit("/");
  cy.get(search).click();
  cy.get(close).should("be.visible");
  cy.realPress("Escape");
  cy.get(close).should("not.exist");
  cy.get(search).should("be.focused");
  cy.then(() => download.resolve());
  cy.wait("@searchChunk");
  cy.get(search).should("be.focused");
  cy.get(input).should("not.exist");
  cy.get(search).click();
  cy.get(input).should("be.focused");
});

it("a failed search chunk leaves the page usable and recovers after a reload", () => {
  let blockChunk = true;
  cy.intercept(searchChunk, (request) => {
    if (blockChunk) request.destroy();
  });
  cy.wrap(
    [
      /Failed to fetch dynamically imported module: .*\/assets\/SearchModal-[^/]+\.js/,
    ],
    { log: false },
  ).as("expectedConsoleErrors");
  cy.visit("/");
  cy.get(search).click();
  cy.contains('[role="alert"]', "Search unavailable").should("be.visible");
  cy.get(close).click();
  cy.get('[role="alert"]').should("not.exist");
  cy.get(search).should("be.focused");
  cy.contains("h1", headline).should("be.visible");
  cy.then(() => {
    blockChunk = false;
  });
  cy.reload();
  cy.get(search).click();
  cy.get(input).should("be.focused");
});

import { homepageDocument, initialScriptUrls } from "./helpers.js";

it("initial homepage scripts do not include example preparation or compression", () => {
  homepageDocument().then((document) => {
    const scripts = initialScriptUrls(document);
    expect(scripts.length).to.be.greaterThan(0);
    for (const asset of scripts) {
      cy.request(asset).then(({ status, body }) => {
        expect(status, asset).to.equal(200);
        expect(body, asset).not.to.include("compressToEncodedURIComponent");
        expect(body, asset).not.to.include("function Playground$Button(props)");
      });
    }
  });
});

it("prepared examples survive hydration and navigation back from documentation", () => {
  homepageDocument().then((document) => {
    const examples = ["res", "js"].map((language) => ({
      selector: `code.lang-${language}`,
      html: document.querySelector(`code.lang-${language}`)?.innerHTML,
    }));
    const playgroundHref = document
      .querySelector('a[href^="/try?code="]')
      ?.getAttribute("href");
    expect(playgroundHref).to.match(/^\/try\?code=.+/);
    for (const example of examples)
      expect(example.html).to.include('<span class="hljs-');
    cy.visit("/");
    for (const example of examples)
      cy.get(example.selector).should("have.prop", "innerHTML", example.html);
    cy.contains("a", /^Docs$/).click();
    cy.location("pathname").should("equal", "/docs/manual/introduction");
    cy.get('a[aria-label="homepage"]').click();
    cy.location("pathname").should("equal", "/");
    for (const example of examples) {
      cy.get(example.selector)
        .should("be.visible")
        .and("have.prop", "innerHTML", example.html);
    }
    cy.contains("a", "Edit this example in Playground").should(
      "have.attr",
      "href",
      playgroundHref,
    );
  });
});

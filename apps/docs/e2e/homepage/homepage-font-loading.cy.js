import { headline, homepageDocument } from "./helpers.js";

const fontFiles = [
  "/fonts/subset-Inter-Regular.woff2",
  "/fonts/subset-Inter-SemiBold.woff2",
  "/fonts/subset-Inter-Bold.woff2",
  "/fonts/red-hat-mono-700.woff2",
];

const fonts = [
  '400 1rem "Homepage Inter"',
  '600 1rem "Homepage Inter"',
  '700 1rem "Homepage Inter"',
  '700 1rem "Red Hat Mono"',
];

function loadFont(fontSet, font) {
  return fontSet.load(font).then(
    () => ({ font, loaded: true }),
    (error) => ({ font, loaded: false, error: String(error) }),
  );
}

it("homepage prerender includes exactly its four local font preloads", () => {
  homepageDocument().then((document) => {
    const preloads = Array.from(
      document.querySelectorAll('head link[rel="preload"][as="font"]'),
      (link) => ({
        href: link.getAttribute("href"),
        type: link.getAttribute("type"),
        crossOrigin: link.getAttribute("crossorigin"),
        media: link.getAttribute("media"),
      }),
    );
    expect(preloads).to.deep.equal(
      fontFiles.map((href) => ({
        href,
        type: "font/woff2",
        crossOrigin: "anonymous",
        media:
          href === "/fonts/subset-Inter-Bold.woff2"
            ? "(min-width: 1024px)"
            : null,
      })),
    );
    expect(document.documentElement.outerHTML).not.to.include(
      "fonts.googleapis.com",
    );
    expect(document.documentElement.outerHTML).not.to.include(
      "fonts.gstatic.com",
    );
  });
});

it("homepage loads all four font faces using only local requests", () => {
  const requests = [];
  cy.intercept("**", (request) => {
    const url = new URL(request.url);
    if (
      request.resourceType === "font" ||
      url.hostname === "fonts.googleapis.com" ||
      url.hostname === "fonts.gstatic.com"
    )
      requests.push(url);
  });
  cy.visit("/");
  cy.contains("h1", headline).should("have.css", "font-weight", "700");
  cy.document()
    .then(async (document) => {
      const loaded = await Promise.all(
        fonts.map((font) => loadFont(document.fonts, font)),
      );
      expect(loaded).to.deep.equal(
        fonts.map((font) => ({ font, loaded: true })),
      );
      return fonts.map((font) => document.fonts.check(font));
    })
    .should("deep.equal", [true, true, true, true]);
  cy.get("main section").each(($section) => cy.wrap($section).scrollIntoView());
  cy.document()
    .then((document) => document.fonts.ready)
    .then(() => {
      expect(requests.map((url) => url.pathname)).to.include.members(fontFiles);
      const origin = new URL(Cypress.config("baseUrl")).origin;
      expect(requests.every((url) => url.origin === origin)).to.equal(true);
    });
});

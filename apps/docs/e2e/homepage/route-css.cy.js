import { headline } from "./helpers.js";

const homepageLayoutSelectors = [
  ".max-w-1060",
  ".md\\:grid-cols-10",
  ".md\\:col-span-6",
  ".min-h-148",
];

function expectDesktopLogo() {
  cy.get('a[aria-label="homepage"]')
    .should("have.css", "width", "128px")
    .and("have.css", "height", "40px");
  cy.get('a[aria-label="homepage"] img[alt="ReScript Home"]').should(
    "be.visible",
  );
}

function loadedStyles() {
  return cy.window().then(async (window) => {
    const links = [
      ...window.document.querySelectorAll('link[rel="stylesheet"]'),
    ];
    const styles = await Promise.all(
      links.map(async (link) => {
        const response = await window.fetch(link.href);
        expect(response.status, link.href).to.equal(200);
        return response.text();
      }),
    );
    return styles.join("\n");
  });
}

function flattenRules(rules) {
  return Array.from(rules).flatMap((rule) =>
    "cssRules" in rule ? [rule, ...flattenRules(rule.cssRules)] : [rule],
  );
}

function foundationCounts(window) {
  const rules = Array.from(window.document.styleSheets).flatMap((sheet) =>
    flattenRules(sheet.cssRules),
  );
  const fonts = rules
    .filter((rule) => rule instanceof window.CSSFontFaceRule)
    .map((rule) => rule.cssText);
  const styles = rules.filter((rule) => rule instanceof window.CSSStyleRule);
  const tokens = [
    "--font-sans",
    "--color-gray-90",
    "--color-fire",
    "--text-48",
  ].map(
    (token) =>
      styles.filter((rule) => rule.style.getPropertyValue(token)).length,
  );
  const resets = styles.filter(
    (rule) =>
      rule.selectorText
        .split(",")
        .some((selector) => selector.trim() === "*") &&
      rule.style.boxSizing === "border-box",
  ).length;
  return {
    fonts: fonts.length,
    uniqueFonts: new Set(fonts).size,
    tokens,
    resets,
  };
}

function expectContentStyles() {
  loadedStyles().then((styles) => {
    expect(styles).to.include(".markdown-body");
    expect(styles).not.to.include(".playground-theme");
    for (const selector of homepageLayoutSelectors) {
      expect(styles).not.to.include(selector);
    }
  });
}

it("homepage styles exclude content, search, and playground rules", () => {
  cy.visit("/");
  cy.contains("h1", headline).should("be.visible");
  loadedStyles().then((styles) => {
    expect(styles).to.include(".gallery-selector");
    for (const selector of homepageLayoutSelectors) {
      expect(styles).to.include(selector);
    }
    for (const selector of [
      ".markdown-body",
      ".playground-theme",
      ".DocSearch-Modal",
    ]) {
      expect(styles).not.to.include(selector);
    }
  });
});

it("shared foundations are emitted once across route navigation", () => {
  cy.visit("/");
  cy.window()
    .then(foundationCounts)
    .then((initial) => {
      expect(initial.fonts).to.be.greaterThan(0);
      expect(initial.uniqueFonts).to.equal(initial.fonts);
      expect(initial.tokens).to.deep.equal([1, 1, 1, 1]);
      expect(initial.resets).to.equal(1);
      cy.contains("a", /^Docs$/).click();
      cy.contains("h1", /^ReScript$/).should("be.visible");
      cy.window().then(foundationCounts).should("deep.equal", initial);
      cy.get('a[aria-label="homepage"]').click();
      cy.contains("h1", headline).should("have.css", "font-size", "68px");
      cy.window().then(foundationCounts).should("deep.equal", initial);
    });
});

it("desktop navigation keeps its responsive logo across route stylesheets", () => {
  cy.visit("/");
  expectDesktopLogo();
  cy.contains("a", /^Docs$/).click();
  cy.contains("h1", /^ReScript$/).should("be.visible");
  expectDesktopLogo();
  cy.get('a[aria-label="homepage"]').click();
  cy.contains("h1", headline).should("be.visible");
  expectDesktopLogo();
});

it("documentation styles are prefetched only after navigation intent", () => {
  cy.visit("/");
  const prefetch = 'link[rel="prefetch"][as="style"][href*="/content-"]';
  cy.get(prefetch).should("not.exist");
  cy.contains("a", /^Get started$/).focus();
  cy.get(prefetch).should("have.length", 1);
  cy.contains("a", /^Docs$/).focus();
  cy.get(prefetch).should("not.exist");
});

for (const route of [
  { path: "/docs/manual/introduction/", title: "ReScript" },
  { path: "/brand/", title: "Brand Assets" },
  { path: "/packages/", title: "Libraries & Bindings" },
]) {
  it(`cold ${route.path} loads its content styles`, () => {
    cy.visit(route.path);
    cy.contains("h1", route.title)
      .should("be.visible")
      .and("have.css", "font-weight", "600")
      .and("have.css", "font-size", "48px");
    expectContentStyles();
  });
}

it("cold blog styles preserve article typography", () => {
  cy.visit("/blog/");
  cy.get("h2")
    .first()
    .should("be.visible")
    .and("have.css", "font-size", "48px")
    .and("have.css", "font-weight", "600");
  expectContentStyles();
});

it("mobile documentation drawer retains its layout after navigation", () => {
  cy.viewport(375, 812);
  cy.visit("/");
  cy.contains("a", /^Docs$/).click();
  cy.contains("h1", /^ReScript$/).should("be.visible");
  cy.get('button[aria-label="Toggle navigation menu"]').click();
  cy.get("dialog#mobile-tertiary-drawer")
    .as("drawer")
    .should("be.visible")
    .and("have.css", "background-color", "rgb(255, 255, 255)")
    .and("have.css", "margin-left", "0px");
  cy.get("@drawer")
    .contains("a", /^Installation$/)
    .click();
  cy.contains("h1", /^Installation$/).should("be.visible");
  cy.realPress("Escape");
  cy.get("@drawer").should("not.be.visible");
});

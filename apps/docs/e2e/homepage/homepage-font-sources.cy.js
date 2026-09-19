import { headline } from "./helpers.js";

function collectFontFaces(rules, FontFaceRule) {
  return Array.from(rules).flatMap((rule) => {
    if (rule instanceof FontFaceRule) {
      return [
        {
          family: rule.style.fontFamily.replaceAll('"', ""),
          weight: rule.style.fontWeight,
          style: rule.style.fontStyle,
          source: rule.style.getPropertyValue("src"),
          display: rule.style.getPropertyValue("font-display"),
          unicodeRange: rule.style.getPropertyValue("unicode-range"),
        },
      ];
    }
    return "cssRules" in rule
      ? collectFontFaces(rule.cssRules, FontFaceRule)
      : [];
  });
}

function readFontFaces() {
  return cy
    .window()
    .then((window) =>
      Array.from(window.document.styleSheets).flatMap((sheet) =>
        collectFontFaces(sheet.cssRules, window.CSSFontFaceRule),
      ),
    );
}

function findFontFace(faces, family, weight, style = "normal") {
  return faces.find(
    (face) =>
      face.family === family && face.weight === weight && face.style === style,
  );
}

it("homepage consumes its preloaded Inter faces without bypassing them for local fonts", () => {
  cy.visit("/");
  cy.contains("h1", headline)
    .should("have.css", "font-family")
    .and("match", /^"Homepage Inter", Inter,/);
  readFontFaces().then((faces) => {
    for (const [weight, file] of [
      ["400", "Regular"],
      ["600", "SemiBold"],
      ["700", "Bold"],
    ]) {
      const homepageFace = findFontFace(faces, "Homepage Inter", weight);
      const sharedFace = findFontFace(faces, "Inter", weight);
      expect(homepageFace, `Homepage Inter ${weight}`).not.to.equal(undefined);
      expect(sharedFace, `Inter ${weight}`).not.to.equal(undefined);
      expect(homepageFace.source).to.match(/^url\(/);
      expect(homepageFace.source).to.include(
        `/fonts/subset-Inter-${file}.woff2`,
      );
      expect(homepageFace.source).not.to.include("local(");
      expect(homepageFace.display).to.equal("swap");
      expect(homepageFace.unicodeRange).to.equal(sharedFace.unicodeRange);
      expect(sharedFace.source).to.match(/^local\(/);
    }
  });
});

it("homepage preserves the existing Medium and Italic font faces", () => {
  cy.visit("/");
  readFontFaces().then((faces) => {
    for (const [weight, style] of [
      ["500", "normal"],
      ["400", "italic"],
    ]) {
      const homepageFace = findFontFace(faces, "Homepage Inter", weight, style);
      const sharedFace = findFontFace(faces, "Inter", weight, style);
      expect(sharedFace, `Inter ${weight} ${style}`).not.to.equal(undefined);
      expect(homepageFace).to.deep.equal({
        ...sharedFace,
        family: "Homepage Inter",
      });
    }
  });
});

it("documentation keeps its local-first Inter family across homepage navigation", () => {
  cy.visit("/");
  cy.contains("a", /^Docs$/).click();
  cy.contains("h1", /^ReScript$/)
    .should("have.css", "font-family")
    .and("match", /^Inter,/);
  readFontFaces().then((faces) => {
    const sharedFaces = faces.filter((face) => face.family === "Inter");
    expect(sharedFaces).to.have.length(5);
    for (const face of sharedFaces) expect(face.source).to.match(/^local\(/);
  });
  cy.get('a[aria-label="homepage"]').click();
  cy.contains("h1", headline)
    .should("have.css", "font-family")
    .and("match", /^"Homepage Inter", Inter,/);
  cy.contains("a", /^Docs$/).click();
  cy.contains("h1", /^ReScript$/)
    .should("have.css", "font-family")
    .and("match", /^Inter,/);
});

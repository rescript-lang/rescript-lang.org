import { expect, test } from "playwright/test";

async function readFontFaces(page) {
  return page.evaluate(() => {
    function collectFontFaces(rules) {
      return Array.from(rules).flatMap((rule) => {
        if (rule instanceof CSSFontFaceRule) {
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

        return "cssRules" in rule ? collectFontFaces(rule.cssRules) : [];
      });
    }

    return Array.from(document.styleSheets).flatMap((sheet) =>
      collectFontFaces(sheet.cssRules),
    );
  });
}

function findFontFace(faces, family, weight, style = "normal") {
  return faces.find(
    (face) =>
      face.family === family && face.weight === weight && face.style === style,
  );
}

test("homepage consumes its preloaded Inter faces without bypassing them for local fonts", async ({
  page,
}) => {
  await page.goto("/");
  await expect(
    page.getByRole("heading", {
      level: 1,
      name: "JavaScript Made Simple for Humans and AI",
    }),
  ).toHaveCSS("font-family", /^"Homepage Inter", Inter,/);

  const faces = await readFontFaces(page);
  for (const [weight, file] of [
    ["400", "Regular"],
    ["600", "SemiBold"],
    ["700", "Bold"],
  ]) {
    const homepageFace = findFontFace(faces, "Homepage Inter", weight);
    const sharedFace = findFontFace(faces, "Inter", weight);

    expect(homepageFace).toBeDefined();
    expect(sharedFace).toBeDefined();
    expect(homepageFace.source).toMatch(/^url\(/);
    expect(homepageFace.source).toContain(`/fonts/subset-Inter-${file}.woff2`);
    expect(homepageFace.source).not.toContain("local(");
    expect(homepageFace.display).toBe("swap");
    expect(homepageFace.unicodeRange).toBe(sharedFace.unicodeRange);
    expect(sharedFace.source).toMatch(/^local\(/);
  }
});

test("homepage preserves the existing Medium and Italic font faces", async ({
  page,
}) => {
  await page.goto("/");
  const faces = await readFontFaces(page);
  for (const [weight, style] of [
    ["500", "normal"],
    ["400", "italic"],
  ]) {
    const homepageFace = findFontFace(faces, "Homepage Inter", weight, style);
    const sharedFace = findFontFace(faces, "Inter", weight, style);

    expect(sharedFace).toBeDefined();
    expect(homepageFace).toEqual({ ...sharedFace, family: "Homepage Inter" });
  }
});

test("documentation keeps its local-first Inter family across homepage navigation", async ({
  page,
}) => {
  await page.goto("/");
  await page.getByRole("link", { name: "Docs", exact: true }).click();
  const heading = page.getByRole("heading", {
    level: 1,
    name: "ReScript",
    exact: true,
  });
  await expect(heading).toHaveCSS("font-family", /^Inter,/);

  const faces = (await readFontFaces(page)).filter(
    (face) => face.family === "Inter",
  );
  expect(faces).toHaveLength(5);
  for (const face of faces) {
    expect(face.source).toMatch(/^local\(/);
  }

  await page.getByRole("link", { name: "homepage" }).click();
  await expect(
    page.getByRole("heading", {
      level: 1,
      name: "JavaScript Made Simple for Humans and AI",
    }),
  ).toHaveCSS("font-family", /^"Homepage Inter", Inter,/);
  await page.getByRole("link", { name: "Docs", exact: true }).click();
  await expect(heading).toHaveCSS("font-family", /^Inter,/);
});

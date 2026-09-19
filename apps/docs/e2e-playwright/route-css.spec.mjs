import { expect, test } from "playwright/test";

const homepageTitle = "JavaScript Made Simple for Humans and AI";

async function expectDesktopLogo(page) {
  const homeLink = page.getByRole("link", { name: "homepage" });
  await expect(homeLink).toHaveCSS("width", "128px");
  await expect(homeLink).toHaveCSS("height", "40px");
  await expect(
    homeLink.getByRole("img", { name: "ReScript Home" }),
  ).toBeVisible();
}

async function loadedStyles(page) {
  return page.locator('link[rel="stylesheet"]').evaluateAll(async (links) => {
    const styles = await Promise.all(
      links.map(async (link) => (await fetch(link.href)).text()),
    );
    return styles.join("\n");
  });
}

async function foundationCounts(page) {
  return page.evaluate(() => {
    function flattenRules(rules) {
      return Array.from(rules).flatMap((rule) =>
        "cssRules" in rule ? [rule, ...flattenRules(rule.cssRules)] : [rule],
      );
    }

    const rules = Array.from(document.styleSheets).flatMap((sheet) =>
      flattenRules(sheet.cssRules),
    );
    const fonts = rules
      .filter((rule) => rule instanceof CSSFontFaceRule)
      .map((rule) => rule.cssText);
    const tokens = [
      "--font-sans",
      "--color-gray-90",
      "--color-fire",
      "--text-48",
    ].map(
      (token) =>
        rules.filter(
          (rule) =>
            rule instanceof CSSStyleRule && rule.style.getPropertyValue(token),
        ).length,
    );
    const resets = rules.filter(
      (rule) =>
        rule instanceof CSSStyleRule &&
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
  });
}

test("homepage styles exclude content, search, and playground rules", async ({
  page,
}) => {
  await page.goto("/");
  await expect(
    page.getByRole("heading", { level: 1, name: homepageTitle }),
  ).toBeVisible();

  const styles = await loadedStyles(page);

  expect(styles).toContain(".gallery-selector");
  expect(styles).not.toContain(".markdown-body");
  expect(styles).not.toContain(".playground-theme");
  expect(styles).not.toContain(".DocSearch-Modal");
});

test("shared foundations are emitted once across route navigation", async ({
  page,
}) => {
  await page.goto("/");
  const initial = await foundationCounts(page);
  expect(initial.fonts).toBeGreaterThan(0);
  expect(initial.uniqueFonts).toBe(initial.fonts);
  expect(initial.tokens).toEqual([1, 1, 1, 1]);
  expect(initial.resets).toBe(1);

  await page.getByRole("link", { name: "Docs", exact: true }).click();
  await expect(
    page.getByRole("heading", { level: 1, name: "ReScript", exact: true }),
  ).toBeVisible();
  expect(await foundationCounts(page)).toEqual(initial);

  await page.getByRole("link", { name: "homepage" }).click();
  await expect(
    page.getByRole("heading", { level: 1, name: homepageTitle }),
  ).toHaveCSS("font-size", "68px");
  expect(await foundationCounts(page)).toEqual(initial);
});

test("desktop navigation keeps its responsive logo across route stylesheets", async ({
  page,
}) => {
  await page.setViewportSize({ width: 1440, height: 900 });
  await page.goto("/");
  await expectDesktopLogo(page);
  await page.getByRole("link", { name: "Docs", exact: true }).click();
  await expect(
    page.getByRole("heading", { level: 1, name: "ReScript", exact: true }),
  ).toBeVisible();
  await expectDesktopLogo(page);
  await page.getByRole("link", { name: "homepage" }).click();
  await expect(
    page.getByRole("heading", { level: 1, name: homepageTitle }),
  ).toBeVisible();
  await expectDesktopLogo(page);
});

test("documentation styles are prefetched only after navigation intent", async ({
  page,
}) => {
  await page.goto("/");
  const contentPrefetch = page.locator(
    'link[rel="prefetch"][as="style"][href*="/content-"]',
  );
  await expect(contentPrefetch).toHaveCount(0);
  await page.getByRole("link", { name: "Get started", exact: true }).focus();
  await expect(contentPrefetch).toHaveCount(1);
  await page.getByRole("link", { name: "Docs", exact: true }).focus();
  await expect(contentPrefetch).toHaveCount(0);
});

for (const route of [
  { path: "/docs/manual/introduction/", title: "ReScript" },
  { path: "/brand/", title: "Brand Assets" },
  { path: "/packages/", title: "Libraries & Bindings" },
]) {
  test(`cold ${route.path} loads its content styles`, async ({ page }) => {
    await page.goto(route.path);
    const heading = page.getByRole("heading", {
      level: 1,
      name: route.title,
      exact: true,
    });
    await expect(heading).toBeVisible();
    await expect(heading).toHaveCSS("font-weight", "600");
    await expect(heading).toHaveCSS("font-size", "48px");
    const styles = await loadedStyles(page);
    expect(styles).toContain(".markdown-body");
    expect(styles).not.toContain(".playground-theme");
  });
}

test("cold blog styles preserve article typography", async ({ page }) => {
  await page.goto("/blog/");
  const featuredTitle = page.getByRole("heading", { level: 2 }).first();
  await expect(featuredTitle).toBeVisible();
  await expect(featuredTitle).toHaveCSS("font-size", "48px");
  await expect(featuredTitle).toHaveCSS("font-weight", "600");
  const styles = await loadedStyles(page);
  expect(styles).toContain(".markdown-body");
  expect(styles).not.toContain(".playground-theme");
});

test("mobile documentation drawer retains its layout after navigation", async ({
  page,
}) => {
  await page.setViewportSize({ width: 375, height: 812 });
  await page.goto("/");
  await page.getByRole("link", { name: "Docs", exact: true }).click();
  await expect(
    page.getByRole("heading", { level: 1, name: "ReScript", exact: true }),
  ).toBeVisible();
  await page.getByRole("button", { name: "Toggle navigation menu" }).click();
  const drawer = page.getByRole("dialog");
  await expect(drawer).toBeVisible();
  await expect(drawer).toHaveCSS("background-color", "rgb(255, 255, 255)");
  await expect(drawer).toHaveCSS("margin-left", "0px");
  await drawer.getByRole("link", { name: "Installation", exact: true }).click();
  await expect(
    page.getByRole("heading", { level: 1, name: "Installation", exact: true }),
  ).toBeVisible();
  await page.keyboard.press("Escape");
  await expect(drawer).not.toBeVisible();
});

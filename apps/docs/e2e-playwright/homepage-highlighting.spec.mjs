import { expect, test } from "playwright/test";
import { JSDOM } from "jsdom";

test("initial homepage scripts exclude example preparation and the syntax runtime", async ({
  request,
}) => {
  const response = await request.get("/");
  const { document } = new JSDOM(await response.text()).window;
  const scripts = [
    ...document.querySelectorAll('link[rel="modulepreload"][href]'),
    ...document.querySelectorAll("script[src]"),
  ].map(
    (element) => element.getAttribute("href") ?? element.getAttribute("src"),
  );

  expect(response.ok()).toBe(true);
  expect(scripts.length).toBeGreaterThan(0);
  for (const asset of scripts) {
    const script = await request.get(asset);
    expect(script.ok()).toBe(true);
    const source = await script.text();
    expect(source.includes("compressToEncodedURIComponent"), asset).toBe(false);
    expect(source.includes("registerLanguage"), asset).toBe(false);
    expect(source.includes("function Playground$Button(props)"), asset).toBe(
      false,
    );
  }
});

test("content routes highlight JSON on direct loads and cold homepage navigation", async ({
  page,
  request,
}) => {
  const path = "/docs/manual/build-configuration";
  const response = await request.get(`${path}/`);
  const { document } = new JSDOM(await response.text()).window;
  expect(response.ok()).toBe(true);
  expect(document.querySelector("code.lang-json .hljs-attr")?.textContent).toBe(
    '"sources"',
  );

  await page.goto(`${path}/`);
  const property = page.locator("code.lang-json .hljs-attr").first();
  await expect(property).toHaveText('"sources"');
  await page.goto("/");
  await expect(page).toHaveURL("/");
  await expect(
    page.getByRole("heading", {
      level: 1,
      name: "JavaScript Made Simple for Humans and AI",
    }),
  ).toBeVisible();
  await page.getByRole("link", { name: "Docs", exact: true }).click();
  await expect(
    page.getByRole("heading", { level: 1, name: "ReScript", exact: true }),
  ).toBeVisible();
  await page.getByRole("link", { name: "Configuration", exact: true }).click();
  await expect(page).toHaveURL(path);
  await expect(property).toHaveText('"sources"');
});

test("prepared examples survive hydration and navigation back from documentation", async ({
  page,
  request,
}) => {
  const response = await request.get("/");
  const { document } = new JSDOM(await response.text()).window;
  const examples = ["res", "js"].map((language) => ({
    selector: `code.lang-${language}`,
    html: document.querySelector(`code.lang-${language}`)?.innerHTML,
  }));
  const playgroundHref = document
    .querySelector('a[href^="/try?code="]')
    ?.getAttribute("href");
  const runtimeErrors = [];
  page.on("pageerror", (error) => runtimeErrors.push(error.message));
  page.on("console", (message) => {
    if (message.type() === "error") runtimeErrors.push(message.text());
  });

  expect(response.ok()).toBe(true);
  expect(playgroundHref).toMatch(/^\/try\?code=.+/);
  for (const example of examples) {
    expect(example.html).toContain('<span class="hljs-');
  }
  await page.goto("/");
  for (const example of examples) {
    await expect(page.locator(example.selector)).toHaveJSProperty(
      "innerHTML",
      example.html,
    );
  }
  await page.getByRole("link", { name: "Docs", exact: true }).click();
  await expect(page).toHaveURL(/\/docs\/manual\/introduction$/);
  await page.getByRole("link", { name: "homepage" }).click();
  await expect(page).toHaveURL("/");

  for (const example of examples) {
    await expect(page.locator(example.selector)).toBeVisible();
    await expect(page.locator(example.selector)).toHaveJSProperty(
      "innerHTML",
      example.html,
    );
  }
  await expect(
    page.getByRole("link", { name: "Edit this example in Playground" }),
  ).toHaveAttribute("href", playgroundHref);
  expect(runtimeErrors).toEqual([]);
});

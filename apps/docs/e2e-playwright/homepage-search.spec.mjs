import { expect, test } from "playwright/test";
import { JSDOM } from "jsdom";

const searchChunk = /\/assets\/SearchModal-[^/]+\.js$/;

test("initial homepage assets exclude the search implementation and styles", async ({
  request,
}) => {
  const response = await request.get("/");
  const { document } = new JSDOM(await response.text()).window;
  const initialScripts = [
    ...document.querySelectorAll('link[rel="modulepreload"][href]'),
    ...document.querySelectorAll("script[src]"),
  ].map(
    (element) => element.getAttribute("href") ?? element.getAttribute("src"),
  );
  const initialStyles = [
    ...document.querySelectorAll('link[rel="stylesheet"][href]'),
  ].map((element) => element.getAttribute("href"));

  expect(response.ok()).toBe(true);
  expect(initialScripts.length).toBeGreaterThan(0);
  expect(initialStyles.length).toBeGreaterThan(0);
  for (const asset of initialScripts) {
    const script = await request.get(asset);
    expect(script.ok()).toBe(true);
    const source = await script.text();
    expect(source.includes("search-insights"), asset).toBe(false);
    expect(source.includes("DocSearch-Modal"), asset).toBe(false);
  }
  for (const asset of initialStyles) {
    const stylesheet = await request.get(asset);
    expect(stylesheet.ok()).toBe(true);
    expect((await stylesheet.text()).includes(".DocSearch-Modal"), asset).toBe(
      false,
    );
  }
});

test("search loads on activation, stays styled, and supports keyboard reopening", async ({
  page,
}) => {
  await page.setViewportSize({ width: 1440, height: 900 });
  const insightsRequests = [];
  const searchRequests = [];
  page.on("request", (request) => {
    if (request.url().includes("search-insights")) {
      insightsRequests.push(request.url());
    }
    if (searchChunk.test(request.url())) {
      searchRequests.push(request.url());
    }
  });
  await page.goto("/");
  const search = page.getByRole("button", { name: "Search", exact: true });
  const input = page.getByPlaceholder("Search docs", { exact: true });

  await expect(search).toBeVisible();
  await expect(input).toHaveCount(0);
  expect(insightsRequests).toEqual([]);
  expect(searchRequests).toEqual([]);
  await search.click();
  await expect(input).toBeFocused();
  expect(searchRequests.length).toBeGreaterThan(0);
  await expect(page.locator(".DocSearch-Container")).toHaveCSS(
    "position",
    "fixed",
  );
  await expect(page.locator(".DocSearch-Modal")).toHaveCSS("opacity", "1");
  await expect(page.locator(".DocSearch-Modal")).toHaveCSS(
    "max-width",
    "768px",
  );
  await input.press("Escape");
  await expect(input).toHaveCount(0);

  await page.keyboard.press("/");
  await expect(input).toBeFocused();
  await input.press("/");
  await expect(input).toHaveValue("/");
  await input.press("Escape");
  await expect(input).toHaveValue("");
  await expect(input).toBeFocused();
  await input.press("Escape");
  await expect(input).toHaveCount(0);
  await page.keyboard.press("Control+k");
  await expect(input).toBeFocused();
  await input.press("Escape");
  await expect(input).toHaveCount(0);
});

test("lazy search results navigate into documentation", async ({ page }) => {
  await page.route(
    (url) =>
      (url.hostname.endsWith(".algolia.net") ||
        url.hostname.endsWith(".algolianet.com")) &&
      url.pathname.endsWith("/queries"),
    async (route) => {
      await route.fulfill({
        json: {
          results: [
            {
              hits: [
                {
                  objectID: "installation",
                  url: "https://rescript-lang.org/docs/manual/installation",
                  url_without_anchor:
                    "https://rescript-lang.org/docs/manual/installation",
                  type: "lvl1",
                  anchor: null,
                  content: null,
                  hierarchy: {
                    lvl0: "ReScript",
                    lvl1: "Installation",
                    lvl2: null,
                    lvl3: null,
                    lvl4: null,
                    lvl5: null,
                    lvl6: null,
                  },
                },
              ],
              nbHits: 1,
              page: 0,
              nbPages: 1,
              hitsPerPage: 20,
              processingTimeMS: 1,
              query: "installation",
              index: "test-index",
              queryID: "homepage-search-test",
            },
          ],
        },
      });
    },
  );
  await page.goto("/");
  await page.getByRole("button", { name: "Search", exact: true }).click();
  await page
    .getByPlaceholder("Search docs", { exact: true })
    .fill("installation");
  await page
    .locator(".DocSearch-Modal")
    .getByRole("link", { name: "Installation", exact: true })
    .click();

  await expect(page).toHaveURL(/\/docs\/manual\/installation$/);
  await expect(
    page.getByRole("heading", { name: "Installation", level: 1, exact: true }),
  ).toBeVisible();
  await expect(
    page.getByPlaceholder("Search docs", { exact: true }),
  ).toHaveCount(0);
});

test("a pending search load can be closed without opening the modal afterward", async ({
  page,
}) => {
  const download = Promise.withResolvers();
  await page.route(searchChunk, async (route) => {
    await download.promise;
    await route.continue();
  });
  await page.goto("/");
  const search = page.getByRole("button", { name: "Search", exact: true });
  const response = page.waitForResponse(searchChunk);

  try {
    await search.click();
    await expect(
      page.getByRole("button", { name: "Close search" }),
    ).toBeVisible();
    await page.keyboard.press("Escape");
    await expect(
      page.getByRole("button", { name: "Close search" }),
    ).toHaveCount(0);
    await expect(search).toBeFocused();
  } finally {
    download.resolve();
    await page.unrouteAll({ behavior: "wait" });
  }
  await (await response).finished();
  await expect(search).toBeFocused();

  await expect(
    page.getByPlaceholder("Search docs", { exact: true }),
  ).toHaveCount(0);
  await search.click();
  await expect(
    page.getByPlaceholder("Search docs", { exact: true }),
  ).toBeFocused();
});

test("a failed search chunk leaves the page usable and recovers after a reload", async ({
  page,
}) => {
  await page.route(searchChunk, (route) => route.abort());
  await page.goto("/");
  const search = page.getByRole("button", { name: "Search", exact: true });
  await search.click();

  await expect(page.getByRole("alert")).toContainText("Search unavailable");
  await page.getByRole("button", { name: "Close search" }).click();
  await expect(page.getByRole("alert")).toHaveCount(0);
  await expect(search).toBeFocused();
  await expect(
    page.getByRole("heading", {
      level: 1,
      name: "JavaScript Made Simple for Humans and AI",
    }),
  ).toBeVisible();
  await page.unrouteAll({ behavior: "wait" });
  await page.reload();
  await search.click();
  await expect(
    page.getByPlaceholder("Search docs", { exact: true }),
  ).toBeFocused();
});

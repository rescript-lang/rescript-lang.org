import { expect, test } from "playwright/test";

function observeRuntimeErrors(page) {
  const errors = [];

  page.on("pageerror", (error) => errors.push(error.message));
  page.on("console", (message) => {
    if (message.type() === "error") {
      errors.push(message.text());
    }
  });

  return errors;
}

function observeFailedLocalImages(page) {
  const failures = [];

  page.on("response", (response) => {
    const request = response.request();
    if (
      request.resourceType() === "image" &&
      new URL(response.url()).origin === "http://127.0.0.1:4173" &&
      !response.ok()
    ) {
      failures.push(`${response.status()} ${response.url()}`);
    }
  });

  return failures;
}

async function expectPageStyles(page) {
  await expect
    .poll(() =>
      page.evaluate(() => getComputedStyle(document.documentElement).opacity),
    )
    .toBe("1");
}

async function loadHomepageImages(page) {
  const sections = page.locator("main section");
  const sectionCount = await sections.count();

  for (let index = 0; index < sectionCount; index += 1) {
    await sections.nth(index).scrollIntoViewIfNeeded();
  }

  return page.locator("img").evaluateAll(async (images) => {
    await Promise.all(
      images.map((image) => image.decode().catch(() => undefined)),
    );
    return images
      .filter((image) => image.complete && image.naturalWidth === 0)
      .map((image) => image.currentSrc || image.src);
  });
}

test("homepage hydrates with working links and copy feedback", async ({
  context,
  page,
}) => {
  const runtimeErrors = observeRuntimeErrors(page);
  const failedImages = observeFailedLocalImages(page);

  await context.grantPermissions(["clipboard-read", "clipboard-write"], {
    origin: "http://127.0.0.1:4173",
  });
  await page.goto("/");
  await expectPageStyles(page);

  await expect(
    page.getByRole("heading", {
      level: 1,
      name: "JavaScript Made Simple for Humans and AI",
    }),
  ).toBeVisible();
  await expect(
    page.getByRole("link", { name: "Get started", exact: true }),
  ).toHaveAttribute("href", "/docs/manual/installation");
  await expect(
    page.getByRole("link", { name: "Edit this example in Playground" }),
  ).toHaveAttribute("href", /\/try\?code=.+/);

  await page
    .getByRole("button", { name: "Copy npm install rescript command" })
    .click();
  await expect(page.getByText("Copied!", { exact: true })).toBeVisible();
  await expect
    .poll(() => page.evaluate(() => navigator.clipboard.readText()))
    .toBe("npm install rescript");

  const brokenLoadedImages = await loadHomepageImages(page);

  expect(brokenLoadedImages).toEqual([]);
  expect(failedImages).toEqual([]);
  expect(runtimeErrors).toEqual([]);
});

test("client navigation preserves homepage and documentation styles", async ({
  page,
}) => {
  const runtimeErrors = observeRuntimeErrors(page);

  await page.goto("/");
  await expectPageStyles(page);
  await page.getByRole("link", { name: "Docs", exact: true }).click();

  await expect(page).toHaveURL(/\/docs\/manual\/introduction$/);
  await expect(
    page.getByRole("heading", { level: 1, name: "ReScript", exact: true }),
  ).toBeVisible();
  await expectPageStyles(page);

  await page.getByRole("link", { name: "homepage" }).click();
  await expect(page).toHaveURL("/");
  await expect(
    page.getByRole("heading", {
      level: 1,
      name: "JavaScript Made Simple for Humans and AI",
    }),
  ).toBeVisible();
  await expectPageStyles(page);

  expect(runtimeErrors).toEqual([]);
});

test("mobile navigation opens the packages route", async ({ page }) => {
  const runtimeErrors = observeRuntimeErrors(page);

  await page.setViewportSize({ width: 375, height: 812 });
  await page.goto("/");

  await page.getByRole("button", { name: "Toggle additional menu" }).click();
  const packagesLink = page.getByRole("link", {
    name: "Packages",
    exact: true,
  });
  await expect(packagesLink).toBeVisible();
  await packagesLink.click();

  await expect(page).toHaveURL(/\/packages(?:\?search=)?$/);
  await expect(
    page.getByRole("heading", {
      level: 1,
      name: "Libraries & Bindings",
      exact: true,
    }),
  ).toBeVisible();
  await expectPageStyles(page);
  expect(runtimeErrors).toEqual([]);
});

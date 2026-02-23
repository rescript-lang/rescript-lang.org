open Playwright

describe("Docs Page", () => {
  test("has the correct page title", async ({page}) => {
    let _ = await page->goto("/docs")
    await page->expect->toHaveTitle("ReScript Documentation")
  })

  test("renders the docs overview heading", async ({page}) => {
    let _ = await page->goto("/docs")
    let heading = page->getByRole("heading", ~options={name: "Documentation"})
    await heading->expect->toBeVisible
  })

  test("docs navigation sidebar is present on the introduction page", async ({page}) => {
    let _ = await page->goto("/docs/manual/latest/introduction")
    let sidebar = page->getByRole("navigation")
    await sidebar->expect->toBeVisible
  })

  test("can navigate from the overview to the introduction", async ({page}) => {
    let _ = await page->goto("/docs")
    let introLink = page->getByRole("link", ~options={name: "Introduction"})
    await introLink->first->click
    await page->expect->toHaveURL("/docs/manual/latest/introduction")
  })

  test("introduction page renders main content with h1", async ({page}) => {
    let _ = await page->goto("/docs/manual/latest/introduction")
    let mainContent = page->locator("main")
    await mainContent->expect->toBeVisible
    let heading = page->getByRole("heading", ~options={name: "Introduction", level: 1})
    await heading->expect->toBeVisible
  })

  test("syntax lookup page loads with heading", async ({page}) => {
    let _ = await page->goto("/syntax-lookup")
    let heading = page->getByRole("heading", ~options={name: "Syntax Lookup"})
    await heading->expect->toBeVisible
  })

  test("packages page loads", async ({page}) => {
    let _ = await page->goto("/packages")
    let heading = page->getByRole("heading", ~options={name: "Packages"})
    await heading->expect->toBeVisible
  })

  test("has no accessibility violations on the docs overview", async ({page}) => {
    let _ = await page->goto("/docs")
    await page->assertNoA11yViolations
  })

  test("has no accessibility violations on the introduction page", async ({page}) => {
    let _ = await page->goto("/docs/manual/latest/introduction")
    await page->assertNoA11yViolations
  })

  test("visual snapshot — docs overview", async ({page}) => {
    let _ = await page->goto("/docs")
    await page->waitForLoadState("networkidle")
    await takeSnapshot(page, "Docs Overview")
  })

  test("visual snapshot — introduction page", async ({page}) => {
    let _ = await page->goto("/docs/manual/latest/introduction")
    await page->waitForLoadState("networkidle")
    await takeSnapshot(page, "Docs Introduction")
  })
})

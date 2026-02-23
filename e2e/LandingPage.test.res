open Playwright

describe("Landing Page", () => {
  test("has the correct page title", async ({page}) => {
    let _ = await page->goto("/")
    await page
    ->expect
    ->toHaveTitle(
      "ReScript - A robustly typed language that compiles to efficient and human-readable JavaScript.",
    )
  })

  test("renders the hero section heading", async ({page}) => {
    let _ = await page->goto("/")
    let hero =
      page->getByRole(
        "heading",
        ~options={name: "Fast, Simple, Fully Typed JavaScript from the Future"},
      )
    await hero->expect->toBeVisible
  })

  test("primary navigation links are present and visible", async ({page}) => {
    let _ = await page->goto("/")

    await page->getByRole("link", ~options={name: "Docs"})->expect->toBeVisible
    await page->getByRole("link", ~options={name: "Playground"})->expect->toBeVisible
    await page->getByRole("link", ~options={name: "Blog"})->expect->toBeVisible
    await page->getByRole("link", ~options={name: "Community"})->expect->toBeVisible
  })

  test("Get Started link navigates to the introduction", async ({page}) => {
    let _ = await page->goto("/")

    let getStarted = page->getByRole("link", ~options={name: "Get Started"})
    await getStarted->first->click

    await page->expect->toHaveURL("/docs/manual/latest/introduction")
  })

  test("GitHub social link is present", async ({page}) => {
    let _ = await page->goto("/")
    let githubLink = page->getByRole("link", ~options={name: "GitHub"})
    await githubLink->expect->toBeVisible
  })

  test("has no accessibility violations", async ({page}) => {
    let _ = await page->goto("/")
    await page->assertNoA11yViolations
  })

  test("visual snapshot — desktop", async ({page}) => {
    let _ = await page->goto("/")
    await page->waitForLoadState("networkidle")
    await takeSnapshot(page, "Landing Page — Desktop")
  })

  test("visual snapshot — mobile", async ({page}) => {
    let _ = await page->goto("/")
    await page->waitForLoadState("networkidle")
    await takeSnapshot(page, "Landing Page — Mobile")
  })
})

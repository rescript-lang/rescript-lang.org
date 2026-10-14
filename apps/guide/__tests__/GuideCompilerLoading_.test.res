open Vitest

@module("./compilerLoadingFixture.js")
external interceptCompilerScripts: bool => unit = "interceptCompilerScripts"

@module("./compilerLoadingFixture.js")
external expireCompilerLoading: unit => unit = "expireCompilerLoading"

let renderWithCompiler = () =>
  render(
    <ReactRouter.MemoryRouter>
      <GuideHome
        lessons=GuideTestFixtures.guideLessons
        compilerData={bundleBaseUrl: "https://guide-compiler.test"}
      />
    </ReactRouter.MemoryRouter>,
  )

test("shows a compiler loading failure in the guide output", async () => {
  await viewport(1440, 900)
  interceptCompilerScripts(true)
  let screen = await renderWithCompiler()
  await (await screen->getByText("Compiler setup failed"))->element->toBeVisible
  await (
    await screen->getByText(
      "Could not load compiler from url https://guide-compiler.test/v12.3.1/compiler.js",
    )
  )
  ->element
  ->toBeVisible
})

test("shows a useful message when the compiler CDN never responds", async () => {
  await viewport(1440, 900)
  interceptCompilerScripts(false)
  expireCompilerLoading()
  let screen = await renderWithCompiler()
  await (await screen->getByText("Compiler setup failed"))->element->toBeVisible
  await (
    await screen->getByText(
      "ReScript v12.3.1 did not load within 15 seconds. Reload the page to try again.",
    )
  )
  ->element
  ->toBeVisible
})

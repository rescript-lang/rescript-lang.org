open Vitest

@module("./compilerFixture.js")
external waitForCompilerRequest: unit => promise<unit> = "waitForCompilerRequest"
@module("./compilerFixture.js") external failCompilerLoading: unit => unit = "failCompilerLoading"

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
  let screen = await renderWithCompiler()
  await waitForCompilerRequest()
  failCompilerLoading()
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

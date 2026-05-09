open ReactRouter
open Vitest

test("desktop docs overview shows all section cards", async () => {
  await viewport(1440, 900)

  let screen = await render(
    <MemoryRouter initialEntries=["/docs"]>
      <div dataTestId="docs-overview-wrapper">
        <DocsOverview.default />
      </div>
    </MemoryRouter>,
  )

  let docsHeading = await screen->getByText("Docs")
  await element(docsHeading)->toBeVisible

  let languageManual = await screen->getByText("Language Manual")
  await element(languageManual)->toBeVisible

  let ecosystem = await screen->getByText("Ecosystem")
  await element(ecosystem)->toBeVisible

  let tools = await screen->getByText("Tools")
  await element(tools)->toBeVisible

  let wrapper = await screen->getByTestId("docs-overview-wrapper")
  await element(wrapper)->toMatchScreenshot("desktop-docs-overview")
})

test("desktop docs overview shows ecosystem links", async () => {
  await viewport(1440, 900)

  let screen = await render(
    <MemoryRouter initialEntries=["/docs"]>
      <div dataTestId="docs-overview-wrapper">
        <DocsOverview.default />
      </div>
    </MemoryRouter>,
  )

  let packageIndex = await screen->getByText("Package Index")
  await element(packageIndex)->toBeVisible

  let rescriptReact = await screen->getByText("rescript-react")
  await element(rescriptReact)->toBeVisible

  let wrapper = await screen->getByTestId("docs-overview-wrapper")
  await element(wrapper)->toMatchScreenshot("desktop-docs-overview-ecosystem")
})

test("docs overview uses unversioned docs links", async () => {
  await viewport(1440, 900)

  let _screen = await render(
    <MemoryRouter initialEntries=["/docs"]>
      <div dataTestId="docs-overview-wrapper">
        <DocsOverview.default />
      </div>
    </MemoryRouter>,
  )

  let overviewLink = switch document->WebAPI.Document.querySelector(
    "a[href='/docs/manual/introduction']",
  ) {
  | Value(link) => link
  | Null => failwith("expected docs overview to link to the unversioned manual introduction")
  }
  await element(overviewLink)->toBeVisible

  let genTypeLink = switch document->WebAPI.Document.querySelector(
    "a[href='/docs/manual/typescript-integration']",
  ) {
  | Value(link) => link
  | Null => failwith("expected docs overview to link to the unversioned GenType docs page")
  }
  await element(genTypeLink)->toBeVisible

  switch document->WebAPI.Document.querySelector("a[href*='/docs/manual/v']") {
  | Value(_) => failwith("expected docs overview to avoid versioned manual links")
  | Null => ()
  }
})

test("mobile docs overview", async () => {
  await viewport(600, 1200)

  let screen = await render(
    <MemoryRouter initialEntries=["/docs"]>
      <div dataTestId="docs-overview-wrapper">
        <DocsOverview.default />
      </div>
    </MemoryRouter>,
  )

  let docsHeading = await screen->getByText("Docs")
  await element(docsHeading)->toBeVisible

  let languageManual = await screen->getByText("Language Manual")
  await element(languageManual)->toBeVisible

  let wrapper = await screen->getByTestId("docs-overview-wrapper")
  await element(wrapper)->toMatchScreenshot("mobile-docs-overview")
})

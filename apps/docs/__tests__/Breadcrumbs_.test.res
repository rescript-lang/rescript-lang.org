open ReactRouter
open Vitest

@get external textContent: WebAPI.DOMAPI.element => string = "textContent"

let mockBreadcrumbs: list<Url.breadcrumb> = list{
  {Url.name: "Docs", href: "/docs/"},
  {Url.name: "Language Manual", href: "/docs/manual/introduction"},
}

test("breadcrumbs render path segments", async () => {
  await viewport(1440, 900)

  let screen = await render(
    <MemoryRouter initialEntries=["/docs/manual/introduction"]>
      <div dataTestId="breadcrumbs-wrapper">
        <Breadcrumbs crumbs=mockBreadcrumbs />
      </div>
    </MemoryRouter>,
  )

  let docs = await screen->getByText("Docs")
  await element(docs)->toBeVisible

  let languageManual = await screen->getByText("Language Manual")
  await element(languageManual)->toBeVisible

  let wrapper = await screen->getByTestId("breadcrumbs-wrapper")
  await element(wrapper)->toMatchScreenshot("sidebar-breadcrumbs")
})

test("breadcrumbs with deep path", async () => {
  await viewport(1440, 900)

  let deepBreadcrumbs: list<Url.breadcrumb> = list{
    {Url.name: "Docs", href: "/docs/"},
    {Url.name: "Language Manual", href: "/docs/manual/introduction"},
    {Url.name: "Advanced", href: "/docs/manual/advanced"},
  }

  let screen = await render(
    <MemoryRouter initialEntries=["/docs/manual/advanced"]>
      <div dataTestId="breadcrumbs-wrapper">
        <Breadcrumbs crumbs=deepBreadcrumbs />
      </div>
    </MemoryRouter>,
  )

  let docs = await screen->getByText("Docs")
  await element(docs)->toBeVisible

  let languageManual = await screen->getByText("Language Manual")
  await element(languageManual)->toBeVisible

  let advanced = await screen->getByText("Advanced")
  await element(advanced)->toBeVisible

  let wrapper = await screen->getByTestId("breadcrumbs-wrapper")
  await element(wrapper)->toMatchScreenshot("sidebar-breadcrumbs-deep")
})

test("breadcrumbs do not repeat the current page crumb when it is already included", async () => {
  await viewport(1440, 900)

  let apiBreadcrumbs: list<Url.breadcrumb> = list{
    {Url.name: "Docs", href: "/docs/manual/api"},
    {Url.name: "API", href: "/docs/manual/api"},
    {Url.name: "Stdlib", href: "/docs/manual/api/stdlib"},
  }

  let screen = await render(
    <MemoryRouter initialEntries=["/docs/manual/api/stdlib"]>
      <div dataTestId="breadcrumbs-wrapper">
        <Breadcrumbs crumbs=apiBreadcrumbs />
      </div>
    </MemoryRouter>,
  )

  let _breadcrumbs = await screen->getByTestId("breadcrumbs")
  let breadcrumbs = switch document->WebAPI.Document.querySelector("[data-testid='breadcrumbs']") {
  | Value(breadcrumbs) => breadcrumbs
  | Null => failwith("expected breadcrumbs")
  }

  expect(breadcrumbs->textContent)->toBe("Docs / API / Stdlib")
})

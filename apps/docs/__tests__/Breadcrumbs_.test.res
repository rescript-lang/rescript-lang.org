open ReactRouter
open Vitest

let mockBreadcrumbs: list<Url.breadcrumb> = list{
  {Url.name: "Docs", href: "/docs/"},
  {Url.name: "Language Manual", href: "/docs/manual/introduction"},
}

test("breadcrumbs render path segments", async () => {
  await viewport(1440, 900)

  let screen = await render(
    <BrowserRouter>
      <div dataTestId="breadcrumbs-wrapper">
        <Breadcrumbs crumbs=mockBreadcrumbs />
      </div>
    </BrowserRouter>,
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
    <BrowserRouter>
      <div dataTestId="breadcrumbs-wrapper">
        <Breadcrumbs crumbs=deepBreadcrumbs />
      </div>
    </BrowserRouter>,
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

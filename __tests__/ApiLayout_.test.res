open ReactRouter
open Vitest

let mockCategories: array<SidebarLayout.Sidebar.Category.t> = [
  {
    name: "Stdlib",
    items: [
      {name: "Array", href: "/docs/manual/api/stdlib/array"},
      {name: "String", href: "/docs/manual/api/stdlib/string"},
      {name: "Option", href: "/docs/manual/api/stdlib/option"},
    ],
  },
  {
    name: "Belt",
    items: [
      {name: "Belt.Array", href: "/docs/manual/api/belt/array"},
      {name: "Belt.Map", href: "/docs/manual/api/belt/map"},
    ],
  },
]

test("desktop API layout shows sidebar categories and version select", async () => {
  await viewport(1440, 900)

  let screen = await render(
    <MemoryRouter initialEntries=["/docs/manual/api/stdlib/array"]>
      <div dataTestId="api-layout-wrapper">
        <ApiLayout categories=mockCategories>
          <div> {React.string("API documentation for Array module.")} </div>
        </ApiLayout>
      </div>
    </MemoryRouter>,
  )

  let stdlib = await screen->getByText("Stdlib")
  await element(stdlib)->toBeVisible

  let belt = await screen->getByText("Belt")
  await element(belt)->toBeVisible

  let array = await screen->getByText("Array")
  await element(array)->toBeVisible

  let wrapper = await screen->getByTestId("api-layout-wrapper")
  await element(wrapper)->toMatchScreenshot("desktop-api-layout")
})

test("mobile API layout hides sidebar", async () => {
  await viewport(600, 1200)

  let screen = await render(
    <MemoryRouter initialEntries=["/docs/manual/api/stdlib/array"]>
      <div dataTestId="api-layout-wrapper">
        <ApiLayout categories=mockCategories>
          <div> {React.string("API documentation for Array module.")} </div>
        </ApiLayout>
      </div>
    </MemoryRouter>,
  )

  let stdlib = await screen->getByText("Stdlib")
  await element(stdlib)->notToBeVisible

  let content = await screen->getByTestId("side-layout-children")
  await element(content)->toBeVisible

  let wrapper = await screen->getByTestId("api-layout-wrapper")
  await element(wrapper)->toMatchScreenshot("mobile-api-layout")
})

test("old docs warning shows version info", async () => {
  await viewport(1440, 500)

  let screen = await render(
    <BrowserRouter>
      <div dataTestId="old-docs-warning-wrapper">
        <ApiLayout.OldDocsWarning version="v11.0.0" route=%raw(`"/docs/manual/v11.0.0/api"`) />
      </div>
    </BrowserRouter>,
  )

  let warningText = await screen->getByText("here")
  await element(warningText)->toBeVisible

  let wrapper = await screen->getByTestId("old-docs-warning-wrapper")
  await element(wrapper)->toMatchScreenshot("api-old-docs-warning")
})

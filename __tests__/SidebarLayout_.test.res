open ReactRouter
open Vitest

let mockCategory: SidebarLayout.Sidebar.Category.t = {
  name: "Overview",
  items: [
    {name: "Introduction", href: "/docs/manual/introduction"},
    {name: "Installation", href: "/docs/manual/installation"},
    {name: "Getting Started", href: "/docs/manual/getting-started"},
  ],
}

let mockBreadcrumbs: list<Url.breadcrumb> = list{
  {Url.name: "Docs", href: "/docs/"},
  {Url.name: "Language Manual", href: "/docs/manual/introduction"},
}

test("sidebar category renders title and nav items", async () => {
  await viewport(1440, 900)

  let screen = await render(
    <BrowserRouter>
      <div dataTestId="category-wrapper">
        <SidebarLayout.Sidebar.Category category=mockCategory onClick={_ => ()} />
      </div>
    </BrowserRouter>,
  )

  let introduction = await screen->getByText("Introduction")
  await element(introduction)->toBeVisible

  let installation = await screen->getByText("Installation")
  await element(installation)->toBeVisible

  let gettingStarted = await screen->getByText("Getting Started")
  await element(gettingStarted)->toBeVisible

  let wrapper = await screen->getByTestId("category-wrapper")
  await element(wrapper)->toMatchScreenshot("sidebar-category")
})

test("sidebar category highlights active item", async () => {
  await viewport(1440, 900)

  let screen = await render(
    <BrowserRouter>
      <div dataTestId="category-wrapper">
        <SidebarLayout.Sidebar.Category
          category=mockCategory
          isItemActive={item => item.href == "/docs/manual/introduction"}
          onClick={_ => ()}
        />
      </div>
    </BrowserRouter>,
  )

  let introduction = await screen->getByText("Introduction")
  await element(introduction)->toBeVisible

  let wrapper = await screen->getByTestId("category-wrapper")
  await element(wrapper)->toMatchScreenshot("sidebar-category-active-item")
})

test("breadcrumbs render path segments", async () => {
  await viewport(1440, 900)

  let screen = await render(
    <BrowserRouter>
      <div dataTestId="breadcrumbs-wrapper">
        <SidebarLayout.BreadCrumbs crumbs=mockBreadcrumbs />
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

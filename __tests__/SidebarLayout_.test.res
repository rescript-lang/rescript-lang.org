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

let mockTocEntries: TableOfContents.t = {
  title: "Introduction",
  entries: [
    {header: "What is ReScript", href: "#what-is-rescript"},
    {header: "Basic Usage", href: "#basic-usage"},
    {header: "Advanced", href: "#advanced"},
  ],
}

test("sidebar category with active TOC renders entries", async () => {
  await viewport(1440, 900)

  let screen = await render(
    <MemoryRouter initialEntries=["/docs/manual/introduction"]>
      <div dataTestId="toc-wrapper">
        <SidebarLayout.Sidebar.Category
          category=mockCategory
          isItemActive={item => item.href == "/docs/manual/introduction"}
          getActiveToc={item =>
            if item.href == "/docs/manual/introduction" {
              Some(mockTocEntries)
            } else {
              None
            }}
          onClick={() => ()}
        />
      </div>
    </MemoryRouter>,
  )

  let overview = await screen->getByText("What is ReScript")
  await element(overview)->toBeVisible

  let basicUsage = await screen->getByText("Basic Usage")
  await element(basicUsage)->toBeVisible

  let advanced = await screen->getByText("Advanced")
  await element(advanced)->toBeVisible

  let wrapper = await screen->getByTestId("toc-wrapper")
  await element(wrapper)->toMatchScreenshot("sidebar-category-with-toc")
})

test("sidebar category with many items", async () => {
  await viewport(1440, 900)

  let largeCategory: SidebarLayout.Sidebar.Category.t = {
    name: "All Types",
    items: [
      {name: "String", href: "/docs/manual/string"},
      {name: "Int", href: "/docs/manual/int"},
      {name: "Float", href: "/docs/manual/float"},
      {name: "Bool", href: "/docs/manual/bool"},
      {name: "Array", href: "/docs/manual/array"},
      {name: "List", href: "/docs/manual/list"},
      {name: "Option", href: "/docs/manual/option"},
      {name: "Result", href: "/docs/manual/result"},
    ],
  }

  let screen = await render(
    <BrowserRouter>
      <div dataTestId="category-wrapper">
        <SidebarLayout.Sidebar.Category category=largeCategory onClick={_ => ()} />
      </div>
    </BrowserRouter>,
  )

  let stringItem = await screen->getByText("String")
  await element(stringItem)->toBeVisible

  let resultItem = await screen->getByText("Result")
  await element(resultItem)->toBeVisible

  let wrapper = await screen->getByTestId("category-wrapper")
  await element(wrapper)->toMatchScreenshot("sidebar-category-many-items")
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
        <SidebarLayout.BreadCrumbs crumbs=deepBreadcrumbs />
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

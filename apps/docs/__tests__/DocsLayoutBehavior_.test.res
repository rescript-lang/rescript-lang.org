open ReactRouter
open Vitest

@get external textContent: WebAPI.DOMAPI.element => string = "textContent"

let mockCategories: array<SidebarNav.Category.t> = [
  {
    name: "Overview",
    items: [
      {name: "Introduction", href: "/docs/manual/introduction"},
      {name: "Installation", href: "/docs/manual/installation"},
    ],
  },
  {
    name: "Language Features",
    items: [
      {name: "Primitive Types", href: "/docs/manual/primitive-types"},
      {name: "Record", href: "/docs/manual/record"},
      {name: "Object", href: "/docs/manual/object"},
    ],
  },
]

let mockToc: TableOfContents.t = {
  title: "Introduction",
  entries: [
    {header: "What is ReScript", href: "#what-is-rescript"},
    {header: "Prerequisites", href: "#prerequisites"},
    {header: "Getting Started", href: "#getting-started"},
  ],
}

test("docs layout marks the textual content for DocSearch crawling", async () => {
  await viewport(1440, 900)

  let screen = await render(
    <MemoryRouter initialEntries=["/docs/manual/introduction"]>
      <DocsLayout categories=mockCategories activeToc=mockToc docSearchLvl0="Manual">
        <div> {React.string("This is the documentation content.")} </div>
      </DocsLayout>
    </MemoryRouter>,
  )

  let _mainContent = await screen->getByTestId("side-layout-children")

  let mainContent = switch document->WebAPI.Document.querySelector(
    "[data-testid='side-layout-children']",
  ) {
  | Value(element) => element
  | Null => failwith("expected docs layout main content")
  }

  let className = switch mainContent->WebAPI.Element.getAttribute("class") {
  | Value(value) => value
  | Null => ""
  }

  expect(className->String.includes("DocSearch-content"))->toBe(true)

  let lvl0 = switch document->WebAPI.Document.querySelector(".DocSearch-lvl0") {
  | Value(element) => element
  | Null => failwith("expected docs layout to render a DocSearch lvl0 marker")
  }

  expect(lvl0->textContent)->toBe("Manual")
})

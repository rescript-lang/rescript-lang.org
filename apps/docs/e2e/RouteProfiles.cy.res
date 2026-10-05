open Cy

type expectation =
  | Heading(string)
  | BlogIndex
  | Playground

let profiles = [
  ("documentation introduction", "/docs/manual/introduction", Heading("ReScript")),
  ("standard-library array API", "/docs/manual/api/stdlib/array", Heading("Array")),
  ("blog index", "/blog", BlogIndex),
  (
    "current blog article",
    "/blog/reactive-analysis",
    Heading("Real-Time Analysis is Coming to ReScript"),
  ),
  ("community overview", "/community/overview", Heading("Community Overview")),
  ("packages", "/packages", Heading("Libraries & Bindings")),
  ("syntax lookup", "/syntax-lookup", Heading("Syntax Lookup")),
  ("playground", "/try", Playground),
  ("brand control", "/brand", Heading("Brand Assets")),
  ("unknown route control", "/__route-profile-not-found", Heading("404")),
]

let expectProfile = expectation =>
  switch expectation {
  | Heading(heading) => get("h1")->containsChainable(heading)->should("be.visible")->ignore
  | BlogIndex => get("h2")->first->should("be.visible")->ignore
  | Playground => get(".cm-editor")->should("be.visible")->ignore
  }

let expectLoadedStyles = () =>
  Cypress.cyWindow()->Cypress.thenPromise(async window => {
    let styles = await window.document
    ->Cypress.querySelectorAll(`link[rel="stylesheet"][href]`)
    ->Cypress.elementsFrom
    ->Array.map(async link => {
      let response = await window->Cypress.windowFetch(link->Cypress.elementHref)
      Cypress.expect(
        response->Cypress.fetchStatus,
        ~message=link->Cypress.elementHref,
      )->Cypress.equal(200)
      await response->Cypress.responseText
    })
    ->Promise.all
    Cypress.expect(styles->Array.length)->Cypress.greaterThan(0)
  })

// static-server needs a trailing slash to resolve nested index.html files.
let directLoadPath = path =>
  Cypress.baseUrl()->String.includes("127.0.0.1:4173") ? path ++ "/" : path

describe("Route profiles", () => {
  beforeEach(() => viewport(1280, 720))

  profiles->Array.forEach(((name, path, expectation)) =>
    it(
      `direct ${name} load has styles and hydrates`,
      () => {
        visit(directLoadPath(path))
        expectLoadedStyles()->ignore
        expectProfile(expectation)
      },
    )
  )

  it("navigates between documentation, blog, community, and playground", () => {
    visit("/docs/manual/introduction"->directLoadPath)
    getByTestId("navbar-primary")->shouldBeVisible->ignore
    get(`[data-testid="navbar-primary-left-content"] a[href="/blog"]`)->click->ignore
    cyLocation("pathname")->shouldWithValue("eq", "/blog")->ignore
    get("h2")->first->shouldBeVisible->ignore
    get(`[data-testid="navbar-primary-left-content"] a[href="/community/overview"]`)->click->ignore
    cyLocation("pathname")->shouldWithValue("eq", "/community/overview")->ignore
    get("h1")->containsChainable("Community Overview")->shouldBeVisible->ignore
    get(`[data-testid="navbar-primary-left-content"] a[href="/try"]`)->click->ignore
    cyLocation("pathname")->shouldWithValue("eq", "/try")->ignore
    get(".cm-editor")->shouldBeVisible->ignore
  })

  it("keeps pre-rendered syntax highlighting on the API direct load", () => {
    visit("/docs/manual/api/stdlib/array"->directLoadPath)
    get("code.lang-rescript .hljs-keyword")->first->should("be.visible")->ignore
  })
})

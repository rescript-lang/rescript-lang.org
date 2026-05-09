open Cy

let waitForPage = () => {
  getByTestId("navbar-primary")->shouldBeVisible->ignore
  getByTestId("navbar-tertiary")->shouldBeVisible->ignore
  cyWindow()->its("document.readyState")->shouldWithValue("eq", "complete")->ignore
}

let expectBreadcrumbsText = text => {
  getByTestId("breadcrumbs")
  ->should("be.visible")
  ->shouldWithValue("have.text", text)
  ->ignore
}

describe("Breadcrumbs", () => {
  beforeEach(() => {
    viewport(1280, 720)
  })

  it("does not repeat the API root breadcrumb", () => {
    visit("/docs/manual/api/stdlib/")
    waitForPage()
    expectBreadcrumbsText("Docs / API / Stdlib")
  })

  it("does not repeat nested API breadcrumbs", () => {
    visit("/docs/manual/api/stdlib/arraybuffer/")
    waitForPage()
    expectBreadcrumbsText("Docs / API / Stdlib / Arraybuffer")
  })
})

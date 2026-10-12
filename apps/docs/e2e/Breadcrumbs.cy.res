open Cypress

let waitForPage = () => {
  getByTestId("navbar-primary")->should("be.visible")->ignore
  getByTestId("navbar-tertiary")->should("be.visible")->ignore
  cyWindow()->propertyString("document.readyState")->shouldEqual("complete")->ignore
}

let expectBreadcrumbsText = text => {
  getByTestId("breadcrumbs")
  ->should("be.visible")
  ->shouldText(text)
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

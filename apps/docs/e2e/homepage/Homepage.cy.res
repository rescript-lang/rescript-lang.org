open Cypress
open HomepageHelpers

it("homepage hydrates with working links and images", () => {
  visit("/")
  containsIn("h1", headline)->should("be.visible")->ignore
  containsIn("a", "Get started")->shouldAttribute("href", "/docs/manual/installation")->ignore
  containsIn("a", "Edit this example in Playground")
  ->attribute("href")
  ->shouldMatch(/\/try\?code=.+/)
  ->ignore
  get("img")
  ->each(image => {
    wrap(image)
    ->scrollIntoView
    ->shouldSatisfy(
      images => {
        let image = images->item(0)
        expect(image->Option.isSome)->equal(true)
        image->Option.forEach(
          image => {
            expect(image->complete)->equal(true)
            expect(image->naturalWidth)->greaterThan(0)
          },
        )
      },
    )
    ->ignore
  })
  ->ignore
})

it("homepage and documentation navigation works in both directions", () => {
  visit("/")
  containsIn("a", "Docs")->click->ignore
  cyLocation("pathname")->shouldEqual("/docs/manual/introduction")->ignore
  containsIn("h1", "ReScript")->should("be.visible")->ignore
  get(`a[aria-label="homepage"]`)->click->ignore
  cyLocation("pathname")->shouldEqual("/")->ignore
  containsIn("h1", headline)->should("be.visible")->ignore
})

it("mobile navigation opens the packages route", () => {
  viewport(375, 812)
  visit("/")
  get(`button[aria-label="Toggle additional menu"]`)->click->ignore
  containsIn("a", "Packages")->should("be.visible")->click->ignore
  cyLocation("pathname")->shouldEqual("/packages")->ignore
  containsIn("h1", "Libraries & Bindings")->should("be.visible")->ignore
})

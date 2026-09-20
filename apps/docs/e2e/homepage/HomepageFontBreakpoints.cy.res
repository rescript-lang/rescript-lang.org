open Cypress
open HomepageHelpers

let boldFont = "/fonts/subset-Inter-Bold.woff2"

[375, 1023]->Array.forEach(width => {
  it(`homepage at ${width->Int.toString}px does not request the desktop headline font`, () => {
    let fontRequests = ref([])
    intercept(
      {resourceType: "font"},
      request => {
        fontRequests := fontRequests.contents->Array.concat([request.url->url->pathname])
      },
    )->ignore
    viewport(width, 900)
    visit("/")
    containsIn("h1", headline)->shouldCss("font-weight", "600")->ignore
    cyDocument()
    ->thenPromise(document => document->fonts->fontsReady)
    ->then(
      _ => {
        expect(fontRequests.contents->Array.includes("/fonts/subset-Inter-SemiBold.woff2"))->equal(
          true,
        )
        expect(fontRequests.contents->Array.includes(boldFont))->equal(false)
      },
    )
    ->ignore
  })
})

it("the desktop headline font loads at the 1024px breakpoint", () => {
  viewport(1024, 900)
  interceptRoute({pathname: boldFont})->as_("desktopHeadlineFont")->ignore
  visit("/")
  containsIn("h1", headline)->shouldCss("font-weight", "700")->ignore
  wait("@desktopHeadlineFont")->propertyInt("response.statusCode")->shouldWithin(200, 299)->ignore
})

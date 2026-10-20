open Cypress
open HomepageHelpers

let visitWithoutHydration = path => {
  // Cypress needs JavaScript itself; empty application modules keep the AUT prerender-only.
  interceptPattern(/\/assets\/[^/]+\.js(?:\?.*)?$/, request => {
    if /\/entry\.client-[^/]+\.js/->RegExp.test(request.url) {
      request->setRequestAlias("clientEntry")
    }
    request->reply({
      statusCode: 200,
      headers: Dict.fromArray([("content-type", "text/javascript")]),
      body: "",
    })
  })->ignore
  visit(path)
  wait("@clientEntry")->propertyString("response.body")->shouldEqual("")->ignore
}

it("homepage paragraphs render without hydration or downloaded fonts", () => {
  interceptFailurePattern(/\.(?:woff2?|ttf|otf)(?:\?|$)/, {forceNetworkError: true})->ignore
  visitWithoutHydration("/")
  get("html")->shouldCss("opacity", "1")->ignore
  containsIn("p", "ReScript is a strongly typed language that compiles to clean,")
  ->should("be.visible")
  ->shouldCss("color", "rgb(105, 107, 125)")
  ->ignore
  containsIn("p", "Its fast compiler and static type system")->should("be.visible")->ignore
})

["/", "/docs/manual/introduction/"]->Array.forEach(path => {
  it(`${path} remains readable when the shared stylesheet fails`, () => {
    interceptFailureString("**/assets/main-*.css", {forceNetworkError: true})
    ->as_("sharedStylesheet")
    ->ignore
    visitWithoutHydration(path)
    wait("@sharedStylesheet")->shouldPropertyExist("error")->ignore
    get("html")->shouldCss("opacity", "1")->ignore
    if path === "/" {
      containsIn("h1", headline)->should("be.visible")->ignore
    } else {
      containsInRegex("h1", /^ReScript$/)->should("be.visible")->ignore
    }
  })
})

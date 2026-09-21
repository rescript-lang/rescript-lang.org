open Cypress
open HomepageHelpers

it("initial homepage scripts do not include example preparation or compression", () => {
  homepageDocument(document => {
    let scripts = document->initialScriptUrls
    expect(scripts->Array.length)->greaterThan(0)
    scripts->Array.forEach(
      asset =>
        request(asset)
        ->then(
          response => {
            expect(response.status, ~message=asset)->equal(200)
            expect(response.body, ~message=asset)->notInclude("compressToEncodedURIComponent")
            expect(response.body, ~message=asset)->notInclude("function Playground$Button(props)")
          },
        )
        ->ignore,
    )
  })
})

it("prepared examples survive hydration and navigation back from documentation", () => {
  homepageDocument(document => {
    let examples = ["res", "js"]->Array.map(
      language => {
        let selector = `code.lang-${language}`
        let html =
          document
          ->querySelector(selector)
          ->Null.toOption
          ->Option.map(element => element->innerHTML)
          ->Option.getOrThrow
        (selector, html)
      },
    )
    let playgroundHref =
      document
      ->querySelector(`a[href^="/try?code="]`)
      ->Null.toOption
      ->Option.flatMap(element => element->getAttribute("href")->Null.toOption)
      ->Option.getOrThrow
    expect(playgroundHref)->match_(/^\/try\?code=.+/)
    examples->Array.forEach(((_, html)) => expect(html)->include_(`<span class="hljs-`))
    visit("/")
    examples->Array.forEach(
      ((selector, html)) => get(selector)->shouldProperty("innerHTML", html)->ignore,
    )
    containsInRegex("a", /^Docs$/)->click->ignore
    cyLocation("pathname")->shouldEqual("/docs/manual/introduction")->ignore
    get(`a[aria-label="homepage"]`)->click->ignore
    cyLocation("pathname")->shouldEqual("/")->ignore
    examples->Array.forEach(
      ((selector, html)) =>
        get(selector)->should("be.visible")->shouldProperty("innerHTML", html)->ignore,
    )
    containsIn("a", "Edit this example in Playground")
    ->shouldAttribute("href", playgroundHref)
    ->ignore
  })
})

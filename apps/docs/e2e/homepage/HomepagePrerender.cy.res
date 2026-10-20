open Cypress
open HomepageHelpers

it("homepage response contains prerendered content and highlighted examples", () => {
  homepageDocument(document => {
    let text = document->body->textContent->Null.getOr("")
    expect(text)->include_(headline)
    expect(text)->include_("Write in ReScript")
    expectElement(document, "code.lang-res span")->ignore
    expectElement(document, "code.lang-js span")->ignore
    expectElement(document, `a[href="/docs/manual/installation"]`)->ignore
    expectElement(document, `a[href^="/try?code="]`)->Option.forEach(
      link => {
        expect(link->getAttribute("href")->Null.getOr(""))->match_(/\/try\?code=.+/)
      },
    )
  })
})

open Cypress

describe("Open Graph images", () => {
  it("renders a PNG for a same-origin documentation page", () => {
    let pageUrl = WebAPI.URL.make(~url="/docs/manual/introduction", ~base=baseUrl())
    let url = `/ogimage/index.png?url=${encodeURIComponent(pageUrl.href)}`

    requestWithOptions({url, encoding: "binary"})
    ->then(
      response => {
        expect(response.status)->equal(200)
        expect(response.headers->Dict.get("content-type")->Option.getOr(""))->include_("image/png")
        // The PNG signature verifies that the response is an image rather than an HTML error page.
        expect(response.body->String.slice(~start=0, ~end=8))->equal("\x89PNG\r\n\x1a\n")
      },
    )
    ->ignore
  })
})

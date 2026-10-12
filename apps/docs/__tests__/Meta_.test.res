open Vitest

let getMetaContent = name => {
  switch document->WebAPI.Document.querySelector(`meta[name='${name}']`) {
  | Value(element) =>
    switch element->WebAPI.Element.getAttribute("content") {
    | Value(content) => content
    | Null => failwith(`expected ${name} meta tag to have content`)
    }
  | Null => failwith(`expected ${name} meta tag`)
  }
}

let getMetaPropertyContent = property => {
  switch document->WebAPI.Document.querySelector(`meta[property='${property}']`) {
  | Value(element) =>
    switch element->WebAPI.Element.getAttribute("content") {
    | Value(content) => content
    | Null => failwith(`expected ${property} meta tag to have content`)
    }
  | Null => failwith(`expected ${property} meta tag`)
  }
}

test("renders DocSearch crawler meta tags", async () => {
  let _screen = await render(
    <ReactRouter.MemoryRouter initialEntries=["/docs/manual/introduction"]>
      <Meta />
    </ReactRouter.MemoryRouter>,
  )

  expect(getMetaContent("docsearch:language"))->toBe("en")
  expect(getMetaContent("docsearch:version"))->toBe("v12,latest")
})

test("generates Open Graph image URLs from the current page URL", async () => {
  let pagePath = "/docs/manual/introduction?preview=true"
  let rootUrl = Env.root_url->Stdlib.String.endsWith("/") ? Env.root_url : Env.root_url ++ "/"
  let pageUrl = rootUrl ++ "docs/manual/introduction?preview=true"

  let _screen = await render(
    <ReactRouter.MemoryRouter initialEntries=[pagePath]>
      <Meta
        title=?{Some("Raw title should not be in the image URL")}
        description="Raw description should not be in the image URL"
      />
    </ReactRouter.MemoryRouter>,
  )

  expect(getMetaPropertyContent("og:image"))->toBe(
    `${rootUrl}ogimage/index.png?url=${encodeURIComponent(pageUrl)}`,
  )
})

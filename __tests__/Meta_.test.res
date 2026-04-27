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

test("renders DocSearch crawler meta tags", async () => {
  let _screen = await render(<Meta />)

  expect(getMetaContent("docsearch:language"))->toBe("en")
  expect(getMetaContent("docsearch:version"))->toBe("v12,latest")
})

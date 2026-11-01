open ReactRouter
open Vitest

test("docs overview uses unversioned docs links", async () => {
  await viewport(1440, 900)

  let _screen = await render(
    <MemoryRouter initialEntries=["/docs"]>
      <div dataTestId="docs-overview-wrapper">
        <DocsOverview.default />
      </div>
    </MemoryRouter>,
  )

  let overviewLink = switch WebAPI.DOM.window
  ->WebAPI.Window.document
  ->WebAPI.Document.querySelector("a[href='/docs/manual/introduction']") {
  | Value(link) => link
  | Null => panic("expected docs overview to link to the unversioned manual introduction")
  }
  await element(overviewLink)->toBeVisible

  let genTypeLink = switch WebAPI.DOM.window
  ->WebAPI.Window.document
  ->WebAPI.Document.querySelector("a[href='/docs/manual/typescript-integration']") {
  | Value(link) => link
  | Null => panic("expected docs overview to link to the unversioned GenType docs page")
  }
  await element(genTypeLink)->toBeVisible

  switch WebAPI.DOM.window
  ->WebAPI.Window.document
  ->WebAPI.Document.querySelector("a[href*='/docs/manual/v']") {
  | Value(_) => panic("expected docs overview to avoid versioned manual links")
  | Null => ()
  }
})

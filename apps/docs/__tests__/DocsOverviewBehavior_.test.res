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

  let overviewLink = switch document->WebAPI.Document.querySelector(
    "a[href='/docs/manual/introduction']",
  ) {
  | Value(link) => link
  | Null => failwith("expected docs overview to link to the unversioned manual introduction")
  }
  await element(overviewLink)->toBeVisible

  let genTypeLink = switch document->WebAPI.Document.querySelector(
    "a[href='/docs/manual/typescript-integration']",
  ) {
  | Value(link) => link
  | Null => failwith("expected docs overview to link to the unversioned GenType docs page")
  }
  await element(genTypeLink)->toBeVisible

  switch document->WebAPI.Document.querySelector("a[href*='/docs/manual/v']") {
  | Value(_) => failwith("expected docs overview to avoid versioned manual links")
  | Null => ()
  }
})

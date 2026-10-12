open ReactRouter
open Vitest

@get external textContent: WebAPI.DOMAPI.element => string = "textContent"

test("breadcrumbs do not repeat the current page crumb when it is already included", async () => {
  await viewport(1440, 900)

  let apiBreadcrumbs: list<Url.breadcrumb> = list{
    {Url.name: "Docs", href: "/docs/manual/api"},
    {Url.name: "API", href: "/docs/manual/api"},
    {Url.name: "Stdlib", href: "/docs/manual/api/stdlib"},
  }

  let screen = await render(
    <MemoryRouter initialEntries=["/docs/manual/api/stdlib"]>
      <div dataTestId="breadcrumbs-wrapper">
        <Breadcrumbs crumbs=apiBreadcrumbs />
      </div>
    </MemoryRouter>,
  )

  let _breadcrumbs = await screen->getByTestId("breadcrumbs")
  let breadcrumbs = switch document->WebAPI.Document.querySelector("[data-testid='breadcrumbs']") {
  | Value(breadcrumbs) => breadcrumbs
  | Null => failwith("expected breadcrumbs")
  }

  expect(breadcrumbs->textContent)->toBe("Docs / API / Stdlib")
})

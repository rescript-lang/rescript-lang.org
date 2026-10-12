open ReactRouter
open Vitest

@get external textContent: WebAPI.DOMAPI.element => string = "textContent"

let mockItems: array<SyntaxLookup.item> = [
  {
    id: "as-decorator",
    keywords: ["as", "decorator"],
    name: "@as",
    summary: "This is the `@as` decorator.",
    category: Decorators,
    status: Active,
    href: "decorator_as",
  },
  {
    id: "module-decorator",
    keywords: ["module", "decorator"],
    name: "@module",
    summary: "This is the `@module` decorator.",
    category: Decorators,
    status: Active,
    href: "decorator_module",
  },
  {
    id: "pipe-operator",
    keywords: ["pipe", "operator"],
    name: "->",
    summary: "The pipe operator.",
    category: Operators,
    status: Active,
    href: "operators_pipe",
  },
  {
    id: "deprecated-send-pipe",
    keywords: ["send", "pipe", "deprecated"],
    name: "|>",
    summary: "The deprecated pipe operator.",
    category: Operators,
    status: Deprecated,
    href: "operators_deprecated_pipe",
  },
]

test("syntax lookup detail marks active content for DocSearch crawling", async () => {
  await viewport(1440, 900)

  let _screen = await render(
    <BrowserRouter>
      <SyntaxLookup mdxSources=mockItems activeItem={mockItems->Array.getUnsafe(0)}>
        <p> {React.string("Detail content for @as decorator.")} </p>
      </SyntaxLookup>
    </BrowserRouter>,
  )

  switch document->WebAPI.Document.querySelector(".DocSearch-content h1") {
  | Value(heading) => expect(heading->textContent)->toBe("@as")
  | Null => failwith("expected active syntax detail to provide a DocSearch heading")
  }

  let lvl0 = switch document->WebAPI.Document.querySelector(".DocSearch-content .DocSearch-lvl0") {
  | Value(element) => element
  | Null => failwith("expected syntax detail to render a DocSearch lvl0 marker")
  }

  expect(lvl0->textContent)->toBe("Syntax Lookup")
})

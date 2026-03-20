open ReactRouter
open Vitest

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

test("desktop syntax lookup renders categories and tags", async () => {
  await viewport(1440, 900)

  let screen = await render(
    <BrowserRouter>
      <div dataTestId="syntax-lookup-wrapper">
        <SyntaxLookup mdxSources=mockItems />
      </div>
    </BrowserRouter>,
  )

  let decoratorsHeading = await screen->getByText("Decorators")
  await element(decoratorsHeading)->toBeVisible

  let asTag = await screen->getByText("@as")
  await element(asTag)->toBeVisible

  let moduleTag = await screen->getByText("@module")
  await element(moduleTag)->toBeVisible

  let operatorsHeading = await screen->getByText("Operators")
  await element(operatorsHeading)->toBeVisible

  let wrapper = await screen->getByTestId("syntax-lookup-wrapper")
  await element(wrapper)->toMatchScreenshot("desktop-syntax-lookup")
})

test("desktop syntax lookup with active item shows detail box", async () => {
  await viewport(1440, 900)

  let screen = await render(
    <BrowserRouter>
      <div dataTestId="syntax-lookup-wrapper">
        <SyntaxLookup mdxSources=mockItems activeItem={mockItems->Array.getUnsafe(0)}>
          <div> {React.string("Detail content for @as decorator.")} </div>
        </SyntaxLookup>
      </div>
    </BrowserRouter>,
  )

  let detail = await screen->getByText("Detail content for @as decorator.")
  await element(detail)->toBeVisible

  let wrapper = await screen->getByTestId("syntax-lookup-wrapper")
  await element(wrapper)->toMatchScreenshot("desktop-syntax-lookup-active")
})

test("mobile syntax lookup", async () => {
  await viewport(600, 1200)

  let screen = await render(
    <BrowserRouter>
      <div dataTestId="syntax-lookup-wrapper">
        <SyntaxLookup mdxSources=mockItems />
      </div>
    </BrowserRouter>,
  )

  let decoratorsHeading = await screen->getByText("Decorators")
  await element(decoratorsHeading)->toBeVisible

  let asTag = await screen->getByText("@as")
  await element(asTag)->toBeVisible

  let moduleTag = await screen->getByText("@module")
  await element(moduleTag)->toBeVisible

  let operatorsHeading = await screen->getByText("Operators")
  await element(operatorsHeading)->toBeVisible

  let wrapper = await screen->getByTestId("syntax-lookup-wrapper")
  await element(wrapper)->toMatchScreenshot("mobile-syntax-lookup")
})

test("deprecated items show with line-through styling", async () => {
  await viewport(1440, 900)

  let screen = await render(
    <BrowserRouter>
      <div dataTestId="syntax-lookup-wrapper">
        <SyntaxLookup mdxSources=mockItems />
      </div>
    </BrowserRouter>,
  )

  let deprecatedTag = await screen->getByText("|>")
  await element(deprecatedTag)->toBeVisible

  let wrapper = await screen->getByTestId("syntax-lookup-wrapper")
  await element(wrapper)->toMatchScreenshot("desktop-syntax-lookup-deprecated")
})

test("syntax lookup detail box shows summary", async () => {
  await viewport(1440, 900)

  let screen = await render(
    <BrowserRouter>
      <div dataTestId="syntax-lookup-wrapper">
        <SyntaxLookup mdxSources=mockItems activeItem={mockItems->Array.getUnsafe(2)}>
          <div> {React.string("Detailed documentation about the pipe operator.")} </div>
        </SyntaxLookup>
      </div>
    </BrowserRouter>,
  )

  let detail = await screen->getByText("Detailed documentation about the pipe operator.")
  await element(detail)->toBeVisible

  let wrapper = await screen->getByTestId("syntax-lookup-wrapper")
  await element(wrapper)->toMatchScreenshot("desktop-syntax-lookup-pipe-detail")
})

test("mobile syntax lookup with active item", async () => {
  await viewport(600, 1200)

  let screen = await render(
    <BrowserRouter>
      <div dataTestId="syntax-lookup-wrapper">
        <SyntaxLookup mdxSources=mockItems activeItem={mockItems->Array.getUnsafe(0)}>
          <div> {React.string("Detail content for @as decorator.")} </div>
        </SyntaxLookup>
      </div>
    </BrowserRouter>,
  )

  let detail = await screen->getByText("Detail content for @as decorator.")
  await element(detail)->toBeVisible

  let wrapper = await screen->getByTestId("syntax-lookup-wrapper")
  await element(wrapper)->toMatchScreenshot("mobile-syntax-lookup-active")
})

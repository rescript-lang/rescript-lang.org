open ReactRouter
open Vitest

test("renders code block with language label", async () => {
  await viewport(1440, 500)

  let screen = await render(
    <div dataTestId="code-example-wrapper">
      <CodeExample code="let x = 42" lang="res" />
    </div>,
  )

  let label = await screen->getByText("RES")
  await element(label)->toBeVisible

  let wrapper = await screen->getByTestId("code-example-wrapper")
  await element(wrapper)->toMatchScreenshot("code-example-rescript")
})

test("renders code block without label when showLabel is false", async () => {
  await viewport(1440, 500)

  let screen = await render(
    <div dataTestId="code-example-wrapper">
      <CodeExample code="let x = 42" lang="res" showLabel=false />
    </div>,
  )

  let wrapper = await screen->getByTestId("code-example-wrapper")
  await element(wrapper)->toMatchScreenshot("code-example-no-label")
})

test("renders code block with highlighted lines", async () => {
  await viewport(1440, 500)

  let screen = await render(
    <div dataTestId="code-example-wrapper">
      <CodeExample code="let x = 1\nlet y = 2\nlet z = 3" lang="res" highlightedLines=[2] />
    </div>,
  )

  let wrapper = await screen->getByTestId("code-example-wrapper")
  await element(wrapper)->toMatchScreenshot("code-example-highlighted")
})

test("renders toggle with multiple tabs", async () => {
  await viewport(1440, 500)

  let tabs: array<CodeExample.Toggle.tab> = [
    {
      highlightedLines: None,
      label: Some("ReScript"),
      lang: Some("res"),
      code: "let greeting = \"hello\"",
    },
    {
      highlightedLines: None,
      label: Some("JavaScript"),
      lang: Some("js"),
      code: "var greeting = \"hello\";",
    },
  ]

  let screen = await render(
    <BrowserRouter>
      <div dataTestId="toggle-wrapper">
        <CodeExample.Toggle tabs />
      </div>
    </BrowserRouter>,
  )

  let resTab = await screen->getByText("ReScript")
  await element(resTab)->toBeVisible

  let jsTab = await screen->getByText("JavaScript")
  await element(jsTab)->toBeVisible

  let wrapper = await screen->getByTestId("toggle-wrapper")
  await element(wrapper)->toMatchScreenshot("code-toggle-tabs")
})

test("toggle switches between tabs on click", async () => {
  await viewport(1440, 500)

  let tabs: array<CodeExample.Toggle.tab> = [
    {
      highlightedLines: None,
      label: Some("ReScript"),
      lang: Some("res"),
      code: "let greeting = \"hello\"",
    },
    {
      highlightedLines: None,
      label: Some("JavaScript"),
      lang: Some("js"),
      code: "var greeting = \"hello\";",
    },
  ]

  let screen = await render(
    <BrowserRouter>
      <div dataTestId="toggle-wrapper">
        <CodeExample.Toggle tabs />
      </div>
    </BrowserRouter>,
  )

  // Click the JavaScript tab
  let jsTab = await screen->getByText("JavaScript")
  await jsTab->click

  let wrapper = await screen->getByTestId("toggle-wrapper")
  await element(wrapper)->toMatchScreenshot("code-toggle-js-selected")
})

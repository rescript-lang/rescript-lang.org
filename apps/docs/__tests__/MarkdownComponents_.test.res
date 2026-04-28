open ReactRouter
open Vitest

test("renders headings h1 through h5", async () => {
  await viewport(1440, 900)

  let screen = await render(
    <div dataTestId="headings-wrapper">
      <Markdown.H1> {React.string("Heading Level 1")} </Markdown.H1>
      <Markdown.H2 id="heading-2"> {React.string("Heading Level 2")} </Markdown.H2>
      <Markdown.H3 id="heading-3"> {React.string("Heading Level 3")} </Markdown.H3>
      <Markdown.H4 id="heading-4"> {React.string("Heading Level 4")} </Markdown.H4>
      <Markdown.H5 id="heading-5"> {React.string("Heading Level 5")} </Markdown.H5>
    </div>,
  )

  let heading1 = await screen->getByText("Heading Level 1")
  await element(heading1)->toBeVisible

  let wrapper = await screen->getByTestId("headings-wrapper")
  await element(wrapper)->toMatchScreenshot("markdown-headings")
})

test("h1 keeps the generated markdown id for DocSearch", async () => {
  await viewport(1440, 900)

  let _screen = await render(
    <div>
      <Markdown.H1 id="heading-level-1"> {React.string("Heading Level 1")} </Markdown.H1>
    </div>,
  )

  switch document->WebAPI.Document.querySelector("h1#heading-level-1") {
  | Value(_) => ()
  | Null => failwith("expected markdown h1 to keep the generated id")
  }
})

test("markdown headings expose explicit DocSearch hierarchy markers", async () => {
  await viewport(1440, 900)

  let _screen = await render(
    <div>
      <Markdown.H1 id="heading-level-1"> {React.string("Heading Level 1")} </Markdown.H1>
      <Markdown.H2 id="heading-level-2"> {React.string("Heading Level 2")} </Markdown.H2>
      <Markdown.H3 id="heading-level-3"> {React.string("Heading Level 3")} </Markdown.H3>
      <Markdown.H4 id="heading-level-4"> {React.string("Heading Level 4")} </Markdown.H4>
      <Markdown.H5 id="heading-level-5"> {React.string("Heading Level 5")} </Markdown.H5>
    </div>,
  )

  switch document->WebAPI.Document.querySelector("h1.DocSearch-lvl1#heading-level-1") {
  | Value(_) => ()
  | Null => failwith("expected h1 to expose DocSearch lvl1")
  }
  switch document->WebAPI.Document.querySelector("h2.DocSearch-lvl2#heading-level-2") {
  | Value(_) => ()
  | Null => failwith("expected h2 to expose DocSearch lvl2")
  }
  switch document->WebAPI.Document.querySelector("h3.DocSearch-lvl3#heading-level-3") {
  | Value(_) => ()
  | Null => failwith("expected h3 to expose DocSearch lvl3")
  }
  switch document->WebAPI.Document.querySelector("h4.DocSearch-lvl4#heading-level-4") {
  | Value(_) => ()
  | Null => failwith("expected h4 to expose DocSearch lvl4")
  }
  switch document->WebAPI.Document.querySelector("h5.DocSearch-lvl5#heading-level-5") {
  | Value(_) => ()
  | Null => failwith("expected h5 to expose DocSearch lvl5")
  }
})

test("heading anchor links do not duplicate heading ids", async () => {
  await viewport(1440, 900)

  let _screen = await render(
    <div>
      <Markdown.H2 id="duplicate-check"> {React.string("Duplicate Check")} </Markdown.H2>
    </div>,
  )

  let matches = document->WebAPI.Document.querySelectorAll("[id='duplicate-check']")
  expect(matches.length)->toBe(1)
})

test("renders paragraph, strong, and intro", async () => {
  await viewport(1440, 900)

  let screen = await render(
    <div dataTestId="text-wrapper">
      <Markdown.Intro> {React.string("This is an introduction paragraph.")} </Markdown.Intro>
      <Markdown.P>
        {React.string("This is a regular paragraph with ")}
        <Markdown.Strong> {React.string("bold text")} </Markdown.Strong>
        {React.string(" inside it.")}
      </Markdown.P>
    </div>,
  )

  let intro = await screen->getByText("This is an introduction paragraph.")
  await element(intro)->toBeVisible

  let wrapper = await screen->getByTestId("text-wrapper")
  await element(wrapper)->toMatchScreenshot("markdown-text-elements")
})

test("renders Info and Warn admonitions", async () => {
  await viewport(1440, 900)

  let screen = await render(
    <div dataTestId="admonitions-wrapper">
      <Markdown.Info>
        <Markdown.P> {React.string("This is an informational message.")} </Markdown.P>
      </Markdown.Info>
      <Markdown.Warn>
        <Markdown.P> {React.string("This is a warning message.")} </Markdown.P>
      </Markdown.Warn>
    </div>,
  )

  let infoMsg = await screen->getByText("This is an informational message.")
  await element(infoMsg)->toBeVisible

  let warnMsg = await screen->getByText("This is a warning message.")
  await element(warnMsg)->toBeVisible

  let wrapper = await screen->getByTestId("admonitions-wrapper")
  await element(wrapper)->toMatchScreenshot("markdown-admonitions")
})

test("renders Cite with author", async () => {
  await viewport(1440, 900)

  let screen = await render(
    <div dataTestId="cite-wrapper">
      <Markdown.Cite author=Some("Jane Doe")>
        {React.string("ReScript is the future of typed JavaScript.")}
      </Markdown.Cite>
    </div>,
  )

  let author = await screen->getByText("Jane Doe")
  await element(author)->toBeVisible

  let quote = await screen->getByText("ReScript is the future of typed JavaScript.")
  await element(quote)->toBeVisible

  let wrapper = await screen->getByTestId("cite-wrapper")
  await element(wrapper)->toMatchScreenshot("markdown-cite")
})

test("renders blockquote", async () => {
  await viewport(1440, 900)

  let screen = await render(
    <div dataTestId="blockquote-wrapper">
      <Markdown.Blockquote>
        <Markdown.P> {React.string("This is a blockquote with some important text.")} </Markdown.P>
      </Markdown.Blockquote>
    </div>,
  )

  let text = await screen->getByText("This is a blockquote with some important text.")
  await element(text)->toBeVisible

  let wrapper = await screen->getByTestId("blockquote-wrapper")
  await element(wrapper)->toMatchScreenshot("markdown-blockquote")
})

test("renders lists", async () => {
  await viewport(1440, 900)

  let screen = await render(
    <div dataTestId="lists-wrapper">
      <Markdown.Ul>
        <Markdown.Li> {React.string("Apple")} </Markdown.Li>
        <Markdown.Li> {React.string("Banana")} </Markdown.Li>
      </Markdown.Ul>
      <Markdown.Ol>
        <Markdown.Li> {React.string("First step")} </Markdown.Li>
        <Markdown.Li> {React.string("Second step")} </Markdown.Li>
      </Markdown.Ol>
    </div>,
  )

  let unorderedItem = await screen->getByText("Apple")
  await element(unorderedItem)->toBeVisible

  let orderedItem = await screen->getByText("First step")
  await element(orderedItem)->toBeVisible

  let wrapper = await screen->getByTestId("lists-wrapper")
  await element(wrapper)->toMatchScreenshot("markdown-lists")
})

test("renders table", async () => {
  await viewport(1440, 900)

  let screen = await render(
    <div dataTestId="table-wrapper">
      <Markdown.Table>
        <Markdown.Thead>
          <tr>
            <Markdown.Th> {React.string("Name")} </Markdown.Th>
            <Markdown.Th> {React.string("Type")} </Markdown.Th>
          </tr>
        </Markdown.Thead>
        <tbody>
          <tr>
            <Markdown.Td> {React.string("foo")} </Markdown.Td>
            <Markdown.Td> {React.string("string")} </Markdown.Td>
          </tr>
          <tr>
            <Markdown.Td> {React.string("bar")} </Markdown.Td>
            <Markdown.Td> {React.string("int")} </Markdown.Td>
          </tr>
        </tbody>
      </Markdown.Table>
    </div>,
  )

  let nameHeader = await screen->getByText("Name")
  await element(nameHeader)->toBeVisible

  let fooCell = await screen->getByText("foo")
  await element(fooCell)->toBeVisible

  let wrapper = await screen->getByTestId("table-wrapper")
  await element(wrapper)->toMatchScreenshot("markdown-table")
})

test("renders links", async () => {
  await viewport(1440, 900)

  let screen = await render(
    <BrowserRouter>
      <div dataTestId="links-wrapper">
        <Markdown.P>
          <Markdown.A href="https://rescript-lang.org">
            {React.string("External link")}
          </Markdown.A>
        </Markdown.P>
        <Markdown.P>
          <Markdown.A href="/docs/manual/introduction">
            {React.string("Internal link")}
          </Markdown.A>
        </Markdown.P>
      </div>
    </BrowserRouter>,
  )

  let externalLink = await screen->getByText("External link")
  await element(externalLink)->toBeVisible

  let internalLink = await screen->getByText("Internal link")
  await element(internalLink)->toBeVisible

  let wrapper = await screen->getByTestId("links-wrapper")
  await element(wrapper)->toMatchScreenshot("markdown-links")
})

test("renders Image with caption", async () => {
  await viewport(1440, 900)

  let screen = await render(
    <div dataTestId="image-wrapper">
      <Markdown.Image
        className="rounded-lg border border-gray-90/5 text-gray-60"
        src="/lp/community-3.avif"
        caption="A sample image caption"
      />
    </div>,
  )

  let caption = await screen->getByText("A sample image caption")
  await element(caption)->toBeVisible

  let wrapper = await screen->getByTestId("image-wrapper")
  await waitForImages("[data-testid='image-wrapper']")
  await element(wrapper)->toMatchScreenshot("markdown-image")
})

test("renders Video with caption", async () => {
  await viewport(1440, 900)

  let screen = await render(
    <div dataTestId="video-wrapper">
      <Markdown.Video src="https://player.vimeo.com/video/477758754" caption="A sample video" />
    </div>,
  )

  let caption = await screen->getByText("A sample video")
  await element(caption)->toBeVisible
})

test("renders horizontal rule", async () => {
  await viewport(1440, 900)

  let screen = await render(
    <div dataTestId="hr-wrapper">
      <Markdown.P> {React.string("Content above the rule.")} </Markdown.P>
      <Markdown.Hr />
      <Markdown.P> {React.string("Content below the rule.")} </Markdown.P>
    </div>,
  )

  let above = await screen->getByText("Content above the rule.")
  await element(above)->toBeVisible

  let below = await screen->getByText("Content below the rule.")
  await element(below)->toBeVisible

  let wrapper = await screen->getByTestId("hr-wrapper")
  await element(wrapper)->toMatchScreenshot("markdown-hr")
})

test("renders inline code", async () => {
  await viewport(1440, 900)

  let screen = await render(
    <div dataTestId="inline-code-wrapper">
      <Markdown.P>
        {React.string("Use ")}
        <code
          className="md-inline-code px-2 py-0.5 text-gray-60 font-mono rounded-sm bg-gray-10-tr border border-gray-90/5"
        >
          {React.string("Array.map")}
        </code>
        {React.string(" to transform elements.")}
      </Markdown.P>
    </div>,
  )

  let code = await screen->getByText("Array.map")
  await element(code)->toBeVisible

  let wrapper = await screen->getByTestId("inline-code-wrapper")
  await element(wrapper)->toMatchScreenshot("markdown-inline-code")
})

test("renders Anchor with link icon", async () => {
  await viewport(1440, 900)

  let screen = await render(
    <div dataTestId="anchor-wrapper">
      <Markdown.H2 id="test-section"> {React.string("Test Section")} </Markdown.H2>
    </div>,
  )

  let heading = await screen->getByText("Test Section")
  await element(heading)->toBeVisible

  let wrapper = await screen->getByTestId("anchor-wrapper")
  await element(wrapper)->toMatchScreenshot("markdown-anchor")
})

test("renders Image with small size", async () => {
  await viewport(1440, 900)

  let screen = await render(
    <div dataTestId="image-small-wrapper">
      <Markdown.Image
        src="https://rescript-lang.org/brand/rescript-brandmark.svg"
        size=#small
        caption="Small image"
      />
    </div>,
  )

  let caption = await screen->getByText("Small image")
  await element(caption)->toBeVisible

  let wrapper = await screen->getByTestId("image-small-wrapper")
  await element(wrapper)->toMatchScreenshot("markdown-image-small")
})

test("renders Cite without author", async () => {
  await viewport(1440, 900)

  let screen = await render(
    <div dataTestId="cite-no-author-wrapper">
      <Markdown.Cite author=None>
        {React.string("An anonymous quote about functional programming.")}
      </Markdown.Cite>
    </div>,
  )

  let quote = await screen->getByText("An anonymous quote about functional programming.")
  await element(quote)->toBeVisible

  let wrapper = await screen->getByTestId("cite-no-author-wrapper")
  await element(wrapper)->toMatchScreenshot("markdown-cite-no-author")
})

test("renders nested list (ul inside li)", async () => {
  await viewport(1440, 900)

  let screen = await render(
    <div dataTestId="nested-list-wrapper">
      <Markdown.Ul>
        <Markdown.Li> {React.string("Parent item")} </Markdown.Li>
      </Markdown.Ul>
      <Markdown.Ol>
        <Markdown.Li> {React.string("Numbered item")} </Markdown.Li>
      </Markdown.Ol>
    </div>,
  )

  let parentItem = await screen->getByText("Parent item")
  await element(parentItem)->toBeVisible

  let numberedItem = await screen->getByText("Numbered item")
  await element(numberedItem)->toBeVisible

  let wrapper = await screen->getByTestId("nested-list-wrapper")
  await element(wrapper)->toMatchScreenshot("markdown-nested-lists")
})

test("renders Strong text", async () => {
  await viewport(1440, 900)

  let screen = await render(
    <div dataTestId="strong-wrapper">
      <Markdown.P>
        <Markdown.Strong> {React.string("Bold text")} </Markdown.Strong>
        {React.string(" and normal text")}
      </Markdown.P>
    </div>,
  )

  let bold = await screen->getByText("Bold text")
  await element(bold)->toBeVisible

  let wrapper = await screen->getByTestId("strong-wrapper")
  await element(wrapper)->toMatchScreenshot("markdown-strong")
})

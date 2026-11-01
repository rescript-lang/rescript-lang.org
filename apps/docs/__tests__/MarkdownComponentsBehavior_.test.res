open Vitest

test("h1 keeps the generated markdown id for DocSearch", async () => {
  await viewport(1440, 900)

  let _screen = await render(
    <div>
      <Markdown.H1 id="heading-level-1"> {React.string("Heading Level 1")} </Markdown.H1>
    </div>,
  )

  switch WebAPI.DOM.window
  ->WebAPI.Window.document
  ->WebAPI.Document.querySelector("h1#heading-level-1") {
  | Value(_) => ()
  | Null => panic("expected markdown h1 to keep the generated id")
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

  switch WebAPI.DOM.window
  ->WebAPI.Window.document
  ->WebAPI.Document.querySelector("h1.DocSearch-lvl1#heading-level-1") {
  | Value(_) => ()
  | Null => panic("expected h1 to expose DocSearch lvl1")
  }
  switch WebAPI.DOM.window
  ->WebAPI.Window.document
  ->WebAPI.Document.querySelector("h2.DocSearch-lvl2#heading-level-2") {
  | Value(_) => ()
  | Null => panic("expected h2 to expose DocSearch lvl2")
  }
  switch WebAPI.DOM.window
  ->WebAPI.Window.document
  ->WebAPI.Document.querySelector("h3.DocSearch-lvl3#heading-level-3") {
  | Value(_) => ()
  | Null => panic("expected h3 to expose DocSearch lvl3")
  }
  switch WebAPI.DOM.window
  ->WebAPI.Window.document
  ->WebAPI.Document.querySelector("h4.DocSearch-lvl4#heading-level-4") {
  | Value(_) => ()
  | Null => panic("expected h4 to expose DocSearch lvl4")
  }
  switch WebAPI.DOM.window
  ->WebAPI.Window.document
  ->WebAPI.Document.querySelector("h5.DocSearch-lvl5#heading-level-5") {
  | Value(_) => ()
  | Null => panic("expected h5 to expose DocSearch lvl5")
  }
})

test("heading anchor links do not duplicate heading ids", async () => {
  await viewport(1440, 900)

  let _screen = await render(
    <div>
      <Markdown.H2 id="duplicate-check"> {React.string("Duplicate Check")} </Markdown.H2>
    </div>,
  )

  let matches =
    WebAPI.DOM.window
    ->WebAPI.Window.document
    ->WebAPI.Document.querySelectorAll("[id='duplicate-check']")
  expect(matches.length)->toBe(1)
})

test("heading anchor scroll offset clears the sticky docs nav", async () => {
  await viewport(1000, 515)

  let screen = await render(
    <div>
      <nav dataTestId="anchor-primary" className="sticky top-0 h-16 bg-gray-90" />
      <nav dataTestId="anchor-secondary" className="sticky top-16 h-12 bg-white" />
      <nav dataTestId="anchor-tertiary" className="sticky top-28 h-12 bg-white" />
      <div style={{height: "500px"}} />
      <Markdown.H2 id="anchor-offset-target"> {React.string("Anchor Target")} </Markdown.H2>
      <div style={{height: "1000px"}} />
    </div>,
  )

  let target = switch WebAPI.DOM.window
  ->WebAPI.Window.document
  ->WebAPI.Document.querySelector("#anchor-offset-target") {
  | Value(target) => target
  | Null => panic("expected heading anchor target")
  }

  let tertiaryNav = switch WebAPI.DOM.window
  ->WebAPI.Window.document
  ->WebAPI.Document.querySelector("[data-testid='anchor-tertiary']") {
  | Value(nav) => nav
  | Null => panic("expected tertiary nav")
  }

  target->WebAPI.Element.scrollIntoViewAlignToTop

  let targetRect: WebAPI.DOM.domRect = target->WebAPI.Element.getBoundingClientRect
  let tertiaryNavRect: WebAPI.DOM.domRect = tertiaryNav->WebAPI.Element.getBoundingClientRect

  expect(targetRect.top >= tertiaryNavRect.bottom)->toBe(true)
  await screen->unmount
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

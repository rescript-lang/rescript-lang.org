open ReactRouter
open Vitest

@module("vitest")
external testWithTimeout: (string, unit => promise<unit>, int) => unit = "test"

let expectedExample = `module Button = {
  @react.component
  let make = (~count) => {
    let times = switch count {
    | 1 => "once"
    | 2 => "twice"
    | n => n->Int.toString ++ " times"
    }
    let text = \`Click me $\{times\}\`

    <button> {text->React.string} </button>
  }
}`

let snapshotSection = async (~width, ~height, ~sectionTestId, ~screenshotName) => {
  await viewport(width, height)

  let screen = await render(
    <MemoryRouter initialEntries=["/"]>
      <LandingPage />
    </MemoryRouter>,
  )

  let sourceSection = switch document->WebAPI.Document.querySelector(
    `[data-testid="${sectionTestId}"]`,
  ) {
  | Value(section) => section
  | Null => failwith(`expected to find section ${sectionTestId}`)
  }

  let sandboxTestId = `${sectionTestId}-snapshot`
  let snapshotHtml = sourceSection.outerHTML
  await screen->unmount

  let snapshotScreen = await render(
    <div
      dataTestId=sandboxTestId
      style={{width: `${width->Int.toString}px`, margin: "0"}}
      dangerouslySetInnerHTML={"__html": snapshotHtml}
    />,
  )

  let snapshotTarget = await snapshotScreen->getByTestId(sandboxTestId)
  await element(snapshotTarget)->toBeVisible
  await element(snapshotTarget)->toMatchScreenshot(screenshotName)
  await snapshotScreen->unmount
}

let snapshotResponsive = async (~sectionTestId, ~screenshotBase) => {
  await snapshotSection(
    ~width=1440,
    ~height=1800,
    ~sectionTestId,
    ~screenshotName={`${screenshotBase}-desktop`},
  )

  await snapshotSection(
    ~width=900,
    ~height=1800,
    ~sectionTestId,
    ~screenshotName={`${screenshotBase}-tablet`},
  )

  await snapshotSection(
    ~width=600,
    ~height=1800,
    ~sectionTestId,
    ~screenshotName={`${screenshotBase}-mobile`},
  )
}

testWithTimeout(
  "landing intro snapshots",
  async () => {
    await snapshotResponsive(~sectionTestId="landing-intro", ~screenshotBase="landing-page-intro")
  },
  30000,
)

testWithTimeout(
  "landing playground hero snapshots",
  async () => {
    await snapshotResponsive(
      ~sectionTestId="landing-playground-hero",
      ~screenshotBase="landing-page-playground-hero",
    )
  },
  30000,
)

testWithTimeout(
  "landing quick install snapshots",
  async () => {
    await snapshotResponsive(
      ~sectionTestId="landing-quick-install",
      ~screenshotBase="landing-page-quick-install",
    )
  },
  30000,
)

testWithTimeout(
  "landing other selling points snapshots",
  async () => {
    await snapshotResponsive(
      ~sectionTestId="landing-other-selling-points",
      ~screenshotBase="landing-page-other-selling-points",
    )
  },
  30000,
)

testWithTimeout(
  "landing trusted by snapshots",
  async () => {
    await snapshotResponsive(
      ~sectionTestId="landing-trusted-by",
      ~screenshotBase="landing-page-trusted-by",
    )
  },
  30000,
)

testWithTimeout(
  "landing curated resources snapshots",
  async () => {
    await snapshotResponsive(
      ~sectionTestId="landing-curated-resources",
      ~screenshotBase="landing-page-curated-resources",
    )
  },
  30000,
)

test(
  "landing page playground link uses compressed code that the playground can decode",
  async () => {
    let screen = await render(
      <MemoryRouter initialEntries=["/"]>
        <LandingPage />
      </MemoryRouter>,
    )

    let _ = await screen->getByText("Edit this example in Playground")

    let href = switch document->WebAPI.Document.querySelector("a[href*='/try?code=']") {
    | Value(link) =>
      switch link->WebAPI.Element.getAttribute("href") {
      | Value(href) => href
      | Null => failwith("expected landing page playground link to have an href")
      }
    | Null => failwith("expected to find the landing page playground link")
    }

    let {pathname, searchParams} = WebAPI.URL.make(~url=href, ~base="https://rescript-lang.org")

    expect(pathname)->toBe("/try")

    let compressedCode =
      searchParams->WebAPI.URLSearchParams.get("code")->Nullable.make->Nullable.toOption

    let decodedCode =
      compressedCode
      ->Option.getOrThrow
      ->LzString.lzString.decompressFromEncodedURIComponent
      ->Nullable.make
      ->Nullable.toOption

    expect(decodedCode->Option.isSome)->toBe(true)
    expect(decodedCode->Option.getOrThrow)->toBe(expectedExample)
  },
)

test("landing page playground hero renders highlighted code tokens", async () => {
  let screen = await render(
    <MemoryRouter initialEntries=["/"]>
      <LandingPage />
    </MemoryRouter>,
  )

  let _ = await screen->getByText("Write in ReScript")

  let rescriptCodeBlock = switch document->WebAPI.Document.querySelector(
    "[data-testid='landing-playground-hero'] code.lang-res",
  ) {
  | Value(codeBlock) => codeBlock
  | Null => failwith("expected landing playground hero to render the ReScript code block")
  }

  let javascriptCodeBlock = switch document->WebAPI.Document.querySelector(
    "[data-testid='landing-playground-hero'] code.lang-js",
  ) {
  | Value(codeBlock) => codeBlock
  | Null => failwith("expected landing playground hero to render the JavaScript code block")
  }

  expect(rescriptCodeBlock.innerHTML->String.includes("<span"))->toBe(true)
  expect(javascriptCodeBlock.innerHTML->String.includes("<span"))->toBe(true)
})

test(
  "landing page playground hero keeps highlight styling in the sandboxed snapshot copy",
  async () => {
    await viewport(1440, 1800)

    let screen = await render(
      <MemoryRouter initialEntries=["/"]>
        <LandingPage />
      </MemoryRouter>,
    )

    let sourceSection = switch document->WebAPI.Document.querySelector(
      "[data-testid='landing-playground-hero']",
    ) {
    | Value(section) => section
    | Null => failwith("expected to find the landing playground hero section")
    }

    let sandboxTestId = "landing-playground-hero-sandbox"
    let snapshotHtml = sourceSection.outerHTML
    await screen->unmount

    let snapshotScreen = await render(
      <div
        dataTestId=sandboxTestId
        style={{width: "1440px", margin: "0"}}
        dangerouslySetInnerHTML={"__html": snapshotHtml}
      />,
    )

    let _ = await snapshotScreen->getByTestId(sandboxTestId)

    let sandbox = switch document->WebAPI.Document.querySelector(
      "[data-testid='landing-playground-hero-sandbox']",
    ) {
    | Value(sandbox) => sandbox
    | Null => failwith("expected to find the sandboxed landing playground hero")
    }

    let sandboxRect: WebAPI.DOMAPI.domRect = sandbox->WebAPI.Element.getBoundingClientRect

    let rescriptCodeBlock = switch document->WebAPI.Document.querySelector(
      "[data-testid='landing-playground-hero-sandbox'] code.lang-res",
    ) {
    | Value(codeBlock) => codeBlock
    | Null =>
      failwith("expected sandboxed landing playground hero to render the ReScript code block")
    }

    let javascriptCodeBlock = switch document->WebAPI.Document.querySelector(
      "[data-testid='landing-playground-hero-sandbox'] code.lang-js",
    ) {
    | Value(codeBlock) => codeBlock
    | Null =>
      failwith("expected sandboxed landing playground hero to render the JavaScript code block")
    }

    expect(sandboxRect.width > 1000.0)->toBe(true)
    expect(rescriptCodeBlock.innerHTML->String.includes("<span"))->toBe(true)
    expect(javascriptCodeBlock.innerHTML->String.includes("<span"))->toBe(true)
    await snapshotScreen->unmount
  },
)

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

  let body = switch document->WebAPI.Document.querySelector("body") {
  | Value(body) => body
  | Null => failwith("expected document body to exist")
  }

  let sandbox = document->WebAPI.Document.createElement("div")
  let sandboxTestId = `${sectionTestId}-snapshot`
  let clonedSection = (sourceSection :> WebAPI.DOMAPI.node)->WebAPI.Node.cloneNode(~deep=true)

  sandbox->WebAPI.Element.setAttribute(~qualifiedName="data-testid", ~value=sandboxTestId)
  sandbox->WebAPI.Element.setAttribute(
    ~qualifiedName="style",
    ~value="position: absolute; left: 0; top: 0; width: 100%; margin: 0;",
  )

  (sandbox :> WebAPI.DOMAPI.node)->WebAPI.Node.appendChild(clonedSection)->ignore
  (body :> WebAPI.DOMAPI.node)->WebAPI.Node.appendChild(sandbox)->ignore
  await screen->unmount

  let snapshotTarget = pageGetByTestId(sandboxTestId)
  await element(snapshotTarget)->toBeVisible
  await element(snapshotTarget)->toMatchScreenshot(screenshotName)
  body->WebAPI.Element.removeChild(sandbox)->ignore
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

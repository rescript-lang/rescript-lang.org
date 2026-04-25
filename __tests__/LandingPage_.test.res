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

let renderSection = async (~width, ~height, ~renderId, ~sectionTestId) => {
  await viewport(width, height)

  let screen = await render(
    <MemoryRouter initialEntries=["/"]>
      <div dataTestId=renderId>
        <LandingPage />
      </div>
    </MemoryRouter>,
  )

  let renderRoot = await screen->getByTestId(renderId)
  let section = await renderRoot->getByTestId(sectionTestId)
  await element(section)->toBeVisible
  section
}

let snapshotResponsive = async (~sectionTestId, ~screenshotBase) => {
  let desktop = await renderSection(
    ~width=1440,
    ~height=900,
    ~renderId={`${sectionTestId}-desktop-render`},
    ~sectionTestId,
  )
  await element(desktop)->toMatchScreenshot(`${screenshotBase}-desktop`)

  let tablet = await renderSection(
    ~width=900,
    ~height=900,
    ~renderId={`${sectionTestId}-tablet-render`},
    ~sectionTestId,
  )
  await element(tablet)->toMatchScreenshot(`${screenshotBase}-tablet`)

  let mobile = await renderSection(
    ~width=600,
    ~height=1800,
    ~renderId={`${sectionTestId}-mobile-render`},
    ~sectionTestId,
  )
  await element(mobile)->toMatchScreenshot(`${screenshotBase}-mobile`)
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

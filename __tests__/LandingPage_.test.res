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

let renderSection = async (~width, ~height, ~testId, component) => {
  await viewport(width, height)

  let screen = await render(
    <MemoryRouter initialEntries=["/"]>
      <div dataTestId=testId> component </div>
    </MemoryRouter>,
  )

  let wrapper = await screen->getByTestId(testId)
  await element(wrapper)->toBeVisible
  wrapper
}

let snapshotResponsive = async (~testId, ~screenshotBase, component) => {
  let desktop = await renderSection(
    ~width=1440,
    ~height=900,
    ~testId={`${testId}-desktop`},
    component(),
  )
  await element(desktop)->toMatchScreenshot(`${screenshotBase}-desktop`)

  let tablet = await renderSection(
    ~width=900,
    ~height=900,
    ~testId={`${testId}-tablet`},
    component(),
  )
  await element(tablet)->toMatchScreenshot(`${screenshotBase}-tablet`)

  let mobile = await renderSection(
    ~width=600,
    ~height=1200,
    ~testId={`${testId}-mobile`},
    component(),
  )
  await element(mobile)->toMatchScreenshot(`${screenshotBase}-mobile`)
}

testWithTimeout(
  "landing intro snapshots",
  async () => {
    await snapshotResponsive(
      ~testId="landing-intro-test-wrapper",
      ~screenshotBase="landing-page-intro",
      LandingPage.introForTest,
    )
  },
  30000,
)

testWithTimeout(
  "landing playground hero snapshots",
  async () => {
    await snapshotResponsive(
      ~testId="landing-playground-hero-test-wrapper",
      ~screenshotBase="landing-page-playground-hero",
      LandingPage.playgroundHeroForTest,
    )
  },
  30000,
)

testWithTimeout(
  "landing quick install snapshots",
  async () => {
    await snapshotResponsive(
      ~testId="landing-quick-install-test-wrapper",
      ~screenshotBase="landing-page-quick-install",
      LandingPage.quickInstallForTest,
    )
  },
  30000,
)

testWithTimeout(
  "landing other selling points snapshots",
  async () => {
    await snapshotResponsive(
      ~testId="landing-other-selling-points-test-wrapper",
      ~screenshotBase="landing-page-other-selling-points",
      LandingPage.otherSellingPointsForTest,
    )
  },
  30000,
)

testWithTimeout(
  "landing trusted by snapshots",
  async () => {
    await snapshotResponsive(
      ~testId="landing-trusted-by-test-wrapper",
      ~screenshotBase="landing-page-trusted-by",
      LandingPage.trustedByForTest,
    )
  },
  30000,
)

testWithTimeout(
  "landing curated resources snapshots",
  async () => {
    await snapshotResponsive(
      ~testId="landing-curated-resources-test-wrapper",
      ~screenshotBase="landing-page-curated-resources",
      LandingPage.curatedResourcesForTest,
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

open ReactRouter
open Vitest

@module("vitest")
external testWithTimeout: (string, unit => promise<unit>, int) => unit = "test"

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
  await waitForImages(`[data-testid="${sandboxTestId}"]`)
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

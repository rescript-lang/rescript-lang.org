open Cypress

let waitForHydration = () => {
  getByTestId("navbar-primary")->should("be.visible")->ignore
  cyWindow()->propertyString("document.readyState")->shouldEqual("complete")->ignore
  pause(2000)
}

let waitForPlayground = () => {
  get(".cm-editor")->should("be.visible")->ignore
  getByTestId("control-panel")->should("be.visible")->ignore
  pause(2000)
}

let clickNavLink = (~testId, ~text) => {
  get(`[data-testid="${testId}"] a:visible`)
  ->containsChild(text)
  ->click
  ->ignore
}

let compileAndRunImportedCode = () => {
  waitForPlayground()

  get(".cm-content")
  ->typeWithOptions(
    "{selectall}{backspace}@module(\"react\") external reactVersion: string = \"version\"{enter}Console.log(\"React \" ++ reactVersion)",
    {"force": true, "delay": 20},
  )
  ->ignore

  pause(3000)

  contains("JavaScript")->click->ignore
  get("pre.whitespace-pre-wrap")
  ->shouldContainText("from \"react\"")
  ->shouldContainText("console.log")
  ->ignore

  getByTestId("control-panel")
  ->find("button")
  ->containsChild("Run")
  ->click
  ->ignore

  get("div.whitespace-pre-wrap pre")
  ->shouldContainText("React 18.2.0")
  ->ignore
}

let v13Versions = [
  "v13.0.0-alpha.1",
  "v13.0.0-alpha.2",
  "v13.0.0-alpha.3",
  "v13.0.0-alpha.4",
  "v13.0.0-alpha.5",
  "v13.0.0-alpha.6",
]

describe("Playground", () => {
  beforeEach(() => {
    viewport(1280, 720)
    visit("/")
    waitForHydration()
  })

  it("should highlight JavaScript after a direct playground load", () => {
    visit("/try")
    get(".cm-editor")->should("be.visible")->ignore
    get("main")->shouldCss("background-color", "rgb(11, 13, 34)")->ignore
    get(".cm-editor")->shouldCss("background-color", "rgb(11, 13, 34)")->ignore
    get("pre.whitespace-pre-wrap")->shouldContainText("react/jsx-runtime")->ignore
    get("pre code.lang-js span[class^='hljs-']")->should("exist")->ignore
  })

  it("should compile and run imported code in the playground", () => {
    // Navigate to the playground from the homepage
    clickNavLink(~testId="navbar-primary-left-content", ~text="Playground")
    currentUrl()->shouldInclude("/try")->ignore

    compileAndRunImportedCode()
  })

  Array.forEach(v13Versions, version => {
    it(
      `should compile and run imported code with ${version}`,
      () => {
        clickNavLink(~testId="navbar-primary-left-content", ~text="Playground")
        waitForPlayground()

        contains("Settings")->click->ignore
        get(`select[name="compilerVersions"]`)
        ->select(version)
        ->shouldValue(version)
        ->ignore

        compileAndRunImportedCode()
      },
    )
  })

  it("should run exception code with v13.0.0-alpha.6", () => {
    let code = `exception HttpError({status: int})

let isRetriable: exn => bool = error =>
  switch error {
  | HttpError({status: 502 | 503 | 504}) => true
  | _ => false
  }

Console.log(isRetriable(HttpError({status: 500})))`
    let compressedCode = LzString.lzString.compressToEncodedURIComponent(code)
    visit(`/try?version=v13.0.0-alpha.6&code=${compressedCode}`)
    waitForPlayground()

    get("pre.whitespace-pre-wrap")->shouldContainText("Primitive_exceptions.mjs")->ignore
    getByTestId("control-panel")
    ->find("button")
    ->containsChild("Run")
    ->click
    ->ignore

    get("div.whitespace-pre-wrap pre")->shouldContainText("false")->ignore
  })

  it("should open the landing page example in the playground with code and compiled output", () => {
    containsIn("a", "Edit this example in Playground")
    ->scrollIntoView
    ->should("be.visible")
    ->click
    ->ignore

    currentUrl()->shouldInclude("/try?code=")->ignore
    waitForPlayground()

    get(".cm-content")
    ->shouldContainText("module Button = {")
    ->shouldContainText("Click me")
    ->ignore

    get("pre.whitespace-pre-wrap")
    ->should("be.visible")
    ->shouldContainText("react/jsx-runtime")
    ->shouldContainText("Click me")
    ->ignore
  })

  it("should switch to light mode from toast and back to dark mode in settings", () => {
    // Navigate to playground and wait for initial render
    clickNavLink(~testId="navbar-primary-left-content", ~text="Playground")
    currentUrl()->shouldInclude("/try")->ignore
    waitForPlayground()

    // Switch to light mode through the onboarding toast
    getByTestId("playground-lightmode-toast")
    ->should("be.visible")
    ->find("button")
    ->containsChild("Try it now")
    ->click
    ->ignore

    // Verify playground shell is in light mode
    get("main")->shouldClass("playground-theme-light")->ignore
    get("main")->shouldCss("background-color", "rgb(250, 251, 252)")->ignore
    get(".cm-editor")
    ->shouldCss("background-color", "rgb(255, 255, 255)")
    ->ignore
    cyWindow()
    ->thenMap(window => window.localStorage->WebAPI.Storage.getItem("playgroundTheme"))
    ->shouldEqual(Null.make("light"))
    ->ignore

    // Switch back to dark mode from Settings
    contains("Settings")->click->ignore
    get("main")
    ->find("button")
    ->containsChild("Dark")
    ->click
    ->ignore

    // Verify playground shell is back to dark mode
    get("main")->shouldClass("playground-theme-dark")->ignore
    get("main")->shouldCss("background-color", "rgb(11, 13, 34)")->ignore
    get(".cm-editor")->shouldCss("background-color", "rgb(11, 13, 34)")->ignore
    cyWindow()
    ->thenMap(window => window.localStorage->WebAPI.Storage.getItem("playgroundTheme"))
    ->shouldEqual(Null.make("dark"))
    ->ignore
  })
})

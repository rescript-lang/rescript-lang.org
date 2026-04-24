open Cy

let waitForHydration = () => {
  getByTestId("navbar-primary")->shouldBeVisible->ignore
  cyWindow()->its("document.readyState")->shouldWithValue("eq", "complete")->ignore
  wait(2000)
}

let waitForPlayground = () => {
  get(".cm-editor")->should("be.visible")->ignore
  getByTestId("control-panel")->should("be.visible")->ignore
  wait(2000)
}

let clickNavLink = (~testId, ~text) => {
  get(`[data-testid="${testId}"] a:visible`)
  ->containsChainable(text)
  ->click
  ->ignore
}

describe("Playground", () => {
  beforeEach(() => {
    viewport(1280, 720)
    visit("/")
    waitForHydration()
  })

  it("should compile and run Console.log in the playground", () => {
    // Navigate to the playground from the homepage
    clickNavLink(~testId="navbar-primary-left-content", ~text="Playground")
    url()->shouldInclude("/try")->ignore

    // Wait for the playground editor and compiler to fully load
    waitForPlayground()

    // Clear all existing code and type new ReScript source
    get(".cm-content")
    ->typeWithOptions(
      "{selectall}{backspace}Console.log(\"Hello ReScript!\")",
      {"force": true, "delay": 20},
    )
    ->ignore

    // Allow time for the compiler to process
    wait(3000)

    // Switch to the JavaScript tab and verify compiled output
    contains("JavaScript")->click->ignore
    get("pre.whitespace-pre-wrap")
    ->shouldContainText("console.log")
    ->ignore

    // Click the Run button in the control panel
    getByTestId("control-panel")
    ->find("button")
    ->containsChainable("Run")
    ->click
    ->ignore

    // The Run button auto-switches to the Output tab.
    // Verify the console output panel contains the logged text.
    get("div.whitespace-pre-wrap pre")
    ->shouldContainText("Hello ReScript!")
    ->ignore
  })

  it("should open the landing page example in the playground with code and compiled output", () => {
    containsSelector("a", "Edit this example in Playground")
    ->scrollIntoView
    ->should("be.visible")
    ->click
    ->ignore

    url()->shouldInclude("/try?code=")->ignore
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
    url()->shouldInclude("/try")->ignore
    waitForPlayground()

    // Switch to light mode through the onboarding toast
    getByTestId("playground-lightmode-toast")
    ->should("be.visible")
    ->find("button")
    ->containsChainable("Try it now")
    ->click
    ->ignore

    // Verify playground shell is in light mode
    get("main")->shouldWithValue("have.class", "playground-theme-light")->ignore
    cyWindow()
    ->its("localStorage")
    ->invokeWithArg("getItem", "playgroundTheme")
    ->shouldWithValue("eq", "light")
    ->ignore

    // Switch back to dark mode from Settings
    contains("Settings")->click->ignore
    get("main")
    ->find("button")
    ->containsChainable("Dark")
    ->click
    ->ignore

    // Verify playground shell is back to dark mode
    get("main")->shouldWithValue("have.class", "playground-theme-dark")->ignore
    cyWindow()
    ->its("localStorage")
    ->invokeWithArg("getItem", "playgroundTheme")
    ->shouldWithValue("eq", "dark")
    ->ignore
  })
})

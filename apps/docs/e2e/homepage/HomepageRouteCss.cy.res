open Cypress
open HomepageHelpers

type foundationCounts = {
  fonts: int,
  uniqueFonts: int,
  tokens: array<int>,
  resets: int,
}

let homepageLayoutSelectors = [
  ".max-w-1060",
  ".md\\:grid-cols-10",
  ".md\\:col-span-6",
  ".min-h-148",
]

let expectDesktopLogo = () => {
  get(`a[aria-label="homepage"]`)
  ->shouldCss("width", "128px")
  ->shouldCss("height", "40px")
  ->ignore
  get(`a[aria-label="homepage"] img[alt="ReScript Home"]`)->should("be.visible")->ignore
}

let loadedStyles = () =>
  cyWindow()->thenPromise(async window => {
    let styles = await window.document
    ->querySelectorAll(`link[rel="stylesheet"]`)
    ->elementsFrom
    ->Array.map(async link => {
      let response = await window->windowFetch(link->elementHref)
      expect(response->fetchStatus, ~message=link->elementHref)->equal(200)
      await response->responseText
    })
    ->Promise.all
    styles->Array.join("\n")
  })

let rec flattenRules = rules =>
  rules->Array.flatMap(rule =>
    switch rule->nestedRules->Nullable.toOption {
    | Some(nested) => [rule]->Array.concat(nested->rulesFrom->flattenRules)
    | None => [rule]
    }
  )

let foundationCounts = window => {
  let rules =
    window.document
    ->styleSheets
    ->styleSheetsFrom
    ->Array.flatMap(sheet => sheet->sheetRules->rulesFrom->flattenRules)
  let fonts = rules->Array.filter(rule => rule->ruleType === 5)->Array.map(rule => rule->cssText)
  let styles = rules->Array.filter(rule => rule->ruleType === 1)
  let tokens =
    ["--font-sans", "--color-gray-90", "--color-fire", "--text-48"]->Array.map(token =>
      styles->Array.filter(rule => rule->ruleStyle->propertyValue(token) !== "")->Array.length
    )
  let uniqueFonts =
    fonts->Array.reduce([], (unique, font) =>
      unique->Array.includes(font) ? unique : unique->Array.concat([font])
    )
  let resets = styles->Array.filter(rule =>
    rule
    ->selectorText
    ->String.split(",")
    ->Array.some(selector => selector->String.trim === "*") &&
      rule->ruleStyle->boxSizing === "border-box"
  )
  {
    fonts: fonts->Array.length,
    uniqueFonts: uniqueFonts->Array.length,
    tokens,
    resets: resets->Array.length,
  }
}

let expectContentStyles = () =>
  loadedStyles()->then(styles => {
    expect(styles)->include_(".markdown-body")
    expect(styles)->notInclude(".playground-theme")
    homepageLayoutSelectors->Array.forEach(selector => expect(styles)->notInclude(selector))
  })

it("homepage styles exclude content, search, and playground rules", () => {
  visit("/")
  containsIn("h1", headline)->should("be.visible")->ignore
  loadedStyles()
  ->then(styles => {
    expect(styles)->include_(".gallery-selector")
    homepageLayoutSelectors->Array.forEach(selector => expect(styles)->include_(selector))
    [".markdown-body", ".playground-theme", ".DocSearch-Modal"]->Array.forEach(
      selector => expect(styles)->notInclude(selector),
    )
  })
  ->ignore
})

it("shared foundations are emitted once across route navigation", () => {
  visit("/")
  cyWindow()
  ->thenMap(foundationCounts)
  ->then(initial => {
    expect(initial.fonts)->greaterThan(0)
    expect(initial.uniqueFonts)->equal(initial.fonts)
    expect(initial.tokens)->deepEqual([1, 1, 1, 1])
    expect(initial.resets)->equal(1)
    containsInRegex("a", /^Docs$/)->click->ignore
    containsInRegex("h1", /^ReScript$/)->should("be.visible")->ignore
    cyWindow()->thenMap(foundationCounts)->shouldDeepEqual(initial)->ignore
    get(`a[aria-label="homepage"]`)->click->ignore
    containsIn("h1", headline)->shouldCss("font-size", "68px")->ignore
    cyWindow()->thenMap(foundationCounts)->shouldDeepEqual(initial)->ignore
  })
  ->ignore
})

it("desktop navigation keeps its responsive logo across route stylesheets", () => {
  visit("/")
  expectDesktopLogo()
  containsInRegex("a", /^Docs$/)->click->ignore
  containsInRegex("h1", /^ReScript$/)->should("be.visible")->ignore
  expectDesktopLogo()
  get(`a[aria-label="homepage"]`)->click->ignore
  containsIn("h1", headline)->should("be.visible")->ignore
  expectDesktopLogo()
})

it("documentation styles are prefetched only after navigation intent", () => {
  visit("/")
  let prefetch = `link[rel="prefetch"][as="style"][href*="/content-"]`
  get(prefetch)->should("not.exist")->ignore
  containsInRegex("a", /^Get started$/)->focusElement->ignore
  get(prefetch)->shouldInt("have.length", 1)->ignore
  containsInRegex("a", /^Docs$/)->focusElement->ignore
  get(prefetch)->should("not.exist")->ignore
})

[
  ("/docs/manual/introduction/", "ReScript"),
  ("/brand/", "Brand Assets"),
  ("/packages/", "Libraries & Bindings"),
]->Array.forEach(((path, title)) => {
  it(`cold ${path} loads its content styles`, () => {
    visit(path)
    containsIn("h1", title)
    ->should("be.visible")
    ->shouldCss("font-weight", "600")
    ->shouldCss("font-size", "48px")
    ->ignore
    expectContentStyles()->ignore
  })
})

it("cold blog styles preserve article typography", () => {
  visit("/blog/")
  get("h2")
  ->first
  ->should("be.visible")
  ->shouldCss("font-size", "48px")
  ->shouldCss("font-weight", "600")
  ->ignore
  expectContentStyles()->ignore
})

it("mobile documentation drawer retains its layout after navigation", () => {
  viewport(375, 812)
  visit("/")
  containsInRegex("a", /^Docs$/)->click->ignore
  containsInRegex("h1", /^ReScript$/)->should("be.visible")->ignore
  get(`button[aria-label="Toggle navigation menu"]`)->click->ignore
  get("dialog#mobile-tertiary-drawer")
  ->as_("drawer")
  ->should("be.visible")
  ->shouldCss("background-color", "rgb(255, 255, 255)")
  ->shouldCss("margin-left", "0px")
  ->ignore
  alias("@drawer")->containsChildRegex("a", /^Installation$/)->click->ignore
  containsInRegex("h1", /^Installation$/)->should("be.visible")->ignore
  realPressKey("Escape")->ignore
  alias("@drawer")->should("not.be.visible")->ignore
})

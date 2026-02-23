/**
 * ─────────────────────────────────────────────────────────────────────────────
 * Core types
 * ─────────────────────────────────────────────────────────────────────────────
 */
type page
type locator
type response
type browserContext
type keyboard
type mouse

type fixtures = {
  page: page,
  context: browserContext,
}

/** Access the BrowserContext that owns this page. */
@send
external context: page => browserContext = "context"

/**
 * ─────────────────────────────────────────────────────────────────────────────
 * @chromatic-com/playwright — test, expect, takeSnapshot
 *
 * Using Chromatic's wrapped `test` means snapshot collection is wired up
 * automatically when CHROMATIC_PROJECT_TOKEN is present in the environment;
 * when the token is absent every `takeSnapshot` call is a no-op so the suite
 * still runs as ordinary Playwright tests.
 * ─────────────────────────────────────────────────────────────────────────────
 */
@module("./playwright-shim.mjs")
external test: (string, fixtures => promise<unit>) => unit = "test"

/** Group related tests under a shared label. */
@module("./playwright-shim.mjs") @scope("test")
external describe: (string, unit => unit) => unit = "describe"

/** Run a hook before every test in the current scope. */
@module("./playwright-shim.mjs") @scope("test")
external beforeEach: (fixtures => promise<unit>) => unit = "beforeEach"

/** Run a hook after every test in the current scope. */
@module("./playwright-shim.mjs") @scope("test")
external afterEach: (fixtures => promise<unit>) => unit = "afterEach"

/** Run a hook once before all tests in the current scope (worker-level). */
@module("./playwright-shim.mjs") @scope("test")
external beforeAll: (fixtures => promise<unit>) => unit = "beforeAll"

/** Run a hook once after all tests in the current scope (worker-level). */
@module("./playwright-shim.mjs") @scope("test")
external afterAll: (fixtures => promise<unit>) => unit = "afterAll"

/**
 * Mark a test as the only one that should run in this file while debugging.
 * Tests decorated with `only` must not be committed — set `forbidOnly: true`
 * in playwright.config.mjs to enforce this in CI.
 */
@module("./playwright-shim.mjs") @scope("test")
external only: (string, fixtures => promise<unit>) => unit = "only"

/** Skip a test unconditionally. */
@module("./playwright-shim.mjs") @scope("test")
external skip: (string, fixtures => promise<unit>) => unit = "skip"

/**
 * Capture a Chromatic visual snapshot of the current page state.
 * Call this at the point in your test where the UI is in the state you want
 * to visually compare across builds.
 */
@module("./playwright-shim.mjs")
external takeSnapshot: (page, string) => promise<unit> = "takeSnapshot"

/**
 * ─────────────────────────────────────────────────────────────────────────────
 * Assertions  (expect)
 * ─────────────────────────────────────────────────────────────────────────────
 */
type expect

/**
 * Works for both Locator-based and Page-based assertions, as well as plain
 * value assertions (e.g. array length checks).
 */
@module("@chromatic-com/playwright")
external expect: 'a => expect = "expect"

/** Negate the following matcher. */
@send
external not_: expect => expect = "not"

// ── Locator assertions (async) ────────────────────────────────────────────────
//
// Each assertion comes in two forms:
//   • Plain  — `toBeVisible`  — no options, works cleanly in pipe chains.
//   • WithOptions — `toBeVisibleWith` — accepts a record of options when you
//     need e.g. a custom timeout.
//
// The split is necessary because ReScript's pipe operator (`->`) combined with
// `()` does not compose well with optional labelled arguments.

@send
external toBeVisible: expect => promise<unit> = "toBeVisible"

type toBeVisibleOptions = {timeout?: int}
@send
external toBeVisibleWith: (expect, toBeVisibleOptions) => promise<unit> = "toBeVisible"

@send
external toBeHidden: expect => promise<unit> = "toBeHidden"

@send
external toBeHiddenWith: (expect, toBeVisibleOptions) => promise<unit> = "toBeHidden"

@send
external toBeEnabled: expect => promise<unit> = "toBeEnabled"

@send
external toBeDisabled: expect => promise<unit> = "toBeDisabled"

@send
external toBeChecked: expect => promise<unit> = "toBeChecked"

@send
external toBeFocused: expect => promise<unit> = "toBeFocused"

@send
external toHaveText: (expect, string) => promise<unit> = "toHaveText"

type toHaveTextOptions = {ignoreCase?: bool, useInnerText?: bool, timeout?: int}
@send
external toHaveTextWith: (expect, string, toHaveTextOptions) => promise<unit> = "toHaveText"

@send
external toContainText: (expect, string) => promise<unit> = "toContainText"

type toContainTextOptions = {ignoreCase?: bool, useInnerText?: bool, timeout?: int}
@send
external toContainTextWith: (expect, string, toContainTextOptions) => promise<unit> =
  "toContainText"

@send
external toHaveValue: (expect, string) => promise<unit> = "toHaveValue"

@send
external toHaveAttribute: (expect, string, string) => promise<unit> = "toHaveAttribute"

@send
external toHaveClass: (expect, string) => promise<unit> = "toHaveClass"

@send
external toHaveCount: (expect, int) => promise<unit> = "toHaveCount"

// ── Page-level assertions (async) ─────────────────────────────────────────────

@send
external toHaveURL: (expect, string) => promise<unit> = "toHaveURL"

type toHaveURLOptions = {timeout?: int}
@send
external toHaveURLWith: (expect, string, toHaveURLOptions) => promise<unit> = "toHaveURL"

@send
external toHaveTitle: (expect, string) => promise<unit> = "toHaveTitle"

type toHaveTitleOptions = {timeout?: int}
@send
external toHaveTitleWith: (expect, string, toHaveTitleOptions) => promise<unit> = "toHaveTitle"

// ── Plain value assertions (sync) ─────────────────────────────────────────────

@send external toEqual: (expect, 'a) => unit = "toEqual"
@send external toBe: (expect, 'a) => unit = "toBe"
@send external toHaveLength: (expect, int) => unit = "toHaveLength"
@send external toBeGreaterThan: (expect, int) => unit = "toBeGreaterThan"
@send external toContain: (expect, 'a) => unit = "toContain"

/**
 * ─────────────────────────────────────────────────────────────────────────────
 * Page navigation and state
 * ─────────────────────────────────────────────────────────────────────────────
 */
type gotoOptions = {
  waitUntil?: string,
  timeout?: int,
  referer?: string,
}

/** Navigate to a URL. Resolves when the page load event fires (by default). */
@send
external goto: (page, string, ~options: gotoOptions=?) => promise<Nullable.t<response>> = "goto"

/** Wait for a load state: `"load"`, `"domcontentloaded"`, or `"networkidle"`. */
@send
external waitForLoadState: (page, string) => promise<unit> = "waitForLoadState"

/** Return the page's `<title>` text. */
@send
external title: page => promise<string> = "title"

/** Return the current URL. */
@send
external url: page => string = "url"

/** Reload the current page. */
@send
external reload: page => promise<Nullable.t<response>> = "reload"

/** Press a key or key-chord on the keyboard, e.g. `"Enter"`, `"Control+a"`. */
@send
external press: (page, string) => promise<unit> = "press"

/** Take a full-page screenshot. Returns raw PNG bytes. */
type screenshotOptions = {
  path?: string,
  fullPage?: bool,
  clip?: {x: float, y: float, width: float, height: float},
}

@send
external screenshot: (page, ~options: screenshotOptions=?) => promise<array<int>> = "screenshot"

/**
 * ─────────────────────────────────────────────────────────────────────────────
 * Locator queries on Page
 * ─────────────────────────────────────────────────────────────────────────────
 */
type getByRoleOptions = {
  name?: string,
  exact?: bool,
  hidden?: bool,
  checked?: bool,
  disabled?: bool,
  expanded?: bool,
  pressed?: bool,
  level?: int,
}

type getByTextOptions = {exact?: bool}
type getByLabelOptions = {exact?: bool}
type getByPlaceholderOptions = {exact?: bool}

/** Find elements by their ARIA role (e.g. `"heading"`, `"button"`, `"link"`). */
@send
external getByRole: (page, string, ~options: getByRoleOptions=?) => locator = "getByRole"

/** Find elements by visible text content. */
@send
external getByText: (page, string, ~options: getByTextOptions=?) => locator = "getByText"

/** Find form elements by their associated `<label>` text. */
@send
external getByLabel: (page, string, ~options: getByLabelOptions=?) => locator = "getByLabel"

/** Find elements by `data-testid` attribute. */
@send
external getByTestId: (page, string) => locator = "getByTestId"

/** Find input elements by their placeholder text. */
@send
external getByPlaceholder: (page, string, ~options: getByPlaceholderOptions=?) => locator =
  "getByPlaceholder"

/** Find elements by `alt` text (images, etc.). */
@send
external getByAltText: (page, string) => locator = "getByAltText"

/** Find elements by their `title` attribute. */
@send
external getByTitle: (page, string) => locator = "getByTitle"

/** Select elements using a CSS or XPath selector. */
@send
external locator: (page, string) => locator = "locator"

// ── Locator action types ──────────────────────────────────────────────────────
//
// Same plain / WithOptions split as assertions — `->click` works in pipes
// while `->clickWith(opts)` is available when you need extra options.

/**
 * ─────────────────────────────────────────────────────────────────────────────
 * Locator actions
 * ─────────────────────────────────────────────────────────────────────────────
 */
type clickOptions = {
  button?: string,
  clickCount?: int,
  delay?: int,
  force?: bool,
  timeout?: int,
}

type fillOptions = {force?: bool, timeout?: int}
type hoverOptions = {force?: bool, timeout?: int}
type selectOptionOptions = {force?: bool, timeout?: int}

@send
external click: locator => promise<unit> = "click"

@send
external clickWith: (locator, clickOptions) => promise<unit> = "click"

@send
external dblclick: locator => promise<unit> = "dblclick"

@send
external dblclickWith: (locator, clickOptions) => promise<unit> = "dblclick"

@send
external fill: (locator, string) => promise<unit> = "fill"

@send
external fillWith: (locator, string, fillOptions) => promise<unit> = "fill"

@send
external clear: locator => promise<unit> = "clear"

@send
external clearWith: (locator, fillOptions) => promise<unit> = "clear"

@send
external hover: locator => promise<unit> = "hover"

@send
external hoverWith: (locator, hoverOptions) => promise<unit> = "hover"

@send
external selectOption: (locator, string) => promise<unit> = "selectOption"

@send
external selectOptionWith: (locator, string, selectOptionOptions) => promise<unit> = "selectOption"

@send
external focus: locator => promise<unit> = "focus"

@send
external blur: locator => promise<unit> = "blur"

@send
external tap: locator => promise<unit> = "tap"

/** Read the element's text content. */
@send
external innerText: locator => promise<string> = "innerText"

/** Read an element attribute value. */
@send
external getAttribute: (locator, string) => promise<Nullable.t<string>> = "getAttribute"

/** Read the element's `textContent`. */
@send
external textContent: locator => promise<Nullable.t<string>> = "textContent"

/** Returns `true` when the element is visible right now (no auto-waiting). */
@send
external isVisible: locator => promise<bool> = "isVisible"

/** Returns `true` when the element is enabled right now. */
@send
external isEnabled: locator => promise<bool> = "isEnabled"

type waitForOptions = {state?: string, timeout?: int}

/** Wait for the element to reach a particular state (`"visible"`, `"hidden"`, `"attached"`, `"detached"`). */
@send
external waitFor: (locator, ~options: waitForOptions=?) => promise<unit> = "waitFor"

/** Narrow a locator set to a specific index (zero-based). */
@send
external nth: (locator, int) => locator = "nth"

/** Narrow to the first matching element. */
@send
external first: locator => locator = "first"

/** Narrow to the last matching element. */
@send
external last: locator => locator = "last"

/** Count how many elements the locator matches right now. */
@send
external count: locator => promise<int> = "count"

/** Return all matching elements as an array of locators. */
@send
external all: locator => promise<array<locator>> = "all"

/** Scope a child locator query inside this locator. */
@send
external locatorWithin: (locator, string) => locator = "locator"

/**
 * ─────────────────────────────────────────────────────────────────────────────
 * Locator queries on Locator
 * These mirror the Page-level query helpers so that queries can be scoped
 * within an already-found element.
 * ─────────────────────────────────────────────────────────────────────────────
 */
@send
external locatorGetByRole: (locator, string, ~options: getByRoleOptions=?) => locator = "getByRole"

@send
external locatorGetByText: (locator, string, ~options: getByTextOptions=?) => locator = "getByText"

@send
external locatorGetByLabel: (locator, string, ~options: getByLabelOptions=?) => locator =
  "getByLabel"

@send
external locatorGetByTestId: (locator, string) => locator = "getByTestId"

@send
external locatorGetByPlaceholder: (
  locator,
  string,
  ~options: getByPlaceholderOptions=?,
) => locator = "getByPlaceholder"

/**
 * ─────────────────────────────────────────────────────────────────────────────
 * @axe-core/playwright — accessibility scanning
 * ─────────────────────────────────────────────────────────────────────────────
 */
type axeBuilder

type axeViolation = {
  id: string,
  impact: Nullable.t<string>,
  description: string,
  help: string,
  helpUrl: string,
  tags: array<string>,
}

type axeResults = {
  violations: array<axeViolation>,
  passes: array<JSON.t>,
  incomplete: array<JSON.t>,
  inapplicable: array<JSON.t>,
}

type axeBuilderOptions = {page: page}

/**
 * Create an AxeBuilder instance bound to the given page.
 *
 * ```res
 * let results = await makeAxeBuilder({page})->analyze
 * expect(results.violations)->toHaveLength(0)
 * ```
 */
@module("@axe-core/playwright") @new
external makeAxeBuilder: axeBuilderOptions => axeBuilder = "AxeBuilder"

/** Restrict scanning to a list of WCAG / best-practice tag names, e.g. `["wcag2a", "wcag2aa"]`. */
@send
external withTags: (axeBuilder, array<string>) => axeBuilder = "withTags"

/** Exclude one or more CSS selectors from the scan. */
@send
external exclude: (axeBuilder, string) => axeBuilder = "exclude"

/** Include only the listed CSS selectors in the scan. */
@send
external include_: (axeBuilder, string) => axeBuilder = "include"

/** Disable a specific axe rule by id. */
@send
external disableRules: (axeBuilder, array<string>) => axeBuilder = "disableRules"

/** Run the accessibility scan and resolve with the full results object. */
@send
external analyze: axeBuilder => promise<axeResults> = "analyze"

/**
 * ─────────────────────────────────────────────────────────────────────────────
 * Helpers
 * ─────────────────────────────────────────────────────────────────────────────
 */
/**
 * Format axe violations into a readable multi-line string suitable for use in
 * assertion failure messages.
 */
let formatViolations = (violations: array<axeViolation>) =>
  violations
  ->Array.map(v => {
    let impact = v.impact->Nullable.toOption->Option.getOr("unknown")
    `[${v.id}] (${impact}) ${v.description}\n  ${v.helpUrl}`
  })
  ->Array.join("\n")

/**
 * Assert that a page has no axe violations and format a helpful failure message
 * when violations are found.
 *
 * ```res
 * test("has no a11y violations", async ({page}) => {
 *   let _ = await page->goto("/")
 *   await page->assertNoA11yViolations
 * })
 * ```
 *
 * Optionally restrict the scan to specific WCAG tags:
 *
 * ```res
 * await makeAxeBuilder({page})->withTags(["wcag2a", "wcag2aa"])->analyze->...
 * ```
 */
let assertNoA11yViolations = async (page: page) => {
  let results = await makeAxeBuilder({page: page})->analyze
  let violations = results.violations
  if Array.length(violations) > 0 {
    let msg = `\nAccessibility violations found:\n${formatViolations(violations)}`
    JsError.throwWithMessage(msg)
  }
}

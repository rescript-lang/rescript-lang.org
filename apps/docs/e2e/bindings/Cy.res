// -- Chainable type -----------------------------------------------------------

type t

// -- Cypress global commands --------------------------------------------------

@val @scope("cy")
external visit: string => unit = "visit"

@val @scope("cy")
external get: string => t = "get"

@val @scope("cy")
external contains: string => t = "contains"

@val @scope("cy")
external containsSelector: (string, string) => t = "contains"

@val @scope("cy")
external url: unit => t = "url"

@val @scope("cy")
external cyLocation: string => t = "location"

@val @scope("cy")
external wait: int => unit = "wait"

@val @scope("cy")
external viewport: (int, int) => unit = "viewport"

@val @scope("cy")
external cyScrollTo: string => unit = "scrollTo"

// -- Chainable commands -------------------------------------------------------

// Contains (chainable versions)
@send external containsChainable: (t, string) => t = "contains"
@send external containsSelectorChainable: (t, string, string) => t = "contains"

// Queries
@send external find: (t, string) => t = "find"
@send external first: t => t = "first"

// Actions
@send external click: t => t = "click"
@send external typeWithOptions: (t, string, {..}) => t = "type"
@send external select: (t, string) => t = "select"
@send external scrollIntoView: t => t = "scrollIntoView"

// Assertions
@send external should: (t, string) => t = "should"
@send external shouldWithValue: (t, string, string) => t = "should"
@send external shouldWithKeyValue: (t, string, string, string) => t = "should"

// Traversal
@send external its: (t, string) => t = "its"

// Attributes
@send external invokeWithArg: (t, string, string) => t = "invoke"

// Visibility & state

// Yielding

// -- Describe / It (Mocha globals) --------------------------------------------

@val external describe: (string, unit => unit) => unit = "describe"
@val external it: (string, unit => unit) => unit = "it"
@val external beforeEach: (unit => unit) => unit = "beforeEach"

// -- Window -------------------------------------------------------------------

@val @scope("cy")
external cyWindow: unit => t = "window"

// -- Convenience helpers ------------------------------------------------------

let getByTestId = testId => get(`[data-testid="${testId}"]`)

let shouldBeVisible = chain => chain->should("be.visible")

let shouldContainText = (chain, text) => chain->shouldWithValue("contain.text", text)

let shouldInclude = (chain, value) => chain->shouldWithValue("include", value)

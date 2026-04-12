// -- Chainable type -----------------------------------------------------------

type t

// -- Cypress global commands --------------------------------------------------

@val @scope("cy")
external visit: string => unit = "visit"

@val @scope("cy")
external visitWithOptions: (string, {..}) => unit = "visit"

@val @scope("cy")
external get: string => t = "get"

@val @scope("cy")
external contains: string => t = "contains"

@val @scope("cy")
external containsSelector: (string, string) => t = "contains"

@val @scope("cy")
external title: unit => t = "title"

@val @scope("cy")
external url: unit => t = "url"

@val @scope("cy")
external cyLocation: string => t = "location"

@val @scope("cy")
external wait: int => unit = "wait"

@val @scope("cy")
external reload: unit => unit = "reload"

@val @scope("cy")
external go: string => unit = "go"

@val @scope("cy")
external viewport: (int, int) => unit = "viewport"

@val @scope("cy")
external cyScrollTo: string => unit = "scrollTo"

@val @scope("cy")
external log: string => unit = "log"

// -- Chainable commands -------------------------------------------------------

// Contains (chainable versions)
@send external containsChainable: (t, string) => t = "contains"
@send external containsSelectorChainable: (t, string, string) => t = "contains"

// Queries
@send external find: (t, string) => t = "find"
@send external first: t => t = "first"
@send external last: t => t = "last"
@send external eq: (t, int) => t = "eq"
@send external children: t => t = "children"
@send external parent: t => t = "parent"
@send external parents: (t, string) => t = "parents"
@send external closest: (t, string) => t = "closest"
@send external next: t => t = "next"
@send external prev: t => t = "prev"
@send external siblings: t => t = "siblings"
@send external filter: (t, string) => t = "filter"
@send external not_: (t, string) => t = "not"

// Actions
@send external click: t => t = "click"
@send external clickWithOptions: (t, {..}) => t = "click"
@send external dblclick: t => t = "dblclick"
@send external type_: (t, string) => t = "type"
@send external typeWithOptions: (t, string, {..}) => t = "type"
@send external clear: t => t = "clear"
@send external check: t => t = "check"
@send external uncheck: t => t = "uncheck"
@send external select: (t, string) => t = "select"
@send external trigger: (t, string) => t = "trigger"
@send external scrollIntoView: t => t = "scrollIntoView"
@send external focus: t => t = "focus"
@send external blur: t => t = "blur"

// Assertions
@send external should: (t, string) => t = "should"
@send external shouldWithValue: (t, string, string) => t = "should"
@send external shouldWithKeyValue: (t, string, string, string) => t = "should"
@send external and_: (t, string) => t = "and"
@send external andWithValue: (t, string, string) => t = "and"

// Traversal
@send external each: (t, t => unit) => t = "each"
@send external then: (t, t => unit) => t = "then"
@send external its: (t, string) => t = "its"

// Attributes
@send external invoke: (t, string) => t = "invoke"
@send external invokeWithArg: (t, string, string) => t = "invoke"
@send external attr: (t, string) => t = "attr"

// Visibility & state
@send external asChainable: (t, string) => t = "as"

// Yielding
@send external within: (t, unit => unit) => t = "within"

// -- Describe / It (Mocha globals) --------------------------------------------

@val external describe: (string, unit => unit) => unit = "describe"
@val external it: (string, unit => unit) => unit = "it"
@val external before: (unit => unit) => unit = "before"
@val external beforeEach: (unit => unit) => unit = "beforeEach"
@val external after: (unit => unit) => unit = "after"
@val external afterEach: (unit => unit) => unit = "afterEach"
@val external context: (string, unit => unit) => unit = "context"

// -- Window -------------------------------------------------------------------

@val @scope("cy")
external cyWindow: unit => t = "window"

// -- Convenience helpers ------------------------------------------------------

let getByTestId = testId => get(`[data-testid="${testId}"]`)

let getByRole = role => get(`[role="${role}"]`)

let getByHref = href => get(`a[href="${href}"]`)

let shouldBeVisible = chain => chain->should("be.visible")

let shouldBeVisibleAndClick = chain => chain->should("be.visible")->click

let shouldExist = chain => chain->should("exist")

let shouldContainText = (chain, text) => chain->shouldWithValue("contain.text", text)

let shouldHaveAttr = (chain, attr, value) => chain->shouldWithKeyValue("have.attr", attr, value)

let shouldInclude = (chain, value) => chain->shouldWithValue("include", value)

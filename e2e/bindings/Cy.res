// -- Chainable type -----------------------------------------------------------

type chainable

// -- Cypress global commands --------------------------------------------------

@val @scope("cy")
external visit: string => unit = "visit"

@val @scope("cy")
external visitWithOptions: (string, {..}) => unit = "visit"

@val @scope("cy")
external get: string => chainable = "get"

@val @scope("cy")
external contains: string => chainable = "contains"

@val @scope("cy")
external containsSelector: (string, string) => chainable = "contains"

@val @scope("cy")
external title: unit => chainable = "title"

@val @scope("cy")
external url: unit => chainable = "url"

@val @scope("cy")
external cyLocation: string => chainable = "location"

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
@send external containsChainable: (chainable, string) => chainable = "contains"
@send external containsSelectorChainable: (chainable, string, string) => chainable = "contains"

// Queries
@send external find: (chainable, string) => chainable = "find"
@send external first: chainable => chainable = "first"
@send external last: chainable => chainable = "last"
@send external eq: (chainable, int) => chainable = "eq"
@send external children: chainable => chainable = "children"
@send external parent: chainable => chainable = "parent"
@send external parents: (chainable, string) => chainable = "parents"
@send external closest: (chainable, string) => chainable = "closest"
@send external next: chainable => chainable = "next"
@send external prev: chainable => chainable = "prev"
@send external siblings: chainable => chainable = "siblings"
@send external filter: (chainable, string) => chainable = "filter"
@send external not_: (chainable, string) => chainable = "not"

// Actions
@send external click: chainable => chainable = "click"
@send external clickWithOptions: (chainable, {..}) => chainable = "click"
@send external dblclick: chainable => chainable = "dblclick"
@send external type_: (chainable, string) => chainable = "type"
@send external clear: chainable => chainable = "clear"
@send external check: chainable => chainable = "check"
@send external uncheck: chainable => chainable = "uncheck"
@send external select: (chainable, string) => chainable = "select"
@send external trigger: (chainable, string) => chainable = "trigger"
@send external scrollIntoView: chainable => chainable = "scrollIntoView"
@send external focus: chainable => chainable = "focus"
@send external blur: chainable => chainable = "blur"

// Assertions
@send external should: (chainable, string) => chainable = "should"
@send external shouldWithValue: (chainable, string, string) => chainable = "should"
@send external shouldWithKeyValue: (chainable, string, string, string) => chainable = "should"
@send external and_: (chainable, string) => chainable = "and"
@send external andWithValue: (chainable, string, string) => chainable = "and"

// Traversal
@send external each: (chainable, chainable => unit) => chainable = "each"
@send external then: (chainable, chainable => unit) => chainable = "then"
@send external its: (chainable, string) => chainable = "its"

// Attributes
@send external invoke: (chainable, string) => chainable = "invoke"
@send external invokeWithArg: (chainable, string, string) => chainable = "invoke"
@send external attr: (chainable, string) => chainable = "attr"

// Visibility & state
@send external asChainable: (chainable, string) => chainable = "as"

// Yielding
@send external within: (chainable, unit => unit) => chainable = "within"

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
external cyWindow: unit => chainable = "window"

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

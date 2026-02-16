type page
type expect
type element
type mock

/**
 * Vitest
 */
@module("vitest")
external test: (string, unit => promise<unit>) => unit = "test"

@module("vitest") @scope("vi")
external fn: unit => 'a => 'b = "fn"

@module("vitest")
external expect: 'a => expect = "expect"

/**
 * Vitest browser
 */
@module("vitest/browser") @scope("page")
external viewport: (int, int) => promise<unit> = "viewport"

/**
 * vitest-browser-react
 */
@module("vitest-browser-react")
external render: Jsx.element => promise<element> = "render"

@module("vitest") @scope("expect")
external element: 'a => element = "element"

/*
 * Locators
 */
@send
external getByTestId: (element, string) => promise<element> = "getByTestId"

@send
external getByText: (element, string) => promise<element> = "getByText"

@send
external getByLabelText: (element, string) => promise<element> = "getByLabelText"

@send
external getAllByLabelText: (element, string) => promise<array<element>> = "getAllByLabelText"

@send
external getByRole: (element, [#button]) => promise<element> = "getByRole"

/**
 * Actions
 */
@send
external click: element => promise<unit> = "click"

/**
 * Vitest assertions
 */
@send
external toBe: (expect, 'a) => unit = "toBe"

@send
external toHaveBeenCalled: expect => unit = "toHaveBeenCalled"

/**
 * Browser assertions
 */
@send
external toBeVisible: element => promise<unit> = "toBeVisible"

@send @scope("not")
external notToBeVisible: element => promise<unit> = "toBeVisible"

@send
external toMatchScreenshot: (element, string) => promise<unit> = "toMatchScreenshot"

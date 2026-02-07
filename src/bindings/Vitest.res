type page
type expect
type screen
type assertion

@module("vitest")
external test: (string, unit => promise<unit>) => unit = "test"

@module("vitest")
external expect: 'a => expect = "expect"

@send
external toBe: (expect, 'a) => unit = "toBe"

@send
external toBeVisible: expect => promise<unit> = "toBeVisible"

@module("vitest-browser-react")
external render: Jsx.element => promise<screen> = "render"

@send
external getByText: (screen, string) => expect = "getByText"

@module("vitest") @scope("expect")
external element: 'a => expect = "element"

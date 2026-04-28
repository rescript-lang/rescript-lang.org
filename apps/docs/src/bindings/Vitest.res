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

@send
external unmount: element => promise<unit> = "unmount"

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
external getByTextWithOptions: (element, string, {"exact": bool}) => promise<element> = "getByText"

let getByTextExact = (element, text) => getByTextWithOptions(element, text, {"exact": true})

@send
external getByLabelText: (element, string) => promise<element> = "getByLabelText"

@send
external getAllByLabelText: (element, string) => promise<array<element>> = "getAllByLabelText"

@send
external getByRole: (element, [#button]) => promise<element> = "getByRole"

external imageFromNode: WebAPI.DOMAPI.node => WebAPI.DOMAPI.htmlImageElement = "%identity"

let waitForImages = async (selector: string) => {
  let root = switch document->WebAPI.Document.querySelector(selector) {
  | Value(root) => root
  | Null => failwith(`expected to find screenshot target ${selector}`)
  }

  let images = root->WebAPI.Element.querySelectorAll("img")

  if images.length > 0 {
    for i in 0 to images.length - 1 {
      let image = images->WebAPI.NodeList.item(i)->imageFromNode
      await image->WebAPI.HTMLImageElement.decode
    }
  }
}

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

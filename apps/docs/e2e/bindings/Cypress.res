type chain<'a>
type elements
type assertion
type spy
type console
type rec window = {document: Dom.document, console: console, navigator: {clipboard: clipboard}}
and clipboard
type response = {status: int, body: string}
type automation = {command: string, params?: {permissions: array<string>, origin: string}}
type clickOptions = {scrollBehavior: string}

@val external it: (string, unit => unit) => unit = "it"
@val external beforeEach: (unit => unit) => unit = "beforeEach"
@val external afterEach: (unit => unit) => unit = "afterEach"
@val @scope("cy") external visit: string => unit = "visit"
@val @scope("cy") external viewport: (int, int) => unit = "viewport"
@val @scope("cy") external get: string => chain<elements> = "get"
@val @scope("cy") external alias: string => chain<'a> = "get"
@val @scope("cy") external contains: string => chain<elements> = "contains"
@val @scope("cy") external containsIn: (string, string) => chain<elements> = "contains"
@val @scope("cy") external cyLocation: string => chain<string> = "location"
@val @scope("cy") external cyWindow: unit => chain<window> = "window"
@val @scope("cy") external request: string => chain<response> = "request"
@val @scope("cy") external wrap: 'a => chain<'a> = "wrap"
@val @scope("cy") external run: (unit => promise<unit>) => chain<unit> = "then"
@val @scope("cy")
external onBeforeLoad: (@as("window:before:load") _, window => unit) => unit = "on"
@val @scope("cy") external spy: (console, @as("error") _) => spy = "spy"
@get external callCount: spy => int = "callCount"
@val @scope("Cypress")
external automate: (@as("remote:debugger:protocol") _, automation) => promise<unit> = "automation"
@val @scope("Cypress") external baseUrl: @as("baseUrl") _ => string = "config"
@val @scope("Cypress") external isInteractive: @as("isInteractive") _ => bool = "config"
@val @scope("mocha") external forbidOnly: bool => unit = "forbidOnly"
@module("cypress-real-events/support.js") external realEvents: unit = "default"

@send external then: (chain<'a>, 'a => unit) => chain<unit> = "then"
@send external thenPromise: (chain<'a>, 'a => promise<'b>) => chain<'b> = "then"
@send external should: (chain<'a>, string) => chain<'a> = "should"
@send external shouldEqual: (chain<'a>, @as("equal") _, 'a) => chain<'a> = "should"
@send external shouldMatch: (chain<'a>, @as("match") _, RegExp.t) => chain<'a> = "should"
@send
external shouldAttribute: (chain<elements>, @as("have.attr") _, string, string) => chain<elements> =
  "should"
@send external attribute: (chain<elements>, @as("attr") _, string) => chain<string> = "invoke"
@send external shouldSatisfy: (chain<'a>, 'a => unit) => chain<'a> = "should"
@send external click: chain<elements> => chain<elements> = "click"
@send
external realClick: (chain<elements>, clickOptions) => chain<elements> = "realClick"
@send external scrollIntoView: chain<elements> => chain<elements> = "scrollIntoView"
@send external each: (chain<elements>, elements => unit) => chain<elements> = "each"
@send external as_: (chain<'a>, string) => chain<'a> = "as"
@send external item: (elements, int) => option<Dom.element> = "get"
@get external complete: Dom.element => bool = "complete"
@get external naturalWidth: Dom.element => int = "naturalWidth"
@send external readText: clipboard => promise<string> = "readText"

@val external expect: ('a, ~message: string=?) => assertion = "expect"
@send @scope("to") external equal: (assertion, 'a) => unit = "equal"
@send @scope("to") external include_: (assertion, string) => unit = "include"
@send @scope(("to", "be")) external greaterThan: (assertion, int) => unit = "greaterThan"
@send @scope("to") external match_: (assertion, RegExp.t) => unit = "match"

type parser
@new external parser: unit => parser = "DOMParser"
@send external parseHtml: (parser, string, @as("text/html") _) => Dom.document = "parseFromString"
@send external querySelector: (Dom.document, string) => Null.t<Dom.element> = "querySelector"
@get external body: Dom.document => Dom.element = "body"
@get external currentScript: Dom.document => Null.t<Dom.element> = "currentScript"
@get external textContent: Dom.element => Null.t<string> = "textContent"
@send external getAttribute: (Dom.element, string) => Null.t<string> = "getAttribute"

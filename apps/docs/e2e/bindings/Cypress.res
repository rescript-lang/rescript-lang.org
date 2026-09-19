type chain<'a>
type elements
type assertion
type spy
type consoleArgument
type consoleCall = {args: array<consoleArgument>}
@send external getCalls: spy => array<consoleCall> = "getCalls"
@val external consoleArgumentString: option<consoleArgument> => string = "String"
type console
type rec window = {document: Dom.document, console: console, navigator: {clipboard: clipboard}}
and clipboard
type response = {status: int, body: string}
type automation = {command: string, params?: {permissions: array<string>, origin: string}}
type request = {url: string, resourceType: string}
type routeMatcher = {resourceType?: string, pathname?: string}
type searchRouteMatcher = {hostname: RegExp.t, pathname: RegExp.t}
type staticResponse = {statusCode: int, body: JSON.t}
type wrapOptions = {log: bool}
type url
type elementList
type fontFaceSet
type fontFace
type styleSheetList
type styleSheet
type cssRuleList
type cssRule
type cssStyle

@val external it: (string, unit => unit) => unit = "it"
@val external beforeEach: (unit => unit) => unit = "beforeEach"
@val external afterEach: (unit => unit) => unit = "afterEach"
@val @scope("cy") external visit: string => unit = "visit"
@val @scope("cy") external viewport: (int, int) => unit = "viewport"
@val @scope("cy") external get: string => chain<elements> = "get"
@val @scope("cy") external alias: string => chain<'a> = "get"
@val @scope("cy") external contains: string => chain<elements> = "contains"
@val @scope("cy") external containsIn: (string, string) => chain<elements> = "contains"
@val @scope("cy") external containsInRegex: (string, RegExp.t) => chain<elements> = "contains"
@val @scope("cy") external cyLocation: string => chain<string> = "location"
@val @scope("cy") external cyWindow: unit => chain<window> = "window"
@val @scope("cy") external cyDocument: unit => chain<Dom.document> = "document"
@val @scope("cy") external request: string => chain<response> = "request"
@val @scope("cy") external intercept: (routeMatcher, request => unit) => chain<unit> = "intercept"
@val @scope("cy") external interceptAll: (string, request => unit) => chain<unit> = "intercept"
@val @scope("cy") external interceptRoute: routeMatcher => chain<unit> = "intercept"
@val @scope("cy")
external interceptStatic: (searchRouteMatcher, staticResponse) => chain<unit> = "intercept"
@val @scope("cy")
external interceptPattern: (RegExp.t, request => unit) => chain<unit> = "intercept"
@val @scope("cy")
external interceptDeferred: (RegExp.t, unit => promise<unit>) => chain<unit> = "intercept"
@val @scope("cy") external wait: string => chain<response> = "wait"
@val @scope("cy") external wrap: 'a => chain<'a> = "wrap"
@val @scope("cy") external wrapWithOptions: ('a, wrapOptions) => chain<'a> = "wrap"
@val @scope("cy") external run: (unit => promise<unit>) => chain<unit> = "then"
@val @scope("cy") external do_: (unit => unit) => chain<unit> = "then"
@val @scope("cy") external realPressKey: string => chain<unit> = "realPress"
@val @scope("cy") external realPressKeys: array<string> => chain<unit> = "realPress"
@val @scope("cy") external reload: unit => unit = "reload"
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
@send external thenMap: (chain<'a>, 'a => 'b) => chain<'b> = "then"
@send external thenPromise: (chain<'a>, 'a => promise<'b>) => chain<'b> = "then"
@send external should: (chain<'a>, string) => chain<'a> = "should"
@send
external shouldCss: (chain<elements>, @as("have.css") _, string, string) => chain<elements> =
  "should"
@send
external shouldCssProperty: (chain<elements>, @as("have.css") _, string) => chain<string> = "should"
@send external shouldInt: (chain<'a>, string, int) => chain<'a> = "should"
@send
external shouldValue: (chain<elements>, @as("have.value") _, string) => chain<elements> = "should"
@send
external shouldText: (chain<elements>, @as("have.text") _, string) => chain<elements> = "should"
@send external shouldEqual: (chain<'a>, @as("equal") _, 'a) => chain<'a> = "should"
@send external shouldDeepEqual: (chain<'a>, @as("deep.equal") _, 'a) => chain<'a> = "should"
@send external shouldMatch: (chain<'a>, @as("match") _, RegExp.t) => chain<'a> = "should"
@send external andMatch: (chain<string>, @as("match") _, RegExp.t) => chain<string> = "and"
@send external shouldWithin: (chain<int>, @as("be.within") _, int, int) => chain<int> = "should"
@send
external shouldAttribute: (chain<elements>, @as("have.attr") _, string, string) => chain<elements> =
  "should"
@send
external shouldProperty: (chain<elements>, @as("have.prop") _, string, string) => chain<elements> =
  "should"
@send external attribute: (chain<elements>, @as("attr") _, string) => chain<string> = "invoke"
@send external propertyInt: (chain<'a>, string) => chain<int> = "its"
@send external shouldSatisfy: (chain<'a>, 'a => unit) => chain<'a> = "should"
@send external click: chain<elements> => chain<elements> = "click"
@send external first: chain<elements> => chain<elements> = "first"
@send external typeText: (chain<elements>, string) => chain<elements> = "type"
@send
external containsChildRegex: (chain<elements>, string, RegExp.t) => chain<elements> = "contains"
@send external focusElement: chain<elements> => chain<elements> = "focus"
@send external realClick: chain<elements> => chain<elements> = "realClick"
@send external realPress: (chain<elements>, string) => chain<elements> = "realPress"
@send external scrollIntoView: chain<elements> => chain<elements> = "scrollIntoView"
@send external each: (chain<elements>, elements => unit) => chain<elements> = "each"
@send external as_: (chain<'a>, string) => chain<'a> = "as"
@send external item: (elements, int) => option<Dom.element> = "get"
@get external complete: Dom.element => bool = "complete"
@get external naturalWidth: Dom.element => int = "naturalWidth"
@send external readText: clipboard => promise<string> = "readText"
@send external destroy: request => unit = "destroy"

@val external expect: ('a, ~message: string=?) => assertion = "expect"
@send @scope("to") external equal: (assertion, 'a) => unit = "equal"
@send @scope("to") external include_: (assertion, string) => unit = "include"
@send @scope(("to", "not")) external notInclude: (assertion, string) => unit = "include"
@send @scope(("to", "deep")) external deepEqual: (assertion, 'a) => unit = "equal"
@send @scope(("to", "include")) external includeMembers: (assertion, array<'a>) => unit = "members"
@send @scope(("to", "be")) external greaterThan: (assertion, int) => unit = "greaterThan"
@send @scope("to") external match_: (assertion, RegExp.t) => unit = "match"

type parser
@new external parser: unit => parser = "DOMParser"
@send external parseHtml: (parser, string, @as("text/html") _) => Dom.document = "parseFromString"
@send external querySelector: (Dom.document, string) => Null.t<Dom.element> = "querySelector"
@send external querySelectorAll: (Dom.document, string) => elementList = "querySelectorAll"
@get external body: Dom.document => Dom.element = "body"
@get external documentElement: Dom.document => Dom.element = "documentElement"
@get external currentScript: Dom.document => Null.t<Dom.element> = "currentScript"
@get external textContent: Dom.element => Null.t<string> = "textContent"
@get external innerHTML: Dom.element => string = "innerHTML"
@get external outerHTML: Dom.element => string = "outerHTML"
@send external getAttribute: (Dom.element, string) => Null.t<string> = "getAttribute"

@val @scope("Array") external elementsFrom: elementList => array<Dom.element> = "from"
@new external url: string => url = "URL"
@get external pathname: url => string = "pathname"
@get external hostname: url => string = "hostname"
@get external urlOrigin: url => string = "origin"

@get external fonts: Dom.document => fontFaceSet = "fonts"
@get external fontsReady: fontFaceSet => promise<fontFaceSet> = "ready"
@send external loadFont: (fontFaceSet, string) => promise<array<fontFace>> = "load"
@send external checkFont: (fontFaceSet, string) => bool = "check"

@get external styleSheets: Dom.document => styleSheetList = "styleSheets"
@val @scope("Array") external styleSheetsFrom: styleSheetList => array<styleSheet> = "from"
@get external sheetRules: styleSheet => cssRuleList = "cssRules"
@val @scope("Array") external rulesFrom: cssRuleList => array<cssRule> = "from"
@get external ruleType: cssRule => int = "type"
@get external nestedRules: cssRule => Nullable.t<cssRuleList> = "cssRules"
@get external ruleStyle: cssRule => cssStyle = "style"
@get external fontFamily: cssStyle => string = "fontFamily"
@get external fontWeight: cssStyle => string = "fontWeight"
@get external fontStyle: cssStyle => string = "fontStyle"
@send external propertyValue: (cssStyle, string) => string = "getPropertyValue"

module Document = {
  @val external document: Dom.element = "document"
  @scope("document") @val external createElement: string => Dom.element = "createElement"
  @scope("document") @val external createTextNode: string => Dom.element = "createTextNode"
}

module ClassList = {
  type t
  @send external toggle: (t, string) => unit = "toggle"
  @send external remove: (t, string) => unit = "remove"
}

module Element = {
  @send external appendChild: (Dom.element, Dom.element) => unit = "appendChild"
  @send external removeChild: (Dom.element, Dom.element) => unit = "removeChild"
  @set external setClassName: (Dom.element, string) => unit = "className"
  @get external classList: Dom.element => ClassList.t = "classList"
  @send external getBoundingClientRect: Dom.element => {..} = "getBoundingClientRect"
  @send external addEventListener: (Dom.element, string, unit => unit) => unit = "addEventListener"

  @send
  external getElementById: (Dom.element, string) => Nullable.t<Dom.element> = "getElementById"

  type contentWindow
  @get external contentWindow: Dom.element => option<contentWindow> = "contentWindow"

  @send
  external postMessage: (contentWindow, string, ~targetOrigin: string=?) => unit = "postMessage"

  @send
  external postMessageAny: (contentWindow, 'a, ~targetOrigin: string=?) => unit = "postMessage"

  module Style = {
    @scope("style") @set external width: (Dom.element, string) => unit = "width"
    @scope("style") @set external height: (Dom.element, string) => unit = "height"
  }
}

type animationFrameId

@scope("window") @val
external requestAnimationFrame: (unit => unit) => animationFrameId = "requestAnimationFrame"

@scope("window") @val
external cancelAnimationFrame: animationFrameId => unit = "cancelAnimationFrame"

module Window = {
  @scope("window") @val external addEventListener: (string, 'a => unit) => unit = "addEventListener"
  @scope("window") @val
  external removeEventListener: (string, 'a => unit) => unit = "removeEventListener"
  @scope("window") @val external innerWidth: int = "innerWidth"
  @scope("window") @val external innerHeight: int = "innerHeight"
  @scope("window") @val external scrollY: int = "scrollY"

  module History = {
    @scope(("window", "history")) @val
    external pushState: (nullable<'a>, @as(json`""`) _, ~url: string=?) => unit = "pushState"
    @scope(("window", "history")) @val
    external replaceState: (nullable<'a>, @as(json`""`) _, ~url: string=?) => unit = "replaceState"
  }

  module Location = {
    @scope(("window", "location")) @val external href: string = "href"
  }

  module Navigator = {
    @scope(("window", "navigator")) @val external userAgent: string = "userAgent"
  }
}

module Fetch = {
  module Response = {
    type t
    @send external text: t => promise<string> = "text"
    @send external json: t => promise<JSON.t> = "json"
  }

  @val external fetch: string => promise<Response.t> = "fetch"
}

module URL = {
  type t = {
    hash: string,
    host: string,
    hostname: string,
    href: string,
    pathname: string,
  }
  @new external make: string => t = "URL"
}

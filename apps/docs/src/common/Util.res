module String = {
  let camelCase = str =>
    str->String.replaceRegExpBy1Unsafe(/-([a-z])/g, (
      ~match as _,
      ~group1,
      ~offset as _,
      ~input as _,
    ) => group1->String.toUpperCase)

  let capitalize = str =>
    str->String.slice(~start=0, ~end=1)->String.toUpperCase ++ str->String.slice(~start=1)

  let capitalizeSentence = str =>
    str
    ->String.split(" ")
    ->Array.map(str => str->String.length > 2 ? str->String.capitalize : str)
    ->Array.join(" ")
}

module Url = {
  let isAbsolute = (str: string): bool => {
    let regex = /^(?:[a-z]+:)?\/\//i
    regex->RegExp.test(str)
  }

  let baseUrl = () => {
    Env.root_url->Stdlib.String.endsWith("/") ? Env.root_url : Env.root_url ++ "/"
  }

  let makeAbsoluteUrl = pathOrUrl => {
    if isAbsolute(pathOrUrl) {
      pathOrUrl
    } else {
      let path =
        pathOrUrl->Stdlib.String.startsWith("/")
          ? pathOrUrl->Stdlib.String.slice(~start=1)
          : pathOrUrl

      baseUrl() ++ path
    }
  }

  let makeOpenGraphImageUrl = url => {
    `${baseUrl()}ogimage/index.png?url=${encodeURIComponent(url)}`
  }
}

module Date = {
  type intl

  @new @scope("Intl")
  external dateTimeFormat: (string, {"month": string, "day": string, "year": string}) => intl =
    "DateTimeFormat"

  @send external format: (intl, Date.t) => string = "format"

  let toDayMonthYear = (date: Date.t) => {
    dateTimeFormat("en-US", {"month": "short", "day": "numeric", "year": "numeric"})->format(date)
  }
}

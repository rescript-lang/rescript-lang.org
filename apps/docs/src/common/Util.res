module Unsafe = {
  external elementAsString: React.element => string = "%identity"
}

module String = {
  let camelCase: string => string = %raw("str => {
     return str.replace(/-([a-z])/g, function (g) { return g[1].toUpperCase(); });
    }")

  let capitalize: string => string = %raw("str => {
      return str && str.charAt(0).toUpperCase() + str.substring(1);
    }")

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

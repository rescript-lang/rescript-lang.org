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

  let leadingSlash = str => str->String.startsWith("/") ? str : "/" ++ str
}

module Url = {
  let isAbsolute = (str: string): bool => {
    let regex = /^(?:[a-z]+:)?\/\//i
    regex->RegExp.test(str)
  }

  let getRootPath = path => {
    if path->Stdlib.String.includes("docs/manual") {
      "/docs/manual"
    } else if path->Stdlib.String.includes("docs/react") {
      "/docs/react"
    } else {
      ""
    }
  }

  let createRelativePath = (currentPath, href) => {
    if (
      href->Stdlib.String.includes("docs/manual") ||
      href->Stdlib.String.includes("docs/react") ||
      href->Stdlib.String.includes("community") ||
      href->Stdlib.String.includes("blog") ||
      href->Stdlib.String.includes("try")
    ) {
      href
    } else {
      let rootPath = getRootPath(currentPath)
      let href = href->Stdlib.String.replace("docs/manual", "")
      (rootPath ++ href->String.leadingSlash)->Stdlib.String.replaceAll("//", "/")
    }
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

/**
 * 防抖
 * @param fn the func to debounce
 * @param delay milliseconds
 * @returns new debounced function
 */
let debounce = (fn: unit => unit, delay: int) => {
  let timer = ref(None)
  () => {
    timer.contents->Option.forEach(clearTimeout)
    timer := Some(setTimeout(~handler=fn, ~timeout=delay))
  }
}

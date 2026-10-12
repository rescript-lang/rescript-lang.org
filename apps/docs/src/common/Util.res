module String = {
  let camelCase = str =>
    str->String.replaceRegExpBy1Unsafe(/-([a-z])/g, (
      ~match as _,
      ~group1,
      ~offset as _,
      ~input as _,
    ) => group1->String.toUpperCase)

  let kebabCase = string =>
    string
    ->String.replaceAllRegExp(/([a-z])([A-Z])/g, "$1-$2")
    ->String.toLowerCase
    ->String.replaceAll(" ", "-")

  let capitalize = str =>
    str->String.slice(~start=0, ~end=1)->String.toUpperCase ++ str->String.slice(~start=1)

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
      href->Stdlib.String.includes("try") ||
      href->Stdlib.String.includes("/llms/") ||
      href->Stdlib.String.startsWith("#")
    ) {
      href
    } else {
      let rootPath = getRootPath(currentPath)
      let href = href->Stdlib.String.replace("docs/manual", "")
      (rootPath ++ href->String.leadingSlash)->Stdlib.String.replaceAll("//", "/")
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

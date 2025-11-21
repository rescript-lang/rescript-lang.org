module Url: {
  let isAbsolute: string => bool
  let getRootPath: string => string
  let createRelativePath: (string, string) => string
}

module Unsafe: {
  let elementAsString: React.element => string
}

module String: {
  let camelCase: string => string
  let kebabCase: string => string
  let capitalize: string => string
  let capitalizeSentence: string => string
  let leadingSlash: string => string
}

module Date: {
  let toDayMonthYear: Date.t => string
}

let debounce: (unit => unit, int) => unit => unit

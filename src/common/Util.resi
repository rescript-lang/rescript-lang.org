module Url: {
  let isAbsolute: string => bool
}

module Unsafe: {
  let elementAsString: React.element => string
}

module String: {
  let camelCase: string => string
  let capitalize: string => string
  let capitalizeSentence: string => string
}

module Date: {
  let toDayMonthYear: Date.t => string
}

let debounce: (unit => unit, int) => unit => unit

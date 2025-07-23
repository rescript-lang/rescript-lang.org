module Url: {
  let isAbsolute: string => bool
}

module Unsafe: {
  let elementAsString: React.element => string
}

module String: {
  let camelCase: string => string
  let capitalize: string => string
}

module Date: {
  let toDayMonthYear: Date.t => string
}

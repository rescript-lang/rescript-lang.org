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
  // TODO: convert to ReScript
  let isAbsolute: string => bool = %raw(`
    function(str) {
      var r = new RegExp('^(?:[a-z]+:)?//', 'i');
      if (r.test(str))
      {
        return true
      }
      return false;
    }
  `)
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

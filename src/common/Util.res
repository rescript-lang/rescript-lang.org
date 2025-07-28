/**
module Debounce = {
  // See: https://davidwalsh.name/javascript-debounce-function
  let debounce = (~wait, fn) => {
    let timeout = ref(None)

    () => {
      let unset = () => timeout := None

      switch timeout.contents {
      | Some(id) => Js.Global.clearTimeout(id)
      | None => fn()
      }
      timeout := Some(Js.Global.setTimeout(unset, wait))
    }
  }

  let debounce3 = (~wait, ~immediate=false, fn) => {
    let timeout = ref(None)

    (a1, a2, a3) => {
      let unset = () => {
        timeout := None
        immediate ? fn(a1, a2, a3) : ()
      }

      switch timeout.contents {
      | Some(id) => Js.Global.clearTimeout(id)
      | None => fn(a1, a2, a3)
      }
      timeout := Some(Js.Global.setTimeout(unset, wait))

      if immediate && timeout.contents === None {
        fn(a1, a2, a3)
      } else {
        ()
      }
    }
  }
}
**/
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
}

module Url = {
  let isAbsolute: string => bool = %raw(`
    function(str) {
      var r = new RegExp('^(?:[a-z]+:)?//', 'i');
      if (r.test(str))
      {
        return true
      }
      return false;
    }
  `) //', 'i');
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

let removeVersionFromPathname = (pathname: string) =>
  pathname
  ->Stdlib.String.split("/")
  ->Array.filter(s => {
    let isVersion = s->Stdlib.String.includes("v") && s->Stdlib.String.includes(".")
    !isVersion
  })
  ->Array.join("/")

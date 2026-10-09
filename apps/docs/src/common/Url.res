type breadcrumb = {
  name: string,
  href: string,
}

/* Beautifies url based string to somewhat acceptable representation */
let prettyString = (str: string) => {
  open Util.String
  str->camelCase->capitalize
}

let normalizePath = string => {
  string->String.replaceRegExp(/\/$/, "")->String.toLocaleLowerCase
}

let normalizeAnchor = string => {
  string
  ->String.replaceRegExp(/<[^>]+>/g, "")
  ->String.replaceRegExp(/([\r\n]+ +)+/g, "")
  ->String.replaceAll(" ", "-")
  ->String.replaceAll("_", "-")
  ->String.replaceAll("&", "")
  ->String.replaceAllRegExp(/[^a-zA-Z0-9-]/g, "")
  ->String.toLocaleLowerCase
}

type anchorIdState = Dict.t<int>

let makeAnchorIdState = () => Dict.make()

let makeUniqueAnchorId = (~state, ~title) => {
  let baseId = title->normalizeAnchor
  let count = state->Dict.get(baseId)->Option.getOr(0)
  state->Dict.set(baseId, count + 1)

  count === 0 ? baseId : `${baseId}-${count->Int.toString}`
}

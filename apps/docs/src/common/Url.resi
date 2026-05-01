type t = {
  fullpath: array<string>,
  base: array<string>,
  pagepath: array<string>,
}

// Moved here from the original sidebar URL helper.
type breadcrumb = {
  name: string,
  href: string,
}

let parse: string => t

let prettyString: string => string

@unboxed
type storageKey =
  | @as("manual_version") Manual
  | @as("react_version") React
  | @as("playground_version") Playground

let getVersionFromStorage: storageKey => option<string>

let normalizePath: string => string

let normalizeAnchor: string => string

type anchorIdState

let makeAnchorIdState: unit => anchorIdState

let makeUniqueAnchorId: (~state: anchorIdState, ~title: string) => string

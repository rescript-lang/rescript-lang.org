type breadcrumb = {
  name: string,
  href: string,
}

let prettyString: string => string

let normalizePath: string => string

let normalizeAnchor: string => string

type anchorIdState

let makeAnchorIdState: unit => anchorIdState

let makeUniqueAnchorId: (~state: anchorIdState, ~title: string) => string

type version =
  | Latest
  | Next
  | NoVersion
  | Version(string)

type t = {
  fullpath: array<string>,
  base: array<string>,
  version: version,
  pagepath: array<string>,
}

// Moved here from original SidebarLayout.UrlPath
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

let getVersionString: t => string

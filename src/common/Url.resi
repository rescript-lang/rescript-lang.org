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

let getVersionString: t => string

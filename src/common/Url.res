type version =
  | Latest
  | Next
  | NoVersion
  | Version(string)

/*
  Example 1:
  Url: "/docs/manual/latest/advanced/introduction"

  Results in:
  fullpath: ["docs", "manual", "latest", "advanced", "introduction"]
  base: ["docs", "manual"]
  version: Latest
  pagepath: ["advanced", "introduction"]
 */

/*
  Example 2:
  Url: "/apis/"

  Results in:
  fullpath: ["apis"]
  base: ["apis"]
  version: NoVersion
  pagepath: []
 */

/*
  Example 3:
  Url: "/apis/javascript/v7.1.1/node"

  Results in:
  fullpath: ["apis", "javascript", "v7.1.1", "node"]
  base: ["apis", "javascript"]
  version: Version("v7.1.1"),
  pagepath: ["node"]
 */

type t = {
  fullpath: array<string>,
  base: array<string>,
  version: version,
  pagepath: array<string>,
}

type breadcrumb = {
  name: string,
  href: string,
}

/* Beautifies url based string to somewhat acceptable representation */
let prettyString = (str: string) => {
  open Util.String
  str->camelCase->capitalize
}

let parse = (route: string): t => {
  let fullpath = route->String.split("/")->Array.filter(s => s !== "")
  let foundVersionIndex = Array.findIndex(fullpath, chunk => {
    Re.test(%re(`/latest|next|v\d+(\.\d+)?(\.\d+)?/`), chunk)
  })

  let (version, base, pagepath) = if foundVersionIndex == -1 {
    (NoVersion, fullpath, [])
  } else {
    let version = switch fullpath[foundVersionIndex] {
    | Some(version) if version === Constants.versions.next => Next
    | Some(version) if version === Constants.versions.latest => Latest
    | Some("latest") => Latest // still used for React docs
    | Some(v) => Version(v)
    | None => NoVersion
    }
    (
      version,
      fullpath->Array.slice(~start=0, ~end=foundVersionIndex),
      fullpath->Array.slice(~start=foundVersionIndex + 1, ~end=Array.length(fullpath)),
    )
  }

  {fullpath, base, version, pagepath}
}

let getVersionString = url =>
  switch url.version {
  | Next => Constants.versions.next
  | Latest | NoVersion => Constants.versions.latest
  | Version(version) => version
  }

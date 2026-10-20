type t = string

// Used to prevent issues with webkit based date representations
let parse = (dateStr: string): Date.t => dateStr->String.replaceRegExp(/-/g, "/")->Date.fromString

let toDate = dateStr => parse(dateStr)

// ISO date-only strings represent midnight UTC, independent of the build timezone.
let toUTCDate = dateStr => Date.fromString(dateStr)

external fromString: string => t = "%identity"

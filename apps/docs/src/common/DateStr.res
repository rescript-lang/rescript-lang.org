type t = string

// Used to prevent issues with webkit based date representations
let parse = (dateStr: string): Date.t => dateStr->String.replaceRegExp(/-/g, "/")->Date.fromString

let fromDate = date => Date.toString(date)
let toDate = dateStr => parse(dateStr)

external fromString: string => t = "%identity"

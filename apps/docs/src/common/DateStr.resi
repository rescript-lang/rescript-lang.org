/* JSON doesn't support a native date type, so we need to codify dates as strings */
type t

external fromString: string => t = "%identity"

let fromDate: Date.t => t
let toDate: t => Date.t

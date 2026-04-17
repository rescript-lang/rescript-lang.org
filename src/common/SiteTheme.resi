let storageKey: string

type t = Light | Dark

let toString: t => string
let fromString: string => t
let toggle: t => t
let getInitial: unit => t
let applyToDom: t => unit
let persist: t => unit
let set: t => unit

type highlighter
type definition
type registeredLanguage
type highlightOptions = {language: string}
type highlightResult = {value: string}

let defaultInstance: highlighter

/** Preserve an existing language or alias when route modules initialize more than once. */
let ensureRegistered: (highlighter, string, definition) => unit

let make: highlighter => highlighter
let registerLanguage: (highlighter, string, definition) => unit
let highlight: (highlighter, string, highlightOptions) => highlightResult

let getLanguage: (highlighter, string) => option<registeredLanguage>

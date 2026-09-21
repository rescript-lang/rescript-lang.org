type highlighter
type definition

let defaultInstance: highlighter

/** Preserve an existing language or alias when route modules initialize more than once. */
let ensureRegistered: (highlighter, string, definition) => unit

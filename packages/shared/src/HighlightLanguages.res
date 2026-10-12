type highlighter
type definition
type registeredLanguage

@module("highlight.js/lib/core")
external defaultInstance: highlighter = "default"

@send
external getLanguage: (highlighter, string) => option<registeredLanguage> = "getLanguage"

@send
external registerLanguage: (highlighter, string, definition) => unit = "registerLanguage"

let ensureRegistered = (highlighter, name, definition) =>
  switch highlighter->getLanguage(name) {
  | Some(_) => ()
  | None => highlighter->registerLanguage(name, definition)
  }

@module("highlight.js/lib/languages/javascript")
external javascript: HighlightLanguages.definition = "default"

let register = highlighter =>
  highlighter->HighlightLanguages.ensureRegistered("javascript", javascript)

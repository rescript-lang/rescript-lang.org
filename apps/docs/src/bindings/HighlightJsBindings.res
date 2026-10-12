type highlightOptions = {language: string}
type highlightResult = {value: string}

@module("highlight.js/lib/core") @scope("default")
external make: unit => HighlightLanguages.highlighter = "newInstance"

@module("highlight.js/lib/languages/bash")
external bash: HighlightLanguages.definition = "default"

@module("highlight.js/lib/languages/css")
external css: HighlightLanguages.definition = "default"

@module("highlight.js/lib/languages/diff")
external diff: HighlightLanguages.definition = "default"

@module("highlight.js/lib/languages/javascript")
external javascript: HighlightLanguages.definition = "default"

@module("highlight.js/lib/languages/typescript")
external typescript: HighlightLanguages.definition = "default"

@module("highlight.js/lib/languages/json")
external json: HighlightLanguages.definition = "default"

@module("highlight.js/lib/languages/plaintext")
external text: HighlightLanguages.definition = "default"

@module("highlight.js/lib/languages/xml")
external html: HighlightLanguages.definition = "default"

@module("highlight.js/lib/languages/yaml")
external yaml: HighlightLanguages.definition = "default"

@module("highlight.js/lib/languages/ini")
external toml: HighlightLanguages.definition = "default"

@module("highlightjs-rescript")
external rescript: HighlightLanguages.definition = "default"

@send
external registerLanguage: (
  HighlightLanguages.highlighter,
  string,
  HighlightLanguages.definition,
) => unit = "registerLanguage"

@send
external highlight: (HighlightLanguages.highlighter, string, highlightOptions) => highlightResult =
  "highlight"

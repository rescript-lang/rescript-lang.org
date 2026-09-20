type t
type language
type highlightOptions = {language: string}
type highlightResult = {value: string}

@module("highlight.js/lib/core") @scope("default")
external make: unit => t = "newInstance"

@module("highlight.js/lib/languages/javascript")
external javascript: language = "default"

@module("highlightjs-rescript")
external rescript: language = "default"

@send
external registerLanguage: (t, string, language) => unit = "registerLanguage"

@send
external highlight: (t, string, highlightOptions) => highlightResult = "highlight"

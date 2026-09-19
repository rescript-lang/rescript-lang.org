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

@module("highlight.js/lib/languages/ini")
external toml: HighlightLanguages.definition = "default"

@module("highlightjs-rescript")
external rescript: HighlightLanguages.definition = "default"

let register = highlighter => {
  highlighter->HighlightLanguages.ensureRegistered("rescript", rescript)
  highlighter->HighlightLanguages.ensureRegistered("javascript", javascript)
  highlighter->HighlightLanguages.ensureRegistered("css", css)
  highlighter->HighlightLanguages.ensureRegistered("ts", typescript)
  highlighter->HighlightLanguages.ensureRegistered("sh", bash)
  highlighter->HighlightLanguages.ensureRegistered("bash", bash)
  highlighter->HighlightLanguages.ensureRegistered("toml", toml)
  highlighter->HighlightLanguages.ensureRegistered("json", json)
  highlighter->HighlightLanguages.ensureRegistered("text", text)
  highlighter->HighlightLanguages.ensureRegistered("html", html)
  highlighter->HighlightLanguages.ensureRegistered("diff", diff)
  highlighter->HighlightLanguages.ensureRegistered("typescript", typescript)
}

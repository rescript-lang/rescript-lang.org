open Vitest

type registeredLanguage
type highlightOptions = {language: string}
type highlightResult = {value: string}

@module("highlight.js/lib/core") @scope("default")
external createHighlighter: unit => HighlightLanguages.highlighter = "newInstance"

@module("highlight.js/lib/languages/javascript")
external javascript: HighlightLanguages.definition = "default"

@module("highlight.js/lib/languages/plaintext")
external plaintext: HighlightLanguages.definition = "default"

@send
external getLanguage: (HighlightLanguages.highlighter, string) => option<registeredLanguage> =
  "getLanguage"

@send
external highlight: (HighlightLanguages.highlighter, string, highlightOptions) => highlightResult =
  "highlight"

test("registering a missing language makes its grammar and aliases available", async () => {
  let highlighter = createHighlighter()

  expect(highlighter->getLanguage("javascript"))->toEqual(None)
  expect(highlighter->getLanguage("js"))->toEqual(None)
  highlighter->HighlightLanguages.ensureRegistered("javascript", javascript)

  let result = highlighter->highlight("const answer = 42;", {language: "js"})
  expect(result.value)->toBe(
    "<span class=\"hljs-keyword\">const</span> answer = <span class=\"hljs-number\">42</span>;",
  )
})

test("registering an existing name or alias does not replace its grammar", async () => {
  let highlighter = createHighlighter()
  highlighter->HighlightLanguages.ensureRegistered("javascript", javascript)
  let original = highlighter->getLanguage("javascript")

  highlighter->HighlightLanguages.ensureRegistered("javascript", plaintext)
  highlighter->HighlightLanguages.ensureRegistered("js", plaintext)

  expect(highlighter->getLanguage("javascript"))->toBe(original)
  expect(highlighter->getLanguage("js"))->toBe(original)
  let result = highlighter->highlight("const answer = 42;", {language: "js"})
  expect(result.value)->toBe(
    "<span class=\"hljs-keyword\">const</span> answer = <span class=\"hljs-number\">42</span>;",
  )
})

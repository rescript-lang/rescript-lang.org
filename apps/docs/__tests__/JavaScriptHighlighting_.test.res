open Vitest

type registeredLanguage
type highlightOptions = {language: string}
type highlightResult = {value: string}

@module("highlight.js/lib/core") @scope("default")
external createHighlighter: unit => HighlightLanguages.highlighter = "newInstance"

@send
external listLanguages: HighlightLanguages.highlighter => array<string> = "listLanguages"

@send
external getLanguage: (HighlightLanguages.highlighter, string) => option<registeredLanguage> =
  "getLanguage"

@send
external highlight: (HighlightLanguages.highlighter, string, highlightOptions) => highlightResult =
  "highlight"

test("playground registration loads only JavaScript and its working aliases", async () => {
  let highlighter = createHighlighter()
  highlighter->JavaScriptHighlighting.register

  let missingAliases =
    ["javascript", "js", "jsx", "mjs", "cjs"]->Array.filter(alias =>
      highlighter->getLanguage(alias)->Option.isNone
    )
  expect(highlighter->listLanguages)->toEqual(["javascript"])
  expect(missingAliases)->toEqual([])
  let result = highlighter->highlight("const answer = 42;", {language: "js"})
  expect(result.value)->toBe(
    "<span class=\"hljs-keyword\">const</span> answer = <span class=\"hljs-number\">42</span>;",
  )
})

open Vitest

test("registering a missing language makes its grammar and aliases available", async () => {
  let highlighter = HighlightLanguages.make(HighlightLanguages.defaultInstance)

  expect(highlighter->HighlightLanguages.getLanguage("javascript"))->toEqual(None)
  expect(highlighter->HighlightLanguages.getLanguage("js"))->toEqual(None)
  highlighter->HighlightLanguages.ensureRegistered("javascript", HighlightJsBindings.javascript)

  let result = highlighter->HighlightLanguages.highlight("const answer = 42;", {language: "js"})
  expect(result.value)->toBe(
    "<span class=\"hljs-keyword\">const</span> answer = <span class=\"hljs-number\">42</span>;",
  )
})

test("registering an existing name or alias does not replace its grammar", async () => {
  let highlighter = HighlightLanguages.make(HighlightLanguages.defaultInstance)
  highlighter->HighlightLanguages.ensureRegistered("javascript", HighlightJsBindings.javascript)
  let original = highlighter->HighlightLanguages.getLanguage("javascript")

  highlighter->HighlightLanguages.ensureRegistered("javascript", HighlightJsBindings.text)
  highlighter->HighlightLanguages.ensureRegistered("js", HighlightJsBindings.text)

  expect(highlighter->HighlightLanguages.getLanguage("javascript"))->toBe(original)
  expect(highlighter->HighlightLanguages.getLanguage("js"))->toBe(original)
  let result = highlighter->HighlightLanguages.highlight("const answer = 42;", {language: "js"})
  expect(result.value)->toBe(
    "<span class=\"hljs-keyword\">const</span> answer = <span class=\"hljs-number\">42</span>;",
  )
})

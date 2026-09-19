open Vitest

type registeredLanguage
type highlightOptions = {language: string}
type highlightResult = {value: string}

@module("highlight.js/lib/core") @scope("default")
external createHighlighter: unit => HighlightLanguages.highlighter = "newInstance"

@send
external getLanguage: (HighlightLanguages.highlighter, string) => option<registeredLanguage> =
  "getLanguage"

@send
external highlight: (HighlightLanguages.highlighter, string, highlightOptions) => highlightResult =
  "highlight"

let aliases = [
  "rescript",
  "res",
  "resi",
  "javascript",
  "js",
  "jsx",
  "mjs",
  "cjs",
  "css",
  "ts",
  "tsx",
  "mts",
  "cts",
  "typescript",
  "sh",
  "bash",
  "zsh",
  "toml",
  "json",
  "jsonc",
  "text",
  "txt",
  "html",
  "xhtml",
  "rss",
  "atom",
  "xjb",
  "xsd",
  "xsl",
  "plist",
  "wsf",
  "svg",
  "diff",
  "patch",
]

test("content registration preserves every established language name and alias", async () => {
  let highlighter = createHighlighter()
  highlighter->ContentHighlighting.register

  let missingAliases =
    aliases->Array.filter(alias => highlighter->getLanguage(alias)->Option.isNone)
  expect(missingAliases)->toEqual([])
})

test("content registration produces highlighted ReScript and escaped plain text", async () => {
  let highlighter = createHighlighter()
  highlighter->ContentHighlighting.register

  let rescript = highlighter->highlight("let count = 1", {language: "res"})
  let text = highlighter->highlight("<button>Example & code</button>", {language: "text"})

  expect(rescript.value->String.includes("<span class=\"hljs-keyword\">let</span>"))->toBe(true)
  expect(rescript.value->String.includes("<span class=\"hljs-number\">1</span>"))->toBe(true)
  expect(text.value)->toBe("&lt;button&gt;Example &amp; code&lt;/button&gt;")
})

test("repeated content initialization leaves registered grammars unchanged", async () => {
  let highlighter = createHighlighter()
  highlighter->ContentHighlighting.register
  let original = highlighter->getLanguage("javascript")
  let before = highlighter->highlight("const count: number = 1;", {language: "ts"})

  highlighter->ContentHighlighting.register

  let after = highlighter->highlight("const count: number = 1;", {language: "ts"})
  expect(highlighter->getLanguage("javascript"))->toBe(original)
  expect(highlighter->getLanguage("js"))->toBe(original)
  expect(after.value)->toBe(before.value)
})

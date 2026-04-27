open Vitest

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

let highlightedValue = (value: string): DocSearch.highlightedValue => {value: value}

let makeHit = (~type_: DocSearch.contentType, ~url: string): DocSearch.docSearchHit => {
  objectID: "test",
  content: Nullable.null,
  url,
  url_without_anchor: Nullable.make(url),
  type_,
  anchor: Nullable.null,
  hierarchy: {
    lvl0: Nullable.make("Test"),
    lvl1: Nullable.make("Test Page"),
    lvl2: Nullable.null,
    lvl3: Nullable.null,
    lvl4: Nullable.null,
    lvl5: Nullable.null,
    lvl6: Nullable.null,
  },
  deprecated: None,
  _highlightResult: {hierarchy: Nullable.null},
  _snippetResult: {content: Nullable.null},
}

// ---------------------------------------------------------------------------
// markdownToHtml
// ---------------------------------------------------------------------------

test("markdownToHtml strips leading backslash + whitespace", async () => {
  expect(Search.markdownToHtml("\\ hello"))->toBe("hello")
})

test("markdownToHtml replaces interior backslash + whitespace with a space", async () => {
  expect(Search.markdownToHtml("foo\\ bar"))->toBe("foo bar")
})

test("markdownToHtml handles multiple interior backslashes", async () => {
  expect(Search.markdownToHtml("a\\ b\\ c"))->toBe("a b c")
})

test("markdownToHtml strips leading and replaces interior backslashes together", async () => {
  expect(Search.markdownToHtml("\\ a\\ b"))->toBe("a b")
})

test(
  "markdownToHtml removes an MDN reference with a markdown link and trailing period",
  async () => {
    expect(
      Search.markdownToHtml("Some text. See [Array](https://developer.mozilla.org/array) on MDN."),
    )->toBe("Some text.")
  },
)

test(
  "markdownToHtml removes an MDN reference with a markdown link without trailing period",
  async () => {
    expect(
      Search.markdownToHtml("Some text. See [Array](https://developer.mozilla.org/array) on MDN"),
    )->toBe("Some text.")
  },
)

test("markdownToHtml removes an MDN plain URL reference with trailing period", async () => {
  expect(Search.markdownToHtml("Read more. See https://developer.mozilla.org/foo on MDN."))->toBe(
    "Read more.",
  )
})

test("markdownToHtml removes an MDN plain URL reference without trailing period", async () => {
  expect(Search.markdownToHtml("Read more. See https://developer.mozilla.org/foo on MDN"))->toBe(
    "Read more.",
  )
})

test("markdownToHtml converts a markdown link to plain text", async () => {
  expect(Search.markdownToHtml("[click here](https://example.com)"))->toBe("click here")
})

test("markdownToHtml converts multiple markdown links", async () => {
  expect(Search.markdownToHtml("[foo](http://a.com) and [bar](http://b.com)"))->toBe("foo and bar")
})

test("markdownToHtml passes through a link with empty text", async () => {
  expect(Search.markdownToHtml("[](https://example.com)"))->toBe("[](https://example.com)")
})

test("markdownToHtml converts backtick code to <code> tags", async () => {
  expect(Search.markdownToHtml("`Array.map`"))->toBe("<code>Array.map</code>")
})

test("markdownToHtml converts multiple backtick spans", async () => {
  expect(Search.markdownToHtml("Use `map` and `filter`"))->toBe(
    "Use <code>map</code> and <code>filter</code>",
  )
})

test("markdownToHtml converts **text** to <strong> tags", async () => {
  expect(Search.markdownToHtml("**important**"))->toBe("<strong>important</strong>")
})

test("markdownToHtml converts bold within a sentence", async () => {
  expect(Search.markdownToHtml("This is **very** important"))->toBe(
    "This is <strong>very</strong> important",
  )
})

test("markdownToHtml converts *text* to <em> tags", async () => {
  expect(Search.markdownToHtml("*emphasis*"))->toBe("<em>emphasis</em>")
})

test("markdownToHtml converts italic within a sentence", async () => {
  expect(Search.markdownToHtml("This is *quite* nice"))->toBe("This is <em>quite</em> nice")
})

test("markdownToHtml converts double newline to <br />", async () => {
  expect(Search.markdownToHtml("first\n\nsecond"))->toBe("first<br />second")
})

test("markdownToHtml converts triple+ newlines to a single <br />", async () => {
  expect(Search.markdownToHtml("first\n\n\nsecond"))->toBe("first<br />second")
})

test("markdownToHtml converts single newline to a space", async () => {
  expect(Search.markdownToHtml("first\nsecond"))->toBe("first second")
})

test("markdownToHtml trims leading whitespace", async () => {
  expect(Search.markdownToHtml("  hello"))->toBe("hello")
})

test("markdownToHtml trims trailing whitespace", async () => {
  expect(Search.markdownToHtml("hello  "))->toBe("hello")
})

test("markdownToHtml trims both sides", async () => {
  expect(Search.markdownToHtml("  hello  "))->toBe("hello")
})

test("markdownToHtml handles empty string", async () => {
  expect(Search.markdownToHtml(""))->toBe("")
})

test("markdownToHtml passes plain text through unchanged", async () => {
  expect(Search.markdownToHtml("just plain text"))->toBe("just plain text")
})

test("markdownToHtml applies multiple transformations together", async () => {
  expect(
    Search.markdownToHtml("Use `map` on **arrays**.\n\nSee [docs](http://x.com) for *details*."),
  )->toBe("Use <code>map</code> on <strong>arrays</strong>.<br />See docs for <em>details</em>.")
})

test(
  "markdownToHtml still converts bold inside code because regexes run sequentially",
  async () => {
    expect(Search.markdownToHtml("`**notbold**`"))->toBe("<code><strong>notbold</strong></code>")
  },
)

test("getHighlightedTitle rebuilds crawler API titles and preserves marked prefixes", async () => {
  let hit = {
    ...makeHit(
      ~type_=Content,
      ~url="https://rescript-lang.org/docs/manual/api/stdlib/array/#value-mapWithIndex",
    ),
    hierarchy: {
      lvl0: Nullable.make("Array"),
      lvl1: Nullable.make("mapWithIndex"),
      lvl2: Nullable.null,
      lvl3: Nullable.null,
      lvl4: Nullable.null,
      lvl5: Nullable.null,
      lvl6: Nullable.null,
    },
    _snippetResult: {
      content: Nullable.make(highlightedValue("See <mark>Array.map</mark> on MDN.")),
    },
  }

  expect(Search.getHighlightedTitle(hit))->toBe("<mark>Array.map</mark>WithIndex")
})

test(
  "getHighlightedTitle prefers real hierarchy highlights when Algolia returns them",
  async () => {
    let highlightedHierarchy: DocSearch.highlightedHierarchy = {
      lvl0: Nullable.null,
      lvl1: Nullable.null,
      lvl2: Nullable.make(highlightedValue("<mark>Section</mark> title")),
      lvl3: Nullable.null,
      lvl4: Nullable.null,
      lvl5: Nullable.null,
      lvl6: Nullable.null,
    }
    let hit = {
      ...makeHit(~type_=Lvl2, ~url="https://rescript-lang.org/docs/manual/page#section"),
      _highlightResult: {hierarchy: Nullable.make(highlightedHierarchy)},
    }

    expect(Search.getHighlightedTitle(hit))->toBe("<mark>Section</mark> title")
  },
)

test("getContentHtml prefers crawler snippet markup over plain content", async () => {
  let hit = {
    ...makeHit(~type_=Content, ~url="https://rescript-lang.org/docs/manual/api/stdlib/array/"),
    content: Nullable.make("map(array, fn) returns a new array."),
    _snippetResult: {
      content: Nullable.make(highlightedValue("map(array, fn) returns a new <mark>array</mark>.")),
    },
  }

  expect(Search.getContentHtml(hit))->toEqual(
    Some("map(array, fn) returns a new <mark>array</mark>."),
  )
})

// ---------------------------------------------------------------------------
// isChildHit
// ---------------------------------------------------------------------------

test("isChildHit treats Lvl2 as a child hit", async () => {
  expect(Search.isChildHit(makeHit(~type_=Lvl2, ~url="https://example.com/page")))->toBe(true)
})

test("isChildHit treats Lvl3 as a child hit", async () => {
  expect(Search.isChildHit(makeHit(~type_=Lvl3, ~url="https://example.com/page")))->toBe(true)
})

test("isChildHit treats Lvl4 as a child hit", async () => {
  expect(Search.isChildHit(makeHit(~type_=Lvl4, ~url="https://example.com/page")))->toBe(true)
})

test("isChildHit treats Lvl5 as a child hit", async () => {
  expect(Search.isChildHit(makeHit(~type_=Lvl5, ~url="https://example.com/page")))->toBe(true)
})

test("isChildHit treats Lvl6 as a child hit", async () => {
  expect(Search.isChildHit(makeHit(~type_=Lvl6, ~url="https://example.com/page")))->toBe(true)
})

test("isChildHit treats Content as a child hit", async () => {
  expect(Search.isChildHit(makeHit(~type_=Content, ~url="https://example.com/page")))->toBe(true)
})

test("isChildHit treats Lvl2 as a child hit even without a hash in the URL", async () => {
  expect(Search.isChildHit(makeHit(~type_=Lvl2, ~url="https://example.com/no-hash")))->toBe(true)
})

test("isChildHit treats Content as a child hit even with a hash in the URL", async () => {
  expect(Search.isChildHit(makeHit(~type_=Content, ~url="https://example.com/page#section")))->toBe(
    true,
  )
})

test("isChildHit treats Lvl0 without a hash as not a child hit", async () => {
  expect(Search.isChildHit(makeHit(~type_=Lvl0, ~url="https://example.com/page")))->toBe(false)
})

test("isChildHit treats Lvl0 with a hash as a child hit", async () => {
  expect(Search.isChildHit(makeHit(~type_=Lvl0, ~url="https://example.com/page#section")))->toBe(
    true,
  )
})

test("isChildHit treats Lvl0 with a trailing # as a child hit", async () => {
  expect(Search.isChildHit(makeHit(~type_=Lvl0, ~url="https://example.com/page#")))->toBe(true)
})

test("isChildHit treats Lvl1 without a hash as not a child hit", async () => {
  expect(Search.isChildHit(makeHit(~type_=Lvl1, ~url="https://example.com/page")))->toBe(false)
})

test("isChildHit treats Lvl1 with a hash as a child hit", async () => {
  expect(Search.isChildHit(makeHit(~type_=Lvl1, ~url="https://example.com/page#heading")))->toBe(
    true,
  )
})

test("isChildHit treats Lvl1 with a deeply nested hash anchor as a child hit", async () => {
  expect(
    Search.isChildHit(
      makeHit(~type_=Lvl1, ~url="https://example.com/docs/manual/api#some-section"),
    ),
  )->toBe(true)
})

test("isChildHit treats Lvl1 with an empty URL as not a child hit", async () => {
  expect(Search.isChildHit(makeHit(~type_=Lvl1, ~url="")))->toBe(false)
})

test("toRelativeSiteUrl strips the site origin from an absolute URL", async () => {
  let result = Search.toRelativeSiteUrl(
    "https://rescript-lang.org/docs/manual/introduction#what-is-rescript",
    ~siteUrl="https://rescript-lang.org/",
  )

  expect(result)->toBe("/docs/manual/introduction#what-is-rescript")
})

test("toRelativeSiteUrl leaves absolute URLs unchanged when siteUrl is empty", async () => {
  let result = Search.toRelativeSiteUrl(
    "https://rescript-lang.org/docs/manual/introduction#what-is-rescript",
    ~siteUrl="",
  )

  expect(result)->toBe("https://rescript-lang.org/docs/manual/introduction#what-is-rescript")
})

test("normalizeHitUrls rewrites absolute site URLs to relative paths", async () => {
  let hit = makeHit(
    ~type_=Lvl1,
    ~url="https://rescript-lang.org/docs/manual/typescript-integration#gentype",
  )
  let result = Search.normalizeHitUrls([hit], ~siteUrl="https://rescript-lang.org/")

  expect(result[0]->Option.map(hit => hit.url))->toEqual(
    Some("/docs/manual/typescript-integration#gentype"),
  )
  expect(result[0]->Option.flatMap(hit => hit.url_without_anchor->Nullable.toOption))->toEqual(
    Some("/docs/manual/typescript-integration#gentype"),
  )
})

test("normalizeHitUrls tolerates crawler hits without url_without_anchor", async () => {
  let hit: DocSearch.docSearchHit = Obj.magic(
    Dict.fromArray([
      ("objectID", "crawler-hit"),
      ("content", "map(array, fn) returns a new array."),
      ("url", "https://rescript-lang.org/docs/manual/api/stdlib/array/#value-map"),
      ("type", "content"),
    ]),
  )

  let result = Search.normalizeHitUrls([hit], ~siteUrl="https://rescript-lang.org/")

  expect(result[0]->Option.map(hit => hit.url))->toEqual(
    Some("/docs/manual/api/stdlib/array/#value-map"),
  )
  expect(result[0]->Option.flatMap(hit => hit.url_without_anchor->Nullable.toOption))->toEqual(
    Some("/docs/manual/api/stdlib/array/"),
  )
})

test("renders disabled search copy when Algolia config is missing", async () => {
  await viewport(1440, 500)

  let screen = await render(<Search />)

  await element(await screen->getByText("Search unavailable"))->toBeVisible
  await element(await screen->getByLabelText("Search unavailable for this build"))->toBeVisible
})

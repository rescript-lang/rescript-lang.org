open Vitest

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

let makeHit = (~type_: DocSearch.contentType, ~url: string): DocSearch.docSearchHit => {
  objectID: "test",
  content: Nullable.null,
  url,
  url_without_anchor: url,
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
  _highlightResult: Obj.magic(Dict.make()),
  _snippetResult: Obj.magic(Dict.make()),
}

// ---------------------------------------------------------------------------
// markdownToHtml
// ---------------------------------------------------------------------------

describe("markdownToHtml", () => {
  // --- backslash stripping ---

  describe("backslash stripping", () => {
    test(
      "strips leading backslash + whitespace",
      async () => {
        expect(Search.markdownToHtml("\\ hello"))->toBe("hello")
      },
    )

    test(
      "replaces interior backslash + whitespace with a space",
      async () => {
        expect(Search.markdownToHtml("foo\\ bar"))->toBe("foo bar")
      },
    )

    test(
      "handles multiple interior backslashes",
      async () => {
        expect(Search.markdownToHtml("a\\ b\\ c"))->toBe("a b c")
      },
    )

    test(
      "strips leading and replaces interior backslashes together",
      async () => {
        expect(Search.markdownToHtml("\\ a\\ b"))->toBe("a b")
      },
    )
  })

  // --- MDN reference link removal ---

  describe("MDN reference removal", () => {
    test(
      "removes MDN reference with markdown link and trailing period",
      async () => {
        expect(
          Search.markdownToHtml(
            "Some text. See [Array](https://developer.mozilla.org/array) on MDN.",
          ),
        )->toBe("Some text.")
      },
    )

    test(
      "removes MDN reference with markdown link without trailing period",
      async () => {
        expect(
          Search.markdownToHtml(
            "Some text. See [Array](https://developer.mozilla.org/array) on MDN",
          ),
        )->toBe("Some text.")
      },
    )

    test(
      "removes MDN plain URL reference with trailing period",
      async () => {
        expect(
          Search.markdownToHtml("Read more. See https://developer.mozilla.org/foo on MDN."),
        )->toBe("Read more.")
      },
    )

    test(
      "removes MDN plain URL reference without trailing period",
      async () => {
        expect(
          Search.markdownToHtml("Read more. See https://developer.mozilla.org/foo on MDN"),
        )->toBe("Read more.")
      },
    )
  })

  // --- markdown link stripping ---

  describe("markdown link stripping", () => {
    test(
      "converts markdown link to plain text",
      async () => {
        expect(Search.markdownToHtml("[click here](https://example.com)"))->toBe("click here")
      },
    )

    test(
      "converts multiple markdown links",
      async () => {
        expect(Search.markdownToHtml("[foo](http://a.com) and [bar](http://b.com)"))->toBe(
          "foo and bar",
        )
      },
    )

    test(
      "passes through link with empty text (regex requires non-empty text)",
      async () => {
        expect(Search.markdownToHtml("[](https://example.com)"))->toBe("[](https://example.com)")
      },
    )
  })

  // --- inline code ---

  describe("backtick code", () => {
    test(
      "converts backtick code to <code> tags",
      async () => {
        expect(Search.markdownToHtml("`Array.map`"))->toBe("<code>Array.map</code>")
      },
    )

    test(
      "converts multiple backtick spans",
      async () => {
        expect(Search.markdownToHtml("Use `map` and `filter`"))->toBe(
          "Use <code>map</code> and <code>filter</code>",
        )
      },
    )
  })

  // --- bold ---

  describe("bold", () => {
    test(
      "converts **text** to <strong> tags",
      async () => {
        expect(Search.markdownToHtml("**important**"))->toBe("<strong>important</strong>")
      },
    )

    test(
      "converts bold within a sentence",
      async () => {
        expect(Search.markdownToHtml("This is **very** important"))->toBe(
          "This is <strong>very</strong> important",
        )
      },
    )
  })

  // --- italic ---

  describe("italic", () => {
    test(
      "converts *text* to <em> tags",
      async () => {
        expect(Search.markdownToHtml("*emphasis*"))->toBe("<em>emphasis</em>")
      },
    )

    test(
      "converts italic within a sentence",
      async () => {
        expect(Search.markdownToHtml("This is *quite* nice"))->toBe("This is <em>quite</em> nice")
      },
    )
  })

  // --- newlines ---

  describe("newlines", () => {
    test(
      "converts double newline to <br />",
      async () => {
        expect(Search.markdownToHtml("first\n\nsecond"))->toBe("first<br />second")
      },
    )

    test(
      "converts triple+ newlines to single <br />",
      async () => {
        expect(Search.markdownToHtml("first\n\n\nsecond"))->toBe("first<br />second")
      },
    )

    test(
      "converts single newline to space",
      async () => {
        expect(Search.markdownToHtml("first\nsecond"))->toBe("first second")
      },
    )
  })

  // --- trimming ---

  describe("trimming", () => {
    test(
      "trims leading whitespace",
      async () => {
        expect(Search.markdownToHtml("  hello"))->toBe("hello")
      },
    )

    test(
      "trims trailing whitespace",
      async () => {
        expect(Search.markdownToHtml("hello  "))->toBe("hello")
      },
    )

    test(
      "trims both sides",
      async () => {
        expect(Search.markdownToHtml("  hello  "))->toBe("hello")
      },
    )
  })

  // --- combined / edge cases ---

  describe("combined transformations", () => {
    test(
      "handles empty string",
      async () => {
        expect(Search.markdownToHtml(""))->toBe("")
      },
    )

    test(
      "plain text passes through unchanged",
      async () => {
        expect(Search.markdownToHtml("just plain text"))->toBe("just plain text")
      },
    )

    test(
      "applies multiple transformations together",
      async () => {
        expect(
          Search.markdownToHtml(
            "Use `map` on **arrays**.\n\nSee [docs](http://x.com) for *details*.",
          ),
        )->toBe(
          "Use <code>map</code> on <strong>arrays</strong>.<br />See docs for <em>details</em>.",
        )
      },
    )

    test(
      "bold inside code still gets converted (sequential regex application)",
      async () => {
        expect(Search.markdownToHtml("`**notbold**`"))->toBe(
          "<code><strong>notbold</strong></code>",
        )
      },
    )
  })
})

// ---------------------------------------------------------------------------
// isChildHit
// ---------------------------------------------------------------------------

describe("isChildHit", () => {
  // --- child-level types (always true) ---

  describe("child-level types", () => {
    test(
      "Lvl2 is a child hit",
      async () => {
        expect(Search.isChildHit(makeHit(~type_=Lvl2, ~url="https://example.com/page")))->toBe(true)
      },
    )

    test(
      "Lvl3 is a child hit",
      async () => {
        expect(Search.isChildHit(makeHit(~type_=Lvl3, ~url="https://example.com/page")))->toBe(true)
      },
    )

    test(
      "Lvl4 is a child hit",
      async () => {
        expect(Search.isChildHit(makeHit(~type_=Lvl4, ~url="https://example.com/page")))->toBe(true)
      },
    )

    test(
      "Lvl5 is a child hit",
      async () => {
        expect(Search.isChildHit(makeHit(~type_=Lvl5, ~url="https://example.com/page")))->toBe(true)
      },
    )

    test(
      "Lvl6 is a child hit",
      async () => {
        expect(Search.isChildHit(makeHit(~type_=Lvl6, ~url="https://example.com/page")))->toBe(true)
      },
    )

    test(
      "Content is a child hit",
      async () => {
        expect(Search.isChildHit(makeHit(~type_=Content, ~url="https://example.com/page")))->toBe(
          true,
        )
      },
    )

    test(
      "Lvl2 is a child hit even without hash in URL",
      async () => {
        expect(Search.isChildHit(makeHit(~type_=Lvl2, ~url="https://example.com/no-hash")))->toBe(
          true,
        )
      },
    )

    test(
      "Content is a child hit even with hash in URL",
      async () => {
        expect(
          Search.isChildHit(makeHit(~type_=Content, ~url="https://example.com/page#section")),
        )->toBe(true)
      },
    )
  })

  // --- Lvl0 ---

  describe("Lvl0", () => {
    test(
      "Lvl0 without hash is not a child hit",
      async () => {
        expect(Search.isChildHit(makeHit(~type_=Lvl0, ~url="https://example.com/page")))->toBe(
          false,
        )
      },
    )

    test(
      "Lvl0 with hash is a child hit",
      async () => {
        expect(
          Search.isChildHit(makeHit(~type_=Lvl0, ~url="https://example.com/page#section")),
        )->toBe(true)
      },
    )

    test(
      "Lvl0 with hash at end of URL is a child hit",
      async () => {
        expect(Search.isChildHit(makeHit(~type_=Lvl0, ~url="https://example.com/page#")))->toBe(
          true,
        )
      },
    )
  })

  // --- Lvl1 ---

  describe("Lvl1", () => {
    test(
      "Lvl1 without hash is not a child hit",
      async () => {
        expect(Search.isChildHit(makeHit(~type_=Lvl1, ~url="https://example.com/page")))->toBe(
          false,
        )
      },
    )

    test(
      "Lvl1 with hash is a child hit",
      async () => {
        expect(
          Search.isChildHit(makeHit(~type_=Lvl1, ~url="https://example.com/page#heading")),
        )->toBe(true)
      },
    )

    test(
      "Lvl1 with deeply nested hash anchor is a child hit",
      async () => {
        expect(
          Search.isChildHit(
            makeHit(~type_=Lvl1, ~url="https://example.com/docs/manual/api#some-section"),
          ),
        )->toBe(true)
      },
    )

    test(
      "Lvl1 with empty URL is not a child hit",
      async () => {
        expect(Search.isChildHit(makeHit(~type_=Lvl1, ~url="")))->toBe(false)
      },
    )
  })
})

test("renders disabled search copy when Algolia config is missing", async () => {
  await viewport(1440, 500)

  let screen = await render(<Search />)

  await element(await screen->getByText("Search unavailable"))->toBeVisible
  await element(await screen->getByLabelText("Search unavailable for this build"))->toBeVisible
})

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

let withHierarchy = (
  hit: DocSearch.docSearchHit,
  ~lvl0: string,
  ~lvl1: string,
): DocSearch.docSearchHit => {
  ...hit,
  hierarchy: {...hit.hierarchy, lvl0: Nullable.make(lvl0), lvl1: Nullable.make(lvl1)},
}

module ThrowsOnRender = {
  @react.component
  let make = (): React.element => failwith("search render exploded")
}

module CurrentPath = {
  @react.component
  let make = () => {
    let location = ReactRouter.useLocation()
    <span> {React.string((location.pathname :> string))} </span>
  }
}

// ---------------------------------------------------------------------------
// markdownToHtml
// ---------------------------------------------------------------------------

test("markdownToHtml strips leading backslash + whitespace", async () => {
  expect(SearchResults.markdownToHtml("\\ hello"))->toBe("hello")
})

test("markdownToHtml replaces interior backslash + whitespace with a space", async () => {
  expect(SearchResults.markdownToHtml("foo\\ bar"))->toBe("foo bar")
})

test("markdownToHtml handles multiple interior backslashes", async () => {
  expect(SearchResults.markdownToHtml("a\\ b\\ c"))->toBe("a b c")
})

test("markdownToHtml strips leading and replaces interior backslashes together", async () => {
  expect(SearchResults.markdownToHtml("\\ a\\ b"))->toBe("a b")
})

test(
  "markdownToHtml removes an MDN reference with a markdown link and trailing period",
  async () => {
    expect(
      SearchResults.markdownToHtml(
        "Some text. See [Array](https://developer.mozilla.org/array) on MDN.",
      ),
    )->toBe("Some text.")
  },
)

test(
  "markdownToHtml removes an MDN reference with a markdown link without trailing period",
  async () => {
    expect(
      SearchResults.markdownToHtml(
        "Some text. See [Array](https://developer.mozilla.org/array) on MDN",
      ),
    )->toBe("Some text.")
  },
)

test("markdownToHtml removes an MDN plain URL reference with trailing period", async () => {
  expect(
    SearchResults.markdownToHtml("Read more. See https://developer.mozilla.org/foo on MDN."),
  )->toBe("Read more.")
})

test("markdownToHtml removes an MDN plain URL reference without trailing period", async () => {
  expect(
    SearchResults.markdownToHtml("Read more. See https://developer.mozilla.org/foo on MDN"),
  )->toBe("Read more.")
})

test("markdownToHtml converts a markdown link to plain text", async () => {
  expect(SearchResults.markdownToHtml("[click here](https://example.com)"))->toBe("click here")
})

test("markdownToHtml converts multiple markdown links", async () => {
  expect(SearchResults.markdownToHtml("[foo](http://a.com) and [bar](http://b.com)"))->toBe(
    "foo and bar",
  )
})

test("markdownToHtml passes through a link with empty text", async () => {
  expect(SearchResults.markdownToHtml("[](https://example.com)"))->toBe("[](https://example.com)")
})

test("markdownToHtml converts backtick code to <code> tags", async () => {
  expect(SearchResults.markdownToHtml("`Array.map`"))->toBe("<code>Array.map</code>")
})

test("markdownToHtml converts multiple backtick spans", async () => {
  expect(SearchResults.markdownToHtml("Use `map` and `filter`"))->toBe(
    "Use <code>map</code> and <code>filter</code>",
  )
})

test("markdownToHtml converts **text** to <strong> tags", async () => {
  expect(SearchResults.markdownToHtml("**important**"))->toBe("<strong>important</strong>")
})

test("markdownToHtml converts bold within a sentence", async () => {
  expect(SearchResults.markdownToHtml("This is **very** important"))->toBe(
    "This is <strong>very</strong> important",
  )
})

test("markdownToHtml converts *text* to <em> tags", async () => {
  expect(SearchResults.markdownToHtml("*emphasis*"))->toBe("<em>emphasis</em>")
})

test("markdownToHtml converts italic within a sentence", async () => {
  expect(SearchResults.markdownToHtml("This is *quite* nice"))->toBe("This is <em>quite</em> nice")
})

test("markdownToHtml converts double newline to <br />", async () => {
  expect(SearchResults.markdownToHtml("first\n\nsecond"))->toBe("first<br />second")
})

test("markdownToHtml converts triple+ newlines to a single <br />", async () => {
  expect(SearchResults.markdownToHtml("first\n\n\nsecond"))->toBe("first<br />second")
})

test("markdownToHtml converts single newline to a space", async () => {
  expect(SearchResults.markdownToHtml("first\nsecond"))->toBe("first second")
})

test("markdownToHtml trims leading whitespace", async () => {
  expect(SearchResults.markdownToHtml("  hello"))->toBe("hello")
})

test("markdownToHtml trims trailing whitespace", async () => {
  expect(SearchResults.markdownToHtml("hello  "))->toBe("hello")
})

test("markdownToHtml trims both sides", async () => {
  expect(SearchResults.markdownToHtml("  hello  "))->toBe("hello")
})

test("markdownToHtml handles empty string", async () => {
  expect(SearchResults.markdownToHtml(""))->toBe("")
})

test("markdownToHtml passes plain text through unchanged", async () => {
  expect(SearchResults.markdownToHtml("just plain text"))->toBe("just plain text")
})

test("markdownToHtml applies multiple transformations together", async () => {
  expect(
    SearchResults.markdownToHtml(
      "Use `map` on **arrays**.\n\nSee [docs](http://x.com) for *details*.",
    ),
  )->toBe("Use <code>map</code> on <strong>arrays</strong>.<br />See docs for <em>details</em>.")
})

test(
  "markdownToHtml still converts bold inside code because regexes run sequentially",
  async () => {
    expect(SearchResults.markdownToHtml("`**notbold**`"))->toBe(
      "<code><strong>notbold</strong></code>",
    )
  },
)

test("getHighlightedTitle renders crawler API titles as value names", async () => {
  let hit = withHierarchy(
    makeHit(
      ~type_=Content,
      ~url="https://rescript-lang.org/docs/manual/api/stdlib/array/#value-mapWithIndex",
    ),
    ~lvl0="Array",
    ~lvl1="mapWithIndex",
  )
  let hit = {
    ...hit,
    _snippetResult: {
      content: Nullable.make(highlightedValue("See <mark>Array.map</mark> on MDN.")),
    },
  }

  expect(SearchResults.getHighlightedTitle(hit))->toBe("<mark>map</mark>WithIndex")
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

    expect(SearchResults.getHighlightedTitle(hit))->toBe("<mark>Section</mark> title")
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

  expect(SearchResults.getContentHtml(hit))->toEqual(
    Some("map(array, fn) returns a new <mark>array</mark>."),
  )
})

test("hitComponent routes relative hit URLs through React Router", async () => {
  await viewport(1440, 500)

  let hit = makeHit(~type_=Lvl1, ~url="/docs/manual/api/stdlib/list/")

  let screen = await render(
    <ReactRouter.MemoryRouter initialEntries=["/"]>
      <CurrentPath />
      <SearchHit hit />
    </ReactRouter.MemoryRouter>,
  )

  await element(await screen->getByText("/"))->toBeVisible
  await (await screen->getByText("Test Page"))->click
  await element(await screen->getByText("/docs/manual/api/stdlib/list/"))->toBeVisible
})

test(
  "getContentHtml falls back to plain content when crawler hit has no snippet result",
  async () => {
    let hit: DocSearch.docSearchHit = Obj.magic(
      Dict.fromArray([
        ("objectID", "crawler-hit"),
        ("content", "map(array, fn) returns a new array."),
        ("url", "https://rescript-lang.org/docs/manual/api/stdlib/array/#value-map"),
        ("type", "content"),
        (
          "hierarchy",
          Obj.magic(
            Dict.fromArray([
              ("lvl0", Obj.magic("Array")),
              ("lvl1", Obj.magic("map")),
              ("lvl2", Obj.magic(Nullable.null)),
              ("lvl3", Obj.magic(Nullable.null)),
              ("lvl4", Obj.magic(Nullable.null)),
              ("lvl5", Obj.magic(Nullable.null)),
              ("lvl6", Obj.magic(Nullable.null)),
            ]),
          ),
        ),
      ]),
    )

    expect(SearchResults.getContentHtml(hit))->toEqual(Some("map(array, fn) returns a new array."))
  },
)

test("search error boundary catches render errors without replacing surrounding page", async () => {
  await viewport(1440, 500)
  let closed = ref(false)

  let screen = await render(
    <div>
      <span> {React.string("Docs page stays rendered")} </span>
      <SearchErrorBoundary onClose={() => closed := true}>
        <ThrowsOnRender />
      </SearchErrorBoundary>
    </div>,
  )

  await element(await screen->getByText("Docs page stays rendered"))->toBeVisible
  await element(await screen->getByText("Search unavailable"))->toBeVisible
  await (await screen->getByLabelText("Close search"))->click
  expect(closed.contents)->toBe(true)
})

test("loading search can be canceled before the modal is available", async () => {
  let closed = ref(false)
  let screen = await render(<SearchNotice kind=#Loading onClose={() => closed := true} />)

  await element(await screen->getByText("Loading search"))->toBeVisible
  await (await screen->getByLabelText("Close search"))->click
  expect(closed.contents)->toBe(true)
})

// ---------------------------------------------------------------------------
// isChildHit
// ---------------------------------------------------------------------------

test("isChildHit treats Lvl2 as a child hit", async () => {
  expect(SearchResults.isChildHit(makeHit(~type_=Lvl2, ~url="https://example.com/page")))->toBe(
    true,
  )
})

test("search subtitles omit top-level, missing, and empty parent titles", async () => {
  let topLevel = makeHit(~type_=Lvl1, ~url="/docs/manual")
  let child = makeHit(~type_=Lvl2, ~url="/docs/manual#child")

  expect(SearchResults.getSubtitle({...topLevel, type_: Lvl0}))->toEqual(None)
  expect(SearchResults.getSubtitle(topLevel))->toEqual(None)
  expect(SearchResults.getSubtitle(child))->toEqual(Some("Test Page"))
  expect(
    SearchResults.getSubtitle({...child, hierarchy: {...child.hierarchy, lvl1: Nullable.null}}),
  )->toEqual(None)
  expect(
    SearchResults.getSubtitle({
      ...child,
      hierarchy: {...child.hierarchy, lvl1: Nullable.make("")},
    }),
  )->toEqual(None)
})

test("search state opens once and closes from active or inactive", async () => {
  let modal = SearchModal.make
  let anotherModal = React.lazy_(() => import(SearchModal.make))
  let active = Search.reduce(Inactive, Open(modal))

  expect(active)->toEqual(Search.Active(modal))
  expect(Search.reduce(active, Open(anotherModal)))->toEqual(active)
  expect(Search.reduce(active, Close))->toEqual(Search.Inactive)
  expect(Search.reduce(Inactive, Close))->toEqual(Search.Inactive)
})

test("isChildHit treats Lvl3 as a child hit", async () => {
  expect(SearchResults.isChildHit(makeHit(~type_=Lvl3, ~url="https://example.com/page")))->toBe(
    true,
  )
})

test("isChildHit treats Lvl4 as a child hit", async () => {
  expect(SearchResults.isChildHit(makeHit(~type_=Lvl4, ~url="https://example.com/page")))->toBe(
    true,
  )
})

test("isChildHit treats Lvl5 as a child hit", async () => {
  expect(SearchResults.isChildHit(makeHit(~type_=Lvl5, ~url="https://example.com/page")))->toBe(
    true,
  )
})

test("isChildHit treats Lvl6 as a child hit", async () => {
  expect(SearchResults.isChildHit(makeHit(~type_=Lvl6, ~url="https://example.com/page")))->toBe(
    true,
  )
})

test("isChildHit treats Content as a child hit", async () => {
  expect(SearchResults.isChildHit(makeHit(~type_=Content, ~url="https://example.com/page")))->toBe(
    true,
  )
})

test("isChildHit treats Lvl2 as a child hit even without a hash in the URL", async () => {
  expect(SearchResults.isChildHit(makeHit(~type_=Lvl2, ~url="https://example.com/no-hash")))->toBe(
    true,
  )
})

test("isChildHit treats Content as a child hit even with a hash in the URL", async () => {
  expect(
    SearchResults.isChildHit(makeHit(~type_=Content, ~url="https://example.com/page#section")),
  )->toBe(true)
})

test("isChildHit treats Lvl0 without a hash as not a child hit", async () => {
  expect(SearchResults.isChildHit(makeHit(~type_=Lvl0, ~url="https://example.com/page")))->toBe(
    false,
  )
})

test("isChildHit treats Lvl0 with a hash as a child hit", async () => {
  expect(
    SearchResults.isChildHit(makeHit(~type_=Lvl0, ~url="https://example.com/page#section")),
  )->toBe(true)
})

test("isChildHit treats Lvl0 with a trailing # as a child hit", async () => {
  expect(SearchResults.isChildHit(makeHit(~type_=Lvl0, ~url="https://example.com/page#")))->toBe(
    true,
  )
})

test("isChildHit treats Lvl1 without a hash as not a child hit", async () => {
  expect(SearchResults.isChildHit(makeHit(~type_=Lvl1, ~url="https://example.com/page")))->toBe(
    false,
  )
})

test("isChildHit treats Lvl1 with a hash as a child hit", async () => {
  expect(
    SearchResults.isChildHit(makeHit(~type_=Lvl1, ~url="https://example.com/page#heading")),
  )->toBe(true)
})

test("isChildHit treats Lvl1 with a deeply nested hash anchor as a child hit", async () => {
  expect(
    SearchResults.isChildHit(
      makeHit(~type_=Lvl1, ~url="https://example.com/docs/manual/api#some-section"),
    ),
  )->toBe(true)
})

test("isChildHit treats Lvl1 with an empty URL as not a child hit", async () => {
  expect(SearchResults.isChildHit(makeHit(~type_=Lvl1, ~url="")))->toBe(false)
})

test("toRelativeSiteUrl strips the site origin from an absolute URL", async () => {
  let result = SearchResults.toRelativeSiteUrl(
    "https://rescript-lang.org/docs/manual/introduction#what-is-rescript",
    ~siteUrl="https://rescript-lang.org/",
  )

  expect(result)->toBe("/docs/manual/introduction#what-is-rescript")
})

test("toRelativeSiteUrl leaves absolute URLs unchanged when siteUrl is empty", async () => {
  let result = SearchResults.toRelativeSiteUrl(
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
  let result = SearchResults.normalizeHitUrls([hit], ~siteUrl="https://rescript-lang.org/")

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
      (
        "hierarchy",
        Obj.magic(
          Dict.fromArray([
            ("lvl0", Obj.magic("Array")),
            ("lvl1", Obj.magic("map")),
            ("lvl2", Obj.magic(Nullable.null)),
            ("lvl3", Obj.magic(Nullable.null)),
            ("lvl4", Obj.magic(Nullable.null)),
            ("lvl5", Obj.magic(Nullable.null)),
            ("lvl6", Obj.magic(Nullable.null)),
          ]),
        ),
      ),
    ]),
  )

  let result = SearchResults.normalizeHitUrls([hit], ~siteUrl="https://rescript-lang.org/")

  expect(result[0]->Option.map(hit => hit.url))->toEqual(
    Some("/docs/manual/api/stdlib/array/#value-map"),
  )
  expect(result[0]->Option.flatMap(hit => hit.url_without_anchor->Nullable.toOption))->toEqual(
    Some("/docs/manual/api/stdlib/array/"),
  )
})

test("normalizeHitUrls keeps API hit order while separating Belt group labels", async () => {
  let beltHit = withHierarchy(
    {
      ...makeHit(
        ~type_=Content,
        ~url="https://rescript-lang.org/docs/manual/api/belt/array/#value-map",
      ),
      objectID: "belt-array-map",
    },
    ~lvl0="Array",
    ~lvl1="map",
  )
  let stdlibHit = withHierarchy(
    {
      ...makeHit(
        ~type_=Content,
        ~url="https://rescript-lang.org/docs/manual/api/stdlib/array/#value-map",
      ),
      objectID: "stdlib-array-map",
    },
    ~lvl0="Array",
    ~lvl1="map",
  )

  let result = SearchResults.normalizeHitUrls(
    [beltHit, stdlibHit],
    ~siteUrl="https://rescript-lang.org/",
  )

  expect(result[0]->Option.map(hit => hit.objectID))->toEqual(Some("belt-array-map"))
  expect(result[0]->Option.flatMap(hit => hit.hierarchy.lvl0->Nullable.toOption))->toEqual(
    Some("Belt.Array"),
  )
  expect(result[1]->Option.map(hit => hit.objectID))->toEqual(Some("stdlib-array-map"))
  expect(result[1]->Option.flatMap(hit => hit.hierarchy.lvl0->Nullable.toOption))->toEqual(
    Some("Array"),
  )
})

test("renders disabled search copy when Algolia config is missing", async () => {
  await viewport(1440, 500)

  let screen = await render(<Search />)

  await element(await screen->getByText("Search unavailable"))->toBeVisible
  await element(await screen->getByLabelText("Search unavailable for this build"))->toBeVisible
})

test("active DocSearch enables Algolia Insights", async () => {
  await viewport(1440, 500)

  let _screen = await render(
    <ReactRouter.MemoryRouter initialEntries=["/"]>
      <SearchModal
        apiKey="test-api-key" appId="TESTAPP" indexName="test_index" onClose={() => ()}
      />
    </ReactRouter.MemoryRouter>,
  )

  let hasInsightsScript = switch WebAPI.Document.querySelector(
    document,
    "script[src*='search-insights']",
  ) {
  | Value(_) => true
  | Null => false
  }

  expect(hasInsightsScript)->toBe(true)
})

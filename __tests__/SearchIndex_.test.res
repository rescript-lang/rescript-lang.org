open Vitest

// ---------------------------------------------------------------------------
// maxContentLength
// ---------------------------------------------------------------------------

test("maxContentLength is 500", async () => {
  expect(SearchIndex.maxContentLength)->toBe(500)
})

// ---------------------------------------------------------------------------
// truncate
// ---------------------------------------------------------------------------

test("truncate returns string as-is when shorter than maxLen", async () => {
  expect(SearchIndex.truncate("hello", ~maxLen=10))->toBe("hello")
})

test("truncate returns string as-is when exactly maxLen", async () => {
  expect(SearchIndex.truncate("hello", ~maxLen=5))->toBe("hello")
})

test("truncate truncates and adds ellipsis when longer than maxLen", async () => {
  expect(SearchIndex.truncate("hello world", ~maxLen=5))->toBe("hello...")
})

test("truncate handles empty string", async () => {
  expect(SearchIndex.truncate("", ~maxLen=5))->toBe("")
})

test("truncate handles maxLen=0 with ellipsis", async () => {
  expect(SearchIndex.truncate("abc", ~maxLen=0))->toBe("...")
})

test("truncate truncates to single character with ellipsis", async () => {
  expect(SearchIndex.truncate("abcdef", ~maxLen=1))->toBe("a...")
})

// ---------------------------------------------------------------------------
// slugify
// ---------------------------------------------------------------------------

test("slugify lowercases text", async () => {
  expect(SearchIndex.slugify("Hello World"))->toBe("hello-world")
})

test("slugify replaces spaces with hyphens", async () => {
  expect(SearchIndex.slugify("foo bar baz"))->toBe("foo-bar-baz")
})

test("slugify removes non-alphanumeric characters", async () => {
  expect(SearchIndex.slugify("Hello, World!"))->toBe("hello-world")
})

test("slugify collapses multiple spaces into a single hyphen", async () => {
  expect(SearchIndex.slugify("foo   bar"))->toBe("foo-bar")
})

test("slugify handles empty string", async () => {
  expect(SearchIndex.slugify(""))->toBe("")
})

test("slugify preserves numbers", async () => {
  expect(SearchIndex.slugify("Section 42"))->toBe("section-42")
})

test("slugify removes special characters like parentheses and dots", async () => {
  expect(SearchIndex.slugify("Array.map()"))->toBe("arraymap")
})

test("slugify handles already-slugified text", async () => {
  expect(SearchIndex.slugify("already-slugified"))->toBe("already-slugified")
})

// ---------------------------------------------------------------------------
// stripMdxTags
// ---------------------------------------------------------------------------

test("stripMdxTags removes CodeTab blocks", async () => {
  let input = "before\n<CodeTab labels=[\"RE\"]>\nsome code\n</CodeTab>\nafter"
  expect(SearchIndex.stripMdxTags(input))->toBe("before\nafter")
})

test("stripMdxTags removes HTML tags", async () => {
  expect(SearchIndex.stripMdxTags("<div>hello</div>"))->toBe("hello")
})

test("stripMdxTags removes fenced code blocks", async () => {
  let input = "before\n```rescript\nlet x = 1\n```\nafter"
  expect(SearchIndex.stripMdxTags(input))->toBe("before\nafter")
})

test("stripMdxTags strips inline code backticks", async () => {
  expect(SearchIndex.stripMdxTags("use `Array.map` here"))->toBe("use Array.map here")
})

test("stripMdxTags strips bold markers", async () => {
  expect(SearchIndex.stripMdxTags("this is **bold** text"))->toBe("this is bold text")
})

test("stripMdxTags strips italic markers", async () => {
  expect(SearchIndex.stripMdxTags("this is *italic* text"))->toBe("this is italic text")
})

test("stripMdxTags strips markdown links while keeping link text", async () => {
  expect(SearchIndex.stripMdxTags("click [here](https://example.com) now"))->toBe("click here now")
})

test("stripMdxTags removes heading markers", async () => {
  expect(SearchIndex.stripMdxTags("## My Heading"))->toBe("My Heading")
})

test("stripMdxTags removes h1 through h6 markers", async () => {
  let input = "# H1\n## H2\n### H3\n#### H4\n##### H5\n###### H6"
  expect(SearchIndex.stripMdxTags(input))->toBe("H1\nH2\nH3\nH4\nH5\nH6")
})

test("stripMdxTags collapses multiple newlines to a single newline", async () => {
  expect(SearchIndex.stripMdxTags("a\n\n\nb"))->toBe("a\nb")
})

test("stripMdxTags handles empty string", async () => {
  expect(SearchIndex.stripMdxTags(""))->toBe("")
})

test("stripMdxTags handles combined markdown formatting", async () => {
  let input = "Use **`Array.map`** to [transform](http://x.com) items."
  let result = SearchIndex.stripMdxTags(input)
  expect(result)->toBe("Use Array.map to transform items.")
})

// ---------------------------------------------------------------------------
// cleanDocstring
// ---------------------------------------------------------------------------

test("cleanDocstring returns simple text as-is", async () => {
  expect(SearchIndex.cleanDocstring("Simple description"))->toBe("Simple description")
})

test("cleanDocstring takes content before first ## heading", async () => {
  let input = "Intro text\n## Details\nMore info"
  expect(SearchIndex.cleanDocstring(input))->toBe("Intro text")
})

test("cleanDocstring takes content before first code block", async () => {
  let input = "Intro text\n```rescript\nlet x = 1\n```"
  expect(SearchIndex.cleanDocstring(input))->toBe("Intro text")
})

test("cleanDocstring strips inline code backticks", async () => {
  expect(SearchIndex.cleanDocstring("Returns `true` or `false`"))->toBe("Returns true or false")
})

test("cleanDocstring strips bold formatting", async () => {
  expect(SearchIndex.cleanDocstring("This is **important**"))->toBe("This is important")
})

test("cleanDocstring strips italic formatting", async () => {
  expect(SearchIndex.cleanDocstring("This is *emphasized*"))->toBe("This is emphasized")
})

test("cleanDocstring strips markdown links", async () => {
  expect(SearchIndex.cleanDocstring("See [docs](http://example.com)"))->toBe("See docs")
})

test("cleanDocstring collapses multiple newlines to spaces", async () => {
  let input = "line one\n\nline two\n\nline three"
  expect(SearchIndex.cleanDocstring(input))->toBe("line one line two line three")
})

test("cleanDocstring replaces single newlines with spaces", async () => {
  let input = "line one\nline two"
  expect(SearchIndex.cleanDocstring(input))->toBe("line one line two")
})

test("cleanDocstring handles empty string", async () => {
  expect(SearchIndex.cleanDocstring(""))->toBe("")
})

test("cleanDocstring lets headings take priority over code blocks", async () => {
  let input = "Intro\n## Section\nText\n```\ncode\n```"
  expect(SearchIndex.cleanDocstring(input))->toBe("Intro")
})

// ---------------------------------------------------------------------------
// extractIntro
// ---------------------------------------------------------------------------

test("extractIntro extracts text before first ## heading", async () => {
  let input = "Some intro text.\n## First Section\nDetails here."
  let result = SearchIndex.extractIntro(input)
  expect(result)->toBe("Some intro text.")
})

test("extractIntro removes an H1 heading at the start", async () => {
  let input = "# Page Title\nIntro paragraph.\n## Section"
  let result = SearchIndex.extractIntro(input)
  expect(result)->toBe("Intro paragraph.")
})

test("extractIntro returns stripped content when there are no headings", async () => {
  let input = "Just some plain text content."
  expect(SearchIndex.extractIntro(input))->toBe("Just some plain text content.")
})

test("extractIntro handles empty string", async () => {
  expect(SearchIndex.extractIntro(""))->toBe("")
})

test("extractIntro strips MDX tags from the intro", async () => {
  let input = "Use **bold** and `code`.\n## Section"
  expect(SearchIndex.extractIntro(input))->toBe("Use bold and code.")
})

test("extractIntro removes H1 but preserves the rest of the content", async () => {
  let input = "# Title\nFirst paragraph.\nSecond paragraph."
  expect(SearchIndex.extractIntro(input))->toBe("First paragraph.\nSecond paragraph.")
})

// ---------------------------------------------------------------------------
// extractHeadings
// ---------------------------------------------------------------------------

test("extractHeadings extracts h2 headings", async () => {
  let input = "Intro\n## First\nContent one.\n## Second\nContent two."
  let headings = SearchIndex.extractHeadings(input)
  expect(Array.length(headings))->toBe(2)
  expect(headings[0]->Option.map(h => h.level))->toEqual(Some(2))
  expect(headings[0]->Option.map(h => h.text))->toEqual(Some("First"))
  expect(headings[1]->Option.map(h => h.text))->toEqual(Some("Second"))
})

test("extractHeadings extracts h3 headings", async () => {
  let input = "## Parent\n### Child\nSub content."
  let headings = SearchIndex.extractHeadings(input)
  expect(headings[0]->Option.map(h => h.level))->toEqual(Some(2))
  expect(headings[1]->Option.map(h => h.level))->toEqual(Some(3))
  expect(headings[1]->Option.map(h => h.text))->toEqual(Some("Child"))
})

test("extractHeadings does not extract h1 headings", async () => {
  let input = "# Title\nSome text\n## Real Heading\nContent."
  let headings = SearchIndex.extractHeadings(input)
  expect(Array.length(headings))->toBe(1)
  expect(headings[0]->Option.map(h => h.text))->toEqual(Some("Real Heading"))
})

test("extractHeadings returns an empty array when there are no headings", async () => {
  let input = "Just plain text with no headings."
  let headings = SearchIndex.extractHeadings(input)
  expect(Array.length(headings))->toBe(0)
})

test("extractHeadings includes section content between headings", async () => {
  let input = "## Heading\nThis is the content of the section."
  let headings = SearchIndex.extractHeadings(input)
  expect(headings[0]->Option.map(h => h.content))->toEqual(
    Some("This is the content of the section."),
  )
})

test("extractHeadings strips MDX tags from section content", async () => {
  let input = "## Heading\nUse **bold** and `code` here."
  let headings = SearchIndex.extractHeadings(input)
  expect(headings[0]->Option.map(h => h.content))->toEqual(Some("Use bold and code here."))
})

test("extractHeadings truncates section content to maxContentLength", async () => {
  let longContent = String.repeat("a", 600)
  let input = "## Heading\n" ++ longContent
  let headings = SearchIndex.extractHeadings(input)
  let contentLen = headings[0]->Option.map(h => String.length(h.content))->Option.getOr(0)
  // 500 chars + "..." = 503
  expect(contentLen)->toBe(503)
})

test("extractHeadings handles multiple heading levels", async () => {
  let input = "## H2\nA\n### H3\nB\n#### H4\nC\n##### H5\nD\n###### H6\nE"
  let headings = SearchIndex.extractHeadings(input)
  expect(Array.length(headings))->toBe(5)
  expect(headings[0]->Option.map(h => h.level))->toEqual(Some(2))
  expect(headings[1]->Option.map(h => h.level))->toEqual(Some(3))
  expect(headings[2]->Option.map(h => h.level))->toEqual(Some(4))
  expect(headings[3]->Option.map(h => h.level))->toEqual(Some(5))
  expect(headings[4]->Option.map(h => h.level))->toEqual(Some(6))
})

// ---------------------------------------------------------------------------
// makeHierarchy
// ---------------------------------------------------------------------------

test("makeHierarchy creates a hierarchy with only required fields", async () => {
  let h = SearchIndex.makeHierarchy(~lvl0="Docs", ~lvl1="Overview", ())
  expect(h.lvl0)->toBe("Docs")
  expect(h.lvl1)->toBe("Overview")
  expect(h.lvl2)->toEqual(None)
  expect(h.lvl3)->toEqual(None)
  expect(h.lvl4)->toEqual(None)
  expect(h.lvl5)->toEqual(None)
  expect(h.lvl6)->toEqual(None)
})

test("makeHierarchy creates a hierarchy with all optional fields", async () => {
  let h = SearchIndex.makeHierarchy(
    ~lvl0="Docs",
    ~lvl1="Guide",
    ~lvl2="Chapter",
    ~lvl3="Section",
    ~lvl4="Sub A",
    ~lvl5="Sub B",
    ~lvl6="Sub C",
    (),
  )
  expect(h.lvl0)->toBe("Docs")
  expect(h.lvl1)->toBe("Guide")
  expect(h.lvl2)->toEqual(Some("Chapter"))
  expect(h.lvl3)->toEqual(Some("Section"))
  expect(h.lvl4)->toEqual(Some("Sub A"))
  expect(h.lvl5)->toEqual(Some("Sub B"))
  expect(h.lvl6)->toEqual(Some("Sub C"))
})

test("makeHierarchy creates a hierarchy with partial optional fields", async () => {
  let h = SearchIndex.makeHierarchy(~lvl0="API", ~lvl1="Array", ~lvl2="map", ())
  expect(h.lvl2)->toEqual(Some("map"))
  expect(h.lvl3)->toEqual(None)
})

// ---------------------------------------------------------------------------
// optionToJson
// ---------------------------------------------------------------------------

test("optionToJson converts Some to a JSON string", async () => {
  expect(SearchIndex.optionToJson(Some("hello")))->toEqual(JSON.String("hello"))
})

test("optionToJson converts None to JSON null", async () => {
  expect(SearchIndex.optionToJson(None))->toEqual(JSON.Null)
})

test("optionToJson converts Some empty string to a JSON string", async () => {
  expect(SearchIndex.optionToJson(Some("")))->toEqual(JSON.String(""))
})

// ---------------------------------------------------------------------------
// hierarchyToJson
// ---------------------------------------------------------------------------

test("hierarchyToJson serializes a hierarchy with only required fields", async () => {
  let h = SearchIndex.makeHierarchy(~lvl0="Docs", ~lvl1="Page", ())
  let json = SearchIndex.hierarchyToJson(h)
  let expected = {
    let d = Dict.make()
    d->Dict.set("lvl0", JSON.String("Docs"))
    d->Dict.set("lvl1", JSON.String("Page"))
    d->Dict.set("lvl2", JSON.Null)
    d->Dict.set("lvl3", JSON.Null)
    d->Dict.set("lvl4", JSON.Null)
    d->Dict.set("lvl5", JSON.Null)
    d->Dict.set("lvl6", JSON.Null)
    JSON.Object(d)
  }
  expect(json)->toEqual(expected)
})

test("hierarchyToJson serializes optional fields as JSON strings", async () => {
  let h = SearchIndex.makeHierarchy(~lvl0="API", ~lvl1="Array", ~lvl2="map", ())
  let json = SearchIndex.hierarchyToJson(h)
  let expected = {
    let d = Dict.make()
    d->Dict.set("lvl0", JSON.String("API"))
    d->Dict.set("lvl1", JSON.String("Array"))
    d->Dict.set("lvl2", JSON.String("map"))
    d->Dict.set("lvl3", JSON.Null)
    d->Dict.set("lvl4", JSON.Null)
    d->Dict.set("lvl5", JSON.Null)
    d->Dict.set("lvl6", JSON.Null)
    JSON.Object(d)
  }
  expect(json)->toEqual(expected)
})

// ---------------------------------------------------------------------------
// weightToJson
// ---------------------------------------------------------------------------

test("weightToJson serializes weight to a JSON object with number values", async () => {
  let w: SearchIndex.weight = {pageRank: 10, level: 80, position: 3}
  let json = SearchIndex.weightToJson(w)
  let expected = {
    let d = Dict.make()
    d->Dict.set("pageRank", JSON.Number(10.0))
    d->Dict.set("level", JSON.Number(80.0))
    d->Dict.set("position", JSON.Number(3.0))
    JSON.Object(d)
  }
  expect(json)->toEqual(expected)
})

test("weightToJson serializes zero values correctly", async () => {
  let w: SearchIndex.weight = {pageRank: 0, level: 0, position: 0}
  let json = SearchIndex.weightToJson(w)
  let expected = {
    let d = Dict.make()
    d->Dict.set("pageRank", JSON.Number(0.0))
    d->Dict.set("level", JSON.Number(0.0))
    d->Dict.set("position", JSON.Number(0.0))
    JSON.Object(d)
  }
  expect(json)->toEqual(expected)
})

// ---------------------------------------------------------------------------
// toJson
// ---------------------------------------------------------------------------

test("toJson serializes a full record with all fields", async () => {
  let r: SearchIndex.record = {
    objectID: "docs/overview",
    url: "/docs/overview#intro",
    url_without_anchor: "/docs/overview",
    anchor: Some("intro"),
    content: Some("Introduction text"),
    type_: "lvl2",
    hierarchy: SearchIndex.makeHierarchy(~lvl0="Docs", ~lvl1="Overview", ~lvl2="Intro", ()),
    weight: {pageRank: 5, level: 80, position: 1},
  }
  let json = SearchIndex.toJson(r)

  let expected = {
    let d = Dict.make()
    d->Dict.set("objectID", JSON.String("docs/overview"))
    d->Dict.set("url", JSON.String("/docs/overview#intro"))
    d->Dict.set("url_without_anchor", JSON.String("/docs/overview"))
    d->Dict.set("anchor", JSON.String("intro"))
    d->Dict.set("content", JSON.String("Introduction text"))
    d->Dict.set("type", JSON.String("lvl2"))
    d->Dict.set(
      "hierarchy",
      {
        let hd = Dict.make()
        hd->Dict.set("lvl0", JSON.String("Docs"))
        hd->Dict.set("lvl1", JSON.String("Overview"))
        hd->Dict.set("lvl2", JSON.String("Intro"))
        hd->Dict.set("lvl3", JSON.Null)
        hd->Dict.set("lvl4", JSON.Null)
        hd->Dict.set("lvl5", JSON.Null)
        hd->Dict.set("lvl6", JSON.Null)
        JSON.Object(hd)
      },
    )
    d->Dict.set(
      "weight",
      {
        let wd = Dict.make()
        wd->Dict.set("pageRank", JSON.Number(5.0))
        wd->Dict.set("level", JSON.Number(80.0))
        wd->Dict.set("position", JSON.Number(1.0))
        JSON.Object(wd)
      },
    )
    JSON.Object(d)
  }
  expect(json)->toEqual(expected)
})

test("toJson serializes a record with None optional fields as null", async () => {
  let r: SearchIndex.record = {
    objectID: "page",
    url: "/page",
    url_without_anchor: "/page",
    anchor: None,
    content: None,
    type_: "lvl1",
    hierarchy: SearchIndex.makeHierarchy(~lvl0="Cat", ~lvl1="Page", ()),
    weight: {pageRank: 1, level: 100, position: 0},
  }
  let json = SearchIndex.toJson(r)

  let expected = {
    let d = Dict.make()
    d->Dict.set("objectID", JSON.String("page"))
    d->Dict.set("url", JSON.String("/page"))
    d->Dict.set("url_without_anchor", JSON.String("/page"))
    d->Dict.set("anchor", JSON.Null)
    d->Dict.set("content", JSON.Null)
    d->Dict.set("type", JSON.String("lvl1"))
    d->Dict.set(
      "hierarchy",
      {
        let hd = Dict.make()
        hd->Dict.set("lvl0", JSON.String("Cat"))
        hd->Dict.set("lvl1", JSON.String("Page"))
        hd->Dict.set("lvl2", JSON.Null)
        hd->Dict.set("lvl3", JSON.Null)
        hd->Dict.set("lvl4", JSON.Null)
        hd->Dict.set("lvl5", JSON.Null)
        hd->Dict.set("lvl6", JSON.Null)
        JSON.Object(hd)
      },
    )
    d->Dict.set(
      "weight",
      {
        let wd = Dict.make()
        wd->Dict.set("pageRank", JSON.Number(1.0))
        wd->Dict.set("level", JSON.Number(100.0))
        wd->Dict.set("position", JSON.Number(0.0))
        JSON.Object(wd)
      },
    )
    JSON.Object(d)
  }
  expect(json)->toEqual(expected)
})

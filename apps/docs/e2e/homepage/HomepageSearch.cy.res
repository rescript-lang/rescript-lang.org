open Cypress
open HomepageHelpers

let searchChunk = /\/assets\/SearchModal-[^/]+\.js$/
let search = `button[aria-label="Search"]`
let input = `input[placeholder="Search docs"]`
let close = `button[aria-label="Close search"]`
let searchRoute = {hostname: /\.(algolia\.net|algolianet\.com)$/, pathname: /\/queries$/}

let emptyResults = JSON.parseOrThrow(`{
    "results": [{
      "hits": [],
      "nbHits": 0,
      "page": 0,
      "nbPages": 0,
      "hitsPerPage": 20,
      "processingTimeMS": 1,
      "query": "/",
      "index": "test-index"
    }]
  }`)

let installationResults = JSON.parseOrThrow(`{
    "results": [{
      "hits": [{
        "objectID": "installation",
        "url": "https://rescript-lang.org/docs/manual/installation",
        "url_without_anchor": "https://rescript-lang.org/docs/manual/installation",
        "type": "lvl1",
        "anchor": null,
        "content": null,
        "hierarchy": {
          "lvl0": "ReScript",
          "lvl1": "Installation",
          "lvl2": null,
          "lvl3": null,
          "lvl4": null,
          "lvl5": null,
          "lvl6": null
        }
      }],
      "nbHits": 1,
      "page": 0,
      "nbPages": 1,
      "hitsPerPage": 20,
      "processingTimeMS": 1,
      "query": "installation",
      "index": "test-index",
      "queryID": "homepage-search-test"
    }]
  }`)

it("initial homepage assets exclude the search implementation and styles", () => {
  homepageDocument(document => {
    let scripts = document->initialScriptUrls
    let styles =
      document
      ->querySelectorAll(`link[rel="stylesheet"][href]`)
      ->elementsFrom
      ->Array.filterMap(element => element->getAttribute("href")->Null.toOption)
    expect(scripts->Array.length)->greaterThan(0)
    expect(styles->Array.length)->greaterThan(0)
    scripts->Array.forEach(
      asset =>
        request(asset)
        ->then(
          response => {
            expect(response.status, ~message=asset)->equal(200)
            expect(response.body, ~message=asset)->notInclude("search-insights")
            expect(response.body, ~message=asset)->notInclude("DocSearch-Modal")
          },
        )
        ->ignore,
    )
    styles->Array.forEach(
      asset =>
        request(asset)
        ->then(
          response => {
            expect(response.status, ~message=asset)->equal(200)
            expect(response.body, ~message=asset)->notInclude(".DocSearch-Modal")
          },
        )
        ->ignore,
    )
  })
})

it("search loads on activation, stays styled, and supports keyboard reopening", () => {
  interceptStatic(searchRoute, {statusCode: 200, body: emptyResults})
  ->as_("keyboardSearch")
  ->ignore
  let requests = ref([])
  interceptAll("**", request => {
    if request.url->String.includes("search-insights") || searchChunk->RegExp.test(request.url) {
      requests := requests.contents->Array.concat([request.url])
    }
  })->ignore
  visit("/")
  get(search)->should("be.visible")->ignore
  get(input)->should("not.exist")->ignore
  do_(() => expect(requests.contents)->deepEqual([]))->ignore
  get(search)->click->ignore
  get(input)->should("be.focused")->ignore
  do_(() =>
    expect(requests.contents->Array.some(url => searchChunk->RegExp.test(url)))->equal(true)
  )->ignore
  get(".DocSearch-Container")->shouldCss("position", "fixed")->ignore
  get(".DocSearch-Modal")->shouldCss("opacity", "1")->shouldCss("max-width", "768px")->ignore
  realPressKey("Escape")->ignore
  get(input)->should("not.exist")->ignore
  realPressKey("/")->ignore
  get(input)->should("be.focused")->ignore
  realPressKey("/")->ignore
  get(input)->shouldValue("/")->ignore
  wait("@keyboardSearch")->propertyInt("response.statusCode")->shouldEqual(200)->ignore
  realPressKey("Escape")->ignore
  get(input)->shouldValue("")->should("be.focused")->ignore
  realPressKey("Escape")->ignore
  get(input)->should("not.exist")->ignore
  realPressKeys(["Control", "k"])->ignore
  get(input)->should("be.focused")->ignore
  realPressKey("Escape")->ignore
  get(input)->should("not.exist")->ignore
})

it("lazy search results navigate into documentation", () => {
  interceptStatic(searchRoute, {statusCode: 200, body: installationResults})->ignore
  visit("/")
  get(search)->click->ignore
  get(input)->typeText("installation")->ignore
  get(".DocSearch-Modal")->containsChildRegex("a", /^Installation$/)->click->ignore
  cyLocation("pathname")->shouldEqual("/docs/manual/installation")->ignore
  containsInRegex("h1", /^Installation$/)->should("be.visible")->ignore
  get(input)->should("not.exist")->ignore
})

it("a pending search load can be closed without opening the modal afterward", () => {
  let download = Promise.withResolvers()
  interceptDeferred(searchChunk, () => download.promise)->as_("searchChunk")->ignore
  visit("/")
  get(search)->click->ignore
  get(close)->should("be.visible")->ignore
  realPressKey("Escape")->ignore
  get(close)->should("not.exist")->ignore
  get(search)->should("be.focused")->ignore
  do_(() => download.resolve())->ignore
  wait("@searchChunk")->ignore
  get(search)->should("be.focused")->ignore
  get(input)->should("not.exist")->ignore
  get(search)->click->ignore
  get(input)->should("be.focused")->ignore
})

it("a failed search chunk leaves the page usable and recovers after a reload", () => {
  let blockChunk = ref(true)
  interceptPattern(searchChunk, request => {
    if blockChunk.contents {
      request->destroy
    }
  })->ignore
  wrapWithOptions(
    [/Failed to fetch dynamically imported module: .*\/assets\/SearchModal-[^/]+\.js/],
    {log: false},
  )
  ->as_("expectedConsoleErrors")
  ->ignore
  visit("/")
  get(search)->click->ignore
  containsIn(`[role="alert"]`, "Search unavailable")->should("be.visible")->ignore
  get(close)->click->ignore
  get(`[role="alert"]`)->should("not.exist")->ignore
  get(search)->should("be.focused")->ignore
  containsIn("h1", headline)->should("be.visible")->ignore
  do_(() => blockChunk := false)->ignore
  reload()
  get(search)->click->ignore
  get(input)->should("be.focused")->ignore
})

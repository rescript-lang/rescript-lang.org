open Cypress
open HomepageHelpers

let fontFiles = [
  "/fonts/subset-Inter-Regular.woff2",
  "/fonts/subset-Inter-SemiBold.woff2",
  "/fonts/subset-Inter-Bold.woff2",
  "/fonts/red-hat-mono-700.woff2",
]

let fontDescriptions = [
  `400 1rem "Homepage Inter"`,
  `600 1rem "Homepage Inter"`,
  `700 1rem "Homepage Inter"`,
  `700 1rem "Red Hat Mono"`,
]

let expectPreload = (link, href) => {
  expect(link->getAttribute("href")->Null.toOption)->equal(Some(href))
  expect(link->getAttribute("type")->Null.toOption)->equal(Some("font/woff2"))
  expect(link->getAttribute("crossorigin")->Null.toOption)->equal(Some("anonymous"))
  expect(link->getAttribute("media")->Null.toOption)->equal(
    href === "/fonts/subset-Inter-Bold.woff2" ? Some("(min-width: 1024px)") : None,
  )
}

it("homepage prerender includes exactly its four local font preloads", () => {
  homepageDocument(document => {
    let preloads = document->querySelectorAll(`head link[rel="preload"][as="font"]`)->elementsFrom
    expect(preloads->Array.length)->equal(fontFiles->Array.length)
    preloads->Array.forEachWithIndex(
      (link, index) =>
        fontFiles->Array.get(index)->Option.forEach(href => expectPreload(link, href)),
    )
    let html = document->documentElement->outerHTML
    expect(html)->notInclude("fonts.googleapis.com")
    expect(html)->notInclude("fonts.gstatic.com")
  })
})

it("homepage loads all four font faces using only local requests", () => {
  let requests = ref([])
  interceptAll("**", request => {
    let requestUrl = request.url->url
    if (
      request.resourceType === "font" ||
      requestUrl->hostname === "fonts.googleapis.com" ||
      requestUrl->hostname === "fonts.gstatic.com"
    ) {
      requests := requests.contents->Array.concat([requestUrl])
    }
  })->ignore
  visit("/")
  containsIn("h1", headline)->shouldCss("font-weight", "700")->ignore
  cyDocument()
  ->thenPromise(async document => {
    let fontSet = document->Cypress.fonts
    let loaded = await fontDescriptions
    ->Array.map(
      async font => {
        let _ = await fontSet->loadFont(font)
        (font, true)
      },
    )
    ->Promise.all
    expect(loaded)->deepEqual(fontDescriptions->Array.map(font => (font, true)))
    fontDescriptions->Array.map(font => fontSet->checkFont(font))
  })
  ->shouldDeepEqual([true, true, true, true])
  ->ignore
  get("main section")->each(section => wrap(section)->scrollIntoView->ignore)->ignore
  cyDocument()
  ->thenPromise(document => document->fonts->fontsReady)
  ->then(_ => {
    expect(requests.contents->Array.map(requestUrl => requestUrl->pathname))->includeMembers(
      fontFiles,
    )
    let expectedOrigin = baseUrl()->url->urlOrigin
    expect(
      requests.contents->Array.every(requestUrl => requestUrl->urlOrigin === expectedOrigin),
    )->equal(true)
  })
  ->ignore
})

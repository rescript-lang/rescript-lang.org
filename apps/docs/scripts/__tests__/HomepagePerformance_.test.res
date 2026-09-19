open ScriptTest

type asset = {path: string, rawBytes: int, gzipBytes: int}
type assetGroup = {requests: int, rawBytes: int, gzipBytes: int, assets: array<asset>}
type media = {
  images: int,
  imagesMissingWidth: int,
  imagesMissingHeight: int,
  videos: int,
  videosMissingWidth: int,
  videosMissingHeight: int,
  localAssets: int,
}
type report = {javascript: assetGroup, css: assetGroup, bodyElements: int, media: media}
type input = {html: string, readAsset: WebAPI.URLAPI.url => promise<buffer>}
@module("../homepage-performance.mjs")
external createReport: input => promise<report> = "createReport"

let javascript = buffer("console.log('home')")
let css = buffer("body { color: black; }")
let html = `<!doctype html><html><head>
<link rel="modulepreload prefetch" href="/assets/home.js">
<link rel="stylesheet" href="/assets/home.css">
<link rel="preload" as="style" href="/assets/home.css">
<link rel="stylesheet" href="https://fonts.example/font.css">
</head><body><main><img src="/images/home.png"></main>
<video poster="/images/poster.png"></video></body></html>`

let readAsset = async (url: WebAPI.URLAPI.url) => {
  switch url.pathname {
  | "/assets/home.js" => javascript
  | "/assets/home.css" => css
  | "/images/home.png" => buffer("image")
  | "/images/poster.png" => buffer("poster")
  | _ => await readBuffer(join([tmpdir(), "missing-homepage-fixture", url.pathname]))
  }
}

test("createReport measures unique local assets and media contracts", async () => {
  let report = await createReport({html, readAsset})
  expect(report.javascript)->toStrictEqual({
    requests: 1,
    rawBytes: javascript->byteLength,
    gzipBytes: gzip(javascript, {level: 9})->byteLength,
    assets: [
      {
        path: "/assets/home.js",
        rawBytes: javascript->byteLength,
        gzipBytes: gzip(javascript, {level: 9})->byteLength,
      },
    ],
  })
  expect(report.css.requests)->toBe(1)
  expect(report.css.rawBytes)->toBe(css->byteLength)
  expect(report.bodyElements)->toBe(3)
  expect(report.media)->toStrictEqual({
    images: 1,
    imagesMissingWidth: 1,
    imagesMissingHeight: 1,
    videos: 1,
    videosMissingWidth: 1,
    videosMissingHeight: 1,
    localAssets: 2,
  })
})

test("createReport rejects a missing local media asset", async () => {
  await expect(
    createReport({
      html: html->String.replace("/images/home.png", "/images/missing.png"),
      readAsset,
    }),
  )->rejectsWith("Unable to read local asset /images/missing.png")
})

test("createReport rejects an empty initial asset group", async () => {
  await expect(
    createReport({html: "<!doctype html><html><body><main>Home</main></body></html>", readAsset}),
  )->rejectsWith("found no local JavaScript assets")
})

test("createReport reports large assets without imposing a size ceiling", async () => {
  let largeScript = buffer(String.repeat("x", 2_000_000))
  let report = await createReport({
    html,
    readAsset: async url => url.pathname == "/assets/home.js" ? largeScript : await readAsset(url),
  })
  expect(report.javascript.rawBytes)->toBe(2_000_000)
})

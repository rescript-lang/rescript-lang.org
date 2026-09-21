open Cypress
open HomepageHelpers

type candidate = {url: string, width: int}

let responsiveNames = [
  "ReScript community photo 1",
  "ReScript editor tooling",
  "ReScript JavaScript output",
]

let candidates = sourceSet =>
  sourceSet
  ->String.split(",")
  ->Array.map(candidate => {
    let parts = candidate->String.trim->String.split(" ")->Array.filter(part => part !== "")
    {
      url: parts->Array.get(0)->Option.getOrThrow,
      width: parts
      ->Array.get(1)
      ->Option.flatMap(part => part->String.replace("w", "")->Int.fromString)
      ->Option.getOrThrow,
    }
  })

let imagePreloadUrls = document =>
  document
  ->querySelectorAll(`link[rel="preload"][as="image"]`)
  ->elementsFrom
  ->Array.flatMap(link => {
    let sourceUrls =
      link
      ->getAttribute("imagesrcset")
      ->Null.toOption
      ->Option.map(sourceSet => sourceSet->candidates->Array.map(entry => entry.url))
      ->Option.getOr([])
    link
    ->getAttribute("href")
    ->Null.toOption
    ->Option.map(href => [href, ...sourceUrls])
    ->Option.getOr(sourceUrls)
  })

let expectAvailableImage = (url, format) =>
  requestWithOptions({url, encoding: "binary"})->then(response => {
    expect(response.status, ~message=url)->equal(200)
    expect(response.headers->Dict.get("content-type")->Option.getOr(""), ~message=url)->include_(
      `image/${format}`,
    )
    expect(response.body->String.length, ~message=url)->greaterThan(0)
  })

let requireElement = (element, message) => {
  expect(element->Option.isSome, ~message)->equal(true)
  element->Option.getOrThrow
}

let expectAvailableCandidates = (element, format, preloadedImages) => {
  let entries = element->getAttribute("srcset")->Null.toOption->Option.getOr("")->candidates
  expect(entries->Array.map(entry => entry.width))->deepEqual([360, 640, 1000])
  entries->Array.forEach(entry => {
    expect(preloadedImages->Array.includes(entry.url))->equal(false)
    expectAvailableImage(entry.url, format)->ignore
  })
}

let expectResponsivePicture = (picture, preloadedImages) => {
  let sources = picture->querySelectorAllFromElement("source")->elementsFrom
  expect(sources->Array.length)->equal(1)
  let source = sources->Array.get(0)->requireElement("responsive picture source")
  let image =
    picture
    ->querySelectorFromElement("img")
    ->Null.toOption
    ->requireElement("responsive picture image")
  expect(source->getAttribute("type")->Null.toOption)->equal(Some("image/avif"))
  expect(image->getAttribute("loading")->Null.toOption)->equal(Some("lazy"))
  expect(image->getAttribute("decoding")->Null.toOption)->equal(Some("async"))
  let sizes = image->getAttribute("sizes")->Null.toOption->Option.getOrThrow
  expect(sizes === "")->equal(false)
  expect(source->getAttribute("sizes")->Null.toOption)->equal(Some(sizes))
  expectAvailableCandidates(source, "avif", preloadedImages)
  expectAvailableCandidates(image, "webp", preloadedImages)
  expectAvailableImage(image->getAttribute("src")->Null.toOption->Option.getOr(""), "webp")->ignore
}

let mediaBounds = window =>
  window.document
  ->querySelectorAll("main img, main video")
  ->elementsFrom
  ->Array.map(element => {
    let bounds = element->boundingRect
    let hasBox = bounds.width !== 0.0 || bounds.height !== 0.0
    {
      width: bounds.width,
      height: bounds.height,
      top: hasBox ? bounds.top +. window.scrollY : 0.0,
    }
  })

let captureReservedLayout = async window => {
  window.document->body->boundingRect->ignore
  let loadingFonts =
    window.document
    ->fonts
    ->fontFacesFrom
    ->Array.filter(font => font->fontStatus === "loading")
    ->Array.map(font => font->fontLoaded)
  let _ = await loadingFonts->Promise.all
  await Promise.make((resolve, _) =>
    window->windowRequestAnimationFrame(_ => resolve(window->mediaBounds))->ignore
  )
}

let visitBeforeImageResponses = () => {
  let snapshot = Promise.withResolvers()
  let release = snapshot.promise->Promise.then(_ => Promise.resolve())
  interceptDeferredRequest({resourceType: "image"}, _ => release)->ignore
  visitWithOptions(
    "/",
    {
      onBeforeLoad: window =>
        window.document->addEventListenerOnce(
          "DOMContentLoaded",
          () => {
            let capture = async () => {
              let reserved = await window->captureReservedLayout
              snapshot.resolve(reserved)
            }
            capture()->ignore
          },
          {once: true},
        ),
    },
  )
  runPromise(() => snapshot.promise)
}

let decodeHomepageImages = () => {
  get("main section")->each(section => wrap(section)->scrollIntoView->ignore)->ignore
  get("img")
  ->each(image =>
    wrap(image)
    ->scrollIntoView
    ->shouldSatisfy(images => {
      let image = images->item(0)->requireElement("homepage image")
      expect(image->complete, ~message=image->alt)->equal(true)
      expect(image->naturalWidth, ~message=image->alt)->greaterThan(0)
    })
    ->thenPromise(images => images->item(0)->requireElement("homepage image")->decode)
    ->ignore
  )
  ->ignore
  cyWindow()->thenPromise(window => window.document->fonts->fontsReady)->ignore
}

let expectSelectedCandidate = (name, expectedWidth) =>
  get(`img[alt="${name}"]`)
  ->scrollIntoView
  ->thenPromise(async images => {
    let image = images->item(0)->requireElement(name)
    await image->decode
    let source =
      image
      ->parentElement
      ->Nullable.toOption
      ->Option.flatMap(parent => parent->querySelectorFromElement("source")->Null.toOption)
      ->requireElement(`${name} source`)
    let selected =
      source
      ->getAttribute("srcset")
      ->Null.toOption
      ->Option.getOr("")
      ->candidates
      ->Array.find(entry => entry.url->urlWithBase(image->baseURI)->href === image->currentSrc)
      ->requireElement(`${name} selected AVIF candidate`)
    expect(selected.width)->equal(expectedWidth)
    let imageBounds = image->boundingRect
    expect(selected.width->Float.fromInt)->atLeast(imageBounds.width)
  })

it("prerendered homepage reserves dimensions for every image and video", () => {
  homepageDocument(document => {
    let images = document->querySelectorAll("img")->elementsFrom
    let videos = document->querySelectorAll("video")->elementsFrom
    expect(images->Array.length)->equal(63)
    expect(videos->Array.length)->equal(3)
    images
    ->Array.concat(videos)
    ->Array.forEach(
      element => {
        let source =
          element
          ->getAttribute("src")
          ->Null.toOption
          ->Option.orElse(element->getAttribute("poster")->Null.toOption)
          ->Option.getOr("")
        expect(
          element
          ->getAttribute("width")
          ->Null.toOption
          ->Option.flatMap(Float.fromString)
          ->Option.getOr(0.0),
          ~message=source,
        )->greaterThanFloat(0.0)
        expect(
          element
          ->getAttribute("height")
          ->Null.toOption
          ->Option.flatMap(Float.fromString)
          ->Option.getOr(0.0),
          ~message=source,
        )->greaterThanFloat(0.0)
      },
    )
    videos->Array.forEach(
      video => expect(video->getAttribute("preload")->Null.toOption)->equal(Some("none")),
    )
  })
})

it("prerendered responsive media exposes valid AVIF and WebP candidates", () => {
  homepageDocument(document => {
    let pictures = document->querySelectorAll("picture")->elementsFrom
    expect(pictures->Array.length)->equal(3)
    let preloadedImages = document->imagePreloadUrls
    pictures->Array.forEach(picture => expectResponsivePicture(picture, preloadedImages))
  })
})

[375, 1440]->Array.forEach(width => {
  it(`responsive images select appropriately sized files at ${width->Int.toString}px`, () => {
    viewport(width, 900)
    visit("/")
    responsiveNames->Array.forEach(
      name => {
        let expectedWidth = width === 375 && name !== "ReScript community photo 1" ? 360 : 640
        expectSelectedCandidate(name, expectedWidth)->ignore
      },
    )
    [2, 3]->Array.forEach(
      index => {
        get(`button[aria-label="Show community photo ${index->Int.toString}"]`)->click->ignore
        expectSelectedCandidate(`ReScript community photo ${index->Int.toString}`, 640)->ignore
        get(`img[alt="ReScript community photo ${index->Int.toString}"]`)
        ->should("be.visible")
        ->shouldAttribute("width", index === 2 ? "1355" : "1000")
        ->shouldAttribute("height", index === 2 ? "904" : "667")
        ->ignore
      },
    )
  })

  it(
    `homepage media reserves its loaded layout before image responses at ${width->Int.toString}px`,
    () => {
      viewport(width, 900)
      visitBeforeImageResponses()
      ->then(
        reserved => {
          decodeHomepageImages()
          cyWindow()
          ->then(
            window => {
              let loaded = window->mediaBounds
              expect(loaded->Array.length)->equal(reserved->Array.length)
              loaded->Array.forEachWithIndex(
                (bounds, index) => {
                  let expected = reserved->Array.get(index)->Option.getOrThrow
                  expect(bounds.width, ~message=`media ${index->Int.toString} width`)->closeTo(
                    expected.width,
                    0.5,
                  )
                  expect(bounds.height, ~message=`media ${index->Int.toString} height`)->closeTo(
                    expected.height,
                    0.5,
                  )
                  expect(bounds.top, ~message=`media ${index->Int.toString} top`)->closeTo(
                    expected.top,
                    0.5,
                  )
                },
              )
            },
          )
          ->ignore
        },
      )
      ->ignore
    },
  )
})

open Vitest

let metadata: ImageAsset.metadata = {
  availableWidths: [360, 640, 1000],
  imageUrlFor: (width, format) => {
    let format = switch format {
    | #avif => "avif"
    | #webp => "webp"
    }
    Some(`/lp/community-3.avif?width=${width->Int.toString}&format=${format}`)
  },
}

let original: ImageAsset.t = {
  src: "/lp/community-3.avif",
  width: 1000,
  height: 667,
  source: Original,
}

// Source elements have no accessible role; inspect their native media-selection attributes.
let sourceAttribute = name =>
  document
  ->WebAPI.Document.querySelector("picture source")
  ->Null.toOption
  ->Option.flatMap(source => source->WebAPI.Element.getAttribute(name)->Null.toOption)

let imageAttribute = name =>
  document
  ->WebAPI.Document.querySelector("img")
  ->Null.toOption
  ->Option.flatMap(image => image->WebAPI.Element.getAttribute(name)->Null.toOption)

test("original images retain a plain image with dimensions and loading attributes", async () => {
  let screen = await render(
    <ResponsiveImage image=original sizes="343px" alt="Community photo" loading=#lazy />,
  )
  let image = await screen->getByAltText("Community photo")
  await element(image)->toHaveAttribute("src", "/lp/community-3.avif")
  await element(image)->toHaveAttribute("width", "1000")
  await element(image)->toHaveAttribute("height", "667")
  await element(image)->toHaveAttribute("loading", "lazy")
  await element(image)->toHaveAttribute("decoding", "async")
  expect(document->WebAPI.Document.querySelector("picture")->Null.toOption)->toEqual(None)
  expect(imageAttribute("srcset"))->toEqual(None)
})

test("responsive images render one AVIF source and a sized WebP image fallback", async () => {
  let screen = await render(
    <ResponsiveImage
      image={{...original, source: Responsive(metadata)}}
      sizes="(min-width: 768px) 623.2px, 622px"
      alt="Responsive community photo"
      className="gallery-photo"
      loading=#eager
    />,
  )
  let image = await screen->getByAltText("Responsive community photo")
  await element(image)->toHaveAttribute("src", "/lp/community-3.avif?width=1000&format=webp")
  await element(image)->toHaveAttribute(
    "srcset",
    "/lp/community-3.avif?width=360&format=webp 360w, /lp/community-3.avif?width=640&format=webp 640w, /lp/community-3.avif?width=1000&format=webp 1000w",
  )
  await element(image)->toHaveAttribute("sizes", "(min-width: 768px) 623.2px, 622px")
  await element(image)->toHaveAttribute("width", "1000")
  await element(image)->toHaveAttribute("height", "667")
  await element(image)->toHaveAttribute("loading", "eager")
  await element(image)->toHaveClass("gallery-photo")
  expect(sourceAttribute("type"))->toEqual(Some("image/avif"))
  expect(sourceAttribute("sizes"))->toEqual(Some("(min-width: 768px) 623.2px, 622px"))
  expect(sourceAttribute("srcset"))->toEqual(
    Some(
      "/lp/community-3.avif?width=360&format=avif 360w, /lp/community-3.avif?width=640&format=avif 640w, /lp/community-3.avif?width=1000&format=avif 1000w",
    ),
  )
  expect(document->WebAPI.Document.querySelector("source ~ source")->Null.toOption)->toEqual(None)
})

test(
  "unavailable responsive URLs render the valid original without empty source sets",
  async () => {
    let missing = {...metadata, imageUrlFor: (_width, _format) => None}
    let screen = await render(
      <ResponsiveImage
        image={{...original, source: Responsive(missing)}} sizes="343px" alt="Fallback photo"
      />,
    )
    let image = await screen->getByAltText("Fallback photo")
    await element(image)->toHaveAttribute("src", "/lp/community-3.avif")
    expect(imageAttribute("srcset"))->toEqual(None)
    expect(sourceAttribute("srcset"))->toEqual(None)
    expect(document->WebAPI.Document.querySelector("picture")->Null.toOption)->toEqual(None)
  },
)

test(
  "real plugin metadata renders generated assets with the requested image dimensions",
  async () => {
    let screen = await render(
      <ResponsiveImage
        image=LandingPageImages.tooling
        sizes=LandingPageImages.screenshotSizes
        alt="ReScript editor tooling"
      />,
    )
    let image = await screen->getByAltText("ReScript editor tooling")
    await element(image)->toHaveAttribute("width", "1000")
    await element(image)->toHaveAttribute("height", "497")
    await element(image)->toHaveAttribute("sizes", LandingPageImages.screenshotSizes)
    expect(sourceAttribute("type"))->toEqual(Some("image/avif"))
    let generatedWidths = switch LandingPageImages.tooling.source {
    | Original => []
    | Responsive(metadata) => metadata.availableWidths
    }
    expect(generatedWidths)->toEqual([360, 640, 1000])
    let hasGeneratedFallback =
      imageAttribute("src")->Option.map(src =>
        src->String.includes("/@responsive-image/vite-plugin/webp/1000/")
      )
    expect(hasGeneratedFallback)->toEqual(Some(true))
  },
)

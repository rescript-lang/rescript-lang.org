open Vitest

let metadata: ImageAsset.metadata = {
  availableWidths: [360, 640, 1000],
  imageUrlFor: (width, format) => {
    let extension = switch format {
    | #avif => "avif"
    | #webp => "webp"
    }
    Some(`/images/photo-${width->Int.toString}.${extension}`)
  },
}

let original: ImageAsset.t = {
  src: "/images/photo.avif",
  width: 1000,
  height: 667,
  source: Original,
}

test("responsive source sets include every available width for the requested format", async () => {
  expect(ImageAsset.sourceSet(metadata, #avif))->toEqual(
    Some("/images/photo-360.avif 360w, /images/photo-640.avif 640w, /images/photo-1000.avif 1000w"),
  )
  expect(ImageAsset.sourceSet(metadata, #webp))->toEqual(
    Some("/images/photo-360.webp 360w, /images/photo-640.webp 640w, /images/photo-1000.webp 1000w"),
  )
})

test("source sets omit missing and blank image URLs", async () => {
  let partial: ImageAsset.metadata = {
    availableWidths: [360, 640, 1000],
    imageUrlFor: (width, _format) =>
      switch width {
      | 360 => Some("/images/photo-360.avif")
      | 640 => None
      | _ => Some(" ")
      },
  }
  expect(ImageAsset.sourceSet(partial, #avif))->toEqual(Some("/images/photo-360.avif 360w"))
})

test("empty and unavailable candidates omit the source set entirely", async () => {
  expect(ImageAsset.sourceSet({...metadata, availableWidths: []}, #avif))->toEqual(None)
  expect(
    ImageAsset.sourceSet({...metadata, imageUrlFor: (_width, _format) => None}, #webp),
  )->toEqual(None)
})

test("the fallback preserves originals and selects a generated WebP when available", async () => {
  expect(ImageAsset.fallback(original))->toBe("/images/photo.avif")
  expect(ImageAsset.fallback({...original, source: Responsive(metadata)}))->toBe(
    "/images/photo-1000.webp",
  )
})

test("missing or blank generated fallback URLs retain the original image", async () => {
  let missing = {...metadata, imageUrlFor: (_width, _format) => None}
  let blank = {...metadata, imageUrlFor: (_width, _format) => Some("")}
  expect(ImageAsset.fallback({...original, source: Responsive(missing)}))->toBe(
    "/images/photo.avif",
  )
  expect(ImageAsset.fallback({...original, source: Responsive(blank)}))->toBe("/images/photo.avif")
})

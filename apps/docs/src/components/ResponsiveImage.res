@react.component
let make = (~image: ImageAsset.t, ~sizes, ~alt, ~className="", ~loading=?) => {
  let (avifSrcSet, webpSrcSet) = switch image.source {
  | Original => (None, None)
  | Responsive(metadata) => (
      ImageAsset.sourceSet(metadata, #avif),
      ImageAsset.sourceSet(metadata, #webp),
    )
  }
  let img = NativeMedia.createImage({
    className,
    alt,
    src: ImageAsset.fallback(image),
    srcSet: webpSrcSet,
    sizes,
    width: image.width,
    height: image.height,
    loading,
    decoding: #async,
  })

  switch avifSrcSet {
  | None => img
  | Some(srcSet) =>
    <picture>
      <source type_="image/avif" srcSet sizes />
      img
    </picture>
  }
}

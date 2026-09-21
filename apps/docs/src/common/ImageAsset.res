type format = [#avif | #webp]

// Local plugin imports always supply widths; remote image-service metadata is not accepted.
type metadata = {
  availableWidths: array<int>,
  imageUrlFor: (int, format) => option<string>,
}

type source = Original | Responsive(metadata)

type t = {src: string, width: int, height: int, source: source}

let imageUrl = (metadata, width, format) =>
  metadata.imageUrlFor(width, format)->Option.filter(url => url->String.trim !== "")

let sourceSet = (metadata, format) => {
  let candidates =
    metadata.availableWidths->Array.filterMap(width =>
      imageUrl(metadata, width, format)->Option.map(url => `${url} ${width->Int.toString}w`)
    )
  switch candidates {
  | [] => None
  | _ => Some(candidates->Array.join(", "))
  }
}

let fallback = image =>
  switch image.source {
  | Original => image.src
  | Responsive(metadata) => imageUrl(metadata, image.width, #webp)->Option.getOr(image.src)
  }

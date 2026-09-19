type format = [#avif | #webp]
type metadata = {
  availableWidths: array<int>,
  imageUrlFor: (int, format) => option<string>,
}
type source = Original | Responsive(metadata)
type t = {src: string, width: int, height: int, source: source}

let sourceSet: (metadata, format) => option<string>
let fallback: t => string

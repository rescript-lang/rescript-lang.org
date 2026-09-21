// The url marker permits public-file imports; the responsive plugin supplies their metadata.
@module(
  "../../public/lp/community-3.avif?url&w=360;640;1000&format=avif;webp&quality=70&responsive"
)
external community3: ImageAsset.metadata = "default"

@module(
  "../../public/lp/community-2.avif?url&w=360;640;1000&format=avif;webp&quality=70&responsive"
)
external community2: ImageAsset.metadata = "default"

@module(
  "../../public/lp/community-1.avif?url&w=360;640;1000&format=avif;webp&quality=70&responsive"
)
external community1: ImageAsset.metadata = "default"

@module(
  "../../public/lp/editor-tooling-1.avif?url&w=360;640;1000&format=avif;webp&quality=70&responsive"
)
external toolingImage: ImageAsset.metadata = "default"

@module(
  "../../public/lp/easy-to-unadopt.avif?url&w=360;640;1000&format=avif;webp&quality=70&responsive"
)
external unadoptImage: ImageAsset.metadata = "default"

let community: array<ImageAsset.t> = [
  {src: "/lp/community-3.avif", width: 1000, height: 667, source: Responsive(community3)},
  {src: "/lp/community-2.avif", width: 1355, height: 904, source: Responsive(community2)},
  {src: "/lp/community-1.avif", width: 1000, height: 667, source: Responsive(community1)},
]

let tooling: ImageAsset.t = {
  src: "/lp/editor-tooling-1.avif",
  width: 1000,
  height: 497,
  source: Responsive(toolingImage),
}

let unadopt: ImageAsset.t = {
  src: "/lp/easy-to-unadopt.avif",
  width: 1000,
  height: 486,
  source: Responsive(unadoptImage),
}

// Match the grid's column widths; the fixed-height crop needs at least 622px of image width.
let communitySizes = "(min-width: 1188px) 623.2px, (min-width: 1024px) max(622px, calc(60vw - 89.6px)), (min-width: 768px) max(622px, calc(60vw - 51.2px)), (min-width: 576px) max(622px, calc(100vw - 64px)), max(622px, calc(100vw - 32px))"
// The screenshots occupy four columns of the same grid, without cropping.
let screenshotSizes = "(min-width: 1188px) 404.8px, (min-width: 1024px) calc(40vw - 70.4px), (min-width: 768px) calc(40vw - 44.8px), (min-width: 576px) calc(100vw - 64px), calc(100vw - 32px)"

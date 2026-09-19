type fontPreload = {
  rel: string,
  href: string,
  @as("as") as_: string,
  @as("type") type_: string,
  crossOrigin: string,
}

/** Preload the Inter 400/600/700 and Red Hat Mono 700 faces used above the fold. */
let links: unit => array<fontPreload>

let default: unit => React.element

type fontPreload = {
  rel: string,
  href: string,
  @as("as") as_: string,
  @as("type") type_: string,
  crossOrigin: string,
  media?: string,
}

/** Preload above-the-fold faces, including Inter 700 only at the desktop breakpoint. */
let links: unit => array<fontPreload>

let default: unit => React.element

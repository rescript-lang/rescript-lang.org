type fontPreload = {
  rel: string,
  href: string,
  @as("as") as_: string,
  @as("type") type_: string,
  crossOrigin: string,
}

let links: unit => array<fontPreload>

let default: unit => React.element

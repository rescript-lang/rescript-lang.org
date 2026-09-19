type fontPreload = {
  rel: string,
  href: string,
  @as("as") as_: string,
  @as("type") type_: string,
  crossOrigin: string,
}

let fontPreload = href => {
  rel: "preload",
  href,
  as_: "font",
  type_: "font/woff2",
  crossOrigin: "anonymous",
}

let links = () => [
  fontPreload("/fonts/subset-Inter-Regular.woff2"),
  fontPreload("/fonts/subset-Inter-SemiBold.woff2"),
  fontPreload("/fonts/subset-Inter-Bold.woff2"),
  fontPreload("/fonts/red-hat-mono-700.woff2"),
]

let default = () => {
  <>
    <LandingPage />
  </>
}

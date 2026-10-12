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

type loaderData = {playgroundData: LandingPagePlayground.playgroundData}

/** Prerender the fixed example so highlighting and URL compression stay off the client. */
let loader: ReactRouter.Loader.t<loaderData>

@react.component
let default: unit => React.element

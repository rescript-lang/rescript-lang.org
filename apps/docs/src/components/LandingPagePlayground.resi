type playgroundData = {
  rescriptHtml: string,
  javascriptHtml: string,
  playgroundHref: string,
}

/** Render trusted loader markup and reserve space for the decorative images. */
@react.component
let make: (~playgroundData: playgroundData) => React.element

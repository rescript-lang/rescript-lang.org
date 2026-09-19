type playgroundData = {
  rescriptHtml: string,
  javascriptHtml: string,
  playgroundHref: string,
}

/** Render only trusted highlighted markup produced by the homepage loader. */
@react.component
let make: (~playgroundData: playgroundData) => React.element

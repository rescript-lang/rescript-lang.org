type props = {
  @as("data-cy-bootstrap") marker: string,
  suppressHydrationWarning: bool,
  children: string,
}

@module("react")
external createScript: (@as("script") _, props) => React.element = "createElement"

// A text child lets React hydrate the script after Cypress replaces its contents.
let element = () =>
  createScript({
    marker: "",
    suppressHydrationWarning: true,
    children: "/* Cypress bootstrap slot */",
  })

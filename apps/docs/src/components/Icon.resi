module GitHub: {
  @react.component
  let make: (~className: string) => React.element
}

module Npm: {
  @react.component
  let make: (~className: string) => React.element
}
module X: {
  @react.component
  let make: (~className: string) => React.element
}
module Bluesky: {
  @react.component
  let make: (~className: string) => React.element
}
module MagnifierGlass: {
  @react.component
  let make: (~className: string) => React.element
}

module Caret: {
  type direction = [#Up | #Down]
  type size = [#Sm | #Md]

  @react.component
  let make: (~className: string=?, ~size: size=?, ~direction: direction) => React.element
}

module DrawerDots: {
  @react.component
  let make: (~className: string=?) => React.element
}

module CornerLeftUp: {
  @react.component
  let make: (~className: string=?) => React.element
}

module Table: {
  @react.component
  let make: (~className: string=?) => React.element
}

module Close: {
  @react.component
  let make: (~className: string=?) => React.element
}

module ArrowRight: {
  @react.component
  let make: (~className: string=?) => React.element
}

module Discourse: {
  @react.component
  let make: (~className: string=?) => React.element
}

module Hyperlink: {
  @react.component
  let make: (~className: string=?) => React.element
}

module TriangleDown: {
  @react.component
  let make: (~className: string=?) => React.element
}

module ExternalLink: {
  @react.component
  let make: (~className: string=?) => React.element
}

module Copy: {
  @react.component
  let make: (~className: string=?) => React.element
}

module Clipboard: {
  @react.component
  let make: (~className: string=?) => React.element
}

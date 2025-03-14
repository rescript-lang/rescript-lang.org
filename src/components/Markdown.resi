module P: {
  @react.component
  let make: (~children: React.element) => React.element
}

// Used for hero like introduction text in
// e.g Doc sections
module Intro: {
  @react.component
  let make: (~children: React.element) => React.element
}

module Cite: {
  @react.component
  let make: (~author: option<string>, ~children: React.element) => React.element
}

module Info: {
  @react.component
  let make: (~children: React.element) => React.element
}

module Warn: {
  @react.component
  let make: (~children: React.element) => React.element
}

module UrlBox: {
  @react.component
  let make: (~text: string, ~href: string, ~children: Mdx.MdxChildren.t) => React.element
}

// Used for creating invisible, hoverable <a> anchors for url linking
module Anchor: {
  /* let idFormat = (id: string): string => id */

  @react.component
  let make: (~id: string) => React.element
}

module H1: {
  @react.component
  let make: (~children: React.element) => React.element
}

module H2: {
  @react.component
  let make: (~id: string, ~children: React.element) => React.element
}

module H3: {
  @react.component
  let make: (~id: string, ~children: React.element) => React.element
}

module H4: {
  @react.component
  let make: (~id: string, ~children: React.element) => React.element
}

module H5: {
  @react.component
  let make: (~id: string, ~children: React.element) => React.element
}

module Pre: {
  @react.component
  let make: (~children: React.element) => React.element
}

module Table: {
  @react.component
  let make: (~children: React.element) => React.element
}

module Thead: {
  @react.component
  let make: (~children: React.element) => React.element
}

module Th: {
  @react.component
  let make: (~children: React.element) => React.element
}

module Td: {
  @react.component
  let make: (~children: React.element) => React.element
}

module Code: {
  @react.component
  let make: (
    ~className: string=?,
    ~metastring: option<string>,
    ~children: Mdx.Components.unknown,
  ) => React.element
}

module CodeTab: {
  @react.component
  let make: (~children: Mdx.MdxChildren.t, ~labels: array<string>=?) => React.element
}

module Blockquote: {
  @react.component
  let make: (~children: React.element) => React.element
}

module Hr: {
  @react.component
  let make: unit => React.element
}

/*
    This will map either to an external link, or
    an anchor / reference link.

    TODO: Remark / Markdown actually has its own syntax
          for references: e.g. [my article][1]
          but it seems MDX doesn't map this to anything
          specific (It seems as if it was represented as a text
          node inside a <p> tag).

          Example for the AST:
          https://astexplorer.net/#/gist/2befce6edce1475eb4bbec001356b222/cede33d4c7545b8b2d759ded256802036ec3551c

          Possible solution could be to write our own plugin to categorize those
          specific component.
 */
module A: {
  @react.component
  let make: (~href: string, ~target: string=?, ~children: React.element) => React.element
}

module Ul: {
  @react.component
  let make: (~children: React.element) => React.element
}

module Ol: {
  @react.component
  let make: (~children: React.element) => React.element
}

module Li: {
  @react.component
  let make: (~children: React.element) => React.element
}

module Strong: {
  @react.component
  let make: (~children: React.element) => React.element
}

module Image: {
  @react.component
  let make: (
    ~src: string,
    ~size: [#large | #small]=?,
    ~withShadow: bool=?,
    ~caption: string=?,
  ) => React.element
}

module Video: {
  @react.component
  let make: (~src: string, ~caption: string=?) => React.element
}

// Used for the MdxJS Provider

/* Sets our preferred branded styles
   We most likely will never need a different ~components
   option on our website. */

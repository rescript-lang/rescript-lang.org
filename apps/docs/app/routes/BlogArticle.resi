module Params: {
  type t = {slug: string}
}

type props = {
  children: React.element,
  isArchived: bool,
  path: string,
  frontmatter: BlogFrontmatter.t,
}

let make: props => React.element

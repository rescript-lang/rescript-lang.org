type mdxComponent

let arrToReactElement: array<mdxComponent> => React.element

let getMdxType: mdxComponent => string

let getMdxClassName: mdxComponent => option<string>

let fromReactElement: React.element => mdxComponent

module MdxChildren: {
  type unknown
  type t
  type case =
    | String(string)
    | Element(mdxComponent)
    | Array(array<mdxComponent>)
    | Unknown(unknown)
  let classify: t => case
  let getMdxChildren: mdxComponent => t
  let toReactElement: t => React.element
}

module Components: {
  type unknown
}

open WebAPI

type social = X(string) | Bluesky(string)

type author = {
  username: string,
  fullname: string,
  role: string,
  imgUrl: string,
  social: social,
}

type badge =
  | Release
  | Testing
  | Preview
  | Roadmap
  | Community

type attributes = {
  archived: Nullable.t<bool>,
  author: string,
  co_authors: Nullable.t<array<author>>,
  date: DateStr.t,
  previewImg: Nullable.t<string>,
  articleImg: Nullable.t<string>,
  badge: Nullable.t<string>,
  canonical: Path.t,
  category?: string,
  id?: string,
  keywords?: array<string>,
  name?: string,
  description: Nullable.t<string>,
  metaTitle: Nullable.t<string>,
  order?: int,
  path: string,
  section?: string,
  summary?: string,
  status?: string,
  slug: string,
  title: string,
}

type t = {
  __raw: string,
  attributes: attributes,
}

type remarkPlugin

type loadMdxOptions = {remarkPlugins?: array<remarkPlugin>}

@module("react-router-mdx/server")
external loadMdx: (FetchAPI.request, ~options: loadMdxOptions=?) => promise<t> = "loadMdx"

@module("react-router-mdx/client")
external useMdxAttributes: unit => attributes = "useMdxAttributes"

@module("react-router-mdx/client")
external useMdxComponent: (~components: {..}=?) => Jsx.component<'a> = "useMdxComponent"

@module("react-router-mdx/server")
external loadAllMdx: (~filterByPaths: array<string>=?) => promise<array<attributes>> = "loadAllMdx"

@module("react-router-mdx/client")
external useMdxFiles: unit => {..} = "useMdxFiles"

@module("remark-gfm")
external gfm: remarkPlugin = "default"

// The loadAllMdx function logs out all of the file contents as it reads them, which is noisy and not useful.
// We can suppress that logging with this helper function.
let allMdx = await Shims.runWithoutLogging(() => loadAllMdx())

let sortSection = mdxPages =>
  Array.toSorted(mdxPages, (a: attributes, b: attributes) =>
    switch (a.order, b.order) {
    | (Some(a), Some(b)) => a > b ? 1.0 : -1.0
    | _ => -1.0
    }
  )

let groupBySection = mdxPages =>
  Array.reduce(mdxPages, (Dict.make() :> Dict.t<array<attributes>>), (acc, item) => {
    let section = item.section->Option.flatMap(Dict.get(acc, _))
    switch section {
    // If the section already exists, add this item to it
    | Some(section) => section->Array.push(item)
    // otherwise create a new section with this item
    | None => item.section->Option.forEach(section => acc->Dict.set(section, [item]))
    }
    acc
  })

let filterMdxPages = (mdxPages, path) =>
  Array.filter(mdxPages, mdx => (mdx.path :> string)->String.includes(path))

/*
  Abstract type for representing mdx
  components mostly passed as children to
  the component context API
 */
/**
 * The code below is from Next's markdown, and I am not sure it is needed anymore.
 TODO: RR7
 */
type mdxComponent

external fromReactElement: React.element => mdxComponent = "%identity"

external arrToReactElement: array<mdxComponent> => React.element = "%identity"

let getMdxClassName: mdxComponent => option<string> = %raw("element => {
      if(element == null || element.props == null) {
        return;
      }
      return element.props.className;
    }")

let getMdxType: mdxComponent => string = %raw("element => {
      if(element == null || element.props == null) {
        return 'unknown';
      }
      return element.props.mdxType;
    }")

module MdxChildren = {
  type unknown

  type t

  type case =
    | String(string)
    | Element(mdxComponent)
    | Array(array<mdxComponent>)
    | Unknown(unknown)

  let classify = (v: t): case =>
    if %raw(`function (a) { return  a instanceof Array}`)(v) {
      Array((Obj.magic(v): array<mdxComponent>))
    } else if typeof(v) == #string {
      String((Obj.magic(v): string))
    } else if typeof(v) == #object {
      Element((Obj.magic(v): mdxComponent))
    } else {
      Unknown((Obj.magic(v): unknown))
    }

  external toReactElement: t => React.element = "%identity"

  // Sometimes an mdxComponent element can be a string
  // which means it doesn't have any children.
  // We will return the element as its own child then
  let getMdxChildren: mdxComponent => t = %raw("element => {
      if(typeof element === 'string') {
        return element;
      }
      if(element == null || element.props == null || element.props.children == null) {
        return;
      }
      return element.props.children;
    }")
}

module Components = {
  // Used for reflection based logic in
  // components such as `code` or `ul`
  // with runtime reflection
  type unknown
}

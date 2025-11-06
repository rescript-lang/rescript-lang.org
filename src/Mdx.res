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
  path?: string,
  section?: string,
  summary?: string,
  status?: string,
  slug?: string,
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
let allMdx = async () => await Shims.runWithoutLogging(() => loadAllMdx())

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
  Array.filter(mdxPages, mdx => mdx.path->Option.map(String.includes(_, path))->Option.getOr(false))

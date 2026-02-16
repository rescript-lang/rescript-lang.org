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
  canonical: Nullable.t<Path.t>,
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

type tree

type loadMdxOptions = {remarkPlugins?: array<remarkPlugin>}

@module("react-router-mdx/server")
external loadMdx: (WebAPI.FetchAPI.request, ~options: loadMdxOptions=?) => promise<t> = "loadMdx"

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

@module("remark-validate-links")
external validateLinks: remarkPlugin = "default"

@module("mdast-util-to-string")
external childrenToString: {..} => string = "toString"

// The loadAllMdx function logs out all of the file contents as it reads them, which is noisy and not useful.
// We can suppress that logging with this helper function.
let allMdx = async (~filterByPaths: option<array<string>>=?) =>
  await Shims.runWithoutLogging(() => loadAllMdx(~filterByPaths?))

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

@module("unist-util-visit") external visit: (tree, string, {..} => unit) => unit = "visit"

let remarkReScriptPrelude = tree => {
  let prelude = ref("")

  visit(tree, "code", node =>
    if node["lang"] === "res prelude" {
      prelude := prelude.contents + "\n" + node["value"]
    }
  )

  if prelude.contents->String.trim !== "" {
    visit(tree, "code", node => {
      if node["lang"] === "res" {
        let metaString = switch node["meta"]->Nullable.make {
        | Value(value) => value
        | _ => ""
        }

        node["meta"] =
          metaString +
          JSON.stringifyAny(prelude.contents)->Option.mapOr("", prelude => " prelude=" + prelude)

        Console.log2("⇢ Added meta to code block:", node["meta"])
      }
    })
  }
}

let remarkLinkPlugin = (tree, vfile) => {
  visit(tree, "link", node => {
    let url = node["url"]

    // The dev server behaves differently than production builds, so we need to not fail here
    let filePath = switch (vfile["history"][0], Env.dev) {
    | (Some(path), _) => path
    | (None, false) =>
      JsExn.throw(
        `File path not found for vfile: ${JSON.stringifyAny(vfile)->Option.getOr("unknown vfile")}`,
      )
    | (None, true) => ""
    }

    // Direct links to the homepage are OK
    if url == "https://rescript-lang.org" {
      ()
      // Relative paths should be used as much as possible
    } else if url->String.includes("https://rescript-lang.org") {
      JsExn.throw(
        Error(
          `Links to rescript-lang.org are not allowed in MDX files, you should use a relative link instead: ${url} in file ${filePath}`,
        ),
      )
    } else if url->String.startsWith("http") || url->String.startsWith("#") {
      ()
    } else if (
      (!(url->String.includes("api")) && url->String.startsWith("/docs/")) ||
      url->String.startsWith("/blog/") ||
      url->String.startsWith("/community/") ||
      url->String.startsWith("/syntax-lookup/")
    ) {
      JsExn.throw(
        Error(`Link to mdx file should use the relative path: ${url} in file ${filePath}`),
      )
    } else if url->String.startsWith(".") {
      let (path, hash) = {
        let splitHref = url->String.split("#")
        (
          splitHref[0]->Option.getOr("/"),
          splitHref[1]->Option.map(hash => "#" ++ hash)->Option.getOr(""),
        )
      }

      let filePath =
        filePath
        ->String.split("/")
        ->Array.filter(part => !(part->String.includes(".mdx")) || !(part->String.includes(".md")))
        ->Array.join("/")

      // Strip put any file extensions from internal links
      node["url"] =
        Node.Path.resolve(filePath, path)
        ->String.replace(vfile["cwd"] ++ "/markdown-pages", "")
        ->String.replaceAll(".mdx", "")
        ->String.replaceAll(".md", "") ++ hash
    } else if url->String.startsWith("/") {
      ()
    } else {
      JsExn.throw(Error(`Unrecognized link format in MDX: ${url} in file ${filePath}`))
    }
  })
}

external makePlugin: 'a => remarkPlugin = "%identity"

let remarkReScriptPreludePlugin = makePlugin(_options =>
  (tree, _vfile) => remarkReScriptPrelude(tree)
)

let remarkLinkPlugin = makePlugin(_options => (tree, vfile) => remarkLinkPlugin(tree, vfile))

// converts the inner text of headings to kebab-case IDs
let anchorLinkPlugin = (tree, _vfile) => {
  visit(tree, "heading", node => {
    let planText = childrenToString(node)
    let nodeData = switch node["data"] {
    | Some(data) => data
    | None => {
        "hProperties": {
          "id": planText->Url.normalizeAnchor,
          "title": planText,
        },
      }
    }
    node["data"] = nodeData
  })
}

let anchorLinkPlugin = makePlugin(_options => (tree, vfile) => anchorLinkPlugin(tree, vfile))

let plugins = [remarkLinkPlugin, gfm, remarkReScriptPreludePlugin, anchorLinkPlugin]

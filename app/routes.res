open ReactRouter.Routes

let stdlibPaths = {
  let rawFile = await Node.Fs.readFile("./markdown-pages/docs/api/stdlib.json", "utf-8")
  let json = JSON.parseOrThrow(rawFile)
  switch json {
  | Object(json) => Dict.keysToArray(json)
  | _ => []
  }
  ->Array.map(key => "docs/manual/api/" ++ key)
  ->Array.filter(path => path !== "docs/manual/api/stdlib")
}

let beltPaths = {
  let rawFile = await Node.Fs.readFile("./markdown-pages/docs/api/belt.json", "utf-8")
  let json = JSON.parseOrThrow(rawFile)
  switch json {
  | Object(json) => Dict.keysToArray(json)
  | _ => []
  }
  ->Array.map(key => "docs/manual/api/" ++ key)
  ->Array.filter(path => path !== "docs/manual/api/belt")
}

let stdlibRoutes =
  stdlibPaths->Array.map(path => route(path, "./routes/ApiRoute.jsx", ~options={id: path}))

let beltRoutes =
  beltPaths->Array.map(path => route(path, "./routes/ApiRoute.jsx", ~options={id: path}))

let blogArticleRoutes =
  MdxFile.scanPaths(~dir="markdown-pages/blog", ~alias="blog")->Array.map(path =>
    route(path, "./routes/BlogArticleRoute.jsx", ~options={id: path})
  )

let docsManualRoutes =
  MdxFile.scanPaths(~dir="markdown-pages/docs/manual", ~alias="docs/manual")
  ->Array.filter(path => !String.includes(path, "docs/manual/api"))
  ->Array.map(path => route(path, "./routes/DocsManualRoute.jsx", ~options={id: path}))

let docsReactRoutes =
  MdxFile.scanPaths(~dir="markdown-pages/docs/react", ~alias="docs/react")->Array.map(path =>
    route(path, "./routes/DocsReactRoute.jsx", ~options={id: path})
  )

let docsGuidelinesRoutes =
  MdxFile.scanPaths(
    ~dir="markdown-pages/docs/guidelines",
    ~alias="docs/guidelines",
  )->Array.map(path => route(path, "./routes/DocsGuidelinesRoute.jsx", ~options={id: path}))

let mdxRoutes = mdxRoutes("./routes/MdxRoute.jsx")->Array.filter(r => {
  let path = r.path->Option.getOr("")
  !(path->String.startsWith("blog")) &&
  !(path->String.startsWith("docs/manual")) &&
  !(path->String.startsWith("docs/react")) &&
  !(path->String.startsWith("docs/guidelines"))
})

let default = [
  index("./routes/LandingPageRoute.jsx"),
  route("packages", "./routes/PackagesRoute.jsx"),
  route("try", "./routes/TryRoute.jsx"),
  route("syntax-lookup", "./routes/SyntaxLookupRoute.jsx", ~options={id: "syntax-lookup"}),
  route("blog", "./routes/BlogRoute.jsx", ~options={id: "blog-index"}),
  route("blog/archived", "./routes/BlogRoute.jsx", ~options={id: "blog-archived"}),
  route("docs", "./routes/DocsOverview.jsx", ~options={id: "docs-overview"}),
  route("docs/manual/api/stdlib", "./routes/ApiRoute.jsx", ~options={id: "api-stdlib"}),
  route("docs/manual/api/introduction", "./routes/ApiRoute.jsx", ~options={id: "api-intro"}),
  route("docs/manual/api/belt", "./routes/ApiRoute.jsx", ~options={id: "api-belt"}),
  route("docs/manual/api/dom", "./routes/ApiRoute.jsx", ~options={id: "api-dom"}),
  ...stdlibRoutes,
  ...beltRoutes,
  ...blogArticleRoutes,
  ...docsManualRoutes,
  ...docsReactRoutes,
  ...docsGuidelinesRoutes,
  ...mdxRoutes,
  route("*", "./routes/NotFoundRoute.jsx"),
]

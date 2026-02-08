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

let guideRoutes =
  mdxRoutes("./routes/Guide.jsx")->Array.filter(route =>
    route.path->Option.map(path => String.includes(path, "guide/"))->Option.getOr(false)
  )

let mdxRoutes =
  mdxRoutes("./routes/MdxRoute.jsx")->Array.filter(route =>
    route.path->Option.map(path => !String.includes(path, "guide/"))->Option.getOr(true)
  )

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
  ...mdxRoutes,
  route("guides", "./routes/Guides.jsx"),
  ...guideRoutes,
  route("*", "./routes/NotFoundRoute.jsx"),
]

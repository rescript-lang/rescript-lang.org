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
  stdlibPaths->Array.map(path => route(path, "./routes/ApiRoute.mjs", ~options={id: path}))

let beltRoutes =
  beltPaths->Array.map(path => route(path, "./routes/ApiRoute.mjs", ~options={id: path}))

let default = [
  index("./routes/LandingPageRoute.mjs"),
  route("packages", "./routes/PackagesRoute.mjs"),
  route("try", "./routes/TryRoute.mjs"),
  route("syntax-lookup", "./routes/SyntaxLookupRoute.mjs", ~options={id: "syntax-lookup"}),
  route("blog", "./routes/BlogRoute.mjs", ~options={id: "blog-index"}),
  route("blog/archived", "./routes/BlogRoute.mjs", ~options={id: "blog-archived"}),
  route("docs", "./routes/DocsOverview.mjs", ~options={id: "docs-overview"}),
  route("docs/manual/api/stdlib", "./routes/ApiRoute.mjs", ~options={id: "api-stdlib"}),
  route("docs/manual/api/introduction", "./routes/ApiRoute.mjs", ~options={id: "api-intro"}),
  route("docs/manual/api/belt", "./routes/ApiRoute.mjs", ~options={id: "api-belt"}),
  route("docs/manual/api/dom", "./routes/ApiRoute.mjs", ~options={id: "api-dom"}),
  ...stdlibRoutes,
  ...beltRoutes,
  ...mdxRoutes("./routes/MdxRoute.mjs"),
  route("*", "./routes/NotFoundRoute.mjs"),
]

open ReactRouter.Routes
open ReactRouter.Mdx

let stdlibPaths = {
  let rawFile = await Node.Fs.readFile("./docs/api/stdlib.json", "utf-8")
  let json = JSON.parseOrThrow(rawFile)
  switch json {
  | Object(json) => Dict.keysToArray(json)
  | _ => []
  }
  ->Array.map(key => "docs/manual/api/" ++ key)
  ->Array.filter(path => path !== "docs/manual/api/stdlib")
}

let stdlibRoutes =
  stdlibPaths->Array.map(path => route(path, "./routes/ApiRoute.mjs", ~options={id: path}))

let default = [
  index("./routes/LandingPageRoute.mjs"),
  route("packages", "./routes/PackagesRoute.mjs"),
  route("try", "./routes/TryRoute.mjs"),
  route("community", "./routes/CommunityRoute.mjs"),
  route("community/overview", "./routes/CommunityRoute.mjs", ~options={id: "overview"}),
  route("syntax-lookup", "./routes/SyntaxLookupRoute.mjs", ~options={id: "syntax-lookup"}),
  route("blog", "./routes/BlogRoute.mjs"),
  // TODO RR7 get the api index to work with the same template
  // route("docs/manual/api", "./routes/ApiRoute.mjs", ~options={id: "api-index"}),
  route("docs/manual/api/stdlib", "./routes/ApiRoute.mjs", ~options={id: "api-stdlib"}),
  route("docs/manual/api/introduction", "./routes/ApiRoute.mjs", ~options={id: "api-intro"}),
  route("docs/manual/api/belt", "./routes/ApiRoute.mjs", ~options={id: "api-belt"}),
  route("docs/manual/api/dom", "./routes/ApiRoute.mjs", ~options={id: "api-dom"}),
  ...stdlibRoutes,
  ...routes("./routes/MdxRoute.mjs"),
]

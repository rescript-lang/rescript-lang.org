open ReactRouter.Routes
open ReactRouter.Mdx

let default = [
  index("./routes/LandingPageRoute.mjs"),
  route("packages", "./routes/PackagesRoute.mjs"),
  route("try", "./routes/TryRoute.mjs"),
  route("community", "./routes/CommunityRoute.mjs"),
  route("community/overview", "./routes/CommunityRoute.mjs", ~options={id: "overview"}),
  route("syntax-lookup", "./routes/SyntaxLookupRoute.mjs"),
  route("blog", "./routes/BlogRoute.mjs"),
  route("docs/manual/api/stdlib", "./routes/ApiRoute.mjs", ~options={id: "api-stdlib"}),
  route(
    "docs/manual/api/stdlib/bigint", // TODO RR7: generate routes for all api docs
    "./routes/ApiRoute.mjs",
    ~options={id: "api-stdlib-bigint"},
  ),
  route("docs/manual/api/introduction", "./routes/ApiRoute.mjs", ~options={id: "api-intro"}),
  route("docs/manual/api/belt", "./routes/ApiRoute.mjs", ~options={id: "api-belt"}),
  route("docs/manual/api/dom", "./routes/ApiRoute.mjs", ~options={id: "api-dom"}),
  ...routes("./routes/MdxRoute.mjs"),
]

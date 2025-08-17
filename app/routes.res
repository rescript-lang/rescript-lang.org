open ReactRouter.Routes
open ReactRouter.Mdx

let default = [
  index("./routes/LandingPageRoute.mjs"),
  route("try", "./routes/TryRoute.mjs"),
  route("community", "./routes/CommunityRoute.mjs"),
  route("syntax-lookup", "./routes/SyntaxLookupRoute.mjs"),
  route("blog", "./routes/BlogRoute.mjs"),
  ...routes("./routes/MdxRoute.mjs"),
]

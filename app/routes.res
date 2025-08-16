open ReactRouter.Routes
open ReactRouter.Mdx

let default = [
  index("./routes/LandingPageRoute.mjs"),
  route("syntax-lookup", "./routes/SyntaxLookupRoute.mjs"),
  ...routes("./routes/MdxRoute.mjs"),
] // TODO: playground, blog, community, 

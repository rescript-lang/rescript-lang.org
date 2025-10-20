type loaderData = {mdxSources: array<SyntaxLookup.item>}
let loader: ReactRouter.Loader.t<loaderData>
let default: unit => React.element
let convert: Mdx.attributes => SyntaxLookup.item

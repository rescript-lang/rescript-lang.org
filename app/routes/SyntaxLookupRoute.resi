type loaderData = {mdxSources: array<SyntaxLookup.item>}
let loader: ReactRouter.Loader.t<loaderData>
let default: unit => React.element
// TODO: move this out of the route file so it can export only a single react component
let convert: Mdx.attributes => SyntaxLookup.item

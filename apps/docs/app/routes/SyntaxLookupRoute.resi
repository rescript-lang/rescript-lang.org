type loaderData = {mdxSources: array<SyntaxLookup.item>}
@live
let loader: ReactRouter.Loader.t<loaderData>
@live
let default: unit => React.element
// TODO: move this out of the route file so it can export only a single react component
let convert: Mdx.attributes => SyntaxLookup.item

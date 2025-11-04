open ReactRouter
open Mdx

type loaderData = {mdxSources: array<SyntaxLookup.item>}

let convert = (mdx: Mdx.attributes): SyntaxLookup.item => {
  {
    category: SyntaxLookup.Category.fromString(mdx.category->Option.getOrThrow),
    id: mdx.id->Option.getOrThrow,
    keywords: mdx.keywords->Option.getOr([]),
    name: mdx.name->Option.getOrThrow,
    // TODO RR7 this can be removed I think
    children: <div> {React.string("TODO: render MDX here")} </div>,
    status: SyntaxLookup.Status.fromString(mdx.status->Option.getOr("active")),
    summary: mdx.summary->Option.getOrThrow,
    href: mdx.slug->Option.getOrThrow,
  }
}

let loader: Loader.t<loaderData> = async ({request}) => {
  let allMdx = await Shims.runWithoutLogging(() => loadAllMdx())

  let mdxSources =
    allMdx
    ->Array.filter(page => page.path->String.includes("syntax-lookup"))
    ->Array.map(convert)

  {
    mdxSources: mdxSources,
  }
}

let default = () => {
  let {mdxSources} = useLoaderData()
  <>
    <title> {React.string("Syntax Lookup | ReScript API")} </title>
    <SyntaxLookup mdxSources />
  </>
}

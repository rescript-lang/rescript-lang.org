open ReactRouter
type loaderData = {mdxSources: array<SyntaxLookup.item>}

let convert = (mdx: Mdx.attributes): SyntaxLookup.item => {
  {
    category: SyntaxLookup.Category.fromString(mdx.category->Option.getOrThrow),
    id: mdx.id->Option.getOrThrow,
    keywords: mdx.keywords->Option.getOr([]),
    name: mdx.name->Option.getOrThrow,
    status: SyntaxLookup.Status.fromString(mdx.status->Option.getOr("active")),
    summary: mdx.summary->Option.getOrThrow,
    href: mdx.slug->Option.getOrThrow,
  }
}

let loader: Loader.t<loaderData> = async _ => {
  let mdxSources =
    (await MdxFile.loadAllAttributes(~dir="markdown-pages/syntax-lookup"))->Array.map(convert)

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

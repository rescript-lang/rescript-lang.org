open ReactRouter
open Mdx

type loaderData = Mdx.t

let loader: Loader.t<loaderData> = async ({request}) => {
  let res = await loadMdx(request)
  res
}

let default = () => {
  let component = useMdxComponent()
  let attributes = useMdxAttributes()
  <section>
    <h1> {React.string(attributes.title)} </h1>
    {component()}
  </section>
}

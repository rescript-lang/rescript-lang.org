let loader = async () => {
  let props = await Packages.getStaticProps()

  props
}

let default = () => {
  let props = ReactRouter.useLoaderData()
  <>
    <title> {React.string("Package Index | ReScript Documentation")} </title>
    <Packages {...props} />
  </>
}

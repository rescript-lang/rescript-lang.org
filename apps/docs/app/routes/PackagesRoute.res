@live
let loader = async () => {
  let props = await Packages.getStaticProps()

  props
}

@live
let default = () => {
  let props = ReactRouter.useLoaderData()

  <Packages {...props} />
}

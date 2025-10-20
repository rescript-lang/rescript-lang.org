let loader = async () => {
  let props = await Packages.getStaticProps()

  props
}

let default = () => {
  let props = ReactRouter.useLoaderData()
  <Packages {...props} />
}

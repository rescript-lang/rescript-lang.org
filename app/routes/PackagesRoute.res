let loader = async () => {
  let props = await Packages.getStaticProps()

  props
}

let default = () => {
  let props = ReactRouter.useLoaderData()
  <>
    <Meta
      ogSiteName="ReScript Packages"
      title="Package Index | ReScript Documentation"
      description="Official and unofficial resources, libraries and bindings for ReScript"
    />
    <Packages {...props} />
  </>
}

module Card = {
  @react.component
  let make = (~title: string, ~hrefs: array<(string, string)>) => {
    <div className="max-w-84 border border-gray-10 bg-gray-5 px-5 py-8 rounded-lg">
      <h2 className="font-bold text-24 mb-4"> {React.string(title)} </h2>
      <ul>
        {Array.map(hrefs, ((text, href)) =>
          <li key=text className="text-16 mb-1 last:mb-0 text-fire hover:underline">
            <ReactRouter.Link.String to=href> {React.string(text)} </ReactRouter.Link.String>
          </li>
        )->React.array}
      </ul>
    </div>
  }
}

@react.component
let default = (~showVersionSelect=true) => {
  let {pathname} = ReactRouter.useLocation()
  let url = (pathname :> string)->Url.parse

  let version = url->Url.getVersionString

  let languageManual = Constants.languageManual(version)

  let ecosystem = [
    ("Package Index", "/packages"),
    ("rescript-react", "/docs/react/introduction"),
    ("GenType", `/docs/manual/${version}/typescript-integration`),
    ("Reanalyze", "https://github.com/rescript-lang/reanalyze"),
  ]

  <MainLayout>
    <div className="max-w-740 w-full m-auto mt-16 md:mt-6">
      // <div className="mb-6" />
      <Markdown.H1> {React.string("Docs")} </Markdown.H1>

      <div className="grid grid-cols-1 xs:grid-cols-2 gap-8">
        <Card title="Language Manual" hrefs=languageManual />
        <Card title="Ecosystem" hrefs=ecosystem />
        <Card title="Tools" hrefs=Constants.tools />
      </div>
    </div>
  </MainLayout>
}

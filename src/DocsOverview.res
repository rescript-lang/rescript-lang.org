module Card = {
  @react.component
  let make = (~title: string, ~hrefs: array<(string, string)>) => {
    <div className="max-w-[21rem] border border-gray-10 bg-gray-5 px-5 py-8 rounded-lg">
      <h2 className="font-bold text-24 mb-4"> {React.string(title)} </h2>
      <ul>
        {Array.map(hrefs, ((text, href)) =>
          <li key=text className="text-16 mb-1 last:mb-0">
            <Markdown.A href> {React.string(text)} </Markdown.A>
          </li>
        )->React.array}
      </ul>
    </div>
  }
}

@react.component
let default = (~showVersionSelect=true) => {
  let router = Next.Router.useRouter()
  let url = router.route->Url.parse

  let version = url->Url.getVersionString

  let languageManual = Constants.languageManual(version)

  let ecosystem = [
    ("Package Index", "/packages"),
    ("rescript-react", "/docs/react/latest/introduction"),
    ("GenType", `/docs/manual/${version}/typescript-integration`),
    ("Reanalyze", "https://github.com/rescript-lang/reanalyze"),
  ]

  <>
    <div>
      <div className="mb-6" />
      <Markdown.H1> {React.string("Docs")} </Markdown.H1>
    </div>
    <div className="grid grid-cols-1 xs:grid-cols-2 gap-8">
      <Card title="Language Manual" hrefs=languageManual />
      <Card title="Ecosystem" hrefs=ecosystem />
      <Card title="Tools" hrefs=Constants.tools />
    </div>
  </>
}

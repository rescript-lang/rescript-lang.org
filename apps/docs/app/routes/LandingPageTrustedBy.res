@react.component
let make = () => {
  let ourUsersSourcePath = "apps/docs/src/data/OurUsers.res"

  <section dataTestId="landing-trusted-by" className="mt-20 flex flex-col items-center">
    <h3 className="hl-1 text-gray-80 text-center max-w-576 mx-auto">
      {React.string("Trusted by our users")}
    </h3>
    <div
      className="flex flex-wrap mx-4 gap-8 justify-center items-center max-w-xl lg:mx-auto mt-16 mb-16"
    >
      {OurUsers.companies
      ->Array.map(company =>
        switch company {
        | Logo({name, path, url}) =>
          <a key=name href=url rel="noopener noreferrer">
            <img className="hover:opacity-75 max-w-sm h-12" src=path loading=#lazy />
          </a>
        }
      )
      ->React.array}
    </div>
    <a
      href={`https://github.com/rescript-lang/rescript-lang.org/blob/master/${ourUsersSourcePath}`}
    >
      <Button> {React.string("Add Your Logo")} </Button>
    </a>
    <img className="self-start mt-10 max-w-320 opacity-50 max-h-24 w-full" src="/lp/grid.svg" />
  </section>
}

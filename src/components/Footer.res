module Section = {
  @react.component
  let make = (~title, ~children) => {
    <div>
      <span className="block text-gray-60 tracking-wide text-14 uppercase mb-4">
        {React.string(title)}
      </span>
      children
    </div>
  }
}

@react.component
let make = () => {
  let linkClass = "hover:underline hover:pointer"
  let iconLink = "hover:pointer hover:text-gray-60-tr"
  let copyrightYear = Date.make()->Date.getFullYear->Int.toString

  <footer className="flex justify-center border-t border-gray-10">
    <div
      className="flex flex-col md:flex-row justify-between max-w-1280 w-full px-8 py-16 text-gray-80 ">
      <div>
        <img className="w-40 mb-5" src="/static/rescript_logo_black.svg" />
        <div className="text-16">
          <p> {React.string(`© ${copyrightYear} The ReScript Project`)} </p>
          <p>
            {React.string("Software and assets distribution powered by ")}
            <Markdown.A href="https://www.keycdn.com/"> {React.string("KeyCDN")} </Markdown.A>
            {React.string(".")}
          </p>
          <p>
            <a
              target="_blank"
              rel="noopener noreferrer"
              href="https://simpleanalytics.com/rescript-lang.org">
              <img
                className="h-[2.25rem] mt-6"
                src="https://simpleanalyticsbadge.com/rescript-lang.org?counter=true&radius=13"
              />
            </a>
          </p>
        </div>
      </div>
      <div
        className="flex flex-col space-y-16 md:flex-row mt-16 md:mt-0 md:ml-16 md:space-y-0 md:space-x-16">
        <Section title="About">
          <ul className="text-16 text-gray-80-tr space-y-2">
            <li>
              <Next.Link href="/community" className={linkClass}>
                {React.string("Community")}
              </Next.Link>
            </li>
            <li>
              <Next.Link href="/community/association" className={linkClass}>
                {React.string("ReScript Association")}
              </Next.Link>
            </li>
            <li>
              <Next.Link href="/community/donate" className={linkClass}>
                {React.string("Donate")}
              </Next.Link>
            </li>
          </ul>
        </Section>
        <Section title="Find us on">
          <div className="flex space-x-3 text-gray-100">
            <a className=iconLink rel="noopener noreferrer" href=Constants.githubHref>
              <Icon.GitHub className="w-6 h-6" />
            </a>
            <a className=iconLink rel="noopener noreferrer" href=Constants.xHref>
              <Icon.X className="w-6 h-6" />
            </a>
            <a className=iconLink rel="noopener noreferrer" href=Constants.blueSkyHref>
              <Icon.Bluesky className="w-6 h-6" />
            </a>
            <a className=iconLink rel="noopener noreferrer" href=Constants.discourseHref>
              <Icon.Discourse className="w-6 h-6" />
            </a>
          </div>
        </Section>
      </div>
    </div>
  </footer>
}

let make = React.memo(make)

module OtherSellingPoints = {
  @react.component
  let make = () => {
    <section
      className="flex justify-center w-full bg-gray-90 border-t border-gray-80
            px-4 sm:px-8 lg:px-16 pt-24 pb-20 "
    >
      //defines the grid
      <div className="max-w-1060 grid grid-cols-4 md:grid-cols-10 grid-rows-2 gap-8">
        //Large Item
        <div className="pb-24 md:pb-32 row-span-2 row-start-1 col-start-1 col-span-4 md:col-span-6">
          <ImageGallery
            className="w-full "
            imgClassName="w-full h-[25.9rem] object-cover rounded-lg"
            imgSrcs={["/lp/community-3.avif", "/lp/community-2.avif", "/lp/community-1.avif"]}
            imgLoading=#lazy
          />
          <h3 className="hl-3 text-gray-20 mt-4 mb-2">
            {React.string(`A community of programmers who value getting things done`)}
          </h3>
          <p className="body-md text-gray-40">
            {React.string(`No language can be popular without a solid
            community. A great type system isn't useful if library authors
            abuse it. Performance doesn't show if all the libraries are slow.
            Join the ReScript community — A group of companies and individuals
            who deeply care about simplicity, speed and practicality.`)}
          </p>
          <div className="mt-6">
            <a href="https://forum.rescript-lang.org">
              <Button size={Button.Small} kind={Button.PrimaryBlue}>
                {React.string("Join our Forum")}
              </Button>
            </a>
          </div>
        </div>
        // 2 small items
        // Item 2
        <div className="col-span-4 lg:row-start-1">
          <img
            className="w-full rounded-lg border-2 border-turtle-dark"
            src="/lp/editor-tooling-1.avif"
          />
          <h3 className="hl-3 text-gray-20 mt-6 mb-2">
            {React.string(`Tooling that just works out of the box`)}
          </h3>
          <p className="body-md text-gray-40">
            {React.string(`A builtin pretty printer, memory friendly
            VSCode & Vim plugins, a stable type system and compiler that doesn't require lots
            of extra configuration. ReScript brings all the tools you need to
            build reliable JavaScript, Node and ReactJS applications.`)}
          </p>
        </div>
        // Item 3
        <div className="col-span-4 lg:row-start-2">
          <img
            className="w-full rounded-lg border-2 border-fire-30" src="/lp/easy-to-unadopt.avif"
          />
          <h3 className="hl-3 text-gray-20 mt-6 mb-2">
            {React.string(`Easy to adopt — without any lock-in`)}
          </h3>
          <p className="body-md text-gray-40">
            {React.string(`ReScript was made with gradual adoption in mind.  If
            you ever want to go back to plain JavaScript, just remove all
            source files and keep its clean JavaScript output. Tell
            your coworkers that your project will keep functioning with or
            without ReScript!`)}
          </p>
        </div>
        // </div>
      </div>
    </section>
  }
}

module TrustedBy = {
  @react.component
  let make = () => {
    <section className="mt-20 flex flex-col items-center">
      <h3 className="hl-1 text-gray-80 text-center max-w-576 mx-auto">
        {React.string("Trusted by our users")}
      </h3>
      <div
        className="flex flex-wrap mx-4 gap-8 justify-center items-center max-w-xl lg:mx-auto mt-16 mb-16"
      >
        {OurUsers.companies
        ->Array.map(company => {
          let (companyKey, renderedCompany) = switch company {
          | Logo({name, path, url}) => (
              name,
              <a href=url rel="noopener noreferrer">
                <img className="hover:opacity-75 max-w-sm h-12" src=path loading=#lazy />
              </a>,
            )
          }
          <div key=companyKey> renderedCompany </div>
        })
        ->React.array}
      </div>
      <a
        href="https://github.com/rescript-lang/rescript-lang.org/blob/master/src/common/OurUsers.res"
      >
        <Button> {React.string("Add Your Logo")} </Button>
      </a>
      <div className="self-start mt-10 max-w-320 overflow-hidden opacity-50 max-h-24">
        <img className="w-full h-full" src="/lp/grid.svg" />
      </div>
    </section>
  }
}

module CuratedResources = {
  type card = {
    imgSrc: string,
    title: React.element,
    descr: string,
    href: string,
  }

  let cards = [
    {
      imgSrc: "/ic_manual@2x.avif",
      title: React.string("Language Manual"),
      descr: "Look up the basics: Reference for all our language features",
      href: "/docs/manual/introduction",
    },
    {
      imgSrc: "/ic_rescript_react@2x.avif",
      title: React.string("ReScript + React"),
      descr: "First Class bindings for ReactJS used by production users all over the world.",
      href: "/docs/react/introduction",
    },
    {
      imgSrc: "/ic_manual@2x.avif",
      title: React.string("Gradually Adopt ReScript"),
      descr: "Learn how to start using ReScript in your current projects. Try before you buy!",
      href: "/docs/manual/installation#integrate-into-an-existing-js-project",
    },
    {
      imgSrc: "/ic_gentype@2x.avif",
      title: React.string("TypeScript Integration"),
      descr: "Learn how to integrate ReScript in your existing TypeScript codebases.",
      href: "/docs/manual/typescript-integration",
    },
  ]

  let templates = [
    {
      imgSrc: "/nextjs_starter_logo.svg",
      title: <>
        <div> {React.string("ReScript & ")} </div>
        <div className="text-gray-40"> {React.string("NextJS")} </div>
      </>,
      descr: "Get started with our NextJS starter template.",
      href: "https://github.com/rescript-lang/create-rescript-app/blob/master/templates/rescript-template-nextjs/README.md",
    },
    {
      imgSrc: "/vitejs_starter_logo.svg",
      title: <>
        <div> {React.string("ReScript & ")} </div>
        <div className="text-[#6571FB]"> {React.string("ViteJS")} </div>
      </>,
      descr: "Get started with ViteJS and ReScript.",
      href: "https://github.com/rescript-lang/create-rescript-app/blob/master/templates/rescript-template-vite/README.md",
    },
    {
      imgSrc: "/nodejs_starter_logo.svg",
      title: <>
        <div> {React.string("ReScript & ")} </div>
        <div className="text-gray-40" style={{color: "#699D65"}}> {React.string("NodeJS")} </div>
      </>,
      descr: "Get started with ReScript targeting the Node platform.",
      href: "/",
    },
  ]

  @react.component
  let make = () => {
    <section className="bg-gray-100 w-full pb-40 pt-20 ">
      //headline container
      <div
        className="mb-10 max-w-1280 flex flex-col justify-center items-center mx-5 md:mx-8 lg:mx-auto"
      >
        <div className="body-sm md:body-lg text-gray-40 w-40 mb-4 xs:w-auto text-center">
          {React.string("Get up and running with ReScript")}
        </div>
        <h2 className="hl-1 text-gray-20 text-center"> {React.string("Curated resources")} </h2>
      </div>
      <div className="px-5 md:px-8 max-w-1280 mx-auto my-20">
        <div className="body-lg text-center z-2 relative text-gray-40 max-w-48 mx-auto bg-gray-100">
          {React.string("Guides and Docs")}
        </div>
        <hr className="bg-gray-80 h-px border-0 relative -top-3" />
      </div>

      //divider

      //container for guides
      <div>
        <div
          className="grid grid-flow-col grid-cols-2 grid-rows-2 lg:grid-cols-4 lg:grid-rows-1 gap-2 md:gap-4 lg:gap-8 max-w-1280 px-5 md:px-8 mx-auto"
        >
          {cards
          ->Array.mapWithIndex((card, i) =>
            <ReactRouter.Link.String
              key={Int.toString(i)}
              to=card.href
              className="hover:bg-gray-80 bg-gray-90 px-4 md:px-8 pb-0 md:pb-8 relative rounded-xl md:min-w-[196px]"
            >
              <img className="h-[53px] absolute mt-6" src=card.imgSrc loading=#lazy />
              <h5 className="text-gray-10 hl-4 mt-32 h-12"> {card.title} </h5>
              <div className="text-gray-40 mt-2 mb-8 body-sm"> {React.string(card.descr)} </div>
            </ReactRouter.Link.String>
          )
          ->React.array}
        </div>
        //Container for templates
        <div className="px-5 md:px-8 max-w-1280 mx-auto my-20">
          <div className="body-lg text-center z-2 relative text-gray-40 w-32 mx-auto bg-gray-100">
            {React.string("Templates")}
          </div>
          <hr className="bg-gray-80 h-px border-0 relative -top-3" />
        </div>
        <div
          className="grid grid-flow-col grid-cols-2 lg:grid-cols-3 lg:grid-rows-1 gap-2 md:gap-4 lg:gap-8 max-w-1280 px-5 md:px-8 mx-auto"
        >
          {templates
          ->Array.mapWithIndex((card, i) =>
            <a
              key={Int.toString(i)}
              href={card.href}
              className="hover:bg-gray-80 bg-gray-90 px-5 pb-8 relative rounded-xl min-w-[200px]"
            >
              <img className="h-12 absolute mt-5" src=card.imgSrc loading=#lazy />
              <h5 className="text-gray-10 hl-4 mt-32 h-12"> {card.title} </h5>
              <div className="text-gray-40 mt-4 body-sm"> {React.string(card.descr)} </div>
            </a>
          )
          ->React.array}
        </div>
      </div>
    </section>
  }
}

@react.component
let make = (~components=MarkdownComponents.default) => {
  <>
    <Meta
      title="The ReScript Programming Language"
      description="Fast, Simple, Fully Typed JavaScript from the Future"
      keywords=["ReScript", "rescriptlang", "JavaScript", "JS", "TypeScript"]
      ogImage="/Art-3-rescript-launch.avif"
    />
    <div className="mt-4 xs:mt-16">
      <div className="text-gray-80 text-18 z">
        <div className="absolute w-full top-16">
          <Banner>
            {React.string("ReScript 12 is out! Read the ")}
            <ReactRouter.Link to=#"/blog/release-12-0-0" className="underline">
              {React.string("announcement blog post")}
            </ReactRouter.Link>
            {React.string(".")}
          </Banner>
          <div className="relative overflow-hidden pb-32">
            <main className="mt-10 min-w-320 lg:align-center w-full">
              <div className="">
                <div className="w-full">
                  <div className="mt-16 md:mt-32 lg:mt-40 mb-12">
                    <LandingPageIntro />
                  </div>
                  <LandingPagePlaygroundHero />
                  <LandingPageQuickInstall />
                  <LandingPageUniqueSellingPoints />
                  <OtherSellingPoints />
                  <TrustedBy />
                  <CuratedResources />
                </div>
              </div>
            </main>
          </div>
          <Footer />
        </div>
      </div>
    </div>
  </>
}

type card = {
  imgSrc: string,
  title: string,
  descr: string,
  href: string,
}

type templateKind = NextJs | ViteJs | NodeJs

type template = {
  imgSrc: string,
  kind: templateKind,
  descr: string,
  href: string,
}

let cards = [
  {
    imgSrc: "/ic_manual@2x.avif",
    title: "Language Manual",
    descr: "Look up the basics: Reference for all our language features",
    href: "/docs/manual/introduction",
  },
  {
    imgSrc: "/ic_rescript_react@2x.avif",
    title: "ReScript + React",
    descr: "First Class bindings for ReactJS used by production users all over the world.",
    href: "/docs/react/introduction",
  },
  {
    imgSrc: "/ic_manual@2x.avif",
    title: "Gradually Adopt ReScript",
    descr: "Learn how to start using ReScript in your current projects. Try before you buy!",
    href: "/docs/manual/installation#integrate-into-an-existing-js-project",
  },
  {
    imgSrc: "/ic_gentype@2x.avif",
    title: "TypeScript Integration",
    descr: "Learn how to integrate ReScript in your existing TypeScript codebases.",
    href: "/docs/manual/typescript-integration",
  },
]

let templates = [
  {
    imgSrc: "/nextjs_starter_logo.svg",
    kind: NextJs,
    descr: "Get started with our NextJS starter template.",
    href: "https://github.com/rescript-lang/create-rescript-app/blob/master/templates/rescript-template-nextjs/README.md",
  },
  {
    imgSrc: "/vitejs_starter_logo.svg",
    kind: ViteJs,
    descr: "Get started with ViteJS and ReScript.",
    href: "https://github.com/rescript-lang/create-rescript-app/blob/master/templates/rescript-template-vite/README.md",
  },
  {
    imgSrc: "/nodejs_starter_logo.svg",
    kind: NodeJs,
    descr: "Get started with ReScript targeting the Node platform.",
    href: "/",
  },
]

let renderTemplateTitle = kind => {
  switch kind {
  | NextJs =>
    <>
      <span className="block"> {React.string("ReScript & ")} </span>
      <span className="block text-gray-40"> {React.string("NextJS")} </span>
    </>
  | ViteJs =>
    <>
      <span className="block"> {React.string("ReScript & ")} </span>
      <span className="block text-[#6571FB]"> {React.string("ViteJS")} </span>
    </>
  | NodeJs =>
    <>
      <span className="block"> {React.string("ReScript & ")} </span>
      <span className="block text-gray-40" style={{color: "#699D65"}}>
        {React.string("NodeJS")}
      </span>
    </>
  }
}

@react.component
let make = () => {
  <section dataTestId="landing-curated-resources" className="bg-gray-100 w-full pb-40 pt-20 ">
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
            <h5 className="text-gray-10 hl-4 mt-32 h-12"> {React.string(card.title)} </h5>
            <div className="text-gray-40 mt-2 mb-8 body-sm"> {React.string(card.descr)} </div>
          </ReactRouter.Link.String>
        )
        ->React.array}
      </div>
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
        ->Array.mapWithIndex((template, i) =>
          <a
            key={Int.toString(i)}
            href=template.href
            className="hover:bg-gray-80 bg-gray-90 px-5 pb-8 relative rounded-xl min-w-[200px]"
          >
            <img className="h-12 absolute mt-5" src=template.imgSrc loading=#lazy />
            <h5 className="text-gray-10 hl-4 mt-32 h-12"> {renderTemplateTitle(template.kind)} </h5>
            <div className="text-gray-40 mt-4 body-sm"> {React.string(template.descr)} </div>
          </a>
        )
        ->React.array}
      </div>
    </div>
  </section>
}

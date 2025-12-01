// Main unique selling points

module Item = {
  type polygonDirection = Up | Down

  @react.component
  let make = (
    ~caption: string,
    ~title: React.element,
    ~media: React.element=React.string("Placeholder"),
    ~polygonDirection: polygonDirection=Down,
    ~paragraph: React.element,
  ) => {
    let polyPointsLg = switch polygonDirection {
    | Down => "80,0 85,100 100,100 100,0"
    | Up => "85,0 80,100 100,100 100,0"
    }

    let polyPointsMobile = switch polygonDirection {
    | Down => "0,100 100,100 100,70 0,80"
    | Up => "0,100 100,100 100,78 0,72"
    }

    let polyColor = switch polygonDirection {
    | Up => "text-fire"
    | Down => "text-fire-30"
    }

    <div
      className="relative flex justify-center w-full bg-gray-90 px-5 sm:px-8 lg:px-14 overflow-hidden"
    >
      // Content
      <div
        className="relative max-w-1060 z-3 flex flex-wrap justify-center lg:justify-between pb-16 pt-20 md:pb-20 md:pt-32 lg:pb-40 md:space-x-4 w-full"
      >
        <div className="max-w-96 flex flex-col justify-center mb-6 lg:mb-2">
          <div className="hl-overline text-gray-20 mb-4"> {React.string(caption)} </div>
          <h3 className="text-gray-10 mb-4 hl-2 font-semibold"> title </h3>
          <div className="flex">
            <div className="text-gray-30 body-md pr-8"> paragraph </div>
          </div>
        </div>
        //image (right)
        <div className="relative mt-10 lg:mt-0">
          <div
            className="relative w-full z-2 bg-gray-90 flex md:mt-0 items-center justify-center rounded-lg max-w-140 shadow-[0px_4px_55px_0px_rgba(230,72,79,0.10)]"
          >
            media
          </div>
          <img
            className="absolute z-1 bottom-0 right-0 -mb-12 -mr-12 max-w-[20rem]"
            src="/lp/grid2.svg"
          />
        </div>
      </div>
      // Mobile SVG
      <svg
        className={`md:hidden absolute z-1 w-full h-full bottom-0 left-0 ${polyColor}`}
        viewBox="0 0 100 100"
        preserveAspectRatio="none"
      >
        <polygon className="fill-current" points=polyPointsMobile />
      </svg>
      // Tablet / Desktop SVG
      <svg
        className={`hidden md:block absolute z-1 w-full h-full right-0 top-0 ${polyColor}`}
        viewBox="0 0 100 100"
        preserveAspectRatio="none"
      >
        <polygon className="fill-current" points=polyPointsLg />
      </svg>
    </div>
  }
}

let item1 =
  <Item
    caption="Fast and simple"
    title={React.string("The fastest build system on the web")}
    media={<video className="rounded-lg" controls={true} poster={"/lp/fast-build-preview.avif"}>
      <source src="https://assets-17077.kxcdn.com/videos/fast-build-3.mp4" type_="video/mp4" />
    </video>}
    paragraph={<>
      <p>
        {React.string(`ReScript cares about a consistent and fast
      feedback loop for any codebase size. Refactor code, pull complex changes,
      or switch to feature branches as you please. No sluggish CI builds, stale
      caches, wrong type hints, or memory hungry language servers that slow you
      down.`)}
      </p>
      <p className="mt-6">
        // <ReactRouter.Link to={("/docs/manual/build-performance" :> ReactRouter.Link.to)}>
        //   <Button size={Button.Small} kind={Button.PrimaryBlue}>
        //     {React.string("Learn more")}
        //   </Button>
        // </ReactRouter.Link>
      </p>
    </>}
  />

let item2 =
  <Item
    caption="A robust type system"
    title={<span
      className="text-transparent bg-clip-text bg-linear-to-r from-berry-dark-50 to-fire-50"
    >
      {React.string("Type Better")}
    </span>}
    media={<video className="rounded-lg" controls={true} poster={"/lp/type-better-preview.avif"}>
      <source src="https://assets-17077.kxcdn.com/videos/type-better-3.mp4" type_="video/mp4" />
    </video>}
    polygonDirection=Up
    paragraph={React.string(`Every ReScript app is fully typed and provides
      reliable type information for any given value in your program. We
      prioritize simpler types over complex types for the sake of
      clarity and easy debugability. No \`any\`, no magic types, no surprise
      \`undefined\`.
      `)}
  />

let item3 =
  <Item
    caption="Seamless Integration"
    title={<>
      <span className="text-orange-dark"> {React.string("The familiar JS ecosystem")} </span>
      {React.string(" at your fingertips")}
    </>}
    media={<video
      className="rounded-lg" controls={true} poster={"/lp/interop-example-preview.avif"}
    >
      <source src="https://assets-17077.kxcdn.com/videos/interop-example-2.mp4" type_="video/mp4" />
    </video>}
    paragraph={React.string(`Use any library from JavaScript, export ReScript
      libraries to JavaScript, automatically generate TypeScript types. It's
      like you've never left the good parts of JavaScript at all.`)}
  />

@react.component
let make = () => {
  <section className="w-full bg-gray-90 overflow-hidden min-h-148">
    item1
    item2
    item3
  </section>
}

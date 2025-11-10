module Intro = {
  @react.component
  let make = () => {
    <section className="flex justify-center">
      <div className="max-w-1060 flex flex-col items-center px-5 sm:px-8 lg:box-content">
        <h1 className="hl-title text-center max-w-212">
          {React.string("Fast, Simple, Fully Typed JavaScript from the Future")}
        </h1>
        <h2 className="body-lg text-center text-gray-60 my-4 max-w-md">
          {React.string(`ReScript is a robustly typed language that compiles to efficient
            and human-readable JavaScript. It comes with a lightning fast
            compiler toolchain that scales to any codebase size.`)}
        </h2>
        <div className="mt-4 mb-2">
          <Next.Link href="/docs/manual/latest/installation" passHref={true}>
            <Button> {React.string("Get started")} </Button>
          </Next.Link>
        </div>
      </div>
    </section>
  }
}

module PlaygroundHero = {
  type example = {
    res: string,
    js: string,
  }

  let examples = [
    {
      res: `module Button = {
  @react.component
  let make = (~count) => {
    let times = switch count {
    | 1 => "once"
    | 2 => "twice"
    | n => n->Int.toString ++ " times"
    }
    let text = \`Click me $\{times\}\`

    <button> {text->React.string} </button>
  }
}`,
      js: `import * as JsxRuntime from "react/jsx-runtime";

function Playground$Button(props) {
  var count = props.count;
  var times = count !== 1 ? (
    count !== 2 ? count.toString() + " times" : "twice"
  ) : "once";
  var text = "Click me " + times;
  return JsxRuntime.jsx("button", {
    children: text
  });
}

var Button = {
  make: Playground$Button
};

export {
  Button,
}`,
    },
  ]

  @react.component
  let make = () => {
    let (example, _setExample) = React.useState(_ => examples->Array.getUnsafe(0))

    //Playground Section & Background
    <section className="relative mt-20 bg-gray-10">
      <div className="relative flex justify-center w-full">
        <div className="relative w-full pt-6 pb-8 sm:px-8 md:px-16 max-w-[1400px]">
          // Playground widget
          <div
            className="relative z-2 flex flex-col md:flex-row bg-gray-90 mx-auto sm:rounded-lg max-w-[1280px]">
            //Left Side (ReScript)
            <div className="md:w-1/2">
              <div
                className="body-sm text-gray-40 text-center py-3 sm:rounded-t-lg md:rounded-tl-lg bg-gray-100">
                {React.string("Write in ReScript")}
              </div>
              <pre className="text-14 px-8 pt-6 pb-12 whitespace-pre-wrap">
                {HighlightJs.renderHLJS(~darkmode=true, ~code=example.res, ~lang="res", ())}
              </pre>
            </div>
            //Right Side (JavaScript)
            <div className="md:w-1/2 ">
              <div
                className="body-sm text-gray-40 py-3 text-center md:border-l border-gray-80 bg-gray-100 sm:rounded-tr-lg">
                {React.string("Compile to JavaScript")}
              </div>
              <pre
                className="text-14 px-8 pt-6 pb-14 md:border-l border-gray-80 whitespace-pre-wrap">
                {HighlightJs.renderHLJS(~darkmode=true, ~code=example.js, ~lang="js", ())}
              </pre>
            </div>
          </div>

          /* ---Link to Playground--- */
          <div>
            <Next.Link
              href={`/try?code=${LzString.compressToEncodedURIComponent(example.res)}}`}
              className="captions md:px-0 border-b border-gray-40 hover:border-gray-60 text-gray-60">
              {React.string("Edit this example in Playground")}
            </Next.Link>
          </div>
          //
          <div className="hidden md:block">
            <img
              className="absolute z-0 left-0 top-0 -ml-10 -mt-6 h-96 w-96" src="/static/lp/grid.svg"
            />
            <img
              className="absolute z-0 left-0 top-0 -ml-10 mt-10" src="/static/lp/illu_left.png"
            />
          </div>
          <div className="hidden md:block">
            <img
              className="absolute z-0 right-0 bottom-0 -mb-10 mt-24 -mr-10 h-96 w-96"
              src="/static/lp/grid.svg"
            />
            <img
              className="absolute z-3 right-0 bottom-0 -mr-2 mb-10" src="/static/lp/illu_right.png"
            />
          </div>
        </div>
      </div>
    </section>
  }
}

module QuickInstall = {
  module CopyButton = {
    let copyToClipboard: string => bool = %raw(`
  function(str) {
    try {
      const el = document.createElement('textarea');
      el.value = str;
      el.setAttribute('readonly', '');
      el.style.position = 'absolute';
      el.style.left = '-9999px';
      document.body.appendChild(el);
      const selected =
        document.getSelection().rangeCount > 0 ? document.getSelection().getRangeAt(0) : false;
        el.select();
        document.execCommand('copy');
        document.body.removeChild(el);
        if (selected) {
          document.getSelection().removeAllRanges();
          document.getSelection().addRange(selected);
        }
        return true;
      } catch(e) {
        return false;
      }
    }
    `)

    type state =
      | Init
      | Copied
      | Failed

    @react.component
    let make = (~code) => {
      let (state, setState) = React.useState(_ => Init)

      let buttonRef = React.useRef(Nullable.null)

      let onClick = evt => {
        ReactEvent.Mouse.preventDefault(evt)
        if copyToClipboard(code) {
          setState(_ => Copied)
        } else {
          setState(_ => Failed)
        }
      }

      React.useEffect(() => {
        switch state {
        | Copied =>
          let buttonEl = Nullable.toOption(buttonRef.current)->Option.getOrThrow

          // Note on this imperative DOM nonsense:
          // For Tailwind transitions to behave correctly, we need to first paint the DOM element in the tree,
          // and in the next tick, add the opacity-100 class, so the transition animation actually takes place.
          // If we don't do that, the banner will essentially pop up without any animation
          let bannerEl = WebAPI.Document.createElement(document, "div")
          bannerEl.className = "foobar opacity-0 absolute top-0 mt-4 -mr-1 px-2 rounded right-0
            bg-turtle text-gray-80-tr body-sm
            transition-all duration-500 ease-in-out "
          let textNode = WebAPI.Document.createTextNode(document, "Copied!")

          WebAPI.Element.appendChild(bannerEl, textNode)->ignore
          WebAPI.Element.appendChild(buttonEl, bannerEl)->ignore

          let nextFrameId = WebAPI.Window.requestAnimationFrame(window, _ => {
            WebAPI.DOMTokenList.toggle(bannerEl.classList, ~token="opacity-0")->ignore
            WebAPI.DOMTokenList.toggle(bannerEl.classList, ~token="opacity-100")->ignore
          })

          let timeoutId = setTimeout(~handler=() => {
            buttonEl->WebAPI.Element.removeChild(bannerEl)->ignore
            setState(_ => Init)
          }, ~timeout=2000)

          Some(
            () => {
              cancelAnimationFrame(nextFrameId)
              clearTimeout(timeoutId)
            },
          )
        | _ => None
        }
      }, [state])

      <button
        ref={ReactDOM.Ref.domRef((Obj.magic(buttonRef): React.ref<Nullable.t<Dom.element>>))}
        disabled={state === Copied}
        className="relative h-10 w-10 flex justify-center items-center "
        onClick>
        <Icon.Copy className="w-6 h-6 mt-px text-gray-40 hover:cursor-pointer hover:text-gray-80" />
      </button>
    }
  }

  module Instructions = {
    let copyBox = text => {
      <div
        className="flex justify-between items-center pl-6 pr-3 py-3 w-full bg-gray-10 border border-gray-20 rounded max-w-400">
        <span className="font-mono text-14  text-gray-70"> {React.string(text)} </span>
        <CopyButton code=text />
      </div>
    }
    @react.component
    let make = () => {
      <div className="w-full max-w-[400px]">
        <h2 className="hl-3 lg:mt-12"> {React.string("Quick Install")} </h2>
        <div className="captions x text-gray-40 mb-2 mt-1">
          {React.string(
            "You can quickly add ReScript to your existing JavaScript codebase via npm / yarn:",
          )}
        </div>
        <div className="w-full space-y-2"> {copyBox("npm install rescript")} </div>
        <div className="captions x text-gray-40 mb-2 mt-2">
          {React.string("Or generate a new project from the official template with npx:")}
        </div>
        <div className="w-full space-y-2"> {copyBox("npx create-rescript-app")} </div>
      </div>
    }
  }

  @react.component
  let make = () => {
    <section className="my-32 sm:px-4 sm:flex sm:justify-center">
      <div className="max-w-1060 flex flex-col w-full px-5 md:px-8 lg:px-8 lg:box-content ">
        //---Textblock on the left side---
        <div className="relative max-w-112">
          <p
            className="relative z-1 space-y-12 text-gray-80 font-semibold text-24 md:text-32 leading-2">
            <span className="bg-fire-5 rounded-lg border border-fire-10 p-1 ">
              {React.string(`Leverage the full power`)}
            </span>
            {React.string(` of JavaScript in a robustly typed language without the fear of \`any\` types.`)}
          </p>
        </div>
        //spacing between columns
        <div className="w-full mt-12 md:flex flex-col lg:flex-row md:justify-between ">
          <p
            className="relative z-1 text-gray-80 font-semibold text-24 md:text-32 leading-2 max-w-lg">
            {React.string(`ReScript is used to ship and maintain mission-critical products with good UI and UX.`)}
          </p>
          <div className="mt-16 lg:mt-0 self-end max-w-400">
            <Instructions />
          </div>
        </div>
      </div>
    </section>
  }
}

// Main unique selling points
module MainUSP = {
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
        className="relative flex justify-center w-full bg-gray-90 px-5 sm:px-8 lg:px-14 overflow-hidden">
        // Content
        <div
          className="relative max-w-1060 z-3 flex flex-wrap justify-center lg:justify-between pb-16 pt-20 md:pb-20 md:pt-32 lg:pb-40 md:space-x-4 w-full">
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
              className="relative w-full z-2 bg-gray-90 flex md:mt-0 items-center justify-center rounded-lg max-w-140 shadow-[0px_4px_55px_0px_rgba(230,72,79,0.10)]">
              media
            </div>
            <img
              className="absolute z-1 bottom-0 right-0 -mb-12 -mr-12 max-w-[20rem]"
              src="/static/lp/grid2.svg"
            />
          </div>
        </div>
        // Mobile SVG
        <svg
          className={`md:hidden absolute z-1 w-full h-full bottom-0 left-0 ${polyColor}`}
          viewBox="0 0 100 100"
          preserveAspectRatio="none">
          <polygon className="fill-current" points=polyPointsMobile />
        </svg>
        // Tablet / Desktop SVG
        <svg
          className={`hidden md:block absolute z-1 w-full h-full right-0 top-0 ${polyColor}`}
          viewBox="0 0 100 100"
          preserveAspectRatio="none">
          <polygon className="fill-current" points=polyPointsLg />
        </svg>
      </div>
    }
  }

  let item1 =
    <Item
      caption="Fast and simple"
      title={React.string("The fastest build system on the web")}
      media={<video
        className="rounded-lg" controls={true} poster={"/static/lp/fast-build-preview.jpg"}>
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
          <Next.Link href="/docs/manual/latest/build-performance" passHref={true}>
            <Button size={Button.Small} kind={Button.PrimaryBlue}>
              {React.string("Learn more")}
            </Button>
          </Next.Link>
        </p>
      </>}
    />

  let item2 =
    <Item
      caption="A robust type system"
      title={<span
        className="text-transparent bg-clip-text bg-linear-to-r from-berry-dark-50 to-fire-50">
        {React.string("Type Better")}
      </span>}
      media={<video
        className="rounded-lg" controls={true} poster={"/static/lp/type-better-preview.jpg"}>
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
        className="rounded-lg" controls={true} poster={"/static/lp/interop-example-preview.jpg"}>
        <source
          src="https://assets-17077.kxcdn.com/videos/interop-example-2.mp4" type_="video/mp4"
        />
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
}

module OtherSellingPoints = {
  @react.component
  let make = () => {
    <section
      className="flex justify-center w-full bg-gray-90 border-t border-gray-80
            px-4 sm:px-8 lg:px-16 pt-24 pb-20 ">
      //defines the grid
      <div className="max-w-1060 grid grid-cols-4 md:grid-cols-10 grid-rows-2 gap-8">
        //Large Item
        <div className="pb-24 md:pb-32 row-span-2 row-start-1 col-start-1 col-span-4 md:col-span-6">
          <ImageGallery
            className="w-full "
            imgClassName="w-full h-[25.9rem] object-cover rounded-lg"
            imgSrcs={[
              "/static/lp/community-3.jpg",
              "/static/lp/community-2.jpg",
              "/static/lp/community-1.jpg",
            ]}
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
            src="/static/lp/editor-tooling-1.jpg"
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
            className="w-full rounded-lg border-2 border-fire-30"
            src="/static/lp/easy-to-unadopt.jpg"
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
        className="flex flex-wrap mx-4 gap-8 justify-center items-center max-w-xl lg:mx-auto mt-16 mb-16">
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
        href="https://github.com/rescript-lang/rescript-lang.org/blob/master/src/common/OurUsers.res">
        <Button> {React.string("Add Your Logo")} </Button>
      </a>
      <div className="self-start mt-10 max-w-320 overflow-hidden opacity-50 max-h-24">
        <img className="w-full h-full" src="/static/lp/grid.svg" />
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
      imgSrc: "/static/ic_manual@2x.png",
      title: React.string("Language Manual"),
      descr: "Look up the basics: Reference for all our language features",
      href: "/docs/manual/latest/introduction",
    },
    {
      imgSrc: "/static/ic_rescript_react@2x.png",
      title: React.string("ReScript + React"),
      descr: "First Class bindings for ReactJS used by production users all over the world.",
      href: "/docs/react/latest/introduction",
    },
    {
      imgSrc: "/static/ic_manual@2x.png",
      title: React.string("Gradually Adopt ReScript"),
      descr: "Learn how to start using ReScript in your current projects. Try before you buy!",
      href: "/docs/manual/latest/installation#integrate-into-an-existing-js-project",
    },
    {
      imgSrc: "/static/ic_gentype@2x.png",
      title: React.string("TypeScript Integration"),
      descr: "Learn how to integrate ReScript in your existing TypeScript codebases.",
      href: "/docs/manual/latest/typescript-integration",
    },
  ]

  let templates = [
    {
      imgSrc: "/static/nextjs_starter_logo.svg",
      title: <>
        <div> {React.string("ReScript & ")} </div>
        <div className="text-gray-40"> {React.string("NextJS")} </div>
      </>,
      descr: "Get started with our NextJS starter template.",
      href: "https://github.com/rescript-lang/create-rescript-app/blob/master/templates/rescript-template-nextjs/README.md",
    },
    {
      imgSrc: "/static/vitejs_starter_logo.svg",
      title: <>
        <div> {React.string("ReScript & ")} </div>
        <div className="text-[#6571FB]"> {React.string("ViteJS")} </div>
      </>,
      descr: "Get started with ViteJS and ReScript.",
      href: "https://github.com/rescript-lang/create-rescript-app/blob/master/templates/rescript-template-vite/README.md",
    },
    // {
    //   imgSrc: "/static/nodejs_starter_logo.svg",
    //   title: <>
    //     <div> {React.string("ReScript & ")} </div>
    //     <div className="text-gray-40" style={ReactDOM.Style.make(~color="#699D65", ())}>
    //       {React.string("NodeJS")}
    //     </div>
    //   </>,
    //   descr: "Get started with ReScript targeting the Node platform.",
    //   href: "/",
    // },
  ]

  @react.component
  let make = () => {
    <section className="bg-gray-100 w-full pb-40 pt-20 ">
      //headline container
      <div
        className="mb-10 max-w-1280 flex flex-col justify-center items-center mx-5 md:mx-8 lg:mx-auto">
        <div className="body-sm md:body-lg text-gray-40 w-40 mb-4 xs:w-auto text-center">
          {React.string("Get up and running with ReScript")}
        </div>
        <h2 className="hl-1 text-gray-20 text-center"> {React.string("Curated resources")} </h2>
      </div>
      <div className="px-5 md:px-8 max-w-1280 mx-auto my-20">
        <div className="body-lg text-center z-2 relative text-gray-40 max-w-48 mx-auto bg-gray-100">
          {React.string("Guides and Docs")}
        </div>
        <hr className="bg-gray-80 h-px border-0 relative top-[-12px]" />
      </div>

      //divider

      //container for guides
      <div>
        <div
          className="grid grid-flow-col grid-cols-2 grid-rows-2 lg:grid-cols-4 lg:grid-rows-1 gap-2 md:gap-4 lg:gap-8 max-w-1280 px-5 md:px-8 mx-auto">
          {cards
          ->Array.mapWithIndex((card, i) =>
            <Next.Link
              key={Int.toString(i)}
              href={card.href}
              className="hover:bg-gray-80 bg-gray-90 px-4 md:px-8 pb-0 md:pb-8 relative rounded-xl md:min-w-[196px]">
              <img className="h-[53px] absolute mt-6" src=card.imgSrc loading=#lazy />
              <h5 className="text-gray-10 hl-4 mt-32 h-12"> {card.title} </h5>
              <div className="text-gray-40 mt-2 mb-8 body-sm"> {React.string(card.descr)} </div>
            </Next.Link>
          )
          ->React.array}
        </div>
        //Container for templates
        <div className="px-5 md:px-8 max-w-1280 mx-auto my-20">
          <div className="body-lg text-center z-2 relative text-gray-40 w-32 mx-auto bg-gray-100">
            {React.string("Templates")}
          </div>
          <hr className="bg-gray-80 h-px border-0 relative top-[-12px]" />
        </div>
        <div
          className="grid grid-flow-col grid-cols-2 lg:grid-cols-3 lg:grid-rows-1 gap-2 md:gap-4 lg:gap-8 max-w-1280 px-5 md:px-8 mx-auto">
          {templates
          ->Array.mapWithIndex((card, i) =>
            <a
              key={Int.toString(i)}
              href={card.href}
              className="hover:bg-gray-80 bg-gray-90 px-5 pb-8 relative rounded-xl min-w-[200px]">
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

module Sponsors = {
  @react.component
  let make = () => {
    <section className="mt-20 flex flex-col items-center">
      <h3 className="hl-1 text-gray-80 text-center max-w-576 mx-auto">
        {React.string("From the community, for the community")}
      </h3>
      <div
        className="flex flex-wrap mx-4 gap-8 justify-center items-center max-w-md lg:mx-auto mt-16 mb-16">
        <p className="leading-4">
          {React.string(
            "We rely on donations from organizations and individuals to stay independent. ",
          )}
        </p>
        <p className="leading-4">
          {<>
            {React.string(
              "Additional financial resources help us to maintain essential language infrastructure, and to organize events, like the ",
            )}
            <Next.Link href="/blog/retreats" className="no-underline text-fire hover:underline">
              {React.string("annual ReScript Retreat")}
            </Next.Link>
            {React.string(".")}
          </>}
        </p>
      </div>
      <Next.Link href="/community/donate">
        <Button> {React.string("Donate")} </Button>
      </Next.Link>
    </section>
  }
}

@react.component
let make = (~components=MarkdownComponents.default, ~children) => {
  let (isOverlayOpen, setOverlayOpen) = React.useState(() => false)

  <>
    <Meta
      title="The ReScript Programming Language"
      description="Fast, Simple, Fully Typed JavaScript from the Future"
      keywords=["ReScript", "rescriptlang", "JavaScript", "JS", "TypeScript"]
      ogImage="/static/Art-3-rescript-launch.jpg"
    />
    <div className="mt-4 xs:mt-16">
      <div className="text-gray-80 text-18 z">
        <Navigation isOverlayOpen setOverlayOpen />
        <div className="absolute w-full top-16">
          <div className="relative overflow-hidden pb-32">
            <main className="mt-10 min-w-320 lg:align-center w-full">
              <MdxProvider components>
                <div className="">
                  <div className="w-full">
                    <div className="mt-16 md:mt-32 lg:mt-40 mb-12">
                      <Intro />
                    </div>
                    <PlaygroundHero />
                    <QuickInstall />
                    <MainUSP />
                    <OtherSellingPoints />
                    <TrustedBy />
                    <CuratedResources />
                    <Sponsors />
                    children
                  </div>
                </div>
              </MdxProvider>
            </main>
          </div>
          <Footer />
        </div>
      </div>
    </div>
  </>
}

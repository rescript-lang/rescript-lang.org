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
      onClick
    >
      <Icon.Copy className="w-6 h-6 mt-px text-gray-40 hover:cursor-pointer hover:text-gray-80" />
    </button>
  }
}

module Instructions = {
  let copyBox = text => {
    <div
      className="flex justify-between items-center pl-6 pr-3 py-3 w-full bg-gray-10 border border-gray-20 rounded max-w-400"
    >
      <span className="font-mono text-14  text-gray-70"> {React.string(text)} </span>
      <CopyButton code=text />
    </div>
  }
  @react.component
  let make = () => {
    <div className="w-full max-w-400">
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
          className="relative z-1 space-y-12 text-gray-80 font-semibold text-24 md:text-32 leading-2"
        >
          <span className="bg-fire-5 rounded-lg border border-fire-10 p-1 ">
            {React.string(`Leverage the full power`)}
          </span>
          {React.string(` of JavaScript in a robustly typed language without the fear of \`any\` types.`)}
        </p>
      </div>
      //spacing between columns
      <div className="w-full mt-12 md:flex flex-col lg:flex-row md:justify-between ">
        <p
          className="relative z-1 text-gray-80 font-semibold text-24 md:text-32 leading-2 max-w-lg"
        >
          {React.string(`ReScript is used to ship and maintain mission-critical products with good UI and UX.`)}
        </p>
        <div className="mt-16 lg:mt-0 self-end max-w-400">
          <Instructions />
        </div>
      </div>
    </div>
  </section>
}

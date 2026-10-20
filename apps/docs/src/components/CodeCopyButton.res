type state =
  | Init
  | Pending
  | Copied
  | Failed

@react.component
let make = (~code, ~writeClipboard=Clipboard.writeText) => {
  let (state, setState) = React.useState(_ => Init)

  let buttonRef = React.useRef(Nullable.null)

  let copy = async () => {
    setState(_ => Pending)
    let result = await writeClipboard(code)
    setState(_ =>
      switch result {
      | Ok() => Copied
      | Error(_) => Failed
      }
    )
  }
  let onClick = evt => {
    ReactEvent.Mouse.preventDefault(evt)
    copy()->ignore
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
      bannerEl.className = "opacity-0 absolute -top-6 right-0 -mt-5 -mr-4 px-4 py-2 w-40 rounded-lg captions text-white bg-gray-100 text-gray-80-tr transition-all duration-1000 ease-in-out "

      let textNode = WebAPI.Document.createTextNode(document, "Copied to clipboard")

      WebAPI.Element.appendChild(bannerEl, textNode)->ignore
      WebAPI.Element.appendChild(buttonEl, bannerEl)->ignore

      let nextFrameId = WebAPI.Window.requestAnimationFrame(window, _ => {
        WebAPI.DOMTokenList.toggle(bannerEl.classList, ~token="opacity-0")->ignore
        WebAPI.DOMTokenList.toggle(bannerEl.classList, ~token="opacity-100")->ignore
      })

      let timeoutId = setTimeout(~handler=() => {
        buttonEl->WebAPI.Element.removeChild(bannerEl)->ignore
        setState(_ => Init)
      }, ~timeout=3000)

      Some(
        () => {
          cancelAnimationFrame(nextFrameId)
          clearTimeout(timeoutId)
          bannerEl->WebAPI.Element.remove
        },
      )
    | _ => None
    }
  }, [state])
  //Copy-Button
  <button
    ref={HtmlRef.elementRef(buttonRef)}
    type_="button"
    ariaLabel={state === Failed ? "Copy failed, try again" : "Copy code"}
    disabled={state === Pending || state === Copied}
    className="relative"
    onClick
  >
    <Icon.Clipboard
      className="text-gray-30 mt-px hover:cursor-pointer hover:text-gray-60 hover:bg-gray-30 w-6 h-6 p-1 rounded transition-all duration-300 ease-in-out"
    />
  </button>
}

/* Contains some generic hooks */
let useOutsideClick: (ReactDOM.Ref.t, unit => unit) => unit = %raw(`(outerRef, trigger) => {
  function handleClickOutside(event) {
    if (outerRef.current && !outerRef.current.contains(event.target)) {
      trigger();
    }
  }

  React.useEffect(() => {
    document.addEventListener("mousedown", handleClickOutside);
    return () => {
      document.removeEventListener("mousedown", handleClickOutside);
    };
  });
}`)

/** scrollDir is not memo-friendly.
  It must be used with pattern matching.
  Do not pass it directly to child components. */
type scrollDir =
  | Up({scrollY: int})
  | Down({scrollY: int})

type action =
  | Skip
  | EnterTop
  | DownToUp
  | UpToDown
  | KeepDown
  | KeepUp

/**
  This will cause highly frequent events, so use it only once in a root as possible.
  And split the children components to prevent heavy ones from being re-rendered unnecessarily. */
let useScrollDirection = (~topMargin=80, ~threshold=20) => {
  let (scrollDir, setScrollDir) = React.useState(() => Up({
    scrollY: 999999, // pseudo infinity
  }))

  React.useEffect(() => {
    let onScroll = e => {
      let eventType = (e["type"] :> string)

      setScrollDir(prev => {
        let scrollY = Webapi.Window.scrollY
        let enterTopMargin = scrollY <= topMargin

        if eventType === "reset-scroll-direction" {
          Up({scrollY: scrollY})
        } else {
          let action = switch prev {
          | Up(_) if enterTopMargin => Skip
          | Down(_) if enterTopMargin => EnterTop
          | Up({scrollY: prevScrollY}) if prevScrollY < scrollY => UpToDown
          | Up({scrollY: prevScrollY}) if prevScrollY - threshold >= scrollY => KeepUp
          | Down({scrollY: prevScrollY}) if scrollY < prevScrollY => DownToUp
          | Down({scrollY: prevScrollY}) if scrollY - threshold >= prevScrollY => KeepDown
          | _ => Skip
          }

          switch action {
          | Skip => prev
          | EnterTop | DownToUp | KeepUp => Up({scrollY: scrollY})
          | UpToDown | KeepDown => Down({scrollY: scrollY})
          }
        }
      })
    }
    Webapi.Window.addEventListener("scroll", onScroll)
    Webapi.Window.addEventListener("reset-scroll-direction", onScroll)
    Some(
      () => {
        Webapi.Window.removeEventListener("scroll", onScroll)
        Webapi.Window.removeEventListener("reset-scroll-direction", onScroll)
      },
    )
  }, [topMargin, threshold])

  scrollDir
}

let useResetScrollDirection = () => {
  React.useCallback(() => {
    // We really need better handling for plain DOM...
    %raw(`window.dispatchEvent(new Event("reset-scroll-direction"))`)
  }, [])
}

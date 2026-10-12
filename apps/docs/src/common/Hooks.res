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
    let onScroll = _e => {
      setScrollDir(prev => {
        let scrollY = scrollY->Float.toInt
        let enterTopMargin = scrollY <= topMargin

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
      })
    }

    // let onScroll = Util.debounce(onScroll, 50)

    WebAPI.Window.addEventListener(window, Scroll, onScroll)
    Some(() => WebAPI.Window.removeEventListener(window, Scroll, onScroll))
  }, [topMargin, threshold])

  scrollDir
}

type mediaQueryListEvent = {matches: bool}

let useMediaQuery = (query: string) => {
  let (matches, setMatches) = React.useState(() => {
    false
  })

  React.useEffect(() => {
    let mediaQueryList = WebAPI.Window.matchMedia(window, query)
    setMatches(_ => mediaQueryList.matches)

    let listener = (e: mediaQueryListEvent) => setMatches(_ => e.matches)

    WebAPI.MediaQueryList.addEventListener(mediaQueryList, Change, listener)
    Some(() => WebAPI.MediaQueryList.removeEventListener(mediaQueryList, Change, listener))
  }, [query])

  matches
}

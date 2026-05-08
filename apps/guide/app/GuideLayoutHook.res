type dragTarget =
  | NotDragging
  | ResizingColumns
  | ResizingRows

type t = {
  shellRef: React.ref<Nullable.t<Dom.element>>,
  theme: GuideLayout.theme,
  toggleTheme: ReactEvent.Mouse.t => unit,
  startColumnResize: ReactEvent.Mouse.t => unit,
  startRowResize: ReactEvent.Mouse.t => unit,
}

let useLayout = (): t => {
  let shellRef: React.ref<Nullable.t<Dom.element>> = React.useRef(Nullable.null)
  let (paneSizes, setPaneSizes) = React.useState(() => GuideLayout.defaultPaneSizes)
  let (theme, setTheme) = React.useState(() => GuideLayout.Light)
  let (themeLoaded, setThemeLoaded) = React.useState(() => false)
  let (paneSizesLoaded, setPaneSizesLoaded) = React.useState(() => false)
  let dragTarget = React.useRef(NotDragging)

  React.useEffect(() => {
    setTheme(_ => GuideLayout.loadTheme())
    setPaneSizes(_ =>
      GuideLayout.loadPaneSizes()->GuideLayout.clampPaneSizes(
        ~viewportWidth=window.innerWidth->Int.toFloat,
        ~viewportHeight=window.innerHeight->Int.toFloat,
      )
    )
    setThemeLoaded(_ => true)
    setPaneSizesLoaded(_ => true)
    None
  }, [])

  React.useEffect(() => {
    if themeLoaded {
      theme->GuideLayout.saveTheme
    }
    None
  }, (theme, themeLoaded))

  React.useEffect(() => {
    if paneSizesLoaded {
      paneSizes->GuideLayout.savePaneSizes
    }
    None
  }, (paneSizes, paneSizesLoaded))

  React.useEffect(() => {
    switch shellRef.current {
    | Value(element) =>
      // CSS variables keep the two resizable axes in one place for layout and tests.
      WebAPI.Element.setAttribute(
        element->GuideDom.toWebElement,
        ~qualifiedName="style",
        ~value=paneSizes->GuideLayout.paneSizesStyle,
      )
    | Null | Undefined => ()
    }
    None
  }, [paneSizes])

  React.useEffect(() => {
    let stopDragging = _event => dragTarget.current = NotDragging

    let onMouseMove = event =>
      switch dragTarget.current {
      | ResizingColumns =>
        let pointerX = event->ReactEvent.Mouse.clientX->Int.toFloat
        let viewportWidth = window.innerWidth->Int.toFloat
        let instructionsWidth = GuideLayout.clampInstructionsWidth(~viewportWidth, ~pointerX)
        setPaneSizes(previous => {...previous, instructionsWidth: Some(instructionsWidth)})
      | ResizingRows =>
        let pointerY = event->ReactEvent.Mouse.clientY->Int.toFloat
        let viewportHeight = window.innerHeight->Int.toFloat
        let outputHeight = GuideLayout.clampOutputHeight(~viewportHeight, ~pointerY)
        setPaneSizes(previous => {...previous, outputHeight})
      | NotDragging => ()
      }

    WebAPI.Window.addEventListener(window, Mousemove, onMouseMove)
    WebAPI.Window.addEventListener(window, Mouseup, stopDragging)

    Some(
      () => {
        WebAPI.Window.removeEventListener(window, Mousemove, onMouseMove)
        WebAPI.Window.removeEventListener(window, Mouseup, stopDragging)
      },
    )
  }, [])

  let startDragging = (target, event) => {
    ReactEvent.Mouse.preventDefault(event)
    dragTarget.current = target
  }

  {
    shellRef,
    theme,
    toggleTheme: _event => setTheme(previous => previous->GuideLayout.toggleTheme),
    startColumnResize: event => startDragging(ResizingColumns, event),
    startRowResize: event => startDragging(ResizingRows, event),
  }
}

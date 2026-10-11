external elementToDialog: Dom.element => WebAPI.DOMAPI.htmlDialogElement = "%identity"

@react.component
let make = (~categories: array<SidebarNav.Category.t>, ~activeToc) => {
  let {pathname} = ReactRouter.useLocation()
  let currentRoute = (pathname :> string)->Url.normalizePath
  let dialogRef = React.useRef(Nullable.null)
  let (isOpen, setOpen) = React.useState(_ => false)
  let close = () => setOpen(_ => false)

  React.useEffect(() => {
    switch dialogRef.current {
    | Value(element) =>
      let dialog = element->elementToDialog
      let handleClose = _ => close()
      dialog->WebAPI.HTMLDialogElement.addEventListener(Close, handleClose)
      Some(() => dialog->WebAPI.HTMLDialogElement.removeEventListener(Close, handleClose))
    | Null | Undefined => None
    }
  }, [])

  React.useEffect(() => {
    switch dialogRef.current {
    | Value(element) =>
      let dialog = element->elementToDialog
      if isOpen {
        dialog->WebAPI.HTMLDialogElement.showModal
      } else {
        dialog->WebAPI.HTMLDialogElement.close
      }
    | Null | Undefined => ()
    }
    None
  }, [isOpen])

  React.useEffect(() => {
    close()
    None
  }, [pathname])

  React.useEffect(() => {
    let breakpoint = window->WebAPI.Window.matchMedia("(min-width: 768px)")
    let handleChange = _ => close()
    breakpoint->WebAPI.MediaQueryList.addEventListener(Change, handleChange)
    Some(() => breakpoint->WebAPI.MediaQueryList.removeEventListener(Change, handleChange))
  }, [])

  <>
    <div className="md:hidden border-b border-gray-20 px-4">
      <button
        type_="button"
        className="flex items-center gap-3 h-12 text-14 font-medium text-gray-80"
        ariaControls="community-mobile-sidebar"
        ariaExpanded=isOpen
        onClick={_ => setOpen(_ => true)}
      >
        <img className="h-4" src="/ic_sidebar_drawer.svg" alt="" />
        {React.string("Community navigation")}
      </button>
    </div>
    <dialog
      ref={ReactDOM.Ref.domRef(dialogRef)}
      id="community-mobile-sidebar"
      dataTestId="community-mobile-sidebar"
      ariaLabel="Community navigation"
      onClick={event => {
        if event->ReactEvent.Mouse.target == event->ReactEvent.Mouse.currentTarget {
          close()
        }
      }}
      className="fixed inset-x-0 top-16 bottom-0 m-0 w-full max-w-none max-h-none h-[calc(100dvh-4rem)] bg-white px-4 py-4 overflow-y-auto backdrop:bg-gray-90/40"
    >
      {isOpen
        ? <>
            <div className="flex items-center justify-between">
              <span className="text-16 font-medium"> {React.string("Community")} </span>
              <button
                type_="button"
                ariaLabel="Close community navigation"
                className="flex items-center justify-center h-12 w-12"
                onClick={_ => close()}
              >
                <Icon.Close />
              </button>
            </div>
            <nav ariaLabel="Community pages">
              {categories
              ->Array.map(category =>
                <SidebarNav.Category
                  key=category.name
                  category
                  isItemActive={item => item.href->Url.normalizePath === currentRoute}
                  getActiveToc={item =>
                    item.href->Url.normalizePath === currentRoute ? Some(activeToc) : None}
                  onClick=close
                />
              )
              ->React.array}
            </nav>
          </>
        : React.null}
    </dialog>
  </>
}

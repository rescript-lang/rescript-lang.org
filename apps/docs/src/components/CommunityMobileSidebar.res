external elementToDialog: Dom.element => WebAPI.DOMAPI.htmlDialogElement = "%identity"

@react.component
let make = (~categories: array<SidebarNav.Category.t>, ~activeToc, ~route) => {
  let currentRoute = route->Url.normalizePath
  let (isOpen, setOpen) = React.useState(_ => false)
  let close = () => setOpen(_ => false)

  let attachDialog = React.useCallback(node => {
    switch node {
    | Nullable.Value(element) =>
      let dialog = element->elementToDialog
      let breakpoint = window->WebAPI.Window.matchMedia("(min-width: 768px)")
      let handleClose = _ => {
        // StrictMode can reopen the dialog before a cleanup's close event arrives.
        if !dialog.open_ {
          setOpen(_ => false)
        }
      }
      let handleBreakpointChange = _ => {
        if breakpoint.matches {
          setOpen(_ => false)
        }
      }
      dialog->WebAPI.HTMLDialogElement.addEventListener(Close, handleClose)
      breakpoint->WebAPI.MediaQueryList.addEventListener(Change, handleBreakpointChange)
      if breakpoint.matches {
        setOpen(_ => false)
      } else {
        dialog->WebAPI.HTMLDialogElement.showModal
      }
      Some(
        () => {
          dialog->WebAPI.HTMLDialogElement.removeEventListener(Close, handleClose)
          breakpoint->WebAPI.MediaQueryList.removeEventListener(Change, handleBreakpointChange)
          dialog->WebAPI.HTMLDialogElement.close
        },
      )
    | Nullable.Null | Nullable.Undefined => None
    }
  }, [setOpen])

  <>
    <div className="md:hidden border-b border-gray-20 px-4">
      <button
        type_="button"
        className="flex items-center gap-3 h-12 text-14 font-medium text-gray-80"
        ariaControls=?{isOpen ? Some("community-mobile-sidebar") : None}
        ariaExpanded=isOpen
        onClick={_ => setOpen(_ => true)}
      >
        <img className="h-4" src="/ic_sidebar_drawer.svg" alt="" />
        {React.string("Community navigation")}
      </button>
    </div>
    {isOpen
      ? <dialog
          ref={ReactDOM.Ref.callbackDomRef(attachDialog)}
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
        </dialog>
      : React.null}
  </>
}

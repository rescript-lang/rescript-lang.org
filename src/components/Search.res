let apiKey = Env.algolia_read_api_key
let indexName = Env.algolia_index_name
let appId = Env.algolia_app_id

type state = Active | Inactive

let navigator: DocSearch.navigator = {
  navigate: ({itemUrl}) => {
    ReactRouter.navigate(itemUrl)
  },
}

@react.component
let make = () => {
  let (state, setState) = React.useState(_ => Inactive)

  let handleCloseModal = () => {
    let () = switch WebAPI.Document.querySelector(document, ".DocSearch-Modal") {
    | Value(modal) =>
      switch WebAPI.Document.querySelector(document, "body") {
      | Value(body) =>
        WebAPI.DOMTokenList.remove(body.classList, "DocSearch--active")
        modal->WebAPI.Element.addEventListener(Transitionend, () => {
          setState(_ => Inactive)
        })
      | Null => setState(_ => Inactive)
      }
    | Null => ()
    }
  }

  React.useEffect(() => {
    let isEditableTag = (el: WebAPI.DOMAPI.element) =>
      switch el.tagName {
      | "TEXTAREA" | "SELECT" | "INPUT" => true
      | _ => false
      }

    let focusSearch = (e: WebAPI.UIEventsAPI.keyboardEvent) => {
      switch document.activeElement {
      | Value(el)
        if el->isEditableTag || (Obj.magic(el): WebAPI.DOMAPI.htmlElement).isContentEditable => ()
      | _ =>
        setState(_ => Active)
        WebAPI.KeyboardEvent.preventDefault(e)
      }
    }

    let handleGlobalKeyDown = (e: WebAPI.UIEventsAPI.keyboardEvent) => {
      switch e.key {
      | "/" => focusSearch(e)
      | "k" if e.ctrlKey || e.metaKey => focusSearch(e)
      | "Escape" => handleCloseModal()
      | _ => ()
      }
    }
    WebAPI.Window.addEventListener(window, Keydown, handleGlobalKeyDown)
    Some(() => WebAPI.Window.removeEventListener(window, Keydown, handleGlobalKeyDown))
  }, [setState])

  let onClick = _ => {
    setState(_ => Active)
  }

  let onClose = React.useCallback(() => {
    handleCloseModal()
  }, [setState])

  <>
    <button
      onClick
      type_="button"
      className="text-gray-60 hover:text-fire-50 cursor-pointer"
      ariaLabel="Search"
    >
      <Icon.MagnifierGlass className="fill-current" />
    </button>
    {switch state {
    | Active =>
      switch ReactDOM.querySelector("body") {
      | Some(element) =>
        ReactDOM.createPortal(
          <DocSearch
            apiKey
            appId
            indexName
            navigator
            onClose
            initialScrollY={window.scrollY->Float.toInt}
            searchParameters={distinct: 3, hitsPerPage: 20}
          />,
          element,
        )
      | None => React.null
      }
    | Inactive => React.null
    }}
  </>
}

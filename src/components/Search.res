let apiKey = "a2485ef172b8cd82a2dfa498d551399b"
let indexName = "rescript-lang"
let appId = "S32LNEY41T"

type state = Active | Inactive

let hit = ({hit, children}: DocSearch.hitComponent) => {
  let toTitle = str => str->String.charAt(0)->String.toUpperCase ++ String.sliceToEnd(str, ~start=1)

  let description = switch hit.url
  ->String.split("/")
  ->Array.sliceToEnd(~start=1)
  ->List.fromArray {
  | list{"blog" as r | "community" as r, ..._} => r->toTitle
  | list{"docs", doc, version, ...rest} =>
    let path = rest->List.toArray

    let info =
      path
      ->Array.slice(~start=0, ~end=Array.length(path) - 1)
      ->Array.map(path =>
        switch path {
        | "api" => "API"
        | other => toTitle(other)
        }
      )

    [doc->toTitle, version->toTitle]->Array.concat(info)->Array.join(" / ")
  | _ => ""
  }

  <ReactRouter.Link to=Url({hit.url}) className="flex flex-col w-full">
    <span className="text-gray-60 captions px-4 pt-3 pb-1 block">
      {description->React.string}
    </span>
    children
  </ReactRouter.Link>
}

let transformItems = (items: DocSearch.transformItems) => {
  items->Array.filterMap(item => {
    let url = try WebAPI.URL.make(~url=item.url)->Some catch {
    | Exn.Error(obj) =>
      Console.error2(`Failed to parse URL ${item.url}`, obj)
      None
    }
    switch url {
    | Some({pathname, hash}) => {...item, url: pathname ++ hash}->Some
    | None => None
    }
  })
}

@react.component
let make = () => {
  let (state, setState) = React.useState(_ => Inactive)
  let location = ReactRouter.useLocation()

  let version = Url.parse(location.pathname)->Url.getVersionString

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
    <button onClick type_="button" className="text-gray-60 hover:text-fire-50 p-2">
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
            onClose
            searchParameters={facetFilters: ["version:" ++ version]}
            initialScrollY={window.scrollY->Float.toInt}
            transformItems={transformItems}
            hitComponent=hit
          />,
          element,
        )
      | None => React.null
      }
    | Inactive => React.null
    }}
  </>
}

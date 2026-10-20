type modal = React.component<SearchModal.props<string, string, string, unit => unit>>
type state = Inactive | Active(modal)
type action = Open(modal) | Close

let reduce = (state, action) =>
  switch (state, action) {
  | (Inactive, Open(modal)) => Active(modal)
  | (Active(_), Open(_)) => state
  | (_, Close) => Inactive
  }

let unavailableText = "Search unavailable"
let unavailableLabel = "Search unavailable for this build"

@get external isContentEditable: WebAPI.DOMAPI.element => option<bool> = "isContentEditable"
@get external focusMethod: WebAPI.DOMAPI.element => option<unit => unit> = "focus"
@get external inputValue: WebAPI.DOMAPI.element => option<string> = "value"
@send external focusElement: WebAPI.DOMAPI.element => unit = "focus"

let isEditable = (element: WebAPI.DOMAPI.element) =>
  switch element.tagName {
  | "TEXTAREA" | "SELECT" | "INPUT" => true
  | _ => element->isContentEditable->Option.getOr(false)
  }

let restoreFocus = element =>
  switch element->focusMethod {
  | Some(_) => element->focusElement
  | None => ()
  }

let hasSearchQuery = () =>
  switch document.activeElement {
  | Value(element) =>
    WebAPI.DOMTokenList.contains(element.classList, "DocSearch-Input") &&
    element->inputValue->Option.map(value => value !== "")->Option.getOr(false)
  | Null => false
  }

let activateSearch = (~dispatch, ~returnFocus: React.ref<option<WebAPI.DOMAPI.element>>) => {
  if returnFocus.current->Option.isNone {
    returnFocus.current = document.activeElement->Null.toOption
  }
  dispatch(Open(React.lazy_(() => import(SearchModal.make))))
}

@react.component
let make = () => {
  let (state, dispatch) = React.useReducer(reduce, Inactive)
  let returnFocus = React.useRef(None)
  let algoliaConfig = Env.algoliaPublicConfig

  let onClose = React.useCallback(() => {
    switch WebAPI.Document.querySelector(document, "body") {
    | Value(body) => WebAPI.DOMTokenList.remove(body.classList, "DocSearch--active")
    | Null => ()
    }
    dispatch(Close)
    returnFocus.current->Option.forEach(restoreFocus)
    returnFocus.current = None
  }, [dispatch])

  // Synchronize the document-wide shortcuts with search availability.
  React.useEffect(() => {
    switch algoliaConfig {
    | None => None
    | Some(_) =>
      let handleGlobalKeyDown = (event: WebAPI.UIEventsAPI.keyboardEvent) => {
        if event.key === "Escape" && !hasSearchQuery() {
          onClose()
        } else if event.key === "/" || (event.key === "k" && (event.ctrlKey || event.metaKey)) {
          switch document.activeElement {
          | Value(element) if isEditable(element) => ()
          | _ =>
            activateSearch(~dispatch, ~returnFocus)
            WebAPI.KeyboardEvent.preventDefault(event)
          }
        }
      }
      // Read Escape's query before autocomplete clears it at the input.
      WebAPI.Window.addEventListener(window, Keydown, handleGlobalKeyDown, ~options={capture: true})
      Some(
        () =>
          WebAPI.Window.removeEventListener(
            window,
            Keydown,
            handleGlobalKeyDown,
            ~options={capture: true},
          ),
      )
    }
  }, (algoliaConfig, onClose, dispatch))

  switch algoliaConfig {
  | None =>
    <button
      type_="button"
      disabled=true
      className="text-gray-50 cursor-not-allowed inline-flex items-center gap-2"
      ariaLabel=unavailableLabel
      title="Search is disabled for this build"
    >
      <Icon.MagnifierGlass className="fill-current" />
      <span> {React.string(unavailableText)} </span>
    </button>
  | Some({appId, indexName, searchApiKey}) =>
    <>
      <button
        onClick={_ => activateSearch(~dispatch, ~returnFocus)}
        type_="button"
        className="text-gray-60 hover:text-fire-50 cursor-pointer"
        ariaLabel="Search"
      >
        <Icon.MagnifierGlass className="fill-current" />
      </button>
      {switch state {
      | Active(modal) =>
        switch ReactDOM.querySelector("body") {
        | Some(body) =>
          ReactDOM.createPortal(
            <SearchErrorBoundary onClose>
              <React.Suspense fallback={<SearchNotice kind=#Loading onClose />}>
                {React.createElement(modal, {apiKey: searchApiKey, appId, indexName, onClose})}
              </React.Suspense>
            </SearchErrorBoundary>,
            body,
          )
        | None => React.null
        }
      | Inactive => React.null
      }}
    </>
  }
}

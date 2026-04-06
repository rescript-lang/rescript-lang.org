let apiKey = Env.algolia_read_api_key
let indexName = Env.algolia_index_name
let appId = Env.algolia_app_id

type state = Active | Inactive

let navigator: DocSearch.navigator = {
  navigate: ({itemUrl}) => {
    ReactRouter.navigate(itemUrl)
  },
}

let getHighlightedTitle: DocSearch.docSearchHit => string = %raw(`
  function(hit) {
    try { return hit._highlightResult.hierarchy.lvl1.value; }
    catch(e) { return hit.hierarchy.lvl1 || ''; }
  }
`)

let markdownToHtml = (text: string): string =>
  text
  ->String.replaceRegExp(RegExp.fromString("\\[([^\\]]+)\\]\\([^)]*\\)", ~flags="g"), "$1")
  ->String.replaceRegExp(RegExp.fromString("\\x60([^\\x60]+)\\x60", ~flags="g"), "<code>$1</code>")
  ->String.replaceRegExp(
    RegExp.fromString("\\*\\*([^*]+)\\*\\*", ~flags="g"),
    "<strong>$1</strong>",
  )
  ->String.replaceRegExp(RegExp.fromString("\\*([^*]+)\\*", ~flags="g"), "<em>$1</em>")
  ->String.replaceRegExp(RegExp.fromString("\\n{2,}", ~flags="g"), "<br />")
  ->String.replaceRegExp(RegExp.fromString("\\n", ~flags="g"), " ")
  ->String.trim

let hitComponent = ({hit, children: _}: DocSearch.hitComponent): React.element => {
  let titleHtml = getHighlightedTitle(hit)
  let contentHtml = hit.content->Nullable.toOption->Option.map(markdownToHtml)

  <a href={hit.url}>
    <div className="DocSearch-Hit-Container">
      <div className="DocSearch-Hit-content-wrapper">
        <span className="DocSearch-Hit-title" dangerouslySetInnerHTML={{"__html": titleHtml}} />
        {switch contentHtml {
        | Some(c) if String.length(c) > 0 =>
          <span className="DocSearch-Hit-path" dangerouslySetInnerHTML={{"__html": c}} />
        | _ => React.null
        }}
      </div>
    </div>
  </a>
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
            hitComponent
            onClose
            initialScrollY={window.scrollY->Float.toInt}
            searchParameters={distinct: 3, hitsPerPage: 20, attributesToSnippet: ["content:9999"]}
          />,
          element,
        )
      | None => React.null
      }
    | Inactive => React.null
    }}
  </>
}

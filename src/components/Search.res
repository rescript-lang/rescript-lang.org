type state = Active | Inactive

let unavailableText = "Search unavailable"
let unavailableLabel = "Search unavailable for this build"

let toRelativeSiteUrl = (url: string, ~siteUrl: string): string => {
  let normalizedSiteUrl = siteUrl->String.replaceRegExp(RegExp.fromString("/+$", ~flags=""), "")
  if normalizedSiteUrl !== "" && String.startsWith(url, normalizedSiteUrl) {
    let relativePath = String.slice(url, ~start=String.length(normalizedSiteUrl))
    if relativePath === "" {
      "/"
    } else if String.startsWith(relativePath, "/") {
      relativePath
    } else {
      "/" ++ relativePath
    }
  } else {
    url
  }
}

let normalizeHitUrls = (items: array<DocSearch.docSearchHit>, ~siteUrl: string) =>
  items->Array.map(hit => {
    let url = toRelativeSiteUrl(hit.url, ~siteUrl)
    let urlWithoutAnchor =
      hit.url_without_anchor
      ->Nullable.toOption
      ->Option.getOr(hit.url->String.split("#")->Array.get(0)->Option.getOr(hit.url))
    let url_without_anchor = toRelativeSiteUrl(urlWithoutAnchor, ~siteUrl)->Nullable.make
    {...hit, url, url_without_anchor}
  })

let navigator = (~siteUrl: string): DocSearch.navigator => {
  navigate: ({itemUrl}) => {
    ReactRouter.navigate(toRelativeSiteUrl(itemUrl, ~siteUrl))
  },
}

let getHighlightedTitle: DocSearch.docSearchHit => string = %raw(`
  function(hit) {
    var type = hit.type;
    var h = hit._highlightResult && hit._highlightResult.hierarchy;
    var raw = hit.hierarchy;
    try {
      if (type && type !== 'lvl1' && type !== 'lvl0') {
        var lvl = h && h[type] && h[type].value;
        if (lvl) return lvl;
      }
      if (h && h.lvl1 && h.lvl1.value) return h.lvl1.value;
    } catch(e) {}
    return (raw && raw.lvl1) || '';
  }
`)

let getSubtitle: DocSearch.docSearchHit => option<string> = %raw(`
  function(hit) {
    var type = hit.type;
    if (type && type !== 'lvl1' && type !== 'lvl0') {
      var raw = hit.hierarchy;
      if (raw && raw.lvl1) return raw.lvl1;
    }
    return undefined;
  }
`)

let markdownToHtml = (text: string): string =>
  text
  // Strip stray backslashes from MDX processing
  ->String.replaceRegExp(RegExp.fromString("^\\\\\\s+", ~flags=""), "")
  ->String.replaceRegExp(RegExp.fromString("\\\\\\s+", ~flags="g"), " ")
  ->String.replaceRegExp(
    RegExp.fromString("See\\s+\\[([^\\]]+)\\]\\([^)]*\\)\\s+on MDN\\.?", ~flags="g"),
    "",
  )
  ->String.replaceRegExp(RegExp.fromString("See\\s+\\S+\\s+on MDN\\.?", ~flags="g"), "")
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

let isChildHit = (hit: DocSearch.docSearchHit) =>
  switch hit.type_ {
  | Lvl2 | Lvl3 | Lvl4 | Lvl5 | Lvl6 | Content => true
  | Lvl0 | Lvl1 => hit.url->String.includes("#")
  }

let hitComponent = ({hit, children: _}: DocSearch.hitComponent): React.element => {
  let titleHtml = getHighlightedTitle(hit)
  let subtitle = getSubtitle(hit)
  let contentHtml = hit.content->Nullable.toOption->Option.map(markdownToHtml)
  let isChild = isChildHit(hit)

  <a href={hit.url}>
    <div className="DocSearch-Hit-Container">
      {isChild ? <Icon.DocTree /> : React.null}
      {isChild ? <Icon.DocHash /> : <Icon.DocPage />}
      <div className="DocSearch-Hit-content-wrapper">
        <span className="DocSearch-Hit-title" dangerouslySetInnerHTML={{"__html": titleHtml}} />
        {switch subtitle {
        | Some(s) => <span className="DocSearch-Hit-subtitle"> {React.string(s)} </span>
        | None => React.null
        }}
        {switch contentHtml {
        | Some(c) if String.length(c) > 0 =>
          <span className="DocSearch-Hit-path" dangerouslySetInnerHTML={{"__html": c}} />
        | _ => React.null
        }}
      </div>
      <Icon.DocSelect />
    </div>
  </a>
}

@react.component
let make = () => {
  let (state, setState) = React.useState(_ => Inactive)
  let algoliaConfig = Env.algoliaPublicConfig

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
    switch algoliaConfig {
    | None => None
    | Some(_) =>
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
        | _ => ()
        }
      }
      WebAPI.Window.addEventListener(window, Keydown, handleGlobalKeyDown)
      Some(() => WebAPI.Window.removeEventListener(window, Keydown, handleGlobalKeyDown))
    }
  }, [algoliaConfig])

  let onClick = _ => {
    setState(_ => Active)
  }

  let onClose = React.useCallback(() => {
    handleCloseModal()
  }, [setState])

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
              apiKey=searchApiKey
              appId
              indexName
              navigator={navigator(~siteUrl=Env.root_url)}
              transformItems={items => normalizeHitUrls(items, ~siteUrl=Env.root_url)}
              hitComponent
              onClose
              initialScrollY={window.scrollY->Float.toInt}
              searchParameters={
                distinct: 3,
                hitsPerPage: 20,
                attributesToSnippet: ["content:9999"],
              }
            />,
            element,
          )
        | None => React.null
        }
      | Inactive => React.null
      }}
    </>
  }
}

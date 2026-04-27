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

let highlightedValue = (value: Nullable.t<DocSearch.highlightedValue>): option<string> =>
  value->Nullable.toOption->Option.map(value => value.value)

let highlightedValueWithMarkup = (value: Nullable.t<DocSearch.highlightedValue>): option<string> =>
  switch highlightedValue(value) {
  | Some(value) if value->String.includes("<mark>") => Some(value)
  | _ => None
  }

let highlightedHierarchyValue = (
  hierarchy: DocSearch.highlightedHierarchy,
  type_: DocSearch.contentType,
): option<string> =>
  switch type_ {
  | Lvl0 => hierarchy.lvl0->highlightedValue
  | Lvl1 => hierarchy.lvl1->highlightedValue
  | Lvl2 => hierarchy.lvl2->highlightedValue
  | Lvl3 => hierarchy.lvl3->highlightedValue
  | Lvl4 => hierarchy.lvl4->highlightedValue
  | Lvl5 => hierarchy.lvl5->highlightedValue
  | Lvl6 => hierarchy.lvl6->highlightedValue
  | Content => None
  }

let highlightedHierarchyValueWithMarkup = (
  hierarchy: DocSearch.highlightedHierarchy,
  type_: DocSearch.contentType,
): option<string> =>
  switch type_ {
  | Lvl0 => hierarchy.lvl0->highlightedValueWithMarkup
  | Lvl1 => hierarchy.lvl1->highlightedValueWithMarkup
  | Lvl2 => hierarchy.lvl2->highlightedValueWithMarkup
  | Lvl3 => hierarchy.lvl3->highlightedValueWithMarkup
  | Lvl4 => hierarchy.lvl4->highlightedValueWithMarkup
  | Lvl5 => hierarchy.lvl5->highlightedValueWithMarkup
  | Lvl6 => hierarchy.lvl6->highlightedValueWithMarkup
  | Content => None
  }

let firstMarkedText = (html: string): option<string> => {
  switch RegExp.exec(/<mark>([^<]+)<\/mark>/, html) {
  | Some(result) =>
    let matches = RegExp.Result.matches(result)
    switch matches[0] {
    | Some(Some(markedText)) => Some(markedText)
    | _ => None
    }
  | None => None
  }
}

let markTitlePrefix = (title: string, markedText: string): string => {
  let markedLength = String.length(markedText)
  if (
    markedLength > 0 && title->String.toLowerCase->String.startsWith(markedText->String.toLowerCase)
  ) {
    let prefix = String.slice(title, ~start=0, ~end=markedLength)
    let suffix = String.slice(title, ~start=markedLength)
    `<mark>${prefix}</mark>${suffix}`
  } else {
    title
  }
}

let getSnippetContent = (hit: DocSearch.docSearchHit): option<string> =>
  switch hit._snippetResult {
  | Some(snippetResult) => snippetResult.content->highlightedValue
  | None => None
  }

let getApiTitle = (hit: DocSearch.docSearchHit): option<string> => {
  if hit.url->String.includes("/docs/manual/api/") {
    switch (hit.hierarchy.lvl0->Nullable.toOption, hit.hierarchy.lvl1->Nullable.toOption) {
    | (Some(moduleName), Some(valueName)) if moduleName !== "" && valueName !== "" =>
      let title = `${moduleName}.${valueName}`
      switch hit->getSnippetContent->Option.flatMap(firstMarkedText) {
      | Some(markedText) => Some(markTitlePrefix(title, markedText))
      | None => Some(title)
      }
    | _ => None
    }
  } else {
    None
  }
}

let getHighlightedTitle = (hit: DocSearch.docSearchHit): string => {
  let highlightedHierarchy =
    hit._highlightResult->Option.flatMap(highlightResult =>
      highlightResult.hierarchy->Nullable.toOption
    )
  let highlightedTitleWithMarkup = highlightedHierarchy->Option.flatMap(hierarchy =>
    switch hit.type_ {
    | Lvl0 | Lvl1 => None
    | _ => highlightedHierarchyValueWithMarkup(hierarchy, hit.type_)
    }
  )

  switch highlightedTitleWithMarkup {
  | Some(title) => title
  | None =>
    switch highlightedHierarchy->Option.flatMap(hierarchy =>
      hierarchy.lvl1->highlightedValueWithMarkup
    ) {
    | Some(title) => title
    | None =>
      switch getApiTitle(hit) {
      | Some(title) => title
      | None =>
        switch highlightedHierarchy->Option.flatMap(hierarchy =>
          highlightedHierarchyValue(hierarchy, hit.type_)
        ) {
        | Some(title) => title
        | None => hit.hierarchy.lvl1->Nullable.toOption->Option.getOr("")
        }
      }
    }
  }
}

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

let getContentHtml = (hit: DocSearch.docSearchHit): option<string> =>
  switch getSnippetContent(hit) {
  | Some(content) => Some(content->markdownToHtml)
  | None => hit.content->Nullable.toOption->Option.map(markdownToHtml)
  }

let hitComponent = ({hit, children: _}: DocSearch.hitComponent): React.element => {
  let titleHtml = getHighlightedTitle(hit)
  let subtitle = getSubtitle(hit)
  let contentHtml = getContentHtml(hit)
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

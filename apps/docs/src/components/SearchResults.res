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

type apiNamespace = StdlibApi | BeltApi

let apiNamespaceForUrl = (url: string): option<apiNamespace> =>
  if url->String.includes("/docs/manual/api/stdlib/") {
    Some(StdlibApi)
  } else if url->String.includes("/docs/manual/api/belt/") {
    Some(BeltApi)
  } else {
    None
  }

let stripCaseInsensitivePrefix = (value: string, prefix: string): string => {
  if (
    prefix->String.length > 0 &&
      value->String.toLowerCase->String.startsWith(prefix->String.toLowerCase)
  ) {
    String.slice(value, ~start=String.length(prefix))
  } else {
    value
  }
}

let baseApiModuleName = (moduleName: string): string =>
  moduleName->stripCaseInsensitivePrefix("Stdlib.")->stripCaseInsensitivePrefix("Belt.")

let apiGroupName = (hit: DocSearch.docSearchHit): option<string> =>
  switch (apiNamespaceForUrl(hit.url), hit.hierarchy.lvl0->Nullable.toOption) {
  | (Some(StdlibApi), Some(moduleName)) if moduleName !== "" =>
    Some(moduleName->stripCaseInsensitivePrefix("Stdlib."))
  | (Some(BeltApi), Some(moduleName)) if moduleName !== "" =>
    Some(`Belt.${moduleName->baseApiModuleName}`)
  | _ => None
  }

let normalizeHitUrls = (items: array<DocSearch.docSearchHit>, ~siteUrl: string) =>
  items->Array.map(hit => {
    let url = toRelativeSiteUrl(hit.url, ~siteUrl)
    let urlWithoutAnchor =
      hit.url_without_anchor
      ->Nullable.toOption
      ->Option.getOr(hit.url->String.split("#")->Array.get(0)->Option.getOr(hit.url))
    let url_without_anchor = toRelativeSiteUrl(urlWithoutAnchor, ~siteUrl)->Nullable.make
    let hierarchy = switch hit->apiGroupName {
    | Some(lvl0) => {...hit.hierarchy, lvl0: Nullable.make(lvl0)}
    | None => hit.hierarchy
    }
    {...hit, url, url_without_anchor, hierarchy}
  })

let navigator = (~siteUrl: string, ~navigate: ReactRouter.navigate): DocSearch.navigator => {
  navigate: ({itemUrl}) => {
    navigate(toRelativeSiteUrl(itemUrl, ~siteUrl))
  },
}

let getSubtitle = (hit: DocSearch.docSearchHit): option<string> =>
  switch hit.type_ {
  | Lvl0 | Lvl1 => None
  | Lvl2 | Lvl3 | Lvl4 | Lvl5 | Lvl6 | Content =>
    hit.hierarchy.lvl1->Nullable.toOption->Option.filter(value => value !== "")
  }

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

let stripApiModulePrefix = (markedText: string, moduleName: string): string => {
  let moduleName = moduleName->baseApiModuleName
  markedText
  ->stripCaseInsensitivePrefix(`Stdlib.${moduleName}.`)
  ->stripCaseInsensitivePrefix(`Belt.${moduleName}.`)
  ->stripCaseInsensitivePrefix(`${moduleName}.`)
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
      let title = valueName
      switch hit->getSnippetContent->Option.flatMap(firstMarkedText) {
      | Some(markedText) =>
        Some(markTitlePrefix(title, stripApiModulePrefix(markedText, moduleName)))
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

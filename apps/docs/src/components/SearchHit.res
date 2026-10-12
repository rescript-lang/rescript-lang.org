@react.component
let make = (~hit: DocSearch.docSearchHit) => {
  let titleHtml = SearchResults.getHighlightedTitle(hit)
  let subtitle = SearchResults.getSubtitle(hit)
  let contentHtml = SearchResults.getContentHtml(hit)
  let isChild = SearchResults.isChildHit(hit)

  <ReactRouter.Link.String to=hit.url>
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
  </ReactRouter.Link.String>
}

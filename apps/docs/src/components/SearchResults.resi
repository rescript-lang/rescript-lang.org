let toRelativeSiteUrl: (string, ~siteUrl: string) => string
let normalizeHitUrls: (
  array<DocSearch.docSearchHit>,
  ~siteUrl: string,
) => array<DocSearch.docSearchHit>
let navigator: (~siteUrl: string, ~navigate: ReactRouter.navigate) => DocSearch.navigator
let getSubtitle: DocSearch.docSearchHit => option<string>
let getHighlightedTitle: DocSearch.docSearchHit => string
let markdownToHtml: string => string
let isChildHit: DocSearch.docSearchHit => bool
let getContentHtml: DocSearch.docSearchHit => option<string>

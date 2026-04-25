// API: https://github.com/algolia/docsearch/tree/v3.5.2/packages/docsearch-react/src/types
type contentType =
  | @as("content") Content
  | @as("lvl0") Lvl0
  | @as("lvl1") Lvl1
  | @as("lvl2") Lvl2
  | @as("lvl3") Lvl3
  | @as("lvl4") Lvl4
  | @as("lvl5") Lvl5
  | @as("lvl6") Lvl6

type hierarchy = {
  lvl0: Nullable.t<string>,
  lvl1: Nullable.t<string>,
  lvl2: Nullable.t<string>,
  lvl3: Nullable.t<string>,
  lvl4: Nullable.t<string>,
  lvl5: Nullable.t<string>,
  lvl6: Nullable.t<string>,
}

type docSearchHit = {
  objectID: string,
  content: Nullable.t<string>,
  url: string,
  url_without_anchor: string,
  @as("type") type_: contentType,
  anchor: Nullable.t<string>,
  hierarchy: hierarchy,
  // Additional field for deprecation information
  deprecated: option<string>,
  // NOTE: docsearch need these two fields to highlight results
  _highlightResult: {.},
  _snippetResult: {.},
}
type transformItems = array<docSearchHit>

type hitComponent = {
  hit: docSearchHit,
  children: React.element,
}

type item = {itemUrl: string}

type navigator = {navigate: item => unit}

type searchParameters = {facetFilters: array<string>}

@module("@docsearch/react") @react.component
external make: (
  ~appId: string,
  ~indexName: string,
  ~apiKey: string,
  ~transformItems: transformItems => transformItems=?,
  ~hitComponent: hitComponent => React.element=?,
  ~navigator: navigator=?,
  ~onClose: unit => unit=?,
  ~searchParameters: searchParameters=?,
  ~initialScrollY: int=?,
) => React.element = "DocSearchModal"

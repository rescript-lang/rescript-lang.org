@module external searchStyles: unit = "../../styles/search.css"

let () = searchStyles

let hitComponent = ({hit, children: _}: DocSearch.hitComponent) => <SearchHit hit />

@react.component
let make = (~apiKey, ~appId, ~indexName, ~onClose: unit => unit) => {
  let navigate = ReactRouter.useNavigate()

  <DocSearch
    apiKey
    appId
    indexName
    navigator={SearchResults.navigator(~siteUrl=Env.root_url, ~navigate)}
    transformItems={items => SearchResults.normalizeHitUrls(items, ~siteUrl=Env.root_url)}
    hitComponent
    onClose
    insights=true
    initialScrollY={window.scrollY->Float.toInt}
    searchParameters={
      distinct: 3,
      hitsPerPage: 20,
      attributesToSnippet: ["content:9999"],
    }
  />
}

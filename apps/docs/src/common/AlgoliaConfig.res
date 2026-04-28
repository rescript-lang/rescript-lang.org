type publicConfig = {
  appId: string,
  indexName: string,
  searchApiKey: string,
}

let isPresent = value =>
  switch value {
  | Some(v) => v !== ""
  | None => false
  }

let missingPublicVars = (~appId, ~indexName, ~searchApiKey): array<string> => {
  let missing = []
  if !isPresent(appId) {
    missing->Array.push("VITE_ALGOLIA_APP_ID")
  }
  if !isPresent(indexName) {
    missing->Array.push("VITE_ALGOLIA_INDEX_NAME")
  }
  if !isPresent(searchApiKey) {
    missing->Array.push("VITE_ALGOLIA_SEARCH_API_KEY")
  }
  missing
}

let publicConfigFrom = (~appId, ~indexName, ~searchApiKey): option<publicConfig> =>
  switch (appId, indexName, searchApiKey) {
  | (Some(appId), Some(indexName), Some(searchApiKey))
    if missingPublicVars(
      ~appId=Some(appId),
      ~indexName=Some(indexName),
      ~searchApiKey=Some(searchApiKey),
    )->Array.length === 0 =>
    Some({appId, indexName, searchApiKey})
  | _ => None
  }

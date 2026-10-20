type publicConfig = {
  appId: string,
  indexName: string,
  searchApiKey: string,
}

let missingPublicVars = (~appId, ~indexName, ~searchApiKey) => {
  let env = Dict.make()
  appId->Option.forEach(value => env->Dict.set("VITE_ALGOLIA_APP_ID", value))
  indexName->Option.forEach(value => env->Dict.set("VITE_ALGOLIA_INDEX_NAME", value))
  searchApiKey->Option.forEach(value => env->Dict.set("VITE_ALGOLIA_SEARCH_API_KEY", value))
  AlgoliaEnvStatus.getMissingPublicAlgoliaVars(~env)
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

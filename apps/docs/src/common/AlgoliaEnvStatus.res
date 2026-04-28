let publicKeys = ["VITE_ALGOLIA_APP_ID", "VITE_ALGOLIA_INDEX_NAME", "VITE_ALGOLIA_SEARCH_API_KEY"]

let getMissingPublicAlgoliaVars = (~env: Dict.t<string>): array<string> =>
  publicKeys->Array.filter(key =>
    switch env->Dict.get(key) {
    | None | Some("") => true
    | Some(_) => false
    }
  )

let formatDisabledMessage = (missing: array<string>) =>
  `Algolia search disabled: missing ${missing->Array.join(", ")}`

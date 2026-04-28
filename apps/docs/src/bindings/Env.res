// If Vite if running in dev mode
external dev: bool = "import.meta.env.DEV"

// Cloudflare deployment URL
external deployment_url: option<string> = "import.meta.env.VITE_DEPLOYMENT_URL"

// the root url of the site, e.g. "https://rescript-lang.org/" or "http://localhost:5173/"
let root_url = switch deployment_url {
| Some(url) if url !== "" => url
| None => dev ? "http://localhost:5173/" : "https://rescript-lang.org/"
| Some(_) => "https://rescript-lang.org/"
}

// Algolia search configuration (read from .env via Vite)
external algoliaAppIdRaw: option<string> = "import.meta.env.VITE_ALGOLIA_APP_ID"
external algoliaIndexNameRaw: option<string> = "import.meta.env.VITE_ALGOLIA_INDEX_NAME"
external algoliaSearchApiKeyRaw: option<string> = "import.meta.env.VITE_ALGOLIA_SEARCH_API_KEY"

let algoliaMissingPublicVars = AlgoliaConfig.missingPublicVars(
  ~appId=algoliaAppIdRaw,
  ~indexName=algoliaIndexNameRaw,
  ~searchApiKey=algoliaSearchApiKeyRaw,
)

let algoliaPublicConfig = AlgoliaConfig.publicConfigFrom(
  ~appId=algoliaAppIdRaw,
  ~indexName=algoliaIndexNameRaw,
  ~searchApiKey=algoliaSearchApiKeyRaw,
)

let algolia_app_id = switch algoliaPublicConfig {
| Some(config) => config.appId
| None => ""
}

let algolia_index_name = switch algoliaPublicConfig {
| Some(config) => config.indexName
| None => ""
}

let algolia_search_api_key = switch algoliaPublicConfig {
| Some(config) => config.searchApiKey
| None => ""
}

let algolia_read_api_key = algolia_search_api_key

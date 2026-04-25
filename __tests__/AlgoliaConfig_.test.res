open Vitest

test("publicConfigFrom returns config when all public vars are present", async () => {
  let result = AlgoliaConfig.publicConfigFrom(
    ~appId=Some("app_123"),
    ~indexName=Some("dev_rescript_lang"),
    ~searchApiKey=Some("search_123"),
  )

  let expected: AlgoliaConfig.publicConfig = {
    appId: "app_123",
    indexName: "dev_rescript_lang",
    searchApiKey: "search_123",
  }

  expect(result)->toEqual(Some(expected))
})

test("publicConfigFrom reports missing public vars in declaration order", async () => {
  let result = AlgoliaConfig.missingPublicVars(
    ~appId=None,
    ~indexName=Some("dev_rescript_lang"),
    ~searchApiKey=None,
  )

  expect(result)->toEqual(["VITE_ALGOLIA_APP_ID", "VITE_ALGOLIA_SEARCH_API_KEY"])
})

test("publisherConfigFrom reports missing publisher vars in declaration order", async () => {
  let result = AlgoliaConfig.missingPublisherVars(
    ~appId=Some("app_123"),
    ~indexName=None,
    ~adminApiKey=None,
  )

  expect(result)->toEqual(["ALGOLIA_INDEX_NAME", "ALGOLIA_ADMIN_API_KEY"])
})

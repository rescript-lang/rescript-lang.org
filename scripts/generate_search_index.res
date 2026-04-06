// Build script: reads all site content, builds Algolia search records, and uploads them.
// Runs as a standalone Node script via: node --env-file-if-exists=.env.local _scripts/generate_search_index.mjs
//
// Required env vars:
//   ALGOLIA_ADMIN_API_KEY -- API key with addObject/deleteObject/editSettings ACLs
//   ALGOLIA_INDEX_NAME    -- e.g. "rescript-lang-dev" or "rescript-lang"
//
// If either is missing, the script logs a warning and exits 0 (graceful skip).

let getEnv = (key: string): option<string> =>
  Node.Process.env
  ->Dict.get(key)
  ->Option.flatMap(v =>
    switch v {
    | "" => None
    | s => Some(s)
    }
  )

let main = async () => {
  let appId = getEnv("ALGOLIA_APP_ID")
  let adminApiKey = getEnv("ALGOLIA_ADMIN_API_KEY")
  let indexName = getEnv("ALGOLIA_INDEX_NAME")

  switch (appId, adminApiKey, indexName) {
  | (Some(appId), Some(apiKey), Some(idx)) => {
      Console.log("[search-index] Building search index records...")

      // 1. Build records from all content sources
      let manualRecords = SearchIndex.buildMarkdownRecords(
        ~category="Manual",
        ~basePath="/docs/manual",
        ~dirPath="markdown-pages/docs/manual",
        ~pageRank=100,
      )
      Console.log(
        `[search-index]   Manual docs: ${Int.toString(Array.length(manualRecords))} records`,
      )

      let reactRecords = SearchIndex.buildMarkdownRecords(
        ~category="React",
        ~basePath="/docs/react",
        ~dirPath="markdown-pages/docs/react",
        ~pageRank=90,
      )
      Console.log(
        `[search-index]   React docs: ${Int.toString(Array.length(reactRecords))} records`,
      )

      let communityRecords = SearchIndex.buildMarkdownRecords(
        ~category="Community",
        ~basePath="/community",
        ~dirPath="markdown-pages/community",
        ~pageRank=50,
      )
      Console.log(
        `[search-index]   Community: ${Int.toString(Array.length(communityRecords))} records`,
      )

      let blogRecords = SearchIndex.buildBlogRecords(~dirPath="markdown-pages/blog", ~pageRank=40)
      Console.log(`[search-index]   Blog: ${Int.toString(Array.length(blogRecords))} records`)

      let syntaxRecords = SearchIndex.buildSyntaxLookupRecords(
        ~dirPath="markdown-pages/syntax-lookup",
        ~pageRank=70,
      )
      Console.log(
        `[search-index]   Syntax lookup: ${Int.toString(Array.length(syntaxRecords))} records`,
      )

      let stdlibApiRecords = SearchIndex.buildApiRecords(
        ~basePath="/docs/manual/api",
        ~dirPath="markdown-pages/docs/api",
        ~pageRank=80,
        ~category="API / StdLib",
        ~files=["stdlib.json"],
      )
      Console.log(
        `[search-index]   API / StdLib: ${Int.toString(Array.length(stdlibApiRecords))} records`,
      )

      let beltApiRecords = SearchIndex.buildApiRecords(
        ~basePath="/docs/manual/api",
        ~dirPath="markdown-pages/docs/api",
        ~pageRank=75,
        ~category="API / Belt",
        ~files=["belt.json"],
      )
      Console.log(
        `[search-index]   API / Belt: ${Int.toString(Array.length(beltApiRecords))} records`,
      )

      let domApiRecords = SearchIndex.buildApiRecords(
        ~basePath="/docs/manual/api",
        ~dirPath="markdown-pages/docs/api",
        ~pageRank=70,
        ~category="API / DOM",
        ~files=["dom.json"],
      )
      Console.log(
        `[search-index]   API / DOM: ${Int.toString(Array.length(domApiRecords))} records`,
      )

      // 2. Concatenate all records
      let allRecords =
        [
          manualRecords,
          reactRecords,
          communityRecords,
          blogRecords,
          syntaxRecords,
          stdlibApiRecords,
          beltApiRecords,
          domApiRecords,
        ]->Array.flat

      let totalCount = Array.length(allRecords)
      Console.log(`[search-index] Total: ${Int.toString(totalCount)} records`)

      // 3. Convert to JSON for Algolia
      let jsonRecords = allRecords->Array.map(SearchIndex.toJson)

      // 4. Initialize Algolia client and upload
      let client = Algolia.make(appId, apiKey)

      Console.log(`[search-index] Uploading to index "${idx}"...`)
      let _ = await client->Algolia.replaceAllObjects({
        indexName: idx,
        objects: jsonRecords,
        batchSize: 1000,
      })
      Console.log("[search-index] Records uploaded successfully.")

      // 5. Configure index settings
      Console.log("[search-index] Updating index settings...")
      let _ = await client->Algolia.setSettings({
        indexName: idx,
        indexSettings: {
          searchableAttributes: [
            "hierarchy.lvl0",
            "hierarchy.lvl1",
            "hierarchy.lvl2",
            "hierarchy.lvl3",
            "hierarchy.lvl4",
            "hierarchy.lvl5",
            "hierarchy.lvl6",
            "content",
          ],
          ranking: ["typo", "words", "attribute", "exact", "custom", "proximity", "filters"],
          exactOnSingleWordQuery: "word",
          attributesForFaceting: ["type"],
          customRanking: ["desc(weight.pageRank)", "desc(weight.level)", "asc(weight.position)"],
          attributesToSnippet: ["content:30"],
          attributeForDistinct: "hierarchy.lvl0",
        },
      })
      Console.log("[search-index] Index settings updated.")

      Console.log("[search-index] Done.")
    }
  | (None, _, _) => Console.log("[search-index] ALGOLIA_APP_ID not set, skipping index upload.")
  | (_, None, _) => Console.log(
      "[search-index] ALGOLIA_ADMIN_API_KEY not set, skipping index upload.",
    )
  | (_, _, None) => Console.log("[search-index] ALGOLIA_INDEX_NAME not set, skipping index upload.")
  }
}

let _ = main()

// Build script: reads all site content, builds Algolia search records, and uploads them.
// Runs as a standalone Node script via: node --env-file-if-exists=.env --env-file-if-exists=.env.local _scripts/generate_search_index.mjs
//
// Required env vars:
//   ALGOLIA_APP_ID       -- Algolia application ID
//   ALGOLIA_ADMIN_API_KEY -- API key with addObject/deleteObject/editSettings ACLs
//   ALGOLIA_INDEX_NAME    -- e.g. "rescript-lang-dev" or "rescript-lang"
//
// If any are missing, the script logs a warning and exits 0 (graceful skip).

let getEnv = (key: string): option<string> =>
  Node.Process.env
  ->Dict.get(key)
  ->Option.flatMap(v =>
    switch v {
    | "" => None
    | s => Some(s)
    }
  )

let compareVersions = (a: string, b: string): float => {
  let parse = (v: string) =>
    v
    ->String.replaceRegExp(RegExp.fromString("^v", ~flags=""), "")
    ->String.split(".")
    ->Array.map(s => Int.fromString(s)->Option.getOr(0))
  let partsA = parse(a)
  let partsB = parse(b)
  switch (partsA[0], partsB[0]) {
  | (Some(a0), Some(b0)) if a0 !== b0 => Int.toFloat(a0 - b0)
  | _ =>
    switch (partsA[1], partsB[1]) {
    | (Some(a1), Some(b1)) if a1 !== b1 => Int.toFloat(a1 - b1)
    | _ =>
      switch (partsA[2], partsB[2]) {
      | (Some(a2), Some(b2)) => Int.toFloat(a2 - b2)
      | _ => 0.0
      }
    }
  }
}

let resolveApiDir = (): option<string> => {
  let majorVersion =
    getEnv("VITE_VERSION_LATEST")
    ->Option.map(v => v->String.replaceRegExp(RegExp.fromString("^v", ~flags=""), ""))
    ->Option.flatMap(v => v->String.split(".")->Array.get(0))
  switch majorVersion {
  | None => {
      Console.log("[search-index] VITE_VERSION_LATEST not set, cannot resolve API version.")
      None
    }
  | Some(major) => {
      let prefix = "v" ++ major ++ "."
      let entries = Node.Fs.readdirSync("data/api")
      let matching =
        entries
        ->Array.filter(entry => String.startsWith(entry, prefix))
        ->Array.toSorted(compareVersions)
      switch matching->Array.at(-1) {
      | Some(dir) => {
          Console.log(`[search-index] Resolved API version: ${dir}`)
          Some("data/api/" ++ dir)
        }
      | None => {
          Console.log(`[search-index] No API version found matching v${major}.*`)
          None
        }
      }
    }
  }
}

let resolveSiteUrl = (): string =>
  getEnv("VITE_DEPLOYMENT_URL")->Option.getOr("https://rescript-lang.org")

let main = async () => {
  let appId = getEnv("ALGOLIA_APP_ID")
  let adminApiKey = getEnv("ALGOLIA_ADMIN_API_KEY")
  let indexName = getEnv("ALGOLIA_INDEX_NAME")
  let publisherConfig = AlgoliaConfig.publisherConfigFrom(~appId, ~indexName, ~adminApiKey)

  switch publisherConfig {
  | Some({appId, indexName, adminApiKey}) => {
      Console.log("[search-index] Building search index records...")

      let apiDir = resolveApiDir()->Option.getOr("markdown-pages/docs/api")
      let siteUrl = resolveSiteUrl()

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
        ~dirPath=apiDir,
        ~pageRank=80,
        ~category="API / StdLib",
        ~files=["stdlib.json"],
      )
      Console.log(
        `[search-index]   API / StdLib: ${Int.toString(Array.length(stdlibApiRecords))} records`,
      )

      let beltApiRecords = SearchIndex.buildApiRecords(
        ~basePath="/docs/manual/api",
        ~dirPath=apiDir,
        ~pageRank=75,
        ~category="API / Belt",
        ~files=["belt.json"],
      )
      Console.log(
        `[search-index]   API / Belt: ${Int.toString(Array.length(beltApiRecords))} records`,
      )

      let domApiRecords = SearchIndex.buildApiRecords(
        ~basePath="/docs/manual/api",
        ~dirPath=apiDir,
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
      let jsonRecords =
        allRecords
        ->Array.map(record => SearchIndex.withBaseUrl(record, ~siteUrl))
        ->Array.map(SearchIndex.toJson)

      // 4. Initialize Algolia client and upload
      let client = Algolia.make(appId, adminApiKey)

      Console.log(`[search-index] Uploading to index "${indexName}"...`)
      let _ = await client->Algolia.replaceAllObjects({
        indexName,
        objects: jsonRecords,
        batchSize: 1000,
      })
      Console.log("[search-index] Records uploaded successfully.")

      // 5. Configure index settings
      Console.log("[search-index] Updating index settings...")
      let _ = await client->Algolia.setSettings({
        indexName,
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
          attributesToSnippet: [],
          attributeForDistinct: "hierarchy.lvl0",
        },
      })
      Console.log("[search-index] Index settings updated.")

      Console.log("[search-index] Done.")
    }
  | None =>
    AlgoliaConfig.missingPublisherVars(~appId, ~indexName, ~adminApiKey)->Array.forEach(name => {
      Console.log(`[search-index] ${name} not set, skipping index upload.`)
    })
  }
}

let _ = main()

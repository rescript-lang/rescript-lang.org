// Bindings for algoliasearch v5 SDK
// https://github.com/algolia/algoliasearch-client-javascript

module SearchClient = {
  type t
}

module BatchResponse = {
  type t
}

module SetSettingsResponse = {
  type t
}

module IndexSettings = {
  type t = {
    searchableAttributes?: array<string>,
    attributesForFaceting?: array<string>,
    customRanking?: array<string>,
    ranking?: array<string>,
    attributesToSnippet?: array<string>,
    attributeForDistinct?: string,
    exactOnSingleWordQuery?: string,
  }
}

module ReplaceAllObjectsOptions = {
  type t = {
    indexName: string,
    objects: array<JSON.t>,
    batchSize?: int,
  }
}

module SetSettingsOptions = {
  type t = {
    indexName: string,
    indexSettings: IndexSettings.t,
  }
}

@module("algoliasearch")
external make: (string, string) => SearchClient.t = "algoliasearch"

@send
external replaceAllObjects: (
  SearchClient.t,
  ReplaceAllObjectsOptions.t,
) => promise<array<BatchResponse.t>> = "replaceAllObjects"

@send
external setSettings: (SearchClient.t, SetSettingsOptions.t) => promise<SetSettingsResponse.t> =
  "setSettings"

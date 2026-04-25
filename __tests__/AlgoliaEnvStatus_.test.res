open Vitest

test("reports missing public vars in declaration order", async () => {
  let env = Dict.fromArray([
    ("VITE_ALGOLIA_APP_ID", ""),
    ("VITE_ALGOLIA_INDEX_NAME", "dev_rescript_lang"),
  ])

  expect(AlgoliaEnvStatus.getMissingPublicAlgoliaVars(~env))->toEqual([
    "VITE_ALGOLIA_APP_ID",
    "VITE_ALGOLIA_SEARCH_API_KEY",
  ])
})

test("formats the disabled search warning", async () => {
  expect(AlgoliaEnvStatus.formatDisabledMessage(["VITE_ALGOLIA_APP_ID"]))->toBe(
    "Algolia search disabled: missing VITE_ALGOLIA_APP_ID",
  )
})

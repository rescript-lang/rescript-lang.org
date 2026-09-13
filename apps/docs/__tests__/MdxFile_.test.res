open Vitest

test("MdxFile.normalizePathname preserves a document route", async () => {
  let result = MdxFile.normalizePathname("/blog/archived/a-small-step-for-bucklescript")

  expect(result)->toBe("/blog/archived/a-small-step-for-bucklescript")
})

test("MdxFile.normalizePathname removes a data route suffix", async () => {
  let result = MdxFile.normalizePathname("/blog/archived/a-small-step-for-bucklescript.data")

  expect(result)->toBe("/blog/archived/a-small-step-for-bucklescript")
})

test("MdxFile.normalizePathname removes React Router's data path segment", async () => {
  let result = MdxFile.normalizePathname("/blog/archived/a-small-step-for-bucklescript/_.data")

  expect(result)->toBe("/blog/archived/a-small-step-for-bucklescript")
})

test("MdxFile.normalizePathname removes a trailing slash", async () => {
  let result = MdxFile.normalizePathname("/blog/archived/a-small-step-for-bucklescript/")

  expect(result)->toBe("/blog/archived/a-small-step-for-bucklescript")
})

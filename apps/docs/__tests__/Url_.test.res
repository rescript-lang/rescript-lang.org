open Vitest

test("Url.parse splits an unversioned route into path segments", async () => {
  let result = Url.parse("/docs/manual/introduction")
  expect(result.base)->toEqual(["docs", "manual", "introduction"])
  expect(result.pagepath)->toEqual([])
  expect(result.fullpath)->toEqual(["docs", "manual", "introduction"])
})

test("Url.parse treats version-like segments as ordinary path content", async () => {
  let result = Url.parse("/docs/manual/v12.0.0/introduction")
  expect(result.base)->toEqual(["docs", "manual", "v12.0.0", "introduction"])
  expect(result.pagepath)->toEqual([])
  expect(result.fullpath)->toEqual(["docs", "manual", "v12.0.0", "introduction"])
})

test("Url.parse treats latest as ordinary path content", async () => {
  let result = Url.parse("/docs/manual/latest/arrays")
  expect(result.base)->toEqual(["docs", "manual", "latest", "arrays"])
  expect(result.pagepath)->toEqual([])
  expect(result.fullpath)->toEqual(["docs", "manual", "latest", "arrays"])
})

test("Url.parse parses routes outside docs without special handling", async () => {
  let result = Url.parse("/community/overview")
  expect(result.base)->toEqual(["community", "overview"])
  expect(result.pagepath)->toEqual([])
  expect(result.fullpath)->toEqual(["community", "overview"])
})

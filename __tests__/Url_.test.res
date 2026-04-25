open Vitest

test("Url.parse parses v-prefixed semver version", async () => {
  let result = Url.parse("/docs/manual/v12.0.0/introduction")
  expect(result.version)->toEqual(Url.Version("v12.0.0"))
  expect(result.base)->toEqual(["docs", "manual"])
  expect(result.pagepath)->toEqual(["introduction"])
  expect(result.fullpath)->toEqual(["docs", "manual", "v12.0.0", "introduction"])
})

test("Url.parse parses version without v prefix matching latest (PR #1231)", async () => {
  let result = Url.parse("/docs/manual/12.0.0/introduction")
  // 12.0.0 matches Constants.versions.latest, so it becomes Latest
  expect(result.version)->toEqual(Url.Latest)
  expect(result.base)->toEqual(["docs", "manual"])
  expect(result.pagepath)->toEqual(["introduction"])
  expect(result.fullpath)->toEqual(["docs", "manual", "12.0.0", "introduction"])
})

test("Url.parse parses latest keyword", async () => {
  let result = Url.parse("/docs/manual/latest/arrays")
  expect(result.version)->toEqual(Url.Latest)
  expect(result.base)->toEqual(["docs", "manual"])
  expect(result.pagepath)->toEqual(["arrays"])
})

test(
  "Url.parse parses 'next' string in URL when it does not match env-based Next version",
  async () => {
    // "next" is matched by the regex, but Constants.versions.next is "13.0.0", not "next"
    let result = Url.parse("/docs/manual/next/arrays")
    expect(result.version)->toEqual(Url.Version("next"))
    expect(result.base)->toEqual(["docs", "manual"])
    expect(result.pagepath)->toEqual(["arrays"])
  },
)

test("Url.parse parses actual next version from env as Next", async () => {
  let nextVer = Constants.versions.next
  let result = Url.parse("/docs/manual/" ++ nextVer ++ "/arrays")
  expect(result.version)->toEqual(Url.Next)
  expect(result.base)->toEqual(["docs", "manual"])
  expect(result.pagepath)->toEqual(["arrays"])
})

test("Url.parse parses route with no version as NoVersion", async () => {
  let result = Url.parse("/community/overview")
  expect(result.version)->toEqual(Url.NoVersion)
  expect(result.base)->toEqual(["community", "overview"])
  expect(result.pagepath)->toEqual([])
})

test("Url.parse parses short v-prefixed version (major.minor)", async () => {
  let result = Url.parse("/apis/javascript/v7.1/node")
  expect(result.version)->toEqual(Url.Version("v7.1"))
  expect(result.base)->toEqual(["apis", "javascript"])
  expect(result.pagepath)->toEqual(["node"])
})

test("Url.parse parses short version without v prefix (major.minor, PR #1231)", async () => {
  let result = Url.parse("/apis/javascript/7.1/node")
  expect(result.version)->toEqual(Url.Version("7.1"))
  expect(result.base)->toEqual(["apis", "javascript"])
  expect(result.pagepath)->toEqual(["node"])
})

test("Url.parse parses major-only version without v prefix (PR #1231)", async () => {
  let result = Url.parse("/docs/manual/12/getting-started")
  expect(result.version)->toEqual(Url.Version("12"))
  expect(result.base)->toEqual(["docs", "manual"])
  expect(result.pagepath)->toEqual(["getting-started"])
})

open Vitest
open RescriptCompilerApi

test("recognizes the compiler API used by v13 alpha 6", async () => {
  let version = Version.fromString("8")

  expect(version->Version.toString)->toBe("8.0")
  expect(version->Version.availableLanguages)->toEqual([Lang.Res])
})

test("enables existing compiler settings for v13 alpha 6", async () => {
  let version = Version.fromString("8")

  expect(version->Version.isMinimumVersion(V4))->toBe(true)
  expect(version->Version.isMinimumVersion(V6))->toBe(true)
})

test("keeps previous compiler APIs supported", async () => {
  ["2", "3", "4", "5", "6", "7"]->Array.forEach(version => {
    expect(version->Version.fromString->Version.toString)->toBe(`${version}.0`)
  })
  expect(Version.fromString("1.0")->Version.availableLanguages)->toEqual([Lang.Reason, Res])
  expect(Version.fromString("unknown")->Version.isMinimumVersion(V4))->toBe(false)
})

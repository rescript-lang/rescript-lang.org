open Vitest

test("selects the latest stable ReScript compiler with ESM output", async () => {
  let version =
    GuideCompilerSettings.latestStableVersion([
      "v12.1.0-alpha.1",
      "v11.1.4",
      "v12.0.0",
      "v12.2.0-beta.1",
      "v12.1.3",
    ])
    ->Option.getOrThrow
    ->Semver.toString

  expect(version)->toBe("v12.1.3")
  expect(GuideCompilerSettings.moduleSystem)->toBe("esmodule")
  expect(GuideCompilerSettings.warnFlags->String.includes("-109"))->toBe(true)
})

open Vitest

test("pins the guide to its validated v12 compiler with ESM output", async () => {
  expect(GuideCompilerSettings.version)->toBe("v12.3.1")
  expect(GuideCompilerSettings.parsedVersion->Semver.toString)->toBe(GuideCompilerSettings.version)
  expect(GuideCompilerSettings.moduleSystem)->toBe("esmodule")
  expect(GuideCompilerSettings.warnFlags->String.includes("-109"))->toBe(true)
})

open ScriptTest

let check = async markdown => {
  let directory = await temporaryDirectory("v13-api-links-")
  let options = {cwd: directory, env: environment, encoding: "utf8"}
  expectSuccess(spawn("git", ["init", "--quiet"], options))
  expectSuccess(
    spawn(
      "git",
      ["remote", "add", "origin", "https://github.com/rescript-lang/rescript-lang.org.git"],
      options,
    ),
  )
  let docs = join([directory, "apps/docs"])
  let manual = join([docs, "markdown-pages/docs/manual"])
  await mkdir(manual, {recursive: true})
  let apiDirectory = join([directory, "data/api"])
  await ApiDataFixtures.snapshot(apiDirectory, "v12.99.0", "MaintenanceModule")
  await ApiDataFixtures.snapshot(apiDirectory, "v13.3.1", "Example")
  await write(join([manual, "api.mdx"]), markdown)
  spawn(
    executable,
    [join([cwd(), "scripts/test-hrefs.mjs"])],
    {
      cwd: docs,
      env: withEnvironment(environment, [("CI", "1")]),
      encoding: "utf8",
    },
  )
}

test("link validation accepts routes from the selected v13 publication", async () => {
  let result = await check(`
[Stdlib](/docs/manual/api/stdlib)
[Dom](/docs/manual/api/dom)
[Nested module](/docs/manual/api/belt/example/)
[API entry](/docs/manual/api/stdlib/example#value-get)
`)
  expectSuccess(result)
  expect(result.stdout)->toContain("0 issues found")
})

for_([
  "/docs/manual/api/stdlibdom",
  "/docs/manual/api/stdlib/typo",
  "/docs/manual/api/stdlib/maintenancemodule",
  "/docs/manual/missing-page",
  "./nested/docs/manual/api/dom",
])("link validation rejects missing or wrong-major API targets: %s", async href => {
  let result = await check(
    `
[Valid API](/docs/manual/api/dom)
[Missing page](${href})
`,
  )
  expectStatus(result, 1)
  expect(result.stdout)->toContain("Cannot find file")
})

open ScriptTest
open LighthouseFixtures

test("Lighthouse artifact names preserve a readable prefix and stable digest", async () => {
  expect(artifactName("perf/fonts"))->toBe(
    "homepage-lighthouse-perf-fonts-a9ef7a117bc3c939559f13724bd78bbc231b97b13463faf0ef79c93832877844",
  )
})

for_([
  ("slash and hyphen", "perf/fonts", "perf-fonts"),
  ("case", "perf/fonts", "Perf/Fonts"),
  ("truncated suffixes", `${String.repeat("a", 80)}-one`, `${String.repeat("a", 80)}-two`),
  ("Unicode", "\u65e5\u672c", "\u4e2d\u6587"),
])("Lighthouse artifact names distinguish %s", async ((_, left, right)) => {
  expect(artifactName(left) != artifactName(right))->toBe(true)
  expect(artifactName(left))->toMatch(/^homepage-lighthouse-[a-z0-9-]{1,80}-[a-f0-9]{64}$/)
  expect(artifactName(right))->toMatch(/^homepage-lighthouse-[a-z0-9-]{1,80}-[a-f0-9]{64}$/)
})

test("artifact-name CLI prints the same key used by the report helper", async () => {
  let state = await workspace()
  let result = run(state, ["artifact-name", "perf/fonts"], ())
  expectSuccess(result)
  expect(result.stdout)->toBe(`${artifactName("perf/fonts")}\n`)
})

for_([[], [""]])("artifact-name CLI rejects missing or empty branch %j", async arguments => {
  let state = await workspace()
  let result = run(state, ["artifact-name", ...arguments], ())
  expectStatus(result, 1)
  expect(result.stdout)->toBe("")
  expect(result.stderr)->toContain("A branch name is required for artifact-name")
})

test("median handles odd and even collections without changing the input", async () => {
  let values = [3., 1., 2.]
  expect(median(values))->toBe(2.)
  expect(median([4., 1., 3., 2.]))->toBe(2.5)
  expect(values)->toStrictEqual([3., 1., 2.])
})

test("createBaseline records median Lighthouse scores", async () => {
  expect(createBaseline(input))->toStrictEqual({
    schemaVersion: 1,
    branch: input.branch,
    commit: input.commit,
    url: input.url,
    collectedAt: "2026-09-18T13:03:00.000Z",
    runs: 3,
    scores: {performance: 80, accessibility: 73, bestPractices: 98, seo: 50},
  })
})

test("formatComment compares scores and links the full artifact", async () => {
  let current = createBaseline(input)
  let target = {
    ...current,
    branch: "test/homepage-performance-guardrails",
    commit: "abcdef1234567890",
    scores: {performance: 78, accessibility: 74, bestPractices: 98, seo: 50},
  }
  let comment = formatComment({current, target, targetBranch: target.branch, artifactUrl})
  expect(comment)->toContain(
    "Compared with target branch `test/homepage-performance-guardrails` at commit `abcdef1`",
  )
  expect(comment)->toContain("| Category | Target | Current | Change |")
  expect(comment)->toContain("| Performance | 78 | **80** | +2 |")
  expect(comment)->toContain("| Accessibility | 74 | **73** | -1 |")
  expect(comment)->toContain(`[Download the full Lighthouse reports and baseline](${artifactUrl})`)
})

test("formatComment identifies a missing target branch baseline", async () => {
  let comment = formatComment({current: createBaseline(input), targetBranch: "master", artifactUrl})
  expect(comment)->toContain("No Lighthouse baseline is available for target branch `master`")
  expect(comment)->toContain("| Performance | N/A | **80** | N/A |")
})

test("baseline and comment CLI preserve the restored target in the report artifact", async () => {
  let state = await workspace()
  await write(join([state.directory, ".lighthouse-target/baseline.json"]), json(target))
  expectSuccess(run(state, ["baseline"], ()))
  expect(await readJson(join([state.directory, ".lighthouseci/baseline.json"])))->toStrictEqual(
    jsonValue(createBaseline(input)),
  )
  expect(
    await readJson(join([state.directory, ".lighthouseci/target-baseline.json"])),
  )->toStrictEqual(jsonValue(target))
  expectSuccess(run(state, ["comment"], ()))
  let comment = await read(join([state.directory, ".lighthouseci/comment.md"]))
  expect(comment)->toContain("Compared with target branch `master` at commit `abcdef1`")
  expect(comment)->toContain("| Performance | 80 | **80** | 0 |")
  expect(comment)->toContain("actions/runs/1/artifacts/2")
})

test("baseline and comment CLI support an absent target baseline", async () => {
  let state = await workspace()
  expectSuccess(run(state, ["baseline"], ()))
  expect(exists(join([state.directory, ".lighthouseci/target-baseline.json"])))->toBe(false)
  expectSuccess(run(state, ["comment"], ()))
  let comment = await read(join([state.directory, ".lighthouseci/comment.md"]))
  expect(comment)->toContain("No Lighthouse baseline is available for target branch `master`")
  expect(comment)->toContain("| Performance | N/A | **80** | N/A |")
})

test("report CLI honors configured input and output paths", async () => {
  let state = await workspace(~reportDirectory="reports", ())
  let currentPath = join([state.directory, "current.json"])
  let targetPath = join([state.directory, "target.json"])
  let commentPath = join([state.directory, "summary.md"])
  let overrides = [
    ("LIGHTHOUSE_REPORT_DIRECTORY", join([state.directory, "reports"])),
    ("LIGHTHOUSE_BASELINE_PATH", currentPath),
    ("LIGHTHOUSE_TARGET_BASELINE_PATH", targetPath),
    ("LIGHTHOUSE_COMMENT_PATH", commentPath),
  ]
  await write(targetPath, json(target))
  expectSuccess(run(state, ["baseline"], ~overrides, ()))
  expect(await readJson(currentPath))->toStrictEqual(jsonValue(createBaseline(input)))
  expect(await readJson(join([state.directory, "reports/target-baseline.json"])))->toStrictEqual(
    jsonValue(target),
  )
  expectSuccess(run(state, ["comment"], ~overrides, ()))
  expect(await read(commentPath))->toContain("Compared with target branch `master`")
})

for_([
  ("baseline", "LIGHTHOUSE_BRANCH"),
  ("baseline", "GITHUB_SHA"),
  ("baseline", "LIGHTHOUSE_URL"),
  ("comment", "LIGHTHOUSE_TARGET_BRANCH"),
  ("comment", "LIGHTHOUSE_ARTIFACT_URL"),
])("report CLI rejects missing required environment variable %j", async ((command, variable)) => {
  let state = await workspace()
  expectSuccess(run(state, ["baseline"], ()))
  let result = run(state, [command], ~overrides=[(variable, "")], ())
  expectStatus(result, 1)
  expect(result.stderr)->toContain(`Missing required environment variable ${variable}`)
})

test("comment CLI rejects a missing current baseline", async () => {
  let state = await workspace()
  let result = run(state, ["comment"], ())
  expectStatus(result, 1)
  expect(result.stderr)->toContain("Current Lighthouse baseline not found")
})

test("baseline CLI rejects malformed target JSON", async () => {
  let state = await workspace()
  await write(join([state.directory, ".lighthouse-target/baseline.json"]), "not JSON")
  let result = run(state, ["baseline"], ())
  expectStatus(result, 1)
  expect(result.stderr)->toContain("SyntaxError")
  expect(exists(join([state.directory, ".lighthouseci/baseline.json"])))->toBe(false)
})

for_([[], ["unknown"]])("report CLI rejects missing or unknown command %j", async command => {
  let state = await workspace()
  let result = run(state, command, ())
  expectStatus(result, 1)
  expect(result.stderr)->toContain("Unknown Lighthouse report command")
})

test("baseline rejects absent reports and missing fetch times", async () => {
  expect(() => median([]))->toThrow("Cannot calculate a median without values")
  expect(() => createBaseline({...input, reports: []}))->toThrow("No Lighthouse reports were found")
  expect(() =>
    createInvalidBaseline(JSON.parseOrThrow(`{"reports":[{"categories":{}}]}`))
  )->toThrow("missing its fetch time")
})

for_([
  `{}`,
  `{"categories":{}}`,
  `{"categories":{"performance":{"score":null}}}`,
])("baseline rejects missing or invalid scores %s", async properties => {
  let report = properties->JSON.parseOrThrow->JSON.Decode.object->Option.getOr(Dict.make())
  let report = Dict.fromArray(
    [...Dict.toArray(report), ("fetchTime", JSON.Encode.string("2026-09-18T13:01:00.000Z"))],
  )
  let input = JSON.Encode.object(
    Dict.fromArray([("reports", JSON.Encode.array([JSON.Encode.object(report)]))]),
  )
  expect(() => createInvalidBaseline(input))->toThrow("missing performance category score")
})

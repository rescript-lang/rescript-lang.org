open ScriptTest
module Workflow = LighthouseWorkflowFixtures

test("environment uses the PR's live target branch and existing artifact keys", async () => {
  let state = await Workflow.fixture(~overrides=[("GH_RESPONSE", "release/current\n")], ())
  expectSuccess(Workflow.run("lighthouse-environment.sh", state))
  let environment = await Workflow.environmentContents(state)
  expect(environment)->toContain("LIGHTHOUSE_BRANCH=Perf/Homepage\n")
  expect(environment)->toContain("LIGHTHOUSE_TARGET_BRANCH=release/current\n")
  expect(environment)->toContain(
    `LIGHTHOUSE_TARGET_ARTIFACT_NAME=${LighthouseFixtures.artifactName("release/current")}\n`,
  )
  expect(environment)->toContain(
    `LIGHTHOUSE_ARTIFACT_NAME=${LighthouseFixtures.artifactName("Perf/Homepage")}\n`,
  )
  expect(await Workflow.calls(state))->toStrictEqual([
    LighthouseFixtures.jsonValue(["api", "/repos/owner/site/pulls/1355", "--jq", ".base.ref"]),
  ])
})

test("production uses its own baseline without a PR lookup", async () => {
  let state = await Workflow.fixture(
    ~overrides=[("GITHUB_EVENT_NAME", "push"), ("RAW_BRANCH", "master"), ("GH_FAIL", "1")],
    (),
  )
  expectSuccess(Workflow.run("lighthouse-environment.sh", state))
  expect(await Workflow.environmentContents(state))->toContain("LIGHTHOUSE_TARGET_BRANCH=master\n")
  expect(exists(join([state.directory, "calls.jsonl"])))->toBe(false)
})

for_([
  ("master", "VITE_DEPLOYMENT_URL=\n", "DOCS_DEPLOYMENT_URL=https://rescript-lang.org\n"),
  (
    "Perf/Homepage",
    "VITE_DEPLOYMENT_URL=https://perf-homepage.rescript-lang.pages.dev\n",
    "DOCS_DEPLOYMENT_URL=https://perf-homepage.rescript-lang.pages.dev\n",
  ),
])("deployment environment for %s does not depend on GitHub artifact access", async ((
  branch,
  expectedViteUrl,
  expectedDocsUrl,
)) => {
  let state = await Workflow.fixture(~overrides=[("RAW_BRANCH", branch), ("GH_FAIL", "1")], ())
  expectSuccess(Workflow.run("deployment-environment.sh", state))
  let environment = await Workflow.environmentContents(state)
  expect(environment)->toContain(expectedViteUrl)
  expect(environment)->toContain(expectedDocsUrl)
  expect(exists(join([state.directory, "calls.jsonl"])))->toBe(false)
})

test("missing target artifacts are allowed", async () => {
  let state = await Workflow.fixture()
  let result = Workflow.run("lighthouse-restore.sh", state)
  expectSuccess(result)
  expect(result.stdout)->toContain("No Lighthouse baseline found for target branch master")
  expect((await Workflow.calls(state))->Array.length)->toBe(1)
})

test("restores and extracts the selected baseline archive", async () => {
  let state = await Workflow.fixture(~overrides=[("GH_RESPONSE", "42\n")], ())
  let state = await Workflow.withArchive(state)
  expectSuccess(Workflow.run("lighthouse-restore.sh", state))
  await Workflow.expectRestored(state)
  let requests = await Workflow.calls(state)
  expect(requests->Array.length)->toBe(3)
  expect(requests->Array.get(1))->toStrictEqual(
    Some(LighthouseFixtures.jsonValue(["api", "/repos/owner/site/actions/artifacts/42/zip"])),
  )
  expect(requests->Array.get(2))->toStrictEqual(Some(Workflow.unzipCall(state)))
})

for_([404, 410])(
  "restore re-queries after a disappearing artifact returns HTTP %i",
  async status => {
    let overrides = Workflow.steps([
      {stdout: "42\n"},
      {
        error: `gh: Artifact unavailable (HTTP ${Int.toString(status)})\n`,
        stdout: `{"message":"Artifact unavailable"}`,
      },
      {stdout: "43\n"},
      {},
    ])
    let state = await Workflow.fixture(~overrides, ())
    let state = await Workflow.withArchive(state)
    expectSuccess(Workflow.run("lighthouse-restore.sh", state))
    let requests = await Workflow.calls(state)
    expect(requests->Array.length)->toBe(5)
    expect(requests->Array.get(0))->toStrictEqual(requests->Array.get(2))
    expect(requests->Array.get(3))->toStrictEqual(
      Some(LighthouseFixtures.jsonValue(["api", "/repos/owner/site/actions/artifacts/43/zip"])),
    )
    expect(requests->Array.get(4))->toStrictEqual(Some(Workflow.unzipCall(state)))
    await Workflow.expectRestored(state)
  },
)

test("restore allows a baseline that disappears without a replacement", async () => {
  let state = await Workflow.fixture(
    ~overrides=Workflow.steps([
      {stdout: "42\n"},
      {error: "gh: Not Found (HTTP 404)\n"},
      {stdout: ""},
    ]),
    (),
  )
  let result = Workflow.run("lighthouse-restore.sh", state)
  expectSuccess(result)
  expect(result.stdout)->toContain("No Lighthouse baseline found")
  expect((await Workflow.calls(state))->Array.length)->toBe(3)
  await Workflow.expectNoArchive(state)
})

test("restore stops after three missing downloads and allows no baseline", async () => {
  let state = await Workflow.fixture(
    ~overrides=Workflow.steps(
      [42, 43, 44]->Array.flatMap(id => [
        {LighthouseWorkflowFixtures.stdout: `${Int.toString(id)}\n`},
        {error: "gh: Not Found (HTTP 404)\n"},
      ]),
    ),
    (),
  )
  let result = Workflow.run("lighthouse-restore.sh", state)
  expectSuccess(result)
  expect(result.stdout)->toContain("after 3 attempts")
  expect((await Workflow.calls(state))->Array.length)->toBe(6)
  await Workflow.expectNoArchive(state)
})

for_([
  "gh: Bad credentials (HTTP 401)\n",
  "gh: Resource not accessible by integration (HTTP 403)\n",
  "gh: API rate limit exceeded (HTTP 429)\n",
  "gh: Internal Server Error (HTTP 500)\n",
  "error connecting to api.github.com\n",
])("restore propagates download failure: %s", async error => {
  let state = await Workflow.fixture(
    ~overrides=Workflow.steps([{stdout: "42\n"}, {error, status: 7}]),
    (),
  )
  let result = Workflow.run("lighthouse-restore.sh", state)
  expectStatus(result, 7)
  expect(result.stderr)->toBe(error)
  expect((await Workflow.calls(state))->Array.length)->toBe(2)
})

test("restore propagates a failed artifact re-query", async () => {
  let state = await Workflow.fixture(
    ~overrides=Workflow.steps([
      {stdout: "42\n"},
      {error: "gh: Not Found (HTTP 404)\n"},
      {error: "error connecting to api.github.com\n", status: 7},
    ]),
    (),
  )
  expectStatus(Workflow.run("lighthouse-restore.sh", state), 7)
  expect((await Workflow.calls(state))->Array.length)->toBe(3)
})

test("restore propagates extraction failures without retrying", async () => {
  let state = await Workflow.fixture(
    ~overrides=[("GH_RESPONSE", "42\n"), ("UNZIP_STATUS", "9")],
    (),
  )
  let state = await Workflow.withArchive(state)
  expectStatus(Workflow.run("lighthouse-restore.sh", state), 9)
  let requests = await Workflow.calls(state)
  expect(requests->Array.length)->toBe(3)
  expect(requests->Array.get(2))->toStrictEqual(Some(Workflow.unzipCall(state)))
})

test("cleanup preserves the newly uploaded artifact", async () => {
  let state = await Workflow.fixture(~overrides=[("GH_RESPONSE", "10\n20\n30\n")], ())
  expectSuccess(Workflow.run("lighthouse-cleanup.sh", state))
  let requests = await Workflow.calls(state)
  expect(requests->Array.slice(~start=1))->toStrictEqual([
    LighthouseFixtures.jsonValue([
      "api",
      "--method",
      "DELETE",
      "/repos/owner/site/actions/artifacts/10",
    ]),
    LighthouseFixtures.jsonValue([
      "api",
      "--method",
      "DELETE",
      "/repos/owner/site/actions/artifacts/30",
    ]),
  ])
})

test("cleanup allows an empty artifact list", async () => {
  let state = await Workflow.fixture()
  expectSuccess(Workflow.run("lighthouse-cleanup.sh", state))
  expect((await Workflow.calls(state))->Array.length)->toBe(1)
})

for_([
  "lighthouse-environment.sh",
  "lighthouse-restore.sh",
  "lighthouse-cleanup.sh",
])("%s propagates GitHub API failures", async script => {
  let state = await Workflow.fixture(~overrides=[("GH_FAIL", "1")], ())
  expectStatus(Workflow.run(script, state), 1)
  expect((await Workflow.calls(state))->Array.length)->toBe(1)
})

open ScriptTest

type step = {stdout?: string, error?: string, status?: int}

let ghFixture = `
const fs = require("node:fs");
const args = process.argv.slice(2);
const callIndex = fs.existsSync(process.env.CALLS)
  ? fs.readFileSync(process.env.CALLS, "utf8").trim().split("\\n").length
  : 0;
fs.appendFileSync(process.env.CALLS, JSON.stringify(args) + "\\n");
if (process.env.GH_FAIL === "1") process.exit(1);
if (process.env.GH_STEPS) {
  const step = JSON.parse(process.env.GH_STEPS)[callIndex];
  if (!step) process.exit(99);
  if (step.error) {
    process.stdout.write(step.stdout || "");
    process.stderr.write(step.error);
    process.exit(step.status ?? 1);
  }
  if (step.stdout !== undefined) {
    process.stdout.write(step.stdout);
    process.exit(0);
  }
}
if (args.some(arg => arg.endsWith("/zip"))) {
  process.stdout.write(fs.readFileSync(process.env.ARCHIVE));
} else if (!args.includes("DELETE")) {
  process.stdout.write(process.env.GH_RESPONSE || "");
}
`

let fixture = async (~overrides=[], ()) => {
  let directory = await temporaryDirectory("lighthouse-workflow-")
  await mkdir(join([directory, "bin"]), {recursive: true})
  await writeExecutable(join([directory, "bin/gh"]), `#!${executable}\n${ghFixture}`, {mode: 0o755})
  {
    directory,
    env: withEnvironment(
      environment,
      [
        ("PATH", `${directory}/bin:${environment->Dict.get("PATH")->Option.getOr("")}`),
        ("CALLS", join([directory, "calls.jsonl"])),
        ("GITHUB_ENV", join([directory, "environment"])),
        ("GITHUB_EVENT_NAME", "pull_request"),
        ("GITHUB_REPOSITORY", "owner/site"),
        ("PR_NUMBER", "1355"),
        ("RAW_BRANCH", "Perf/Homepage"),
        ("LIGHTHOUSE_TARGET_BRANCH", "master"),
        ("LIGHTHOUSE_TARGET_ARTIFACT_NAME", LighthouseFixtures.artifactName("master")),
        ("LIGHTHOUSE_ARTIFACT_NAME", LighthouseFixtures.artifactName("Perf/Homepage")),
        ("CURRENT_ARTIFACT_ID", "20"),
        ("RUNNER_TEMP", directory),
        ("GH_FAIL", "0"),
        ("GH_RESPONSE", ""),
        ("GH_STEPS", ""),
        ...overrides,
      ],
    ),
  }
}

let run = (script, state) =>
  spawn(
    "bash",
    [join([cwd(), "../../.github/scripts", script])],
    {
      cwd: state.directory,
      env: state.env,
      encoding: "utf8",
    },
  )

let calls = async state => {
  let contents = await read(join([state.directory, "calls.jsonl"]))
  contents->String.trim->String.split("\n")->Array.map(line => JSON.parseOrThrow(line))
}
let environmentContents = state => read(join([state.directory, "environment"]))
let steps = (steps: array<step>) => [("GH_STEPS", LighthouseFixtures.json(steps))]

// Use a real ZIP so the restore tests exercise extraction as well as download.
let withArchive = async state => {
  let archive = join([state.directory, "fixture.zip"])
  let contents = base64Buffer(
    "UEsDBBQAAAAAAAAAIVyGLD62EwAAABMAAAANAAAAYmFzZWxpbmUuanNvbnsiYnJhbmNoIjoibWFzdGVyIn1QSwECFAMUAAAAAAAAACFchiw+thMAAAATAAAADQAAAAAAAAAAAAAAgAEAAAAAYmFzZWxpbmUuanNvblBLBQYAAAAAAQABADsAAAA+AAAAAAA=",
  )
  await writeBuffer(archive, contents)
  {...state, env: withEnvironment(state.env, [("ARCHIVE", archive)])}
}

let expectRestored = async state => {
  expect(
    await read(join([state.directory, ".lighthouse-target/baseline.json"])),
  )->toBe(`{"branch":"master"}`)
}

let expectNoArchive = async state => {
  expect(await readdir(join([state.directory, ".lighthouse-target"])))->toStrictEqual([])
  expect(exists(join([state.directory, "lighthouse-target.zip"])))->toBe(false)
}

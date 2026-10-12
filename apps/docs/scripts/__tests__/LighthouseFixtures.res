open ScriptTest

type scores = {performance: int, accessibility: int, bestPractices: int, seo: int}
type baseline = {
  schemaVersion: int,
  branch: string,
  commit: string,
  url: string,
  collectedAt: string,
  runs: int,
  scores: scores,
}
type category = {score: float}
type categories = {
  performance: category,
  accessibility: category,
  @as("best-practices") bestPractices: category,
  seo: category,
}
type report = {fetchTime: string, categories: categories}
type baselineInput = {reports: array<report>, branch: string, commit: string, url: string}
type commentInput = {
  current: baseline,
  target?: baseline,
  targetBranch: string,
  artifactUrl: string,
}

@module("../lighthouse-report.mjs")
external artifactName: string => string = "lighthouseArtifactName"
@module("../lighthouse-report.mjs") external median: array<float> => float = "median"
@module("../lighthouse-report.mjs")
external createBaseline: baselineInput => baseline = "createBaseline"
@module("../lighthouse-report.mjs")
external createInvalidBaseline: JSON.t => baseline = "createBaseline"
@module("../lighthouse-report.mjs") external formatComment: commentInput => string = "formatComment"

let report = (performance, accessibility, bestPractices, seo, fetchTime) => {
  fetchTime,
  categories: {
    performance: {score: performance},
    accessibility: {score: accessibility},
    bestPractices: {score: bestPractices},
    seo: {score: seo},
  },
}
let reports = [
  report(0.79, 0.73, 1., 0.5, "2026-09-18T13:01:00.000Z"),
  report(0.88, 0.74, 0.96, 0.51, "2026-09-18T13:02:00.000Z"),
  report(0.8, 0.72, 0.98, 0.49, "2026-09-18T13:03:00.000Z"),
]
let input = {
  reports,
  branch: "perf/homepage",
  commit: "1234567890abcdef",
  url: "https://1234.rescript-lang.pages.dev",
}
let target = createBaseline({...input, branch: "master", commit: "abcdef1234567890"})
let artifactUrl = "https://github.com/example/actions/runs/1/artifacts/2"
let script = join([cwd(), "scripts/lighthouse-report.mjs"])

let workspace = async (~reportDirectory=".lighthouseci", ()) => {
  let directory = await temporaryDirectory("lighthouse-report-")
  await mkdir(join([directory, reportDirectory]), {recursive: true})
  await mkdir(join([directory, ".lighthouse-target"]), {recursive: true})
  let _ = await reports
  ->Array.mapWithIndex((report, index) =>
    write(
      join([directory, reportDirectory, `lhr-${Int.toString(index)}.json`]),
      JSON.stringifyAny(report)->Option.getOr(""),
    )
  )
  ->Promise.all
  await write(join([directory, reportDirectory, "manifest.json"]), "{}")
  let inherited =
    environment
    ->Dict.toArray
    ->Array.filter(((key, _)) => !(key->String.startsWith("LIGHTHOUSE_")) && key != "GITHUB_SHA")
    ->Dict.fromArray
  {
    directory,
    env: withEnvironment(
      inherited,
      [
        ("LIGHTHOUSE_BRANCH", input.branch),
        ("GITHUB_SHA", input.commit),
        ("LIGHTHOUSE_URL", input.url),
        ("LIGHTHOUSE_TARGET_BRANCH", "master"),
        ("LIGHTHOUSE_ARTIFACT_URL", artifactUrl),
      ],
    ),
  }
}

let run = (state, command, ~overrides=[], ()) =>
  spawn(
    executable,
    [script, ...command],
    {
      cwd: state.directory,
      env: withEnvironment(state.env, overrides),
      encoding: "utf8",
    },
  )
let json = value => JSON.stringifyAny(value)->Option.getOr("")
let jsonValue = value => json(value)->JSON.parseOrThrow

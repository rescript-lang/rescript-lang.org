type assertion<'a>
@module("vitest") external test: (string, unit => promise<unit>) => unit = "test"
@module("vitest") @scope("test")
external for_: array<'a> => (string, 'a => promise<unit>) => unit = "for"
@module("vitest") external describe: (string, unit => unit) => unit = "describe"
@module("vitest") external afterEach: (unit => unit) => unit = "afterEach"
@module("vitest") external expect: 'a => assertion<'a> = "expect"
@send external toBe: (assertion<'a>, 'a) => unit = "toBe"
@send external toEqual: (assertion<'a>, 'a) => unit = "toEqual"
@send @scope("not") external notToMatch: (assertion<string>, RegExp.t) => unit = "toMatch"
@send @scope("rejects")
external rejectsWith: (assertion<promise<'a>>, string) => promise<unit> = "toThrow"
@send @scope("rejects")
external rejectsWithError: assertion<promise<'a>> => promise<unit> = "toBeDefined"
@module("vitest") @scope("vi") external restoreMocks: unit => unit = "restoreAllMocks"
@module("vitest") @scope("vi") external unstubEnvs: unit => unit = "unstubAllEnvs"
@module("vitest") @scope("vi") external unstubGlobals: unit => unit = "unstubAllGlobals"
@module("vitest") @scope("vi") external stubEnv: (string, string) => unit = "stubEnv"
@module("vitest") @scope("vi")
external stubFetch: (@as("fetch") _, string => promise<WebAPI.FetchAPI.response>) => unit =
  "stubGlobal"

type console
type mock
@val external console: console = "console"
@module("vitest") @scope("vi") external spyOn: (console, @as("error") _) => mock = "spyOn"
@send
external mockImplementation: (mock, (string, JsError.t) => unit) => unit = "mockImplementation"

type sandbox = {
  console: Dict.t<JSON.t>,
  parent: {window: {postMessage: (JSON.t, string) => unit}},
}
type context
@module("node:vm") external createContext: sandbox => context = "createContext"
@module("node:vm") external runInContext: (string, context) => unit = "runInContext"

afterEach(() => {
  restoreMocks()
  unstubEnvs()
  unstubGlobals()
})

describe("compiler versions", () => {
  test("sorts numeric version components and prerelease identifiers", async () => {
    let versions = [
      "v12.9.10",
      "v12.10.0-alpha.2",
      "v12.9.11",
      "v12.10.0-alpha.10",
      "v12.10.0",
      "v12.10.0-rc.1",
      "v12.10.0-beta.1",
    ]
    expect(CompilerVersions.supported(versions)->Array.map(Semver.toString))->toEqual([
      "v12.10.0",
      "v12.10.0-rc.1",
      "v12.10.0-beta.1",
      "v12.10.0-alpha.10",
      "v12.10.0-alpha.2",
      "v12.9.11",
      "v12.9.10",
    ])
    let stable = Semver.parse("v12.10.0")->Option.getOrThrow
    expect(Semver.compare(stable, stable))->toBe(0.)
    expect(CompilerVersions.latestStable(CompilerVersions.supported(versions)))->toEqual(
      Some(stable),
    )
  })

  test("keeps the supported compiler range and ignores invalid versions", async () => {
    expect(
      CompilerVersions.supported([
        "invalid",
        "v9.1.0",
        "v10.0.1",
        "v10.1.0",
        "v11.1.3",
        "v11.1.4",
        "v11.2.0-beta.2",
        "v11.2.0",
        "v12.1.0-alpha.1",
        "v12.1.0",
        "v12.2.0-alpha.1",
        "v13.0.0-alpha.1",
      ])->Array.map(Semver.toString),
    )->toEqual(["v13.0.0-alpha.1", "v12.2.0-alpha.1", "v12.1.0", "v11.2.0", "v11.1.4", "v10.1.0"])
  })
})

describe("runtime imports", () => {
  for_([
    ("v12.3.1", "./stdlib/Stdlib_Array.js", "v12.3.1", "Stdlib_Array.js"),
    ("v13.0.0-alpha.1", "./stdlib/Stdlib_Array.mjs", "v13.0.0-alpha.1", "Stdlib_Array.js"),
    ("v12.0.0-alpha.7", "./stdlib/core__Array.js", "v12.0.0-alpha.9", "Array.js"),
    ("v12.0.0-alpha.8", "./stdlib/core__Array.js", "v12.0.0-alpha.9", "core__Array.js"),
    ("v11.1.4", "./stdlib/core__Array.js", "v11.2.0-beta.2", "Core__Array.js"),
  ])("maps %s imports consistently in both apps", async ((
    version,
    path,
    runtimeVersion,
    filename,
  )) => {
    let compilerVersion = Semver.parse(version)->Option.getOrThrow
    let expected = `https://bundles.test/${runtimeVersion}/compiler-builtins/stdlib/${filename}`
    expect(
      CompilerRuntimeImport.url(~bundleBaseUrl="https://bundles.test", ~compilerVersion, path),
    )->toBe(expected)
    expect(
      GuideRuntimeImport.url(~bundleBaseUrl="https://bundles.test", ~compilerVersion, path),
    )->toBe(expected)
    expect(
      CompilerManagerHook.CdnMeta.getStdlibRuntimeUrl(
        "https://bundles.test",
        Semver.parse(runtimeVersion)->Option.getOrThrow,
        filename,
      ),
    )->toBe(expected)
  })

  test("both transforms collect namespace imports without accepting lookalike paths", async () => {
    let source = `
      import * as Arrays from "./stdlib/Stdlib_Array.js";
      import * as Other from "./stdlib-other/Other.js";
      import Default from "./stdlib/Default.js";
      import { value } from "./stdlib/Named.js";
      import "./stdlib/SideEffect.js";
      import * as React from "react";
      const answer = Arrays.length([]);
      export { answer };
    `
    let expected = Dict.fromArray([("Arrays", "./stdlib/Stdlib_Array.js")])
    expect(
      Babel.RuntimeImports.collect(Babel.Parser.parse(source, {sourceType: "module"})),
    )->toEqual(expected)
    let playground = Babel.PlaygroundValidator.validate(
      Babel.Parser.parse(source, {sourceType: "module"}),
    )
    let guide = GuideRuntimeTransform.transform(source)->Option.getOrThrow
    expect(playground.imports)->toEqual(expected)
    expect(guide.imports)->toEqual(expected)
    expect(playground.code)->notToMatch(/\b(import|export)\b/)
    expect(guide.code)->notToMatch(/\b(import|export)\b/)
  })

  test("preserves the playground React entry point detection", async () => {
    let source = "function Playground$App() {} const App = {make: Playground$App}; export {App};"
    expect(
      Babel.PlaygroundValidator.validate(
        Babel.Parser.parse(source, {sourceType: "module"}),
      ).entryPointExists,
    )->toBe(true)
  })
})

describe("console bridge", () => {
  test("serializes iframe logs for the shared decoder, including null", async () => {
    let messages = []
    let origins = []
    let sandbox = createContext({
      console: Dict.make(),
      parent: {
        window: {
          postMessage: (message, origin) => {
            messages->Array.push(message)
            origins->Array.push(origin)
          },
        },
      },
    })
    runInContext(RuntimeConsole.bridgeScript, sandbox)
    runInContext(
      `console.log(null, undefined, {answer: 42}, 5, true); console.warn("warning"); console.error("error")`,
      sandbox,
    )
    expect(origins)->toEqual(["*", "*", "*"])
    expect(messages->Array.map(RuntimeConsole.fromMessage))->toEqual([
      Some({level: #log, content: ["null", "undefined", `{"answer":42}`, "5", "true"]}),
      Some({level: #warn, content: ["warning"]}),
      Some({level: #error, content: ["error"]}),
    ])
    expect(
      messages
      ->Array.getUnsafe(0)
      ->RuntimeConsole.fromMessage
      ->Option.getOrThrow
      ->RuntimeConsole.text,
    )->toBe(`null undefined {"answer":42} 5 true`)
  })

  for_([
    "null",
    "[]",
    `"message"`,
    "{}",
    `{"type":"other","args":[]}`,
    `{"type":"log","args":"text"}`,
    `{"type":"log","args":[null]}`,
    `{"type":"log","args":[{}]}`,
  ])("ignores malformed or unrelated messages: %s", async message => {
    expect(message->JSON.parseOrThrow->RuntimeConsole.fromMessage)->toBe(None)
  })
})

describe("compiler metadata", () => {
  test(
    "uses same-origin bundles in production, the CDN in development, and explicit overrides",
    async () => {
      expect(
        CompilerData.endpoints(
          ~location=SameOriginInProduction,
          ~nodeEnv="production",
          ~override=None,
        ),
      )->toEqual({
        bundleBaseUrl: "/playground-bundles",
        versionsBaseUrl: CompilerData.cdnBaseUrl,
      })
      expect(
        CompilerData.endpoints(
          ~location=SameOriginInProduction,
          ~nodeEnv="development",
          ~override=None,
        ),
      )->toEqual({
        bundleBaseUrl: CompilerData.cdnBaseUrl,
        versionsBaseUrl: CompilerData.cdnBaseUrl,
      })
      expect(
        CompilerData.endpoints(~location=Remote, ~nodeEnv="production", ~override=None),
      )->toEqual({
        bundleBaseUrl: CompilerData.cdnBaseUrl,
        versionsBaseUrl: CompilerData.cdnBaseUrl,
      })
      expect(
        CompilerData.endpoints(
          ~location=SameOriginInProduction,
          ~nodeEnv="production",
          ~override=Some("https://override.test"),
        ),
      )->toEqual({
        bundleBaseUrl: "https://override.test",
        versionsBaseUrl: "https://override.test",
      })
    },
  )

  test("fetches metadata from the override without changing the guide pin", async () => {
    stubEnv("PLAYGROUND_BUNDLE_ENDPOINT", "https://override.test")
    let urls = []
    stubFetch(
      url => {
        urls->Array.push(url)
        Promise.resolve(WebAPI.Response.fromString(`["v13.0.0","v12.3.1"]`))
      },
    )
    expect(await CompilerData.load(~location=SameOriginInProduction))->toEqual(
      Some({
        bundleBaseUrl: "https://override.test",
        versions: ["v13.0.0", "v12.3.1"],
      }),
    )
    expect(urls)->toEqual(["https://override.test/playground-bundles/versions.json"])
    expect(GuideCompilerData.load())->toEqual({bundleBaseUrl: "https://override.test"})
    expect(GuideCompilerSettings.version)->toBe("v12.3.1")
    expect(urls->Array.length)->toBe(1)
  })

  test("rejects an HTTP error even if its body looks like metadata", async () => {
    stubFetch(_ => Promise.resolve(WebAPI.Response.fromString("[]", ~init={status: 503})))
    await expect(CompilerData.fetchVersions("https://bundles.test"))->rejectsWith("HTTP 503")
  })

  for_(["{", "{}", `["v12.3.1",123]`])("rejects invalid metadata: %s", async body => {
    stubFetch(_ => Promise.resolve(WebAPI.Response.fromString(body)))
    await expect(CompilerData.fetchVersions("https://bundles.test"))->rejectsWithError
  })

  test("returns the loader's failure state when the network is unavailable", async () => {
    stubFetch(async _ => JsError.throwWithMessage("offline"))
    let errors = []
    spyOn(console)->mockImplementation(
      (message, error) => {
        errors->Array.push((message, error->JsError.message))
      },
    )
    expect(await CompilerData.load(~location=SameOriginInProduction))->toBe(None)
    expect(errors)->toEqual([("error while fetching compiler versions", "offline")])
  })
})

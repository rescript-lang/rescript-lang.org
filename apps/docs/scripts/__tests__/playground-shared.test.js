import { runInNewContext } from "node:vm";
import { parse } from "@babel/parser";
import { afterEach, describe, expect, test, vi } from "vitest";
import * as Babel from "../../../../packages/shared/src/Babel.jsx";
import * as CompilerData from "../../../../packages/shared/src/CompilerData.jsx";
import * as CompilerRuntimeImport from "../../../../packages/shared/src/CompilerRuntimeImport.jsx";
import * as CompilerVersions from "../../../../packages/shared/src/CompilerVersions.jsx";
import * as RuntimeConsole from "../../../../packages/shared/src/RuntimeConsole.jsx";
import * as Semver from "../../../../packages/shared/src/Semver.jsx";
import * as GuideCompilerData from "../../../guide/app/GuideCompilerData.jsx";
import * as GuideCompilerSettings from "../../../guide/app/GuideCompilerSettings.jsx";
import * as GuideRuntimeImport from "../../../guide/app/GuideRuntimeImport.jsx";
import * as GuideRuntimeTransform from "../../../guide/app/GuideRuntimeTransform.jsx";
import { CdnMeta } from "../../../../packages/playground/src/CompilerManagerHook.jsx";

afterEach(() => {
  vi.restoreAllMocks();
  vi.unstubAllEnvs();
  vi.unstubAllGlobals();
});

describe("compiler versions", () => {
  test("sorts numeric version components and prerelease identifiers", () => {
    const versions = [
      "v12.9.10",
      "v12.10.0-alpha.2",
      "v12.9.11",
      "v12.10.0-alpha.10",
      "v12.10.0",
      "v12.10.0-rc.1",
      "v12.10.0-beta.1",
    ];
    expect(CompilerVersions.supported(versions).map(Semver.toString)).toEqual([
      "v12.10.0",
      "v12.10.0-rc.1",
      "v12.10.0-beta.1",
      "v12.10.0-alpha.10",
      "v12.10.0-alpha.2",
      "v12.9.11",
      "v12.9.10",
    ]);
    expect(
      Semver.compare(Semver.parse("v12.10.0"), Semver.parse("v12.10.0")),
    ).toBe(0);
    expect(
      CompilerVersions.latestStable(CompilerVersions.supported(versions)),
    ).toEqual(Semver.parse("v12.10.0"));
  });

  test("keeps the supported compiler range and ignores invalid versions", () => {
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
      ]).map(Semver.toString),
    ).toEqual([
      "v13.0.0-alpha.1",
      "v12.2.0-alpha.1",
      "v12.1.0",
      "v11.2.0",
      "v11.1.4",
      "v10.1.0",
    ]);
  });
});

describe("runtime imports", () => {
  test.each([
    ["v12.3.1", "./stdlib/Stdlib_Array.js", "v12.3.1", "Stdlib_Array.js"],
    [
      "v13.0.0-alpha.1",
      "./stdlib/Stdlib_Array.mjs",
      "v13.0.0-alpha.1",
      "Stdlib_Array.js",
    ],
    [
      "v12.0.0-alpha.7",
      "./stdlib/core__Array.js",
      "v12.0.0-alpha.9",
      "Array.js",
    ],
    [
      "v12.0.0-alpha.8",
      "./stdlib/core__Array.js",
      "v12.0.0-alpha.9",
      "core__Array.js",
    ],
    ["v11.1.4", "./stdlib/core__Array.js", "v11.2.0-beta.2", "Core__Array.js"],
  ])(
    "maps %s imports consistently in both apps",
    (version, path, runtimeVersion, filename) => {
      const compilerVersion = Semver.parse(version);
      const expected = `https://bundles.test/${runtimeVersion}/compiler-builtins/stdlib/${filename}`;
      expect(
        CompilerRuntimeImport.url(
          "https://bundles.test",
          compilerVersion,
          path,
        ),
      ).toBe(expected);
      expect(
        GuideRuntimeImport.url("https://bundles.test", compilerVersion, path),
      ).toBe(expected);
      expect(
        CdnMeta.getStdlibRuntimeUrl(
          "https://bundles.test",
          Semver.parse(runtimeVersion),
          filename,
        ),
      ).toBe(expected);
    },
  );

  test("both transforms collect namespace imports without accepting lookalike paths", () => {
    const source = `
      import * as Arrays from "./stdlib/Stdlib_Array.js";
      import * as Other from "./stdlib-other/Other.js";
      import Default from "./stdlib/Default.js";
      import { value } from "./stdlib/Named.js";
      import "./stdlib/SideEffect.js";
      import * as React from "react";
      const answer = Arrays.length([]);
      export { answer };
    `;
    const expected = { Arrays: "./stdlib/Stdlib_Array.js" };
    expect(
      Babel.RuntimeImports.collect(parse(source, { sourceType: "module" })),
    ).toEqual(expected);
    const playground = Babel.PlaygroundValidator.validate(
      parse(source, { sourceType: "module" }),
    );
    const guide = GuideRuntimeTransform.transform(undefined, source);
    expect(playground.imports).toEqual(expected);
    expect(guide.imports).toEqual(expected);
    expect(playground.code).not.toMatch(/\b(import|export)\b/);
    expect(guide.code).not.toMatch(/\b(import|export)\b/);
  });

  test("preserves the playground React entry point detection", () => {
    const source =
      "function Playground$App() {} const App = {make: Playground$App}; export {App};";
    expect(
      Babel.PlaygroundValidator.validate(
        parse(source, { sourceType: "module" }),
      ).entryPointExists,
    ).toBe(true);
  });
});

describe("console bridge", () => {
  test("serializes iframe logs for the shared decoder, including null", () => {
    const messages = [];
    const sandbox = {
      console: {},
      parent: {
        window: {
          postMessage: (message, origin) => messages.push({ message, origin }),
        },
      },
    };
    runInNewContext(RuntimeConsole.bridgeScript, sandbox);
    runInNewContext(
      `console.log(null, undefined, {answer: 42}, 5, true); console.warn("warning"); console.error("error")`,
      sandbox,
    );
    expect(messages.map(({ origin }) => origin)).toEqual(["*", "*", "*"]);
    expect(
      messages.map(({ message }) => RuntimeConsole.fromMessage(message)),
    ).toEqual([
      {
        level: "log",
        content: ["null", "undefined", '{"answer":42}', "5", "true"],
      },
      { level: "warn", content: ["warning"] },
      { level: "error", content: ["error"] },
    ]);
    expect(
      RuntimeConsole.text(RuntimeConsole.fromMessage(messages[0].message)),
    ).toBe('null undefined {"answer":42} 5 true');
  });

  test.each([
    null,
    [],
    "message",
    {},
    { type: "other", args: [] },
    { type: "log", args: "text" },
    { type: "log", args: [null] },
    { type: "log", args: [{}] },
  ])("ignores malformed or unrelated messages: %j", (message) => {
    expect(RuntimeConsole.fromMessage(message)).toBeUndefined();
  });
});

describe("compiler metadata", () => {
  test("uses same-origin bundles in production, the CDN in development, and explicit overrides", () => {
    expect(
      CompilerData.endpoints("SameOriginInProduction", "production", undefined),
    ).toEqual({
      bundleBaseUrl: "/playground-bundles",
      versionsBaseUrl: CompilerData.cdnBaseUrl,
    });
    expect(
      CompilerData.endpoints(
        "SameOriginInProduction",
        "development",
        undefined,
      ),
    ).toEqual({
      bundleBaseUrl: CompilerData.cdnBaseUrl,
      versionsBaseUrl: CompilerData.cdnBaseUrl,
    });
    expect(CompilerData.endpoints("Remote", "production", undefined)).toEqual({
      bundleBaseUrl: CompilerData.cdnBaseUrl,
      versionsBaseUrl: CompilerData.cdnBaseUrl,
    });
    expect(
      CompilerData.endpoints(
        "SameOriginInProduction",
        "production",
        "https://override.test",
      ),
    ).toEqual({
      bundleBaseUrl: "https://override.test",
      versionsBaseUrl: "https://override.test",
    });
  });

  test("fetches metadata from the override without changing the guide pin", async () => {
    vi.stubEnv("PLAYGROUND_BUNDLE_ENDPOINT", "https://override.test");
    const fetchMock = vi
      .fn()
      .mockResolvedValue(new Response(JSON.stringify(["v13.0.0", "v12.3.1"])));
    vi.stubGlobal("fetch", fetchMock);
    expect(await CompilerData.load("SameOriginInProduction")).toEqual({
      bundleBaseUrl: "https://override.test",
      versions: ["v13.0.0", "v12.3.1"],
    });
    expect(fetchMock).toHaveBeenCalledWith(
      "https://override.test/playground-bundles/versions.json",
    );
    expect(GuideCompilerData.load()).toEqual({
      bundleBaseUrl: "https://override.test",
    });
    expect(GuideCompilerSettings.version).toBe("v12.3.1");
    expect(fetchMock).toHaveBeenCalledTimes(1);
  });

  test("rejects an HTTP error even if its body looks like metadata", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue(new Response("[]", { status: 503 })),
    );
    await expect(
      CompilerData.fetchVersions("https://bundles.test"),
    ).rejects.toThrow("HTTP 503");
  });

  test.each(["{", "{}", '["v12.3.1", 123]'])(
    "rejects invalid metadata: %s",
    async (body) => {
      vi.stubGlobal("fetch", vi.fn().mockResolvedValue(new Response(body)));
      await expect(
        CompilerData.fetchVersions("https://bundles.test"),
      ).rejects.toBeDefined();
    },
  );

  test("returns the loader's failure state when the network is unavailable", async () => {
    vi.stubGlobal("fetch", vi.fn().mockRejectedValue(new Error("offline")));
    const error = vi.spyOn(console, "error").mockImplementation(() => {});
    expect(await CompilerData.load("SameOriginInProduction")).toBeUndefined();
    expect(error).toHaveBeenCalledWith(
      "error while fetching compiler versions",
      expect.any(Error),
    );
  });
});

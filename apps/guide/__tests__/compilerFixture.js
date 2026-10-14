import { afterEach, beforeEach, expect, vi } from "vitest";

const { loadScript, compile } = vi.hoisted(() => ({
  loadScript: vi.fn(),
  compile: vi.fn(),
}));

// Control the CDN boundary while exercising the real compiler manager, bridge,
// runtime transform, and iframe. No compiler bundles are fetched.
vi.mock("../../../packages/playground/ffi/loadScript.js", () => ({
  default: loadScript,
  removeScript: vi.fn(),
}));

let compilerRequest;

beforeEach(() => {
  compilerRequest = undefined;
  compile.mockReset();
  loadScript.mockImplementation((src, onSuccess, onError) => {
    if (src.endsWith("/compiler.js")) {
      compilerRequest = { onSuccess, onError };
    } else {
      onSuccess();
    }
    return () => {};
  });
});

afterEach(() => vi.unstubAllGlobals());

export async function waitForCompilerRequest() {
  await expect.poll(() => compilerRequest).toBeDefined();
}

export function failCompilerLoading() {
  compilerRequest.onError(new Error("Compiler unavailable"));
}

export function finishCompilerLoading(jsCode) {
  finishLoading({
    type: "success",
    js_code: jsCode,
    warnings: [],
    type_hints: [],
  });
}

export function finishCompilerLoadingWithError() {
  finishLoading({ type: "unexpected_error", msg: "Compilation failed" });
}

function finishLoading(result) {
  compile.mockReturnValue(result);
  vi.stubGlobal("rescript_compiler", {
    api_version: "8",
    make: () => ({
      version: "12.2.0",
      getConfig: () => ({ module_system: "esmodule", warn_flags: "" }),
      setModuleSystem: () => true,
      setWarnFlags: () => true,
      setOpenModules: () => true,
      setExperimentalFeatures: () => true,
      setJsxPreserveMode: () => true,
      rescript: { compile },
    }),
  });
  compilerRequest.onSuccess();
}

export function expectCompiled(code) {
  expect(compile).toHaveBeenCalledWith(code);
}

import assert from "node:assert/strict";
import { test } from "node:test";
import { resolve } from "node:path";
import { deadValues } from "../check-dead-code.mjs";

const root = resolve("fixture");
const diagnostic = (message, options = {}) => ({
  name: "Warning Dead Value",
  file: resolve(root, "src/Example.res"),
  message,
  range: [0, 0, 0, 10],
  ...options,
});

test("rejects unused exports and potentially side-effectful initializers", () => {
  const values = [
    diagnostic("Example.unused is never used"),
    diagnostic("unused is never used and could have side effects", {
      name: "Warning Dead Value With Side Effects",
    }),
  ];
  assert.deepEqual(deadValues(values, root), values);
});

test("keeps unused values in tests in scope", () => {
  const value = diagnostic("unused is never used", {
    file: resolve(root, "__tests__/Example.test.res"),
  });
  assert.deepEqual(deadValues([value], root), [value]);
});

test("ignores dependencies, external files, and deliberate underscore bindings", () => {
  const values = [
    diagnostic("unused is never used", {
      file: resolve(root, "node_modules/example/Example.res"),
    }),
    diagnostic("unused is never used", {
      file: resolve(root, "../sibling/Example.res"),
    }),
    diagnostic("_screen is never used"),
  ];
  assert.deepEqual(deadValues(values, root), []);
});

test("leaves record-field and argument diagnostics advisory", () => {
  assert.deepEqual(
    deadValues(
      [
        diagnostic("field is never used", { name: "Warning Dead Type" }),
        diagnostic("argument is never used", {
          name: "Warning Unused Argument",
        }),
      ],
      root,
    ),
    [],
  );
});

test("fails closed on unexpected analyzer output", () => {
  assert.throws(() => deadValues({}), /Expected a JSON array/);
  assert.throws(() => deadValues([{}]), /Invalid reanalyze diagnostic/);
});

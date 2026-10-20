import test from "node:test";
import assert from "node:assert/strict";
import path from "node:path";

import { run } from "../test.mjs";

test("run routes --update only to test-examples", () => {
  let calls = [];

  run({
    argv: ["--update"],
    execFileSync: (file, args) => {
      calls.push({
        file,
        args,
      });
    },
  });

  assert.equal(calls.length, 3);
  assert.equal(calls[0].file, process.execPath);
  assert.equal(path.basename(calls[0].args[0]), "test-examples.mjs");
  assert.deepEqual(calls[0].args.slice(1), ["--update"]);
  assert.equal(calls[1].file, process.execPath);
  assert.equal(path.basename(calls[1].args[0]), "test-hrefs.mjs");
  assert.deepEqual(calls[1].args.slice(1), []);
  assert.equal(calls[2].file, process.execPath);
  assert.equal(path.basename(calls[2].args[0]), "test-redirects.mjs");
  assert.deepEqual(calls[2].args.slice(1), []);
});

test("run invokes all scripts without flags by default", () => {
  let calls = [];

  run({
    argv: [],
    execFileSync: (file, args) => {
      calls.push({
        file,
        args,
      });
    },
  });

  assert.equal(calls.length, 3);
  assert.equal(path.basename(calls[0].args[0]), "test-examples.mjs");
  assert.deepEqual(calls[0].args.slice(1), []);
  assert.equal(path.basename(calls[1].args[0]), "test-hrefs.mjs");
  assert.deepEqual(calls[1].args.slice(1), []);
  assert.equal(path.basename(calls[2].args[0]), "test-redirects.mjs");
  assert.deepEqual(calls[2].args.slice(1), []);
});

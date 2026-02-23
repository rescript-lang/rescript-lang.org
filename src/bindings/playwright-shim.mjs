/**
 * playwright-shim.mjs
 *
 * Playwright's fixture-injection system inspects the source of the callback
 * passed to `test()` and requires the first parameter to use object
 * destructuring syntax, e.g. `async ({ page }) => {}`.
 *
 * ReScript always compiles record-destructuring arguments to the non-
 * destructuring form `async param => { let page = param.page; … }`, which
 * Playwright rejects with "First argument must use the object destructuring
 * pattern".
 *
 * This shim sits between the ReScript bindings and `@chromatic-com/playwright`.
 * Every function that accepts a `fixtures` callback is wrapped so that the
 * outer function Playwright sees uses real destructuring syntax, and the inner
 * ReScript-compiled callback is called with the same object.
 *
 * The ReScript `Playwright.res` bindings point at this file via
 * `@module("./playwright-shim.mjs")` instead of pointing directly at
 * `@chromatic-com/playwright`.
 */

import { test as _test, expect, takeSnapshot } from "@chromatic-com/playwright";

/** Wrap a ReScript fixtures-callback so Playwright sees destructuring syntax. */
function wrapFn(fn) {
  return async ({ page, context }) => fn({ page, context });
}

/**
 * `test(name, fn)` — register a single test.
 * Attach the same helper methods that Playwright's `test` object exposes so
 * that `@scope("test")` bindings in ReScript continue to work correctly.
 */
export function test(name, fn) {
  return _test(name, wrapFn(fn));
}

/** `test.describe(name, fn)` — group tests; no fixture injection needed. */
test.describe = (name, fn) => _test.describe(name, fn);

/** `test.only(name, fn)` — run only this test while debugging. */
test.only = (name, fn) => _test.only(name, wrapFn(fn));

/** `test.skip(name, fn)` — unconditionally skip a test. */
test.skip = (name, fn) => _test.skip(name, wrapFn(fn));

/** `test.beforeEach(fn)` — run before every test in the current scope. */
test.beforeEach = (fn) => _test.beforeEach(wrapFn(fn));

/** `test.afterEach(fn)` — run after every test in the current scope. */
test.afterEach = (fn) => _test.afterEach(wrapFn(fn));

/** `test.beforeAll(fn)` — run once before all tests in the current scope. */
test.beforeAll = (fn) => _test.beforeAll(wrapFn(fn));

/** `test.afterAll(fn)` — run once after all tests in the current scope. */
test.afterAll = (fn) => _test.afterAll(wrapFn(fn));

export { expect, takeSnapshot };

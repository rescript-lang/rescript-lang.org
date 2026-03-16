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

import {
  test as _test,
  expect,
  takeSnapshot as _takeSnapshot,
} from "@chromatic-com/playwright";

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

/**
 * `takeSnapshot(page, name)` — capture a Chromatic visual snapshot.
 *
 * `@chromatic-com/playwright`'s `takeSnapshot` requires a third `testInfo`
 * argument (added in v0.12+). We wrap it here so callers don't need to
 * pass it explicitly — `_test.info()` returns the current test's info object
 * when called from within a running test.
 *
 * Chromatic rejects snapshots exceeding 25,000,000 px. Long pages easily
 * blow past that limit (e.g. 1424 × 231 821 px). Before snapshotting we
 * therefore clip the document to the current viewport height by setting
 * `overflow: hidden` and an explicit `height` on both <html> and <body>,
 * then restore the original styles afterwards so nothing leaks between tests.
 */
export async function takeSnapshot(page, name) {
  // Clip document to viewport so rrweb only serialises what is visible.
  const viewportSize = page.viewportSize();
  const viewportHeight = viewportSize ? `${viewportSize.height}px` : "100vh";

  const originalStyles = await page.evaluate((h) => {
    const html = document.documentElement;
    const body = document.body;
    const prev = {
      htmlOverflow: html.style.overflow,
      htmlHeight: html.style.height,
      bodyOverflow: body.style.overflow,
      bodyHeight: body.style.height,
    };
    html.style.overflow = "hidden";
    html.style.height = h;
    body.style.overflow = "hidden";
    body.style.height = h;
    return prev;
  }, viewportHeight);

  try {
    await _takeSnapshot(page, name, _test.info());
  } finally {
    // Always restore original styles, even if takeSnapshot throws.
    await page.evaluate((prev) => {
      document.documentElement.style.overflow = prev.htmlOverflow;
      document.documentElement.style.height = prev.htmlHeight;
      document.body.style.overflow = prev.bodyOverflow;
      document.body.style.height = prev.bodyHeight;
    }, originalStyles);
  }
}

export { expect };

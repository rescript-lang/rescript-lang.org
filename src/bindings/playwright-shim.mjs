/**
 * playwright-shim.mjs
 *
 * Provides `takeSnapshot` (with viewport-clipping and automatic testInfo
 * injection) and re-exports `expect` from `@chromatic-com/playwright`.
 *
 * `test` and all hook functions are bound directly to `@chromatic-com/playwright`
 * in `Playwright.res` so that Playwright's source-location tracking (which
 * captures frame[1] of a fresh `Error.captureStackTrace`) points at the test
 * file rather than any intermediate wrapper.
 *
 * ReScript's compiled test callbacks (`async param => { let page = param.page; … }`)
 * are rewritten into the object-destructuring form Playwright requires by the
 * Babel plugin in `playwright-babel-plugin.mjs`, configured via `transform` in
 * `playwright.config.mjs`.
 */

import {
  test,
  expect,
  takeSnapshot as _takeSnapshot,
} from "@chromatic-com/playwright";

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
    await _takeSnapshot(page, name, test.info());
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

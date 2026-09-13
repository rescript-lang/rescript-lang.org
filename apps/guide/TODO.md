# Guide MVP Launch TODO

This checklist is for making the interactive guide ready to launch. It does not
cover writing or editing lesson content.

## 1. Define The Launch Boundary

- [ ] Decide the public guide URL and Cloudflare Worker custom domain.
- [ ] Record that the initial release requires a desktop browser.
- [ ] Define the supported browsers and the performance budget for the initial
      page load.
- [ ] Assign ownership for deployment, CDN/compiler availability, learner
      support, and production incident response.

## 2. Complete The Exercise System

- [ ] Choose a completion strategy for exercises that cannot be checked with
      one exact runtime-output line.
- [ ] Implement that strategy without allowing an incomplete lesson to unlock
      the next one.
- [ ] Decide whether learners need an explicit reset action for one exercise,
      all progress, or both.
- [ ] Decide how published lesson or exercise identifier changes preserve or
      intentionally reset browser-local progress.

## 3. Make Lesson Structure Safe To Publish

- [ ] Add build-time validation that lesson IDs, exercise IDs, and positions
      are unique.
- [ ] Add tests for the complete lesson collection rather than fixtures only.
- [ ] Add tests for invalid or incomplete lesson frontmatter.
- [ ] Verify every published exercise against the production compiler version
      and its expected runtime output.
- [ ] Establish a human review path for lesson accuracy, progression, and
      accessibility. Lesson writing remains author-owned.

## 4. Finish The Product Surface

- [ ] Add the production document metadata, favicon, social preview asset, and
      canonical URL.
- [ ] Decide and implement robots and sitemap/discovery behavior for the guide
      domain.
- [ ] Add keyboard-operable pane resizing or replace resize controls with an
      accessible alternative.
- [ ] Add visible focus styles and announce compiler errors, output changes,
      and checkpoint state changes to assistive technology.
- [x] Show a clear small-screen warning that the guide requires a desktop
      browser.

## 5. Reduce Delivery Risk

- [ ] Split or defer the compiler/editor bundle to meet the agreed initial-load
      budget. The current initial guide route is 1.61 MB uncompressed (463 KB
      gzip).
- [ ] Replace the deprecated Vite `envFile` option.
- [ ] Resolve the guide workspace's `@types/react` peer-dependency warning.
- [ ] Decide whether compiler-version metadata should be available at build
      time, at runtime, or both when the CDN is unavailable.
- [ ] Add graceful user-visible handling for compiler-CDN and runtime failures.

## 6. Prove The Release Path

- [ ] Ensure the pinned Playwright Chromium browser is installed in local and
      CI environments, then run `yarn workspace @rescript-lang/guide ci:test`.
- [ ] Add a production-preview smoke test covering page load, compiler
      availability, one successful checkpoint, hash deep link, persisted draft,
      and final navigation.
- [ ] Test the Cloudflare preview Worker with the intended production domain
      configuration and SPA fallback behavior.
- [ ] Define rollback steps and verify that a prior Worker version can be
      restored.
- [ ] Record the final launch decision and remaining accepted risks in the
      release pull request.

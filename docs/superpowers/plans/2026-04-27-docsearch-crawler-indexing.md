# DocSearch Crawler Indexing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert PR #1231 from build-time Algolia write API indexing to DocSearch crawler-compatible static HTML while preserving the public DocSearch search UI.

**Architecture:** Algolia owns indexing through the DocSearch crawler. The website build should generate only static HTML and existing static artifacts; it must not upload records or set index settings. Search runtime uses public DocSearch credentials, and crawl quality comes from stable `.DocSearch-content` containers, unique heading anchors, atomic paragraph/list content, docsearch meta tags, and crawler documentation.

**Tech Stack:** ReScript v12, React 19, React Router v7 pre-rendering, MDX, `@docsearch/react` v4, Vitest browser mode with Playwright, Yarn 4.

---

## Context

PR: https://github.com/rescript-lang/rescript-lang.org/pull/1231

DocSearch requirement source: https://docsearch.algolia.com/docs/required-configuration/

DocSearch crawler requirements that matter for this repo:

- Use a static `DocSearch-content` class on the main textual content container.
- Use heading selectors for `lvl1` through `lvl6`; every matched heading needs a unique `id` or `name`.
- Searchable body content should be in atomic `<p>` or `<li>` elements.
- Optional `docsearch:*` meta tags can apply record attributes such as language and version.
- Sitemap coverage is recommended so the crawler can find updated pages.

## Recommended Approach

Use the crawler-compliant HTML approach.

Alternative 1, minimal revert, would only delete the write API script and leave the current HTML alone. That avoids code work but leaves crawl quality accidental and keeps known heading-id problems.

Alternative 2, crawler-compliant HTML, removes write credentials and actively shapes the rendered HTML for DocSearch. This is the recommended path because it matches the DocSearch plan constraints and keeps the improved UI independent from indexing.

Alternative 3, keep a local generator for validation only, would retain most of `SearchIndex.res` but stop uploading. That creates two sources of truth for ranking and records, so it should be avoided unless we later need a diagnostics-only script.

## File Map

Remove write API publishing:

- Delete `scripts/generate_search_index.res`.
- Delete `src/bindings/Algolia.res`.
- Delete `src/common/SearchIndex.res`.
- Delete `src/common/SearchIndex.resi`.
- Delete `__tests__/SearchIndex_.test.res`.
- Delete SearchIndex visual snapshots under `__tests__/__screenshots__/SearchIndex_.test.jsx/`.
- Modify `package.json` and `yarn.lock` to remove `algoliasearch` and the `build:search-index` command.
- Modify `.github/workflows/deploy.yml` to stop exporting private Algolia admin variables.
- Modify `.gitignore` only if deleted generated script patterns leave a one-off entry unnecessary.

Keep public DocSearch runtime:

- Keep `@docsearch/react`.
- Keep `src/bindings/DocSearch.res`.
- Keep `src/components/Search.res`.
- Keep public env handling in `src/bindings/Env.res`, but remove publisher-only config from `src/common/AlgoliaConfig.res`.
- Keep `scripts/LogAlgoliaEnvStatus.res` and `src/common/AlgoliaEnvStatus.res` if the public-config warning remains useful.

Make HTML crawler-compatible:

- Modify `src/layouts/SidebarLayout.res` so docs/community/API pages expose `DocSearch-content` on the central `<main>`.
- Modify `app/routes/BlogArticle.res` so article body content is wrapped in an `<article className="DocSearch-content markdown-body">`.
- Modify `app/routes/SyntaxLookup.res` so syntax detail content is crawlable without indexing the whole interactive picker.
- Modify `src/components/Markdown.res` to preserve H1 ids and remove duplicate ids from anchor-link icons.
- Modify `src/markdown/Mdx.res` to generate collision-free heading ids.
- Modify `src/markdown/TocUtils.res` if needed so sidebar links match collision-free rendered heading ids.
- Modify `app/routes/ApiDocs.res` so programmatic API H1/H2 headings have unique ids that match crawl targets.
- Modify `src/components/Meta.res` to emit DocSearch language/version meta tags from existing version constants.

Add or adjust tests:

- Add `__tests__/DocSearchCrawlerMarkup_.test.res` or extend existing layout tests.
- Update `__tests__/AlgoliaConfig_.test.res` to remove publisher-only expectations.
- Update `__tests__/AlgoliaEnvStatus_.test.res` if public env names change.
- Update `__tests__/Search_.test.res` for same-origin absolute crawler URLs and empty `siteUrl` behavior.
- Update or remove generated screenshots only after explicit snapshot approval.

## Implementation Tasks

### Task 1: Add crawler-markup regression coverage

**Files:**

- Modify: `__tests__/DocsLayout_.test.res`
- Modify: `__tests__/MarkdownComponents_.test.res` or add `__tests__/DocSearchCrawlerMarkup_.test.res`
- Modify: `__tests__/Search_.test.res`

- [ ] Add a test that renders `<DocsLayout>` and asserts the central main element has `DocSearch-content`.
- [ ] Add a test that renders `Markdown.H1` with an id and asserts the `<h1>` keeps that id.
- [ ] Add a test that renders `Markdown.H2` and asserts exactly one element in the document has that heading id.
- [ ] Add a search URL test for an empty `siteUrl`: `Search.toRelativeSiteUrl("https://rescript-lang.org/docs/manual/introduction", ~siteUrl="")` should return the original URL.
- [ ] Add a search URL test for a normal same-origin crawler hit: absolute `https://rescript-lang.org/docs/manual/introduction#what-is-rescript` should normalize to `/docs/manual/introduction#what-is-rescript`.
- [ ] Run `yarn build:res`.
- [ ] Run `yarn vitest --browser.headless --run __tests__/DocsLayout_.test.jsx __tests__/MarkdownComponents_.test.jsx __tests__/Search_.test.jsx`.
- [ ] Confirm the new tests fail for the expected reasons before implementation.

### Task 2: Remove Algolia write API publishing

**Files:**

- Delete: `scripts/generate_search_index.res`
- Delete: `src/bindings/Algolia.res`
- Delete: `src/common/SearchIndex.res`
- Delete: `src/common/SearchIndex.resi`
- Delete: `__tests__/SearchIndex_.test.res`
- Delete: `__tests__/__screenshots__/SearchIndex_.test.jsx/*`
- Modify: `package.json`
- Modify: `yarn.lock`
- Modify: `.github/workflows/deploy.yml`
- Modify: `.gitignore`
- Modify: `src/common/AlgoliaConfig.res`
- Modify: `__tests__/AlgoliaConfig_.test.res`

- [ ] Remove `build:search-index` from `package.json`.
- [ ] Restore `build:update-index` to only generate LLM files and the blog feed:

```json
"build:update-index": "yarn build:generate-llms && node _scripts/generate_feed.mjs > public/blog/feed.xml"
```

- [ ] Keep `build` and `prepare` pointed at `build:update-index`; they should not invoke any Algolia uploader.
- [ ] Remove the `algoliasearch` dependency with Yarn so `package.json` and `yarn.lock` stay consistent.
- [ ] Remove `publisherConfig`, `missingPublisherVars`, and `publisherConfigFrom` from `AlgoliaConfig.res`.
- [ ] Update `AlgoliaConfig_.test.res` to cover only public DocSearch config.
- [ ] In `.github/workflows/deploy.yml`, remove `ALGOLIA_ADMIN_API_KEY_DEV`, `ALGOLIA_ADMIN_API_KEY_PROD`, and all `ALGOLIA_*` private exports.
- [ ] Replace the derived basename flow with direct public variables:

```yaml
VITE_ALGOLIA_APP_ID: ${{ vars.VITE_ALGOLIA_APP_ID }}
VITE_ALGOLIA_INDEX_NAME: ${{ vars.VITE_ALGOLIA_INDEX_NAME }}
VITE_ALGOLIA_SEARCH_API_KEY: ${{ vars.VITE_ALGOLIA_SEARCH_API_KEY }}
```

- [ ] Remove `.gitignore` entries that only existed for deleted generated Algolia publishing files.
- [ ] Run `yarn install --immutable` or the repository-approved Yarn flow after dependency removal.
- [ ] Run `yarn build:res`.

### Task 3: Keep the DocSearch UI, but make URL handling crawler-safe

**Files:**

- Modify: `src/components/Search.res`
- Modify: `src/bindings/DocSearch.res`
- Modify: `src/bindings/Env.res`
- Modify: `__tests__/Search_.test.res`

- [ ] Keep the custom hit component and URL normalization, because crawler hits can be absolute URLs.
- [ ] Guard `toRelativeSiteUrl` so an empty `siteUrl` never matches every URL.
- [ ] Treat `Env.root_url` as absent when `VITE_DEPLOYMENT_URL` is `Some("")`, or keep the guard entirely inside `Search.toRelativeSiteUrl`.
- [ ] Do not move ranking or crawler record settings into the client; DocSearch crawler/dashboard owns index settings.
- [ ] Keep `searchParameters` only for UI query behavior, such as `hitsPerPage`, snippets, distinct, and optional facet filters.
- [ ] Run `yarn vitest --browser.headless --run __tests__/Search_.test.jsx`.

### Task 4: Add DocSearch-content containers

**Files:**

- Modify: `src/layouts/SidebarLayout.res`
- Modify: `app/routes/BlogArticle.res`
- Modify: `app/routes/SyntaxLookup.res`
- Modify: `__tests__/DocsLayout_.test.res`
- Modify: `__tests__/BlogArticle_.test.res` if it already covers body markup
- Modify: `__tests__/SyntaxLookup_.test.res` if it already covers detail pages

- [ ] Add `DocSearch-content` to the central `<main>` in `SidebarLayout.res`; this covers manual docs, React docs, guidelines, community pages, API overview, and API detail pages.
- [ ] Wrap blog article body content in an `article` with `DocSearch-content markdown-body`.
- [ ] For syntax lookup detail routes, put `DocSearch-content` on the detail body, not on the whole search-picker UI.
- [ ] Keep visual class order stable and avoid changing layout styles.
- [ ] Run the focused browser tests for touched layouts.

### Task 5: Make heading anchors unique and crawler-readable

**Files:**

- Modify: `src/components/Markdown.res`
- Modify: `src/markdown/Mdx.res`
- Modify: `src/markdown/TocUtils.res`
- Modify: `app/routes/ApiDocs.res`
- Test: `__tests__/MarkdownComponents_.test.res`
- Test: `__tests__/DocsLayout_.test.res`

- [ ] Update `Markdown.H1.make` to accept optional `~id` and `~title` props and render the `id` on the `<h1>` when MDX provides it.
- [ ] Update `Markdown.Anchor.make` so the decorative anchor icon does not render a second element with the same `id`.
- [ ] Add a small heading-id helper in `src/markdown/` if needed so both MDX rendering and table-of-contents generation can use the same collision rules.
- [ ] Update `Mdx.anchorLinkPlugin` so repeated headings get deterministic suffixes such as `usage`, `usage-1`, `usage-2`.
- [ ] Update `TocUtils.buildEntries` to produce hrefs matching the rendered heading ids for duplicate headings.
- [ ] Add ids to programmatic API H1 headings in `ApiDocs.res`; H2 ids already use `type-<name>` and `value-<name>`.
- [ ] Run the heading and layout tests.

### Task 6: Add DocSearch meta tags

**Files:**

- Modify: `src/components/Meta.res`
- Modify: `src/common/Constants.res`
- Test: `__tests__/MetaDescription_.test.res` or add a focused meta test if one exists for head tags

- [ ] Add `<meta name="docsearch:language" content="en" />`.
- [ ] Add `<meta name="docsearch:version" content={Constants.docSearchVersionTokens->Array.join(",")} />` using the current major version from `Constants.versions.latest`; include `latest` when the build serves the latest docs.
- [ ] Keep the tag generic enough that older-version subdomain builds can provide their own version token through existing version constants.
- [ ] Do not hardcode stale version text in route components.

### Task 7: Document crawler-owned indexing

**Files:**

- Modify: `README.md` or add `docs/docsearch.md` if the repo maintainers prefer a focused doc.

- [ ] Document that the DocSearch crawler owns indexing and index settings.
- [ ] Document only public runtime variables:

```txt
VITE_ALGOLIA_APP_ID
VITE_ALGOLIA_INDEX_NAME
VITE_ALGOLIA_SEARCH_API_KEY
```

- [ ] Explicitly state that no admin/write key is used during builds or deployments.
- [ ] Include the expected crawler selectors:

```js
recordProps: {
  lvl0: {
    selectors: ".DocSearch-lvl0",
    defaultValue: "Documentation",
  },
  lvl1: [".DocSearch-content h1", "main h1", "h1", "head > title"],
  lvl2: [".DocSearch-content h2", "main h2", "h2"],
  lvl3: [".DocSearch-content h3", "main h3", "h3"],
  lvl4: [".DocSearch-content h4", "main h4", "h4"],
  lvl5: [".DocSearch-content h5", "main h5", "h5"],
  lvl6: [".DocSearch-content h6", "main h6", "h6"],
  content: [".DocSearch-content p, .DocSearch-content li"],
}
```

- [ ] Note that production crawler start URLs and sitemap configuration live in the Algolia dashboard, not in the site build.

### Task 8: Consider sitemap generation as a follow-up or include it if scope allows

**Files if included now:**

- Create: `scripts/generate_sitemap.res`
- Modify: `package.json`
- Modify: `public/robots.txt`
- Modify: `react-router.config.mjs` only if route data is needed from there

- [ ] Decide whether sitemap generation belongs in this PR or a follow-up.
- [ ] If included, generate `public/sitemap.xml` or `out/sitemap.xml` from the same route sources used by React Router prerendering.
- [ ] Include docs, API detail pages, community pages, syntax lookup detail pages, and blog posts.
- [ ] Add `Sitemap: https://rescript-lang.org/sitemap.xml` to `public/robots.txt`.
- [ ] Verify `yarn build` copies the sitemap into `out/`.

## Final Verification

- [ ] Run `yarn build:res`.
- [ ] Run `yarn vitest --browser.headless --run`.
- [ ] Run `yarn test`.
- [ ] Run `yarn build`.
- [ ] After `yarn build`, inspect representative generated HTML:

```sh
grep -R "DocSearch-content" out/docs/manual/introduction out/docs/react/introduction out/docs/manual/api/stdlib out/blog | head
grep -R 'name="docsearch:version"' out/docs/manual/introduction | head
grep -R 'id="javascript-interop"' out/docs/manual/introduction | head
```

- [ ] Confirm build logs do not invoke `generate_search_index` and do not require any `ALGOLIA_ADMIN_*` variables.
- [ ] Do not update screenshots unless the user confirms snapshot updates.

## Open Decision

Sitemap generation is the only scope question. The DocSearch page calls it "nice to have" but also says it is key for crawler freshness. I would include markup and uploader removal in this PR, then add sitemap generation only if we want crawler discovery guarantees in the same change.

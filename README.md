# rescript-lang.org

[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-v1.4%20adopted-ff69b4.svg)](CODE_OF_CONDUCT.md)

This is the official documentation platform for the [ReScript](https://rescript-lang.org) programming language.

The docs site uses ReScript v12, React 19, React Router v8, Vite 8, and Tailwind CSS v4. Most routes are pre-rendered at build time; `/try` is server-rendered at runtime through Cloudflare Pages Functions.

This is a monorepo: the docs site lives in `apps/docs/`, the interactive guide in `apps/guide/`, and shared playground and library code in `packages/`. The guide pre-renders its entry page and runs its interactive lessons in the browser, with assets served by a Cloudflare Worker.

**Please report any technical issues with ReScript to the [compiler repository](https://github.com/rescript-lang/rescript).**

**If you are missing specific documentation:**

- Some language or compiler features may not be documented yet.
- Open an issue to let us know what is missing.
- If you want to contribute missing docs, see [Contributing](#contributing).

## System Requirements

- `node@26` or higher

This repository uses `yarn@4.13.0` via Corepack.

## Setup

```sh
npm install --global corepack
corepack enable
yarn install
yarn dev
```

`yarn dev` prepares generated assets, starts the ReScript watcher, runs the React Router/Vite dev server, and serves the built client through Wrangler Pages.

## Search and DocSearch

Search is powered by Algolia DocSearch. The DocSearch crawler owns indexing and index settings; site builds and deployments do not upload records, replace indexes, or use an Algolia admin/write key.

The frontend only needs public DocSearch runtime variables:

```sh
VITE_ALGOLIA_APP_ID="..."
VITE_ALGOLIA_INDEX_NAME="..."
VITE_ALGOLIA_SEARCH_API_KEY="..."
```

The GitHub deploy workflow passes the public GitHub secrets named `VITE_ALGOLIA_APP_ID`, `VITE_ALGOLIA_INDEX_NAME`, and `VITE_ALGOLIA_SEARCH_API_KEY` to the `yarn build` step. `VITE_ALGOLIA_INDEX_NAME` is the full runtime index name; the workflow does not add `prod_` or `dev_` prefixes. Builds and deployments should not configure or export Algolia admin/write keys.

DocSearch crawl quality comes from the generated HTML. Searchable page bodies use `DocSearch-content`, each crawlable section provides a hidden `DocSearch-lvl0` marker such as `Manual`, `API`, `React`, `Syntax Lookup`, `Community`, or `Blog`, and headings own unique `id` attributes for section links.

The crawler configuration should use selectors shaped like this:

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

Production crawler start URLs, ranking, and crawler schedules live in the Algolia dashboard. The build generates `sitemap.xml` from the prerendered HTML pages so the crawler can use the deployed sitemap.

## Project Structure Overview

- `apps/docs/app/`: React Router app shell, layouts, route definitions, and route modules
- `apps/docs/src/`: Website bindings, utilities, components, layouts, and MDX compilation
- `apps/docs/markdown-pages/`: MDX content for docs, blog, community pages, and syntax lookup
- `apps/docs/data/`: Sidebar ordering and content metadata
- `apps/docs/scripts/`: Build, code generation, and validation scripts
- `apps/docs/functions/`: Cloudflare Pages Functions for `/try`, `/try.data`, and OG images
- `apps/docs/styles/`: Tailwind v4 theme and custom CSS
- `apps/docs/public/`: Static assets such as images, fonts, and favicons
- `apps/docs/__tests__/`: Vitest browser tests; visual tests live in its `visual/` directory
- `apps/docs/e2e/`: Cypress browser tests
- `apps/guide/`: Interactive guide, lesson content, tests, and Worker configuration; see its [README](apps/guide/README.md)
- `packages/playground/`: Shared browser playground components and compiler integration
- `packages/shared/`: Shared bindings, utilities, highlighting, and the CodeMirror grammar in `plugins/`
- `data/api/`: Compiler-published API JSON snapshots

The playground loads published browser compiler bundles; `yarn build:sync-bundles` downloads them into the ignored `apps/docs/public/playground-bundles/` directory for deployment. Markdown example validation uses the installed `rescript` package.

MDX is compiled by [`MdxFile.res`](apps/docs/src/markdown/MdxFile.res) using `@mdx-js/mdx` and remark plugins. [`MdxContent.res`](apps/docs/src/components/MdxContent.res) renders compiled content and maps custom components such as `Info`, `Warn`, and `CodeTab`.

Tailwind v4 uses the Vite plugin and [`apps/docs/styles/main.css`](apps/docs/styles/main.css). Design tokens and custom utilities live in [`apps/docs/styles/_theme.css`](apps/docs/styles/_theme.css).

The [recommended VS Code extensions](.vscode/extensions.json) provide ReScript support and [Oxfmt editor integration](https://oxc.rs/docs/guide/usage/formatter/editors.html). Oxfmt configuration lives in [`.oxfmtrc.json`](.oxfmtrc.json).

## Dead-code checks

`yarn check:dead-code` compiles every workspace and runs reanalyze across the
monorepo, including FFI exports. CI fails on unused values and exports. Bindings
whose names start with `_` are treated as intentional discards. Record fields,
variant cases, and argument diagnostics remain advisory because JavaScript and
FFI access can be invisible to the analyzer; inspect them with `yarn reanalyze`.

React Router and Cloudflare call exports from JavaScript. Their entry points are
marked `@live` individually in the `.resi` interface, or in `.res` when there is
no interface. Keep these annotations limited to real entry points and do not
duplicate them between files; check JavaScript imports and MDX mappings before
removing a reported export.

## Common Commands

Run these commands from the repository root. To target a workspace, use
`yarn workspace <name> <command>`; the workspace names are `@rescript-lang/docs`,
`@rescript-lang/guide`, `@rescript-lang/playground`, and `@rescript-lang/shared`.

| Command             | Purpose                                                          |
| ------------------- | ---------------------------------------------------------------- |
| `yarn dev`          | Prepare generated files and run the docs development environment |
| `yarn build`        | Build and pre-render the docs site                               |
| `yarn build:guide`  | Build and pre-render the interactive guide                       |
| `yarn preview`      | Build and serve the generated docs client locally                |
| `yarn build:res`    | Generate route types and compile all four workspaces             |
| `yarn build:routes` | Regenerate the shared ReScript route type                        |
| `yarn check:routes` | Check that the shared route type matches the current routes      |
| `yarn dev:res`      | Run the ReScript compiler in watch mode                          |
| `yarn format`       | Run Oxfmt and format ReScript across all four workspaces         |
| `yarn test`         | Run docs markdown example, href, and redirect validation         |
| `yarn ci:test`      | Run docs and guide Vitest browser tests headlessly               |
| `yarn vitest`       | Run docs Vitest browser tests in watch mode                      |
| `yarn vitest:guide` | Run guide Vitest browser tests in watch mode                     |
| `yarn cy:open`      | Open the full-site Cypress suite against the running dev server  |
| `yarn cy:e2e`       | Run the full-site Cypress suite headlessly in Chrome             |
| `yarn test:e2e`     | Build and run homepage Cypress tests with a temporary server     |

## Testing

The documentation route table lives in `apps/docs/route-config.mjs`. React Router
and `apps/docs/generate-route-types.mjs` read the same configuration, including
MDX pages and API modules. `packages/shared/src/Path.res` is generated before
ReScript builds and when starting the ReScript watcher. After changing routes,
adding or removing MDX pages, or updating API data during a watch session, run
`yarn build:routes` again. CI rejects a stale generated file.

### Formatting and Generated Output

`yarn ci:format` checks Oxfmt formatting and ReScript formatting across all four
workspaces. Run `yarn format` to apply both formatters.

`yarn ci:generated` cleans ReScript artifacts, removes tracked compiler output,
and rebuilds, then fails if any tracked `.jsx` or `.mjs` file differs from the
committed version. Most compiler output is ignored by Git; the guide's
`app/root.jsx` and `app/routes.jsx` are currently tracked. After changing their
ReScript sources or updating the compiler, run `yarn build:res` and commit the
regenerated output alongside the sources.

Both checks run on pull requests. Removing tracked output before rebuilding also
catches orphaned output whose source was deleted or excluded from the build.

### Vitest Browser Tests

We use [Vitest](https://vitest.dev/) in browser mode with Playwright for component-level tests. ReScript test files live in `apps/docs/__tests__/` and `apps/guide/__tests__/`. Compile them before running Vitest:

```sh
yarn build:res

# Docs watch mode
yarn vitest

# Guide watch mode
yarn vitest:guide

# Headless docs and guide run (same mode used in CI)
yarn ci:test
```

For a headless run of a single suite, use `yarn vitest --browser.headless --run`
for docs or `yarn vitest:guide --browser.headless --run` for the guide.

Visual screenshot baselines are generated in CI's pinned Linux browser environment. Local snapshot updates are blocked. Push your feature branch, then open [Update Visual Regression Screenshots](https://github.com/rescript-lang/rescript-lang.org/actions/workflows/update-visual-screenshots.yml), select that branch, and choose **Run workflow**. The workflow refuses `master` and commits any changed PNGs back to the selected branch.

You can also dispatch the workflow with the GitHub CLI, replacing `<feature-branch>` with your pushed branch:

```sh
gh workflow run update-visual-screenshots.yml --repo rescript-lang/rescript-lang.org --ref <feature-branch>
```

After the workflow finishes, pull its commit and review the screenshot diff. Only accept screenshots intentionally affected by your change.

### Cypress E2E Tests

The full-site suite covers documentation, navigation, and the playground. Start the local development server in one terminal:

```sh
yarn dev
```

Wait for Vite to report its local URL. In another terminal, run one of these commands:

```sh
yarn cy:open # Interactive Cypress runner (Electron)
yarn cy:run  # Headless run (Electron)
yarn cy:e2e  # Headless run (Chrome must be installed)
```

These commands compile the ReScript specs and default to `http://localhost:5173`. If Vite reports another port, or you want to test a deployed site, pass its URL explicitly:

```sh
yarn cy:e2e --config baseUrl=http://localhost:5174
```

The homepage suite uses the production build and its own configuration. `yarn test:e2e` builds the site, starts a temporary server at `http://127.0.0.1:4173`, runs the homepage specs in Chrome, and stops the server when the tests finish. It does not require `yarn dev`.

### Markdown Example and Link Checks

`yarn test` runs the following:

- `apps/docs/scripts/test-examples.mjs` to compile examples in the manual, React docs, guides and syntax lookup, and compare shown JS and JSX output with the installed compiler
- `apps/docs/scripts/test-hrefs.mjs` to validate relative markdown links under `apps/docs/markdown-pages/`
- `apps/docs/scripts/test-redirects.mjs` to validate redirect rules

Supported ReScript markdown code fences:

- ` ```res `
- ` ```rescript ` (alias for `res`)
- ` ```res sig `
- ` ```resi ` (alias for `res sig`)
- ` ```res prelude `
- ` ```res file=MathUtils.res ` (a separate source file for multi-file examples)
- ` ```resi file=MathUtils.resi ` (its interface)

Indented fences are supported. Prelude blocks provide context for later examples. Use `res nocheck` only for intentionally invalid or incomplete snippets. Malformed CodeTabs fail the check, including missing closing tags and mismatched labels and fences.

Named source files are compiled together with the examples on their page. Filenames must be PascalCase, end in `.res` or `.resi`, and be unique on the page; `Example` is reserved for the checker's main module. Supporting files are removed before checking the next page.

Output comparison ignores formatting and comments. `JS Output` and `JS Output (Module)` use ESM, `JS Output (CommonJS)` uses CommonJS, and `JSX Preserved Output` uses preserved JSX. TypeScript output is not generated or compared by this checker; its ReScript input is still compiled.

Compiler diagnostics embedded in output, such as `%todo`, show the example's filename and source range with the temporary build directory removed.

Refresh generated JS output fences with the installed compiler and format the result:

```sh
yarn test --update
```

You can also run the scripts directly from the docs workspace:

```sh
cd apps/docs
node scripts/test-examples.mjs
node scripts/test-examples.mjs --update
node scripts/test-examples.mjs "manual/module-functions.mdx"
node scripts/test-examples.mjs --include-blog
CI=1 node scripts/test-hrefs.mjs
```

Example-checker patterns are relative to `apps/docs/markdown-pages/docs`. Historical blog posts describe earlier compiler versions, so the default run reports them as skipped. `--include-blog` audits them with the installed compiler; reported differences need review against the original version. Blog files are never rewritten, even with `--update`.

The link checker scans the full MDX tree and does not accept a glob filter. It reports findings locally but only exits unsuccessfully for them when `CI` is set.

From the repository root, run `CI=1 yarn test` before pushing content changes to match CI's link-check failure behavior as well as checking examples and redirects.

## Writing Blog Posts

Create an MDX file in [`apps/docs/markdown-pages/blog`](apps/docs/markdown-pages/blog). Its filename becomes the URL under `/blog/`; use an existing post as a template for the YAML frontmatter (`author`, quoted `date`, `title`, and optional `description`, `co_authors`, `previewImg`, `articleImg`, and `badge`). Author aliases are defined in [`BlogFrontmatter.res`](apps/docs/src/markdown/BlogFrontmatter.res).

Put local images in [`apps/docs/public/img`](apps/docs/public/img) and reference them with `/img/...` URLs. Run `yarn dev` and preview the post at `/blog/<filename>` before opening a PR. Posts under `blog/archived` appear only in the archived listing.

## Adding Your Company Logo

If your company uses ReScript and should appear in the "Trusted by our users" section on the front page:

- Add a black and white `.svg` logo using `#979AAD` as the fill color.
- Put the file in [`apps/docs/public/lp`](apps/docs/public/lp).
- Update [`apps/docs/src/data/OurUsers.res`](apps/docs/src/data/OurUsers.res), including the logo's intrinsic `width` and `height`. For SVGs without explicit dimensions, use their `viewBox` dimensions; scale fractional dimensions together to integers without changing the aspect ratio.
- Commit, push, and open a PR.

## Contributing

Please read and comply with our [Code of Conduct](CODE_OF_CONDUCT.md) and review [CONTRIBUTING.md](CONTRIBUTING.md) before contributing.

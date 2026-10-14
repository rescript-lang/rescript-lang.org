# rescript-lang.org

[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-v1.4%20adopted-ff69b4.svg)](CODE_OF_CONDUCT.md)

This is the official documentation platform for the [ReScript](https://rescript-lang.org) programming language.

The site is a fully pre-rendered static app built with ReScript, React 19, React Router, Vite, and Tailwind CSS, and deployed to Cloudflare Pages.

Route modules live in `app/routes/`, shared ReScript UI code lives in `src/`, and MDX content lives in `markdown-pages/`.

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

- `app/`: React Router app shell, layouts, route definitions, and route modules
- `src/`: ReScript source code for bindings, shared logic, components, and layouts
- `markdown-pages/`: MDX content for docs, blog, community pages, and syntax lookup
- `data/`: Hand-curated data such as sidebar ordering and content metadata
- `scripts/`: Build, code generation, and validation scripts
- `functions/`: Cloudflare Pages Functions
- `styles/`: Tailwind v4 theme and custom CSS
- `public/`: Static assets such as images, fonts, and favicons
- `plugins/`: HighlightJS, CodeMirror, and other content/build plugins
- `compilers/`: Bundled ReScript compiler versions for playground and example validation
- `__tests__/`: Vitest browser tests written in ReScript

Tailwind is configured in [`styles/main.css`](styles/main.css). There is no `tailwind.config.js`.

## Common Commands

| Command              | Purpose                                                           |
| -------------------- | ----------------------------------------------------------------- |
| `yarn dev`           | Prepare generated files and run the local development environment |
| `yarn build`         | Run the full production build                                     |
| `yarn preview`       | Build and serve the generated static client locally               |
| `yarn build:res`     | Compile ReScript only                                             |
| `yarn dev:res`       | Run the ReScript compiler in watch mode                           |
| `yarn format`        | Run Prettier and the ReScript formatter                           |
| `yarn test`          | Run markdown example and href validation                          |
| `yarn ci:test`       | Run Vitest browser tests headlessly                               |
| `yarn vitest`        | Run Vitest directly                                               |
| `yarn vitest:update` | Update screenshot baselines headlessly                            |

## Testing

### Vitest Browser Tests

We use [Vitest](https://vitest.dev/) in browser mode with Playwright for component-level tests. Test files live in `__tests__/` and are written in ReScript.

```sh
# Watch mode
yarn vitest

# Headless run (same mode used in CI)
yarn ci:test
```

To update screenshot baselines, run:

```sh
yarn vitest:update
```

Only update screenshots that are intentionally affected by your change.

### Markdown Example and Link Checks

`yarn test` runs the following:

- `apps/docs/scripts/test-examples.mjs` to compile examples in the manual, React docs, guides and syntax lookup, and compare shown JS and JSX output with the installed compiler
- `apps/docs/scripts/test-hrefs.mjs` to validate relative markdown links under `markdown-pages/`
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

You can also run the scripts directly:

```sh
node apps/docs/scripts/test-examples.mjs
node apps/docs/scripts/test-examples.mjs --update
node apps/docs/scripts/test-examples.mjs "manual/module-functions.mdx"
node apps/docs/scripts/test-examples.mjs --include-blog
node apps/docs/scripts/test-hrefs.mjs
```

Example-checker patterns are relative to `apps/docs/markdown-pages/docs`. Historical blog posts describe earlier compiler versions, so the default run reports them as skipped. `--include-blog` audits them with the installed compiler; reported differences need review against the original version. Blog files are never rewritten, even with `--update`.

Run `yarn test` before pushing content changes so CI does not fail on markdown regressions.

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

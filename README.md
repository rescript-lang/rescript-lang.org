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

- `node@22` or higher
- `corepack` enabled

This repository uses `yarn@4.13.0` via Corepack.

## Setup

```sh
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

Production crawler start URLs, sitemap settings, ranking, and crawler schedules live in the Algolia dashboard.

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

`yarn test` runs both of the following:

- `scripts/test-examples.mjs` to validate ReScript code examples in markdown
- `scripts/test-hrefs.mjs` to validate relative markdown links under `markdown-pages/`

Supported ReScript markdown code fences:

- ` ```res `
- ` ```res sig `
- ` ```res prelude `

Refresh generated JS output fences with:

```sh
yarn test --update
```

You can also run the scripts directly:

```sh
node scripts/test-examples.mjs
node scripts/test-examples.mjs --update
node scripts/test-hrefs.mjs
node scripts/test-hrefs.mjs "markdown-pages/docs/manual/**/*.mdx"
```

Run `yarn test` before pushing content changes so CI does not fail on markdown regressions.

## Writing Blog Posts

If you are writing a blog post, refer to the [blog post guide](https://rescript-lang.org/blogpost-guide).

## Adding Your Company Logo

If your company uses ReScript and should appear in the "Trusted by our users" section on the front page:

- Add a black and white `.svg` logo using `#979AAD` as the fill color.
- Put the file in [`public/lp`](public/lp).
- Update [`src/common/OurUsers.res`](src/common/OurUsers.res).
- Commit, push, and open a PR.

## Contributing

Please read and comply with our [Code of Conduct](CODE_OF_CONDUCT.md) and review [CONTRIBUTING.md](CONTRIBUTING.md) before contributing.

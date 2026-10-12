# Docs Workspace Commands

Run the common development, build, test, and formatting commands from the
repository root. Focused docs helpers live in the docs workspace; invoke them
with `yarn workspace @rescript-lang/docs <command>`:

| Command                   | Purpose                                                                                                  |
| ------------------------- | -------------------------------------------------------------------------------------------------------- |
| `prepare`                 | Compile ReScript and build scripts, check public search config, and generate LLM files and the blog feed |
| `build:generate-llms`     | Regenerate LLM files after compiling and bundling the scripts                                            |
| `dev:vite`                | Run only the React Router/Vite development server                                                        |
| `dev:wrangler`            | Build the docs client and serve it through Wrangler Pages                                                |
| `ci:homepage-performance` | Test the homepage asset reporter and report production-build asset sizes                                 |
| `ci:test:e2e`             | Run homepage Cypress specs against an already-running production server                                  |

`yarn dev` explicitly calls the workspace's `prepare` before starting its
watcher. Yarn 4 does not run `prepare` automatically during installation; see
[Yarn's supported lifecycle scripts](https://yarnpkg.com/advanced/lifecycle-scripts).
The `lefthook` dependency has its own `postinstall` for Git hook installation.
Use root `yarn clean:res` to clean compiler output and `yarn ci:format` to check
formatting.

These contributor tools intentionally run manually. Compile browser test specs
with `yarn build:res` before running the watch commands:

- `yarn vitest:guide` watches the guide's browser tests.
- `yarn vitest:visual` watches the docs visual tests. Screenshot updates use the
  repository's screenshot workflow.
- `yarn convert-images` runs the docs image converter using
  [`image-converter.config.mjs`](../image-converter.config.mjs). It converts
  PNG/JPG/JPEG files under `apps/docs/public/` to AVIF and removes the converted
  originals. Review the resulting asset and reference changes before committing.
- The `cy:open`, `cy:run`, `cy:e2e`, and `test:e2e` root commands support local
  Cypress testing. `test:e2e` builds the docs and manages its homepage test server;
  the `cy:*` commands require a running full-site server.

## Homepage Performance Checks

`homepage-performance.mjs` measures local JavaScript and CSS explicitly referenced
by the built homepage HTML, deduplicating script, module preload, and stylesheet
URLs. The report helps compare this initial HTML asset list across changes.
Measurements are informational: larger bundles, request counts, or DOM sizes
do not fail CI. Missing build output or referenced local assets still fail.

This is not a complete measurement of browser downloads or runtime performance.
It does not follow JavaScript imports, count inline scripts or serialized route
data, or measure later requests, fonts, or external assets. Media checks verify
local `src` and poster files and count missing dimensions; they do not enumerate
`srcset` candidates or measure image transfer sizes. Gzip sizes are calculated
locally, not observed from the deployment.

Use the production-build Cypress suite for functional regressions and Lighthouse
for measurements against the deployed site. Lighthouse and deployed-site E2E
run independently after deployment.

The new script tests are written in ReScript and run in Vitest's Node environment:

```sh
yarn build:res
yarn workspace @rescript-lang/docs ci:test:scripts
```

Existing Node test-runner scripts remain separate.

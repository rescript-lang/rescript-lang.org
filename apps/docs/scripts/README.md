# Homepage Performance Checks

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

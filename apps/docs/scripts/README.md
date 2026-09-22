# Route Profile Performance Checks

`homepage-performance.mjs` measures each representative built route profile:
the homepage reference, docs, API, blog, community, packages, syntax lookup,
playground, and the low-complexity controls. It records HTML, JavaScript, CSS,
and local-media request counts and raw/gzip transfer totals, DOM element count,
and image/video dimensions. Asset entries identify whether they are route-owned,
shared with the homepage, or shared by multiple non-homepage profiles.

The JSON output is retained as `test-results/route-profile-performance.json` in
CI. Measurements are informational: larger bundles, request counts, or DOM
sizes do not fail CI. Missing profile HTML or referenced local assets still fail.

This is not a complete measurement of browser downloads or runtime performance.
It does not follow JavaScript imports, count inline scripts or serialized route
data, or measure later requests, fonts, or external assets. Media checks verify
local `src` and poster files, record each image/video's declared dimensions, and
count missing dimensions; they do not enumerate `srcset` candidates or measure
image transfer sizes. Gzip sizes are calculated locally, not observed from the
deployment.

Use the production-build Cypress suite for functional regressions and Lighthouse
for measurements against the deployed site. The route-profile Cypress suite uses
the server-rendered Cypress bootstrap slot, so direct-load hydration errors and
unexpected console errors fail the run. Lighthouse retains a route-level baseline
and writes `N/A` when the target branch has no comparable profile.

The new script tests are written in ReScript and run in Vitest's Node environment:

```sh
yarn build:res
yarn workspace @rescript-lang/docs ci:test:scripts
```

Existing Node test-runner scripts remain separate.

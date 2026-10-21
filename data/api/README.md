# API documentation data

The compiler repository generates these snapshots. Its publish workflow downloads
the API artifact to this directory and commits it to the website repository.

The website reads `stdlib.json`, `belt.json`, and `dom.json` from the newest
`v<major>.<minor>.<patch>` directory matching `apps/docs/docs-version.json`, also
exposed to ReScript as `DocsVersion.current`. Minor and patch
numbers are compared numerically. Explicit prerelease directory names are ignored.
The selected snapshot must contain all three libraries; an incomplete or invalid
publication fails the build instead of mixing versions or using an older copy.
Each library must include its root module (`stdlib`, `belt`, or `dom`). Every
module must have nonempty `id` and `name` strings, a `docstrings` array of strings,
and an `items` array before the snapshot can be cached or used to generate routes.

Route generation, sidebar navigation, and page content use the same snapshot.
`master` selects v12; this website branch selects v13 through
`apps/docs/docs-version.json`. The displayed documentation version and generated
manual indexes use the same setting.

Pushes to `v13`, including compiler API-data publications, trigger
`.github/workflows/deploy.yml` and deploy the website at
`https://v13.rescript-lang.org`. Compiler publication must target this branch
only after this loader is deployed (compiler issue #8753).

Keep the compiler artifact intact, including the generated `js.json` and
`toc_tree.json` files. The website currently builds its sidebar from the module
data and does not expose the legacy Js library.

# API documentation data

The compiler repository generates these snapshots. Its publish workflow downloads
the API artifact to this directory and commits it to the website repository.

The website reads `stdlib.json`, `belt.json`, and `dom.json` from the newest
`v<major>.<minor>.<patch>` directory matching `apps/docs/docs-version.json`, also
exposed to ReScript as `DocsVersion.current`. Minor and patch
numbers are compared numerically. Explicit prerelease directory names are ignored.
The selected snapshot must contain all three libraries; an incomplete or invalid
publication fails the build instead of mixing versions or using an older copy.

Route generation, sidebar navigation, and page content use the same snapshot.
`master` selects v12; when porting this loader to the v13 website branch, update
`apps/docs/docs-version.json` to `v13` alongside the displayed documentation version.

Keep the compiler artifact intact, including the generated `js.json` and
`toc_tree.json` files. The website currently builds its sidebar from the module
data and does not expose the legacy Js library.

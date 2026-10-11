# ReScript Lang Website – Agent Guidelines

## Project Overview

This monorepo contains the official documentation website for the [ReScript](https://rescript-lang.org) programming language and the interactive guide. Both use **ReScript v12 + React 19 + React Router v8 + Vite 8**. The docs site uses Tailwind CSS v4 and is primarily pre-rendered at build time, with runtime server-side rendering for `/try` through Cloudflare Pages Functions. The guide pre-renders its entry page and runs its interactive lessons in the browser, with assets served by a Cloudflare Worker.

## System Requirements

- Node.js ≥ 26
- Yarn 4.13.0 (via Corepack, pinned in `package.json` and `.yarnrc.yml`)

## Project Structure

```
apps/docs/                 → Documentation website workspace (@rescript-lang/docs)
  app/                     → React Router shell, layouts, and route modules
    routes/                → Page components and loaders (e.g. BlogRoute.res)
  src/                     → Website ReScript code
    bindings/              → App-specific bindings to JS libraries
    common/                → Shared website utilities and hooks
    components/            → Reusable React components
    ffi/                   → Legacy plain JS interop
    layouts/               → Page layout components
    markdown/              → MDX loading, compilation, and frontmatter parsing
  markdown-pages/          → Blog, docs, community, and syntax-lookup MDX
  data/                    → Sidebar ordering and content metadata
  styles/                  → Tailwind v4 entry points, theme, and custom CSS
  scripts/                 → Build, code generation, and validation scripts
  functions/               → Pages Functions for /try, /try.data, and OG images
  server/                  → React Router request handler for Pages Functions
  public/                  → Static assets (images, fonts, favicons)
  __tests__/               → Vitest browser and visual tests
  e2e/                     → Cypress browser tests
apps/guide/                → Interactive guide workspace (@rescript-lang/guide)
packages/playground/       → Shared browser playground (@rescript-lang/playground)
packages/shared/           → Shared bindings and utilities (@rescript-lang/shared)
  src/                     → ReactRouter, Vitest, CodeMirror, highlighting, etc.
  plugins/                 → CodeMirror 6 ReScript/Reason grammar
data/api/                  → Compiler-published API JSON snapshots
.github/                   → CI, deployment, and screenshot workflows
```

Paths in these guidelines are relative to the repository root. Run the commands
below from there; use `yarn workspace <name> <command>` for workspace commands.
The playground loads published browser compiler bundles. Markdown example checks
use the installed `rescript` package, not a separate compiler installation.

## Key Commands

| Command          | Purpose                                                        |
| ---------------- | -------------------------------------------------------------- |
| `yarn dev`       | Run ReScript watcher + Vite dev server + Wrangler (parallel)   |
| `yarn build`     | Full production build (ReScript → scripts → Vite/React Router) |
| `yarn build:res` | ReScript compilation only                                      |
| `yarn dev:res`   | ReScript watch mode only                                       |
| `yarn format`    | Run Oxfmt + ReScript formatter                                 |
| `yarn test`      | Run example, href, and redirect validation scripts             |
| `yarn vitest`    | Run Vitest browser tests with Playwright                       |
| `make`           | Build (install deps + ReScript compile + update index)         |

## Coding Best Practices

- Prefer small functions with a single purpose.
- Use a functional approach but don't make it too hardcore or difficult to understand.
- Keep files and modules small and focused.
- `.res` files must always be capitalized (PascalCase), matching ReScript module conventions.
- Use the pipe-first operator (`->`) for chaining, which is idiomatic ReScript.
- Resolve all warnings and treat them as errors. The project has `"error": "+8"` in `rescript.json`.
- Never directly edit generated `.jsx` files; edit the corresponding `.res` file and rebuild. Most compiler output is ignored by Git; the guide's `apps/guide/app/root.jsx` and `apps/guide/app/routes.jsx` are tracked and must be regenerated with their sources.

## ReScript Rules

- This branch uses **ReScript v12**. Ensure all suggestions match this version.
- Ensure any produced JSX matches ReScript JSX v4 syntax (configured with `"preserve": true`).
- **Never use the `Belt` or `Js` modules** — these are legacy. Use the modern `Stdlib` / core modules instead.
- Always use the `JSON.t` type for JSON values.
- When dealing with promises, prefer `async/await` syntax.
- The project opens `WebAPI.Global` globally via compiler flags, so Web APIs are available without prefix.
- Output format is ES modules with `.jsx` suffix, compiled in-source (`.jsx` files sit alongside `.res` files).
- Reference the abridged documentation for clarification on how ReScript's APIs work: https://rescript-lang.org/llms/manual/llm-small.txt
- If you need more information you can access the full documentation, but do this only when needed as the docs are very large: https://rescript-lang.org/llms/manual/llm-full.txt
- Never use `%raw` unless you are specifically asked to
- Never use `Object.magic`
- Don't add type annotations unless necessary for clarity or to resolve an error. ReScript's type inference is powerful, and often explicit annotations are not needed.

### ReScript Dependencies

- `@rescript/react` — React bindings
- `@rescript/webapi` — Web API bindings (opened globally)

### JS Interop Patterns

The project uses several patterns for JavaScript interop. Follow the existing conventions:

- **`@module` externals** for binding to npm packages (see `apps/docs/src/bindings/` and `packages/shared/src/` for examples):
  ```
  @module("react-router") external useNavigate: unit => string => unit = "useNavigate"
  ```
- **`@module` with `@react.component`** for binding to external React components:
  ```
  @module("react-router") @react.component
  external make: (~children: React.element) => React.element = "Outlet"
  ```
- `%raw` and `%%raw` embed JavaScript; use them only when specifically requested.
- **`@scope`** for binding to object properties like `process.env`.
- **`external ... = "%identity"`** for zero-cost type coercions.
- Put app-specific bindings in `apps/docs/src/bindings/` as a dedicated module (e.g. `Fuse.res`, `DocSearch.res`). Bindings shared with the guide or playground belong in `packages/shared/src/`.

## ReScript React

- This project uses **React 19** and **React Router v8** (framework mode).
- The site uses hybrid rendering: most routes are pre-rendered during the build, while `/try` is server-rendered by Cloudflare Pages Functions at runtime.
- Loaders for pre-rendered routes can access the filesystem during the build. Runtime SSR loaders, including shared loader code reachable from `/try`, execute in Cloudflare and must not depend on Node-only filesystem APIs or other build-time-only operations.
- Docs route modules live in `apps/docs/app/routes/`; the guide's route modules live in `apps/guide/app/`. Routes can export a `loader`, `links`, and a `default` component as needed.
- Route modules **require** both a `.res` and a `.resi` (interface) file for Vite HMR to work.
- Only a single React component can be exposed from a module's JS output.

### Route Module Pattern

Every route follows this pattern:

```rescript
// SomeRoute.res
type loaderData = { ... }

let loader: ReactRouter.Loader.t<loaderData> = async ({request}) => {
  // filesystem access is available here (pre-render time only)
  let data = ...
  data
}

@react.component
let default = () => {
  let data = ReactRouter.useLoaderData()
  <SomeLayout> ... </SomeLayout>
}
```

With a matching interface file:

```rescript
// SomeRoute.resi
type loaderData = { ... }
let loader: ReactRouter.Loader.t<loaderData>

@react.component
let default: unit => React.element
```

### JSX Syntax Rules

- `React.useState` takes a function: `let (age, setAge) = React.useState(_ => 4)`
- Every expression inside an interpolated string must be of type `string`:
  - Wrong: `` `age = ${42}` ``
  - Right: `` `age = ${42->Int.toString}` ``
- `type` is a keyword in ReScript. Use `type_` for JSX props: `<button type_="submit" />`
- **You cannot add text as a direct child of a React component.** Everything must be a `React.element`:
  - Wrong: `<h1>Hello World</h1>`
  - Right: `<h1>{React.string("Hello World")}</h1>`
  - Use `React.string`, `React.int`, `React.float`, and `React.array` for primitive conversions.
- Use `React.null` for rendering nothing.
- Optional props use `?` syntax: `<button ?onClick>` to pass `option<handler>`.

## Styling

- The docs site uses **Tailwind CSS v4**, configured via the Vite plugin (`@tailwindcss/vite`). Design tokens and custom utilities live in `apps/docs/styles/_theme.css`, imported by `apps/docs/styles/main.css` and referenced by route-specific stylesheets.
- The guide uses its own plain CSS in `apps/guide/styles/main.css`.
- **LightningCSS** is used as the CSS transformer.
- The project defines custom design tokens in `apps/docs/styles/_theme.css`:
  - Custom colors: `gray-*`, `fire-*`, `sky-*`, `berry-*`, `water`, `turtle`, `orange-*`
  - Custom font sizes: `text-11` through `text-68`
  - Custom utility classes: `hl-title`, `hl-1`–`hl-5`, `body-lg`, `body-md`, `body-sm`, `captions`
  - Fonts: Inter (sans), Roboto Mono (mono)
- Use existing custom utilities and design tokens. Check `apps/docs/styles/_theme.css` before creating new ones.

## Testing

- Tests use **Vitest 5** in browser mode with **Playwright** (Chromium).
- Browser tests live in `apps/docs/__tests__/` and `apps/guide/__tests__/`. Docs visual tests live in `apps/docs/__tests__/visual/`. Test modules are named `ComponentName_.test.res` (compiled to `.test.jsx`).
- Tests use custom ReScript bindings in `packages/shared/src/Vitest.res`.
- Tests are visual/integration tests that render components and assert visibility, interactions, and screenshots.
- Test pattern:

  ```rescript
  open Vitest

  test("description", async () => {
    await viewport(1440, 500)
    let screen = await render(<MyComponent />)
    let el = await screen->getByTestId("my-element")
    await element(el)->toBeVisible
    await element(el)->toMatchScreenshot("screenshot-name")
  })
  ```

- Components requiring React Router context must be wrapped in `<MemoryRouter>`.
- Do not use `<BrowserRouter>` in tests.
- Run `yarn build:res` before `yarn vitest --browser.headless --run` so the tests use current compiler output.
- Do not update snapshots without asking for confirmation. Approved docs visual baseline changes use the `Update Visual Regression Screenshots` GitHub Actions workflow against the feature branch; pull and review the generated commit. Local screenshot updates are blocked by the Vitest configuration.

## MDX Content

- Documentation content is in `apps/docs/markdown-pages/`, organized by section (blog, docs, community, syntax-lookup).
- `apps/docs/src/markdown/MdxFile.res` loads frontmatter and compiles MDX with `@mdx-js/mdx` and remark plugins. Route loaders pass the compiled content to `MdxContent`.
- `apps/docs/src/components/MdxContent.res` evaluates compiled MDX with `runSync` and maps custom components (e.g. `<Info>`, `<Warn>`, `<CodeTab>`, `<Video>`).
- Code examples in markdown use ` ```res ` (runnable), ` ```res sig ` (signature), and ` ```res prelude ` (shared context).
- `yarn test` validates examples, relative links, and redirects. For matching CI's link-check failure behavior locally, run `CI=1 yarn test`; the link checker reports findings locally but only exits unsuccessfully for them when `CI` is set. It scans the full MDX tree and does not accept a glob filter.

## Formatting & Git Hooks

- **Oxfmt** formats JavaScript, JSON, Markdown/MDX, CSS, and YAML, using `.oxfmtrc.json`.
- **ReScript formatter** (`rescript format`) formats `.res` and `.resi` files.
- **Lefthook** runs Oxfmt and the ReScript formatter on matching staged files in parallel, then auto-stages formatting fixes. See `lefthook.yml` for the file patterns and commands.
- Most generated `.jsx` output is ignored by Git. The two tracked guide entry modules are excluded from Oxfmt; regenerate them with the compiler.
- `.vscode/extensions.json` recommends the Oxc formatter integration and the ReScript extension.

## Pull Requests and Commits

- Use conventional commits format for commit messages (e.g. `feat: add new API docs`, `fix: resolve loader data issue`).
- Commit bodies should explain what changed with some concise details
- PR descriptions should provide context for the change, a summary of the changes with descriptions, and reference any related issues.

## Important Warnings

- Do **not** modify generated `.jsx` / `.mjs` files directly — they are ReScript compiler output.
- Do **not** use `@genType` — the project does not use it.
- The `apps/docs/src/ffi/` directory is legacy; prefer bindings in `apps/docs/src/bindings/` or `packages/shared/src/` for new JS interop.
- When editing route files, always update both the `.res` and `.resi` files.

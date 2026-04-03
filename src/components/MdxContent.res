// ---------------------------------------------------------------------------
// JSX runtime values needed by runSync
// ---------------------------------------------------------------------------

// We re-import the jsx-runtime exports as opaque values so we can pass them
// through to runSync without running into ReScript's monomorphisation of
// the polymorphic `React.jsx` / `React.jsxs` signatures.
/**
 * MdxContent — renders compiled MDX content as a React component.
 *
 * Uses `runSync` from `@mdx-js/mdx` to evaluate compiled MDX (produced by
 * `MdxFile.compileMdx`) and renders the result with a shared component map.
 */
type jsxRuntimeValue

@module("react/jsx-runtime") external fragment: jsxRuntimeValue = "Fragment"
@module("react/jsx-runtime") external jsx: jsxRuntimeValue = "jsx"
@module("react/jsx-runtime") external jsxs: jsxRuntimeValue = "jsxs"

@val @scope(("import", "meta")) external importMetaUrl: string = "url"

// ---------------------------------------------------------------------------
// @mdx-js/mdx runSync binding
// ---------------------------------------------------------------------------

type runOptions = {
  @as("Fragment") fragment: jsxRuntimeValue,
  jsx: jsxRuntimeValue,
  jsxs: jsxRuntimeValue,
  baseUrl: string,
}

type mdxModule

@module("@mdx-js/mdx")
external runSync: (CompiledMdx.t, runOptions) => mdxModule = "runSync"

@get external getDefault: mdxModule => React.component<{..}> = "default"

let runOptions = {
  fragment,
  jsx,
  jsxs,
  baseUrl: importMetaUrl,
}

// ---------------------------------------------------------------------------
// Shared MDX component map
// ---------------------------------------------------------------------------

let components = {
  // Standard HTML element overrides
  "a": Markdown.A.make,
  "blockquote": Markdown.Blockquote.make,
  "code": Markdown.Code.make,
  "h1": Markdown.H1.make,
  "h2": Markdown.H2.make,
  "h3": Markdown.H3.make,
  "h4": Markdown.H4.make,
  "h5": Markdown.H5.make,
  "hr": Markdown.Hr.make,
  "li": Markdown.Li.make,
  "ol": Markdown.Ol.make,
  "p": Markdown.P.make,
  "pre": Markdown.Pre.make,
  "strong": Markdown.Strong.make,
  "table": Markdown.Table.make,
  "th": Markdown.Th.make,
  "thead": Markdown.Thead.make,
  "td": Markdown.Td.make,
  "ul": Markdown.Ul.make,
  // Custom MDX components
  "Cite": Markdown.Cite.make,
  "CodeTab": Markdown.CodeTab.make,
  "Image": Markdown.Image.make,
  "Info": Markdown.Info.make,
  "Intro": Markdown.Intro.make,
  "UrlBox": Markdown.UrlBox.make,
  "Video": Markdown.Video.make,
  "Warn": Markdown.Warn.make,
  "CommunityContent": CommunityContent.make,
  "WarningTable": WarningTable.make,
  "Docson": DocsonLazy.make,
  "Suspense": React.Suspense.make,
}

// ---------------------------------------------------------------------------
// React component
// ---------------------------------------------------------------------------

@react.component
let make = (~compiledMdx: CompiledMdx.t) => {
  let element = React.useMemo(() => {
    let mdxModule = runSync(compiledMdx, runOptions)
    let content = getDefault(mdxModule)
    React.jsx(content, {"components": components})
  }, [compiledMdx])

  element
}

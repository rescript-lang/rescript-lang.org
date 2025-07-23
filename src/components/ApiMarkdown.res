open Markdown
/*
module H1 = {
  @react.component
  let make = (~children) =>
    <h1 className="text-48 tracking-tight leading-tight mb-2 font-sans font-medium text-gray-90"> children </h1>
}*/

module H2 = {
  // We will currently hide the headline, to keep the structure,
  // but having an Elm like documentation
  @react.component
  let make = (~id, ~children) => <>
    <div className="mb-10 mt-20" />
    <Markdown.H2 id> children </Markdown.H2>
  </>
}

type aliasH2 = Markdown.H2.props<string, React.element> => React.element
external asMarkdownH2: 'a => aliasH2 = "%identity"

let default = {
  MarkdownComponents.intro: Intro.make,
  p: P.make,
  li: Li.make,
  h1: H1.make,
  h2: H2.make->asMarkdownH2,
  h3: H3.make,
  h4: H4.make,
  h5: H5.make,
  ul: Ul.make,
  ol: Ol.make,
  a: A.make,
  thead: Thead.make,
  th: Th.make,
  td: Td.make,
  pre: Pre.make,
  code: Code.make,
}

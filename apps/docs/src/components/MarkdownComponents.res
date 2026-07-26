open Markdown

type t = {
  /* MDX shortnames for more advanced components */
  @as("Cite")
  cite?: React.component<Cite.props<option<string>, React.element>>,
  @as("Info")
  info?: React.component<Info.props<React.element>>,
  @as("Warn")
  warn?: React.component<Warn.props<React.element>>,
  @as("Intro")
  intro?: React.component<Intro.props<React.element>>,
  @as("Image")
  image?: React.component<Image.props<string, [#large | #small], bool, string, string, string>>,
  @as("Video")
  video?: React.component<Video.props<string, string>>,
  @as("UrlBox")
  urlBox?: React.component<UrlBox.props<string, string, MdxLegacy.MdxChildren.t>>,
  @as("CodeTab")
  codeTab?: React.component<CodeTab.props<MdxLegacy.MdxChildren.t, array<string>>>,
  /* Common markdown elements */
  p?: React.component<P.props<React.element>>,
  li?: React.component<Li.props<React.element>>,
  h1?: React.component<H1.props<string, string, React.element>>,
  h2?: React.component<H2.props<string, React.element, string>>,
  h3?: React.component<H3.props<string, React.element, string>>,
  h4?: React.component<H4.props<string, React.element, string>>,
  h5?: React.component<H5.props<string, React.element, string>>,
  ul?: React.component<Ul.props<React.element>>,
  ol?: React.component<Ol.props<React.element>>,
  table?: React.component<Table.props<React.element>>,
  thead?: React.component<Thead.props<React.element>>,
  th?: React.component<Th.props<React.element>>,
  td?: React.component<Td.props<React.element>>,
  blockquote?: React.component<Blockquote.props<React.element>>,
  strong?: React.component<Strong.props<React.element>>,
  hr?: React.component<Hr.props>,
  code?: React.component<Code.props<string, option<string>, MdxLegacy.Components.unknown>>,
  pre?: React.component<Pre.props<React.element>>,
  a?: React.component<A.props<string, string, React.element>>,
}

let default = {
  cite: Cite.make,
  info: Info.make,
  intro: Intro.make,
  warn: Warn.make,
  urlBox: UrlBox.make,
  codeTab: CodeTab.make,
  image: Image.make,
  video: Video.make,
  p: P.make,
  li: Li.make,
  h1: H1.make,
  h2: H2.make,
  h3: H3.make,
  h4: H4.make,
  h5: H5.make,
  ul: Ul.make,
  ol: Ol.make,
  table: Table.make,
  thead: Thead.make,
  th: Th.make,
  td: Td.make,
  hr: Hr.make,
  strong: Strong.make,
  a: A.make,
  pre: Pre.make,
  blockquote: Blockquote.make,
  code: Code.make,
}

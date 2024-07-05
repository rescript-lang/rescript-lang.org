open Markdown

type t = {
  /* MDX shortnames for more advanced components */
  @as("Cite")
  cite?: React.componentLike<Cite.props<option<string>, React.element>, React.element>,
  @as("Info")
  info?: React.componentLike<Info.props<React.element>, React.element>,
  @as("Warn")
  warn?: React.componentLike<Warn.props<React.element>, React.element>,
  @as("Intro")
  intro?: React.componentLike<Intro.props<React.element>, React.element>,
  @as("Image")
  image?: React.componentLike<Image.props<string, [#large | #small], bool, string>, React.element>,
  @as("Video")
  video?: React.componentLike<Video.props<string, string>, React.element>,
  @as("UrlBox")
  urlBox?: React.componentLike<UrlBox.props<string, string, Mdx.MdxChildren.t>, React.element>,
  @as("CodeTab")
  codeTab?: CodeTab.props<Mdx.MdxChildren.t, array<string>> => React.element,
  /* Common markdown elements */
  p?: P.props<React.element> => React.element,
  li?: Li.props<React.element> => React.element,
  h1?: H1.props<React.element> => React.element,
  h2?: H2.props<string, React.element> => React.element,
  h3?: H3.props<string, React.element> => React.element,
  h4?: H4.props<string, React.element> => React.element,
  h5?: H5.props<string, React.element> => React.element,
  ul?: Ul.props<React.element> => React.element,
  ol?: Ol.props<React.element> => React.element,
  table?: Table.props<React.element> => React.element,
  thead?: Thead.props<React.element> => React.element,
  th?: Th.props<React.element> => React.element,
  td?: Td.props<React.element> => React.element,
  blockquote?: Blockquote.props<React.element> => React.element,
  strong?: Strong.props<React.element> => React.element,
  hr?: Hr.props => React.element,
  code?: React.componentLike<
    Code.props<string, option<string>, Mdx.Components.unknown>,
    React.element,
  >,
  pre?: Pre.props<React.element> => React.element,
  a?: A.props<string, string, React.element> => React.element,
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

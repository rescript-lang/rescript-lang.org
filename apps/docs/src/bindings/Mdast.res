type tree

@module("mdast-util-from-markdown")
external fromMarkdown: string => tree = "fromMarkdown"

@module("mdast-util-to-string")
external toString: {..} => string = "toString"

@module("unist-util-visit")
external visit: (tree, string, {..} => unit) => unit = "visit"

@unboxed
type listType =
  | @as("list") List
  | @as("listItem") ListItem
  | @as("paragraph") Paragraph
  | @as("link") Link

type rec listContent = {
  @as("type") _type: listType,
  url?: Path.t,
  title?: string,
  value: string,
  children?: array<listContent>,
}

type result = {
  index?: int,
  endIndex?: int,
  map: listContent,
}

type tocOptions = {maxDepth?: int}

@module("mdast-util-toc")
external toc: (tree, tocOptions) => result = "toc"

let rec reduceHeaders = (list: listContent, links: dict<Path.t>) => {
  if list._type == Link {
    let child = list.children->Option.flatMap(children => children[0])
    switch (list.url, child) {
    | (Some(url), Some(child)) => links->Dict.set(child.value, url)
    | (_, _) => ()
    }
  } else {
    switch list.children {
    | Some(children) => children->Array.forEach(child => reduceHeaders(child, links))
    | None => ()
    }
  }
}

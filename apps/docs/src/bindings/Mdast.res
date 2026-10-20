type tree

@module("mdast-util-from-markdown")
external fromMarkdown: string => tree = "fromMarkdown"

@module("mdast-util-to-string")
external toString: {..} => string = "toString"

@module("unist-util-visit")
external visit: (tree, string, {..} => unit) => unit = "visit"

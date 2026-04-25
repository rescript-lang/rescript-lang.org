type hierarchy = {
  lvl0: string,
  lvl1: string,
  lvl2: option<string>,
  lvl3: option<string>,
  lvl4: option<string>,
  lvl5: option<string>,
  lvl6: option<string>,
}

type weight = {
  pageRank: int,
  level: int,
  position: int,
}

type record = {
  objectID: string,
  url: string,
  url_without_anchor: string,
  anchor: option<string>,
  content: option<string>,
  @as("type") type_: string,
  hierarchy: hierarchy,
  weight: weight,
}

type heading = {
  level: int,
  text: string,
  content: string,
}

let maxContentLength: int

let makeHierarchy: (
  ~lvl0: string,
  ~lvl1: string,
  ~lvl2: string=?,
  ~lvl3: string=?,
  ~lvl4: string=?,
  ~lvl5: string=?,
  ~lvl6: string=?,
  unit,
) => hierarchy

let truncate: (string, ~maxLen: int) => string

let slugify: string => string

let stripMdxTags: string => string

let cleanDocstring: string => string

let extractIntro: string => string

let extractHeadings: string => array<heading>

let optionToJson: option<string> => JSON.t

let hierarchyToJson: hierarchy => JSON.t

let weightToJson: weight => JSON.t

let withBaseUrl: (record, ~siteUrl: string) => record

let buildMarkdownRecords: (
  ~category: string,
  ~basePath: string,
  ~dirPath: string,
  ~pageRank: int,
) => array<record>

let buildBlogRecords: (~dirPath: string, ~pageRank: int) => array<record>

let buildSyntaxLookupRecords: (~dirPath: string, ~pageRank: int) => array<record>

let buildApiRecords: (
  ~basePath: string,
  ~dirPath: string,
  ~pageRank: int,
  ~category: string,
  ~files: array<string>=?,
) => array<record>

let toJson: record => JSON.t

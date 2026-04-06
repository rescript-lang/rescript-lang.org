type record

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

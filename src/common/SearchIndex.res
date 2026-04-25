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

let maxContentLength = 500

let makeHierarchy = (~lvl0, ~lvl1, ~lvl2=?, ~lvl3=?, ~lvl4=?, ~lvl5=?, ~lvl6=?, ()) => {
  lvl0,
  lvl1,
  lvl2,
  lvl3,
  lvl4,
  lvl5,
  lvl6,
}

let truncate = (str: string, ~maxLen: int): string =>
  switch String.length(str) > maxLen {
  | true => String.slice(str, ~start=0, ~end=maxLen) ++ "..."
  | false => str
  }

// --- Helpers ---

let slugify = (text: string): string =>
  text
  ->String.toLowerCase
  ->String.replaceRegExp(RegExp.fromString("\\s+", ~flags="g"), "-")
  ->String.replaceRegExp(RegExp.fromString("[^a-z0-9\\-]", ~flags="g"), "")

let stripMdxTags = (text: string): string =>
  text
  ->String.replaceRegExp(RegExp.fromString("<CodeTab[\\s\\S]*?</CodeTab>", ~flags="g"), "")
  ->String.replaceRegExp(RegExp.fromString("<[^>]+>", ~flags="g"), "")
  ->String.replaceRegExp(RegExp.fromString("```[\\s\\S]*?```", ~flags="g"), "")
  ->String.replaceRegExp(RegExp.fromString("`([^`]+)`", ~flags="g"), "$1")
  ->String.replaceRegExp(RegExp.fromString("\\*\\*([^*]+)\\*\\*", ~flags="g"), "$1")
  ->String.replaceRegExp(RegExp.fromString("\\*([^*]+)\\*", ~flags="g"), "$1")
  ->String.replaceRegExp(RegExp.fromString("\\[([^\\]]+)\\]\\([^)]*\\)", ~flags="g"), "$1")
  ->String.replaceRegExp(RegExp.fromString("^#{1,6}\\s+", ~flags="gm"), "")
  ->String.replaceRegExp(RegExp.fromString("\\n{2,}", ~flags="g"), "\n")
  ->String.trim

let cleanDocstring = (text: string): string =>
  text
  // Take content before first heading
  ->String.split("\n## ")
  ->Array.get(0)
  ->Option.getOr(text)
  // Take content before first code block
  ->String.split("\n```")
  ->Array.get(0)
  ->Option.getOr(text)
  // Strip inline code backticks
  ->String.replaceRegExp(RegExp.fromString("`([^`]+)`", ~flags="g"), "$1")
  // Strip bold
  ->String.replaceRegExp(RegExp.fromString("\\*\\*([^*]+)\\*\\*", ~flags="g"), "$1")
  // Strip italic
  ->String.replaceRegExp(RegExp.fromString("\\*([^*]+)\\*", ~flags="g"), "$1")
  // Strip links
  ->String.replaceRegExp(RegExp.fromString("\\[([^\\]]+)\\]\\([^)]*\\)", ~flags="g"), "$1")
  // Collapse multiple newlines into space
  ->String.replaceRegExp(RegExp.fromString("\\n{2,}", ~flags="g"), " ")
  // Replace remaining newlines with space
  ->String.replaceRegExp(RegExp.fromString("\\n", ~flags="g"), " ")
  ->String.trim

let extractIntro = (content: string): string => {
  let parts = content->String.split("\n## ")
  let intro = parts[0]->Option.getOr("")
  intro
  // Remove the # H1 heading line if present at the start
  ->String.replaceRegExp(RegExp.fromString("^#[^#].*\\n", ~flags=""), "")
  ->stripMdxTags
  ->String.trim
}

let findHeadingMatches: string => array<{..}> = %raw(`
  function(content) {
    var regex = /^(#{2,6})\s+(.+)$/gm;
    var results = [];
    var match;
    while ((match = regex.exec(content)) !== null) {
      results.push({ index: match.index, level: match[1].length, text: match[2] });
    }
    return results;
  }
`)

let extractHeadings = (content: string): array<heading> => {
  let matches = findHeadingMatches(content)

  matches->Array.mapWithIndex((m, i) => {
    let startIdx = m["index"] + String.length(m["text"]) + m["level"] + 2
    let endIdx = switch matches[i + 1] {
    | Some(next) => next["index"]
    | None => String.length(content)
    }
    let sectionContent =
      content
      ->String.slice(~start=startIdx, ~end=endIdx)
      ->stripMdxTags
      ->String.trim
      ->truncate(~maxLen=maxContentLength)

    {
      level: m["level"],
      text: m["text"],
      content: sectionContent,
    }
  })
}

// --- File collection ---

let rec collectFiles = (dirPath: string): array<string> => {
  let entries = Node.Fs.readdirSync(dirPath)
  entries->Array.reduce([], (acc, entry) => {
    let fullPath = Node.Path.join([dirPath, entry])
    let stats = Node.Fs.statSync(fullPath)
    switch stats["isDirectory"]() {
    | true => acc->Array.concat(collectFiles(fullPath))
    | false => {
        acc->Array.push(fullPath)
        acc
      }
    }
  })
}

let isMdxFile = (path: string): bool => Node.Path.extname(path) === ".mdx"

let filenameWithoutExt = (path: string): string =>
  Node.Path.basename(path)->String.replace(".mdx", "")

// --- Record builders ---

let buildMarkdownRecords = (
  ~category: string,
  ~basePath: string,
  ~dirPath: string,
  ~pageRank: int,
): array<record> => {
  collectFiles(dirPath)
  ->Array.filter(isMdxFile)
  ->Array.flatMap(filePath => {
    let fileContent = Node.Fs.readFileSync2(filePath, "utf8")
    let parsed = MarkdownParser.parseSync(fileContent)

    switch DocFrontmatter.decode(parsed.frontmatter) {
    | None => []
    | Some(fm) => {
        let pageUrl = switch fm.canonical->Null.toOption {
        | Some(canonical) => canonical
        | None => basePath ++ "/" ++ filenameWithoutExt(filePath)
        }

        let introText = parsed.content->extractIntro->truncate(~maxLen=maxContentLength)
        let pageContent = switch introText {
        | "" => fm.description->Null.toOption->Option.getOr("")
        | text => text
        }

        let pageRecord = {
          objectID: pageUrl,
          url: pageUrl,
          url_without_anchor: pageUrl,
          anchor: None,
          content: Some(pageContent->truncate(~maxLen=maxContentLength)),
          type_: "lvl1",
          hierarchy: makeHierarchy(~lvl0=category, ~lvl1=fm.title, ()),
          weight: {pageRank, level: 100, position: 0},
        }

        let headingRecords =
          parsed.content
          ->extractHeadings
          ->Array.mapWithIndex((heading, i) => {
            let anchor = slugify(heading.text)
            let headingUrl = pageUrl ++ "#" ++ anchor
            let typeLvl = switch heading.level {
            | 2 => "lvl2"
            | 3 => "lvl3"
            | 4 => "lvl4"
            | 5 => "lvl5"
            | _ => "lvl6"
            }
            let weightLevel = switch heading.level {
            | 2 => 80
            | 3 => 60
            | 4 => 40
            | 5 => 20
            | _ => 10
            }
            let hierarchy = switch heading.level {
            | 2 => makeHierarchy(~lvl0=category, ~lvl1=fm.title, ~lvl2=heading.text, ())
            | 3 =>
              makeHierarchy(
                ~lvl0=category,
                ~lvl1=fm.title,
                ~lvl2=heading.text,
                ~lvl3=heading.text,
                (),
              )
            | 4 =>
              makeHierarchy(
                ~lvl0=category,
                ~lvl1=fm.title,
                ~lvl2=heading.text,
                ~lvl3=heading.text,
                ~lvl4=heading.text,
                (),
              )
            | _ => makeHierarchy(~lvl0=category, ~lvl1=fm.title, ~lvl2=heading.text, ())
            }

            {
              objectID: headingUrl,
              url: headingUrl,
              url_without_anchor: pageUrl,
              anchor: Some(anchor),
              content: switch heading.content {
              | "" => None
              | c => Some(c)
              },
              type_: typeLvl,
              hierarchy,
              weight: {pageRank, level: weightLevel, position: i + 1},
            }
          })

        [pageRecord]->Array.concat(headingRecords)
      }
    }
  })
}

let buildBlogRecords = (~dirPath: string, ~pageRank: int): array<record> => {
  open JSON
  Node.Fs.readdirSync(dirPath)
  ->Array.filter(entry => isMdxFile(entry) && entry !== "archived")
  ->Array.filterMap(entry => {
    let fullPath = Node.Path.join([dirPath, entry])
    let stats = Node.Fs.statSync(fullPath)
    switch stats["isDirectory"]() {
    | true => None
    | false => {
        let fileContent = Node.Fs.readFileSync2(fullPath, "utf8")
        let parsed = MarkdownParser.parseSync(fileContent)

        switch parsed.frontmatter {
        | Object(dict{"title": String(title), "description": ?description}) => {
            let slug = filenameWithoutExt(fullPath)
            let url = "/blog/" ++ slug
            let desc = switch description {
            | Some(String(d)) => Some(d->truncate(~maxLen=maxContentLength))
            | _ => None
            }

            Some({
              objectID: url,
              url,
              url_without_anchor: url,
              anchor: None,
              content: desc,
              type_: "lvl1",
              hierarchy: makeHierarchy(~lvl0="Blog", ~lvl1=title, ()),
              weight: {pageRank, level: 100, position: 0},
            })
          }
        | _ => None
        }
      }
    }
  })
}

let buildSyntaxLookupRecords = (~dirPath: string, ~pageRank: int): array<record> => {
  open JSON
  Node.Fs.readdirSync(dirPath)
  ->Array.filter(isMdxFile)
  ->Array.filterMap(entry => {
    let fullPath = Node.Path.join([dirPath, entry])
    let fileContent = Node.Fs.readFileSync2(fullPath, "utf8")
    let parsed = MarkdownParser.parseSync(fileContent)

    switch parsed.frontmatter {
    | Object(dict{
        "id": String(id),
        "name": String(name),
        "summary": String(summary),
        "keywords": ?_keywords,
      }) =>
      Some({
        objectID: "syntax-" ++ id,
        url: "/syntax-lookup",
        url_without_anchor: "/syntax-lookup",
        anchor: None,
        content: Some(summary->truncate(~maxLen=maxContentLength)),
        type_: "lvl1",
        hierarchy: makeHierarchy(~lvl0="Syntax", ~lvl1=name, ()),
        weight: {pageRank, level: 100, position: 0},
      })
    | _ => None
    }
  })
}

let buildApiRecords = (
  ~basePath: string,
  ~dirPath: string,
  ~pageRank: int,
  ~category: string,
  ~files: option<array<string>>=?,
): array<record> => {
  open JSON
  Node.Fs.readdirSync(dirPath)
  ->Array.filter(entry => {
    let isJson = String.endsWith(entry, ".json") && entry !== "toc_tree.json"
    switch files {
    | Some(allowed) => isJson && allowed->Array.includes(entry)
    | None => isJson
    }
  })
  ->Array.flatMap(entry => {
    let fullPath = Node.Path.join([dirPath, entry])
    let fileContent = Node.Fs.readFileSync2(fullPath, "utf8")

    switch JSON.parseOrThrow(fileContent) {
    | Object(modules) =>
      modules
      ->Dict.toArray
      ->Array.flatMap(((key, moduleJson)) => {
        switch moduleJson {
        | Object(dict{
            "id": String(id),
            "name": String(name),
            "docstrings": Array(docstrings),
            "items": Array(items),
          }) => {
            let moduleUrl = basePath ++ "/" ++ key
            let moduleDocstring = switch docstrings[0] {
            | Some(String(d)) => Some(d->cleanDocstring->truncate(~maxLen=maxContentLength))
            | _ => None
            }

            let moduleRecord = {
              objectID: id,
              url: moduleUrl,
              url_without_anchor: moduleUrl,
              anchor: None,
              content: moduleDocstring,
              type_: "lvl1",
              hierarchy: makeHierarchy(~lvl0=category, ~lvl1=name, ()),
              weight: {pageRank, level: 90, position: 0},
            }

            let sortedItems = items->Array.toSorted(
              (a, b) => {
                switch (a, b) {
                | (Object(dict{"name": String(nameA)}), Object(dict{"name": String(nameB)})) =>
                  nameA->String.localeCompare(nameB)
                | _ => 0.
                }
              },
            )

            let itemRecords = sortedItems->Array.filterMapWithIndex(
              (item, i) => {
                switch item {
                | Object(dict{
                    "id": String(itemId),
                    "name": String(itemName),
                    "docstrings": Array(itemDocstrings),
                    "signature": ?signature,
                    "kind": String(kind),
                  }) => {
                    let kindPrefix = switch kind {
                    | "type" => "type-"
                    | _ => "value-"
                    }
                    let itemAnchor = kindPrefix ++ itemName
                    let itemUrl = moduleUrl ++ "#" ++ itemAnchor
                    let qualifiedName = name ++ "." ++ itemName
                    let docstringIntro = switch itemDocstrings[0] {
                    | Some(String(d)) if String.length(d) > 0 => {
                        // Take content before first heading or code block
                        let intro =
                          d
                          ->String.split("\n## ")
                          ->Array.get(0)
                          ->Option.getOr(d)
                          ->String.split("\n```")
                          ->Array.get(0)
                          ->Option.getOr(d)
                          ->String.trim
                        Some(intro->truncate(~maxLen=2000))
                      }
                    | _ => None
                    }
                    let content = switch docstringIntro {
                    | Some(d) if String.length(d) > 0 => Some(d)
                    | _ =>
                      switch signature {
                      | Some(String(s)) => Some(s)
                      | _ => None
                      }
                    }

                    Some({
                      objectID: itemId,
                      url: itemUrl,
                      url_without_anchor: moduleUrl,
                      anchor: Some(itemAnchor),
                      content,
                      type_: "lvl1",
                      hierarchy: makeHierarchy(~lvl0=category, ~lvl1=qualifiedName, ()),
                      weight: {pageRank, level: 70, position: i},
                    })
                  }
                | _ => None
                }
              },
            )

            [moduleRecord]->Array.concat(itemRecords)
          }
        | _ => []
        }
      })
    | _ => []
    | exception _ => []
    }
  })
}

// --- JSON serialization ---

let optionToJson = (opt: option<string>): JSON.t =>
  switch opt {
  | Some(s) => JSON.String(s)
  | None => JSON.Null
  }

let hierarchyToJson = (h: hierarchy): JSON.t => {
  let dict = Dict.make()
  dict->Dict.set("lvl0", JSON.String(h.lvl0))
  dict->Dict.set("lvl1", JSON.String(h.lvl1))
  dict->Dict.set("lvl2", optionToJson(h.lvl2))
  dict->Dict.set("lvl3", optionToJson(h.lvl3))
  dict->Dict.set("lvl4", optionToJson(h.lvl4))
  dict->Dict.set("lvl5", optionToJson(h.lvl5))
  dict->Dict.set("lvl6", optionToJson(h.lvl6))
  JSON.Object(dict)
}

let weightToJson = (w: weight): JSON.t => {
  let dict = Dict.make()
  dict->Dict.set("pageRank", JSON.Number(Int.toFloat(w.pageRank)))
  dict->Dict.set("level", JSON.Number(Int.toFloat(w.level)))
  dict->Dict.set("position", JSON.Number(Int.toFloat(w.position)))
  JSON.Object(dict)
}

let withBaseUrl = (record: record, ~siteUrl: string): record => {
  let normalizedSiteUrl = siteUrl->String.replaceRegExp(RegExp.fromString("/+$", ~flags=""), "")
  let absolutize = (url: string) =>
    if RegExp.test(RegExp.fromString("^https?://", ~flags=""), url) {
      url
    } else {
      let normalizedPath = String.startsWith(url, "/") ? url : "/" ++ url
      normalizedSiteUrl ++ normalizedPath
    }

  {
    ...record,
    url: absolutize(record.url),
    url_without_anchor: absolutize(record.url_without_anchor),
  }
}

let toJson = (r: record): JSON.t => {
  let dict = Dict.make()
  dict->Dict.set("objectID", JSON.String(r.objectID))
  dict->Dict.set("url", JSON.String(r.url))
  dict->Dict.set("url_without_anchor", JSON.String(r.url_without_anchor))
  dict->Dict.set("anchor", optionToJson(r.anchor))
  dict->Dict.set("content", optionToJson(r.content))
  dict->Dict.set("type", JSON.String(r.type_))
  dict->Dict.set("hierarchy", hierarchyToJson(r.hierarchy))
  dict->Dict.set("weight", weightToJson(r.weight))
  JSON.Object(dict)
}

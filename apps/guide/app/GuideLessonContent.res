let fail = message => JsExn.throw(Error(message))

let fieldLabel = (~sourcePath, ~key) => `Guide lesson ${sourcePath} frontmatter "${key}"`

let readString = (~dict, ~sourcePath, ~key) =>
  switch dict->Dict.get(key) {
  | Some(JSON.String(value)) if value->String.trim !== "" => value
  | _ => fail(`${fieldLabel(~sourcePath, ~key)} must be a non-empty string.`)
  }

let readOptionalString = (~dict, ~sourcePath, ~key) =>
  switch dict->Dict.get(key) {
  | Some(JSON.String(value)) => Some(value)
  | Some(_) => fail(`${fieldLabel(~sourcePath, ~key)} must be a string when present.`)
  | None => None
  }

let readInt = (~dict, ~sourcePath, ~key) =>
  switch dict->Dict.get(key) {
  | Some(JSON.Number(value)) => value->Float.toInt
  | _ => fail(`${fieldLabel(~sourcePath, ~key)} must be a number.`)
  }

let readObject = (~dict, ~sourcePath, ~key) =>
  switch dict->Dict.get(key) {
  | Some(JSON.Object(value)) => value
  | _ => fail(`${fieldLabel(~sourcePath, ~key)} must be an object.`)
  }

let frontmatterObject = (~frontmatter, ~sourcePath) =>
  switch frontmatter {
  | JSON.Object(dict) => dict
  | _ => fail(`Guide lesson ${sourcePath} must use object frontmatter.`)
  }

let exerciseFromFrontmatter = (~dict, ~sourcePath): GuideLesson.exercise => {
  let check = switch readOptionalString(~dict, ~sourcePath, ~key="expectedOutput") {
  | Some(expectedOutput) => GuideLesson.ExpectedOutput(expectedOutput)
  | None => GuideLesson.Manual
  }

  {
    id: readString(~dict, ~sourcePath, ~key="id"),
    title: readString(~dict, ~sourcePath, ~key="title"),
    initialCode: readString(~dict, ~sourcePath, ~key="initialCode")->String.trimEnd,
    check,
  }
}

let lessonFromFile = sourcePath => {
  let raw = Node.Fs.readFileSync(sourcePath)
  let {frontmatter, content}: MarkdownParser.result = MarkdownParser.parseSync(raw)
  let dict = frontmatterObject(~frontmatter, ~sourcePath)
  let exerciseDict = readObject(~dict, ~sourcePath, ~key="exercise")

  {
    GuideLesson.id: readString(~dict, ~sourcePath, ~key="id"),
    position: readInt(~dict, ~sourcePath, ~key="position"),
    sourcePath,
    missionLabel: readString(~dict, ~sourcePath, ~key="missionLabel"),
    title: readString(~dict, ~sourcePath, ~key="title"),
    description: readString(~dict, ~sourcePath, ~key="description"),
    content: content->String.trim,
    exercise: exerciseFromFrontmatter(~dict=exerciseDict, ~sourcePath),
  }
}

let rec scanDir = currentDir =>
  Node.Fs.readdirSync(currentDir)->Array.flatMap(entry => {
    let fullPath = Node.Path.join2(currentDir, entry)

    if Node.Fs.statSync(fullPath)["isDirectory"]() {
      scanDir(fullPath)
    } else if Node.Path.extname(entry) === ".mdx" {
      [fullPath]
    } else {
      []
    }
  })

let lessonsDir = () => Node.Path.join2(Node.Process.cwd(), "app/lessons")

let load = (~dir=lessonsDir()) => scanDir(dir)->Array.map(lessonFromFile)->GuideLesson.sort

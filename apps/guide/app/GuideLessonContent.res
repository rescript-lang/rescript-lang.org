let lessonFromFile = sourcePath => {
  let raw = Node.Fs.readFileSync(sourcePath)
  switch GuideLessonFrontmatter.parse(~raw, ~sourcePath) {
  | Ok(lesson) => lesson
  | Error(message) => throw(GuideLessonFrontmatter.InvalidFrontmatter(message))
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

let load = (~dir=lessonsDir()) =>
  scanDir(dir)->Array.map(lessonFromFile)->GuideLessonFrontmatter.validateOrFail->GuideLesson.sort

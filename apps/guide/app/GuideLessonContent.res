let lessonFromFile = sourcePath => {
  let raw = Node.Fs.readFileSync(sourcePath)
  GuideLessonFrontmatter.parse(~raw, ~sourcePath)
}

let collect = results =>
  results->Array.reduce(Ok([]), (accumulator, result) =>
    switch (accumulator, result) {
    | (Ok(lessons), Ok(lesson)) => Ok([...lessons, lesson])
    | (Error(message), _) => Error(message)
    | (_, Error(message)) => Error(message)
    }
  )

let validateAndSort = lessons =>
  switch GuideLessonFrontmatter.validate(lessons) {
  | Ok() => Ok(lessons->GuideLesson.sort)
  | Error(error) => Error(GuideLessonFrontmatter.validationErrorMessage(error))
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
  scanDir(dir)->Array.map(lessonFromFile)->collect->Result.flatMap(validateAndSort)

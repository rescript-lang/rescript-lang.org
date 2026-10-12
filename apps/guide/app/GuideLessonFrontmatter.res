type duplicate = {
  value: string,
  sourcePaths: array<string>,
}

type validationError =
  | DuplicateLessonId(duplicate)
  | DuplicateExerciseId(duplicate)
  | DuplicatePosition(duplicate)

type identifiedValue = {
  value: string,
  sourcePath: string,
}

exception InvalidFrontmatter(string)

let fail = message => throw(InvalidFrontmatter(message))

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

let fromRaw = (~raw, ~sourcePath) => {
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

let parse = (~raw, ~sourcePath) =>
  try {
    Ok(fromRaw(~raw, ~sourcePath))
  } catch {
  | InvalidFrontmatter(message) => Error(message)
  | JsExn(error) =>
    Error(
      error
      ->JsExn.message
      ->Option.getOr(`Guide lesson ${sourcePath} could not parse frontmatter.`),
    )
  }

let findDuplicate = values =>
  values->Array.findMap(current =>
    values
    ->Array.find(other => other.sourcePath !== current.sourcePath && other.value === current.value)
    ->Option.map(other => {
      value: current.value,
      sourcePaths: [current.sourcePath, other.sourcePath],
    })
  )

let lessonIds = (lessons: array<GuideLesson.t>) =>
  lessons->Array.map(lesson => {value: lesson.id, sourcePath: lesson.sourcePath})

let exerciseIds = (lessons: array<GuideLesson.t>) =>
  lessons->Array.map(lesson => {value: lesson.exercise.id, sourcePath: lesson.sourcePath})

let positions = (lessons: array<GuideLesson.t>) =>
  lessons->Array.map(lesson => {
    value: lesson.position->Int.toString,
    sourcePath: lesson.sourcePath,
  })

let validate = lessons =>
  switch lessons->lessonIds->findDuplicate {
  | Some(duplicate) => Error(DuplicateLessonId(duplicate))
  | None =>
    switch lessons->exerciseIds->findDuplicate {
    | Some(duplicate) => Error(DuplicateExerciseId(duplicate))
    | None =>
      switch lessons->positions->findDuplicate {
      | Some(duplicate) => Error(DuplicatePosition(duplicate))
      | None => Ok()
      }
    }
  }

let validationErrorMessage = error =>
  switch error {
  | DuplicateLessonId({value, sourcePaths}) =>
    `Duplicate guide lesson id "${value}" in ${sourcePaths->Array.join(" and ")}.`
  | DuplicateExerciseId({value, sourcePaths}) =>
    `Duplicate guide exercise id "${value}" in ${sourcePaths->Array.join(" and ")}.`
  | DuplicatePosition({value, sourcePaths}) =>
    `Duplicate guide lesson position "${value}" in ${sourcePaths->Array.join(" and ")}.`
  }

let validateOrFail = lessons =>
  switch lessons->validate {
  | Ok() => lessons
  | Error(error) => error->validationErrorMessage->fail
  }

// Source paths are needed for build diagnostics, not for the serialized lesson model.
type t = {sourcePath: string, lesson: GuideLesson.t}

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

let readString = (~dict, ~sourcePath, ~key, ~prefix="", ~allowEmpty=false) =>
  switch dict->Dict.get(key) {
  | Some(JSON.String(value)) if allowEmpty || value->String.trim !== "" => value
  | _ =>
    let requirement = allowEmpty ? "a string" : "a non-empty string"
    fail(`${fieldLabel(~sourcePath, ~key=prefix ++ key)} must be ${requirement}.`)
  }

let isSlug = value => value->String.trim === value && /^[a-z0-9]+(-[a-z0-9]+)*$/->RegExp.test(value)

let readId = (~dict, ~sourcePath, ~prefix="", ~allowSlashes=false) => {
  let id = readString(~dict, ~sourcePath, ~key="id", ~prefix)
  let segments = allowSlashes ? id->String.split("/") : [id]
  if segments->Array.every(isSlug) {
    id
  } else {
    let requirement = allowSlashes
      ? "one or more URL-safe slugs separated by slashes"
      : "a URL-safe slug"
    fail(
      `${fieldLabel(
          ~sourcePath,
          ~key=prefix ++ "id",
        )} must be ${requirement} (lowercase ASCII letters and digits, with hyphens between words).`,
    )
  }
}

let readInt = (~dict, ~sourcePath, ~key) =>
  switch dict->Dict.get(key) {
  | Some(JSON.Number(value)) if value->Float.toInt->Int.toFloat === value => value->Float.toInt
  | _ => fail(`${fieldLabel(~sourcePath, ~key)} must be a 32-bit integer.`)
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
  {
    id: readId(~dict, ~sourcePath, ~prefix="exercise.", ~allowSlashes=true),
    initialCode: readString(
      ~dict,
      ~sourcePath,
      ~key="initialCode",
      ~prefix="exercise.",
    )->String.trimEnd,
    expectedOutput: readString(
      ~dict,
      ~sourcePath,
      ~key="expectedOutput",
      ~prefix="exercise.",
      ~allowEmpty=true,
    ),
  }
}

let fromRaw = (~raw, ~sourcePath) => {
  let {frontmatter, content}: MarkdownParser.result = MarkdownParser.parseSync(raw)
  let dict = frontmatterObject(~frontmatter, ~sourcePath)
  let exerciseDict = readObject(~dict, ~sourcePath, ~key="exercise")

  {
    sourcePath,
    lesson: {
      GuideLesson.id: readId(~dict, ~sourcePath),
      position: readInt(~dict, ~sourcePath, ~key="position"),
      missionLabel: readString(~dict, ~sourcePath, ~key="missionLabel"),
      title: readString(~dict, ~sourcePath, ~key="title"),
      content: content->String.trim,
      exercise: exerciseFromFrontmatter(~dict=exerciseDict, ~sourcePath),
    },
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

let lessonIds = (lessons: array<t>) =>
  lessons->Array.map(({lesson, sourcePath}) => {value: lesson.id, sourcePath})

let exerciseIds = (lessons: array<t>) =>
  lessons->Array.map(({lesson, sourcePath}) => {value: lesson.exercise.id, sourcePath})

let positions = (lessons: array<t>) =>
  lessons->Array.map(({lesson, sourcePath}) => {
    value: lesson.position->Int.toString,
    sourcePath,
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

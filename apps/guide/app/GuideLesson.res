type exerciseCheck =
  | ExpectedOutput(string)
  | Manual

type exercise = {
  id: string,
  title: string,
  initialCode: string,
  check: exerciseCheck,
}

type t = {
  id: string,
  position: int,
  sourcePath: string,
  missionLabel: string,
  title: string,
  description: string,
  content: string,
  exercise: exercise,
}

let sort = lessons =>
  lessons->Array.toSorted((a, b) =>
    switch Int.compare(a.position, b.position) {
    | 0. => String.compare(a.id, b.id)
    | result => result
    }
  )

let firstLesson = lessons => lessons->Array.get(0)->Option.getOrThrow

let lessonAt = (~lessons, index) => lessons->Array.get(index)->Option.getOr(lessons->firstLesson)

let hashForLesson = (lesson: t) => "#" ++ lesson.id

let lessonIdFromHash = hash =>
  if hash->String.startsWith("#") {
    hash->String.slice(~start=1)
  } else {
    hash
  }

let indexForId = (~lessons, lessonId) => {
  let index = lessons->Array.findIndex(lesson => lesson.id === lessonId)
  index < 0 ? 0 : index
}

let indexForHash = (~lessons, hash) => hash->lessonIdFromHash->indexForId(~lessons)

let hasPreviousLesson = index => index > 0

let hasNextLesson = (~lessons, index) => index < lessons->Array.length - 1

let runtimeLogText = (runtimeLog: GuideCompilerFeedback.Output.runtimeLog) =>
  runtimeLog.content->Array.join(" ")

let isExerciseComplete = (~exercise, ~output: GuideCompilerFeedback.Output.t) =>
  switch exercise.check {
  | ExpectedOutput(expected) =>
    output.runtimeLogs->Array.some(runtimeLog => runtimeLog->runtimeLogText === expected)
  | Manual => false
  }

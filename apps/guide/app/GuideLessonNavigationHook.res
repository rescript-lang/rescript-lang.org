type t = {
  lesson: GuideLesson.t,
  output: GuideCompilerFeedback.Output.t,
  setOutput: (GuideCompilerFeedback.Output.t => GuideCompilerFeedback.Output.t) => unit,
  hasPreviousLesson: bool,
  hasNextLesson: bool,
  checkpointComplete: bool,
  forwardActionEnabled: bool,
  goToPreviousLesson: ReactEvent.Mouse.t => unit,
  goToNextLesson: ReactEvent.Mouse.t => unit,
}

let emptyOutput = () => GuideCompilerFeedback.Output.make(~status="Output")

let outputForLessonIndex = index =>
  if index === 0 {
    GuideCompilerFeedback.Output.initial
  } else {
    emptyOutput()
  }

let docsIntroUrl = "https://rescript-lang.org/docs/manual/introduction"

let navigateToLesson = (~goToHash, ~setLessonIndex, ~setOutput, ~lessons, index) => {
  let lesson = GuideLesson.lessonAt(~lessons, index)
  goToHash(lesson->GuideLesson.hashForLesson)
  setLessonIndex(_ => index)
  setOutput(_ => index->outputForLessonIndex)
}

let useLessonNavigation = (~lessons, ~goToDocsIntro): t => {
  let location = ReactRouter.useLocation()
  let navigate = ReactRouter.useNavigate()
  let goToHash = hash => navigate(hash)
  let (lessonIndex, setLessonIndex) = React.useState(() => 0)
  let (output, setOutput) = React.useState(() => GuideCompilerFeedback.Output.initial)

  React.useEffect(() => {
    let currentHash = location.hash->Option.getOr("")
    let nextLessonIndex = GuideLesson.indexForHash(~lessons, currentHash)
    let nextLesson = GuideLesson.lessonAt(~lessons, nextLessonIndex)
    let nextLessonHash = nextLesson->GuideLesson.hashForLesson

    setLessonIndex(_ => nextLessonIndex)
    setOutput(_ => nextLessonIndex->outputForLessonIndex)

    // Keep the hash canonical so direct links, browser back, and MemoryRouter tests share one path.
    if currentHash !== nextLessonHash {
      navigate(nextLessonHash, ~options={replace: true})
    }

    None
  }, (location.hash, navigate, lessons))

  let lesson = GuideLesson.lessonAt(~lessons, lessonIndex)
  let exercise = lesson.exercise
  let hasPreviousLesson = GuideLesson.hasPreviousLesson(lessonIndex)
  let hasNextLesson = GuideLesson.hasNextLesson(~lessons, lessonIndex)
  let exercisePassed = GuideLesson.isExerciseComplete(~exercise, ~output)
  let checkpointComplete = exercisePassed || GuideLayout.isExerciseCompleted(exercise.id)
  let forwardActionEnabled = checkpointComplete

  React.useEffect(() => {
    if exercisePassed {
      GuideLayout.saveCompletedExercise(exercise.id)
    }
    None
  }, (exercisePassed, exercise.id))

  let goToPreviousLesson = _event => {
    if hasPreviousLesson {
      let previousLessonIndex = lessonIndex - 1
      navigateToLesson(~goToHash, ~setLessonIndex, ~setOutput, ~lessons, previousLessonIndex)
    }
  }

  let goToNextLesson = _event => {
    if hasNextLesson && checkpointComplete {
      let nextLessonIndex = lessonIndex + 1
      navigateToLesson(~goToHash, ~setLessonIndex, ~setOutput, ~lessons, nextLessonIndex)
    } else if checkpointComplete {
      goToDocsIntro(docsIntroUrl)
    }
  }

  {
    lesson,
    output,
    setOutput,
    hasPreviousLesson,
    hasNextLesson,
    checkpointComplete,
    forwardActionEnabled,
    goToPreviousLesson,
    goToNextLesson,
  }
}

type loaderData = {
  compilerData: GuideCompilerData.t,
  lessons: array<GuideLesson.t>,
}

exception LessonLoadError(string)

let loader: ReactRouter.Loader.t<loaderData> = async _ => {
  let compilerData = GuideCompilerData.load()
  let lessons = switch GuideLessonContent.load() {
  | Ok(lessons) => lessons
  | Error(message) => throw(LessonLoadError(message))
  }

  {compilerData, lessons}
}

@react.component
let default = () => {
  let {compilerData, lessons}: loaderData = ReactRouter.useLoaderData()
  <GuideHome compilerData lessons />
}

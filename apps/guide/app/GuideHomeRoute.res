type loaderData = {
  compilerData: option<GuideCompilerData.t>,
  lessons: array<GuideLesson.t>,
}

let loader: ReactRouter.Loader.t<loaderData> = async _ => {
  let compilerData = await GuideCompilerData.load()
  let lessons = GuideLessonContent.load()

  {compilerData, lessons}
}

@react.component
let default = () => {
  let {compilerData, lessons}: loaderData = ReactRouter.useLoaderData()
  <GuideHome ?compilerData lessons />
}

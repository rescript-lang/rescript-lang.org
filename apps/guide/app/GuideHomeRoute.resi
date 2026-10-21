type loaderData = {
  compilerData: GuideCompilerData.t,
  lessons: array<GuideLesson.t>,
}

@live
let loader: ReactRouter.Loader.t<loaderData>

@react.component @live
let default: unit => React.element

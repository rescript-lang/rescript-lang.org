type loaderData = {
  compilerData: option<GuideCompilerData.t>,
  lessons: array<GuideLesson.t>,
}

let loader: ReactRouter.Loader.t<loaderData>

@react.component
let default: unit => React.element

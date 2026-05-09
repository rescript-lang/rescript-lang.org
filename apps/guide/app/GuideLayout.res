type theme =
  | Light
  | Dark

type paneSizes = {
  instructionsWidth: option<float>,
  outputHeight: float,
}

let minInstructionsWidth = 320.0
let minWorkspaceWidth = 480.0
let minEditorHeight = 240.0
let minOutputHeight = 160.0
let defaultOutputHeight = 220.0
let storageKey = key => `rescript-guide:v1:${key}`
let themeStorageKey = storageKey("theme")
let instructionsWidthStorageKey = storageKey("pane:instructionsWidth")
let outputHeightStorageKey = storageKey("pane:outputHeight")
let progressStorageKey = storageKey("progress")
let exerciseCodeStorageKey = exerciseId => storageKey(`exercise:${exerciseId}`)

let defaultPaneSizes = {
  instructionsWidth: None,
  outputHeight: defaultOutputHeight,
}

let clampInstructionsWidth = (~viewportWidth, ~pointerX) =>
  pointerX->Float.clamp(~min=minInstructionsWidth, ~max=viewportWidth -. minWorkspaceWidth)

let clampOutputHeight = (~viewportHeight, ~pointerY) =>
  (viewportHeight -. pointerY)
    ->Float.clamp(~min=minOutputHeight, ~max=viewportHeight -. minEditorHeight)

let clampPaneSizes = (~viewportWidth, ~viewportHeight, paneSizes) => {
  let instructionsWidth =
    paneSizes.instructionsWidth->Option.map(width =>
      clampInstructionsWidth(~viewportWidth, ~pointerX=width)
    )

  {
    instructionsWidth,
    outputHeight: paneSizes.outputHeight->Float.clamp(
      ~min=minOutputHeight,
      ~max=viewportHeight -. minEditorHeight,
    ),
  }
}

let paneSizesStyle = paneSizes => {
  let instructionsWidth = switch paneSizes.instructionsWidth {
  | Some(width) => `${width->Float.toString}px`
  | None => "50%"
  }

  `--guide-instructions-width: ${instructionsWidth}; --guide-output-height: ${paneSizes.outputHeight->Float.toString}px;`
}

let themeClass = theme =>
  switch theme {
  | Light => "guide-theme-light"
  | Dark => "guide-theme-dark"
  }

let toggleTheme = theme =>
  switch theme {
  | Light => Dark
  | Dark => Light
  }

let themeToCodeMirror = theme =>
  switch theme {
  | Light => CodeMirror.Theme.Light
  | Dark => CodeMirror.Theme.Dark
  }

let themeToString = theme =>
  switch theme {
  | Light => "light"
  | Dark => "dark"
  }

let themeFromString = value =>
  switch value {
  | "dark" => Dark
  | _ => Light
  }

let themeToggleLabel = theme =>
  switch theme {
  | Light => "Switch to dark mode"
  | Dark => "Switch to light mode"
  }

let themeToggleText = theme =>
  switch theme {
  | Light => "Dark"
  | Dark => "Light"
  }

// localStorage can throw in restricted browser contexts. Persistence is optional
// for the guide, so storage failures fall back to the current UI state.
let getLocalStorageItem = key => {
  try {
    WebAPI.Storage.getItem(window.localStorage, key)->Null.toOption
  } catch {
  | JsExn(_) => None
  }
}

let setLocalStorageItem = (~key, ~value) => {
  try {
    WebAPI.Storage.setItem(window.localStorage, ~key, ~value)
  } catch {
  | JsExn(_) => ()
  }
}

let removeLocalStorageItem = key => {
  try {
    WebAPI.Storage.removeItem(window.localStorage, key)
  } catch {
  | JsExn(_) => ()
  }
}

let loadTheme = () =>
  getLocalStorageItem(themeStorageKey)
  ->Option.map(themeFromString)
  ->Option.getOr(Light)

let saveTheme = theme => setLocalStorageItem(~key=themeStorageKey, ~value=theme->themeToString)

let parseStoredFloat = value =>
  switch value->Float.fromString {
  | Some(value) if value > 0.0 => Some(value)
  | _ => None
  }

let getStoredFloat = key => getLocalStorageItem(key)->Option.flatMap(parseStoredFloat)

let loadPaneSizes = () => {
  instructionsWidth: getStoredFloat(instructionsWidthStorageKey),
  outputHeight: getStoredFloat(outputHeightStorageKey)->Option.getOr(defaultOutputHeight),
}

let savePaneSizes = paneSizes => {
  switch paneSizes.instructionsWidth {
  | Some(width) =>
    setLocalStorageItem(~key=instructionsWidthStorageKey, ~value=width->Float.toString)
  | None => removeLocalStorageItem(instructionsWidthStorageKey)
  }
  setLocalStorageItem(~key=outputHeightStorageKey, ~value=paneSizes.outputHeight->Float.toString)
}

let clearPaneSizes = () => {
  removeLocalStorageItem(instructionsWidthStorageKey)
  removeLocalStorageItem(outputHeightStorageKey)
}

let parseCompletedExerciseIds = value => {
  open JSON

  try {
    switch value->JSON.parseOrThrow {
    | Object(dict{"completedExerciseIds": Array(ids)}) =>
      ids->Array.filterMap(id =>
        switch id {
        | String(id) => Some(id)
        | _ => None
        }
      )
    | _ => []
    }
  } catch {
  | JsExn(_) => []
  }
}

let stringifyCompletedExerciseIds = completedExerciseIds => {
  let dict = Dict.make()
  dict->Dict.set(
    "completedExerciseIds",
    JSON.Array(completedExerciseIds->Array.map(id => JSON.String(id))),
  )
  JSON.Object(dict)->JSON.stringify
}

let loadCompletedExerciseIds = () =>
  getLocalStorageItem(progressStorageKey)
  ->Option.map(parseCompletedExerciseIds)
  ->Option.getOr([])

let saveCompletedExerciseIds = completedExerciseIds =>
  setLocalStorageItem(
    ~key=progressStorageKey,
    ~value=completedExerciseIds->stringifyCompletedExerciseIds,
  )

let saveCompletedExercise = exerciseId => {
  let completedExerciseIds = loadCompletedExerciseIds()
  if !(completedExerciseIds->Array.includes(exerciseId)) {
    saveCompletedExerciseIds(completedExerciseIds->Array.concat([exerciseId]))
  }
}

let isExerciseCompleted = exerciseId => loadCompletedExerciseIds()->Array.includes(exerciseId)

let clearCompletedExercises = () => removeLocalStorageItem(progressStorageKey)

let loadExerciseCode = exerciseId => getLocalStorageItem(exerciseId->exerciseCodeStorageKey)

let saveExerciseCode = (~exerciseId, ~code) =>
  setLocalStorageItem(~key=exerciseId->exerciseCodeStorageKey, ~value=code)

let clearExerciseCode = exerciseId => removeLocalStorageItem(exerciseId->exerciseCodeStorageKey)

module Api = RescriptCompilerApi

let resultBindingName = "__rescriptGuideOutput"

let expressionData = (typeHint: Api.TypeHint.t) =>
  switch typeHint {
  | Expression(data) => Some(data)
  | TypeDeclaration(_) | Binding(_) | CoreType(_) => None
  }

let offsetFromPosition = (position: Api.TypeHint.position, code) => {
  let lines = code->String.split("\n")
  let offset = ref(0)

  if position.line > 1 {
    for i in 0 to position.line - 2 {
      switch lines->Array.get(i) {
      | Some(line) => offset.contents = offset.contents + line->String.length + 1
      | None => ()
      }
    }
  }

  offset.contents + position.col
}

let startsAtLineBoundary = (position: Api.TypeHint.position, code) => {
  let lines = code->String.split("\n")

  switch lines->Array.get(position.line - 1) {
  | Some(line) => line->String.slice(~start=0, ~end=position.col)->String.trim === ""
  | None => false
  }
}

let finalExpressionData = (~code, typeHints) => {
  let best: ref<option<(int, int, Api.TypeHint.data)>> = ref(None)

  typeHints->Array.forEach(typeHint =>
    switch typeHint->expressionData {
    | Some(data) if startsAtLineBoundary(data.start, code) =>
      let startOffset = data.start->offsetFromPosition(code)
      let endOffset = data.end->offsetFromPosition(code)
      switch best.contents {
      | Some((bestEndOffset, bestStartOffset, _))
        if bestEndOffset > endOffset ||
          (bestEndOffset === endOffset && bestStartOffset <= startOffset) => ()
      | _ => best.contents = Some((endOffset, startOffset, data))
      }
    | Some(_) | None => ()
    }
  )

  best.contents->Option.map(((_, _, data)) => data)
}

let instrument = (~code, ~typeHints) => {
  switch typeHints->finalExpressionData(~code) {
  | Some({start, end}) =>
    let startOffset = start->offsetFromPosition(code)
    let endOffset = end->offsetFromPosition(code)
    let expressionSource = code->String.slice(~start=startOffset, ~end=endOffset)->String.trim

    if expressionSource === "" {
      None
    } else {
      let prefix = code->String.slice(~start=0, ~end=startOffset)
      let suffix = code->String.slice(~start=endOffset)
      Some(`${prefix}let ${resultBindingName} = (${expressionSource})${suffix}`)
    }
  | None => None
  }
}

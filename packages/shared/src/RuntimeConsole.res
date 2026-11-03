type level = [#log | #warn | #error]
type log = {level: level, content: array<string>}

@module("./runtimeConsole.js") external bridgeScript: string = "bridgeScript"

@val external toText: JSON.t => string = "String"

let argumentText = value =>
  switch value {
  | JSON.String(_) | JSON.Number(_) | JSON.Boolean(_) => Some(toText(value))
  | _ => None
  }

let fromMessage = data =>
  switch data {
  | JSON.Object(dict) =>
    let level = switch dict->Dict.get("type") {
    | Some(JSON.String("log")) => Some(#log)
    | Some(JSON.String("warn")) => Some(#warn)
    | Some(JSON.String("error")) => Some(#error)
    | _ => None
    }
    let args = dict->Dict.get("args")->Option.flatMap(JSON.Decode.array)
    switch (level, args) {
    | (Some(level), Some(args)) =>
      let content = args->Array.filterMap(argumentText)
      content->Array.length === args->Array.length ? Some({level, content}) : None
    | _ => None
    }
  | _ => None
  }

let text = log => log.content->Array.join(" ")

let useLogs = onLog => React.useEffect(() => {
    let listener = event => event["data"]->fromMessage->Option.forEach(onLog)
    WebAPI.Window.addEventListener(window, Custom("message"), listener)
    Some(() => WebAPI.Window.removeEventListener(window, Custom("message"), listener))
  }, [onLog])

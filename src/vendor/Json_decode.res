@new external _unsafeCreateUninitializedArray: int => array<'a> = "Array"

let _isInteger = value => Float.isFinite(value) && Math.floor(value) === value

type decoder<'a> = JSON.t => 'a

exception DecodeError(string)

let id = json => json

let bool = json =>
  if typeof(json) == #boolean {
    (Obj.magic((json: JSON.t)): bool)
  } else {
    \"@@"(raise, DecodeError("Expected boolean, got " ++ JSON.stringify(json)))
  }

let float = json =>
  if typeof(json) == #number {
    (Obj.magic((json: JSON.t)): float)
  } else {
    \"@@"(raise, DecodeError("Expected number, got " ++ JSON.stringify(json)))
  }

let int = json => {
  let f = float(json)
  if _isInteger(f) {
    (Obj.magic((f: float)): int)
  } else {
    \"@@"(raise, DecodeError("Expected integer, got " ++ JSON.stringify(json)))
  }
}

let string = json =>
  if typeof(json) == #string {
    (Obj.magic((json: JSON.t)): string)
  } else {
    \"@@"(raise, DecodeError("Expected string, got " ++ JSON.stringify(json)))
  }

let char = json => {
  let s = string(json)
  if String.length(s) == 1 {
    String.getUnsafe(s, 0)->Obj.magic
  } else {
    \"@@"(raise, DecodeError("Expected single-character string, got " ++ JSON.stringify(json)))
  }
}

let date = json => Date.fromString(string(json))

let nullable = (decode, json) =>
  if (Obj.magic(json): Null.t<'a>) === Null.null {
    Null.null
  } else {
    Null.make(decode(json))
  }

/* TODO: remove this? */
let nullAs = (value, json) =>
  if (Obj.magic(json): Null.t<'a>) === Null.null {
    value
  } else {
    \"@@"(raise, DecodeError("Expected null, got " ++ JSON.stringify(json)))
  }

let array = (decode, json) =>
  if Array.isArray(json) {
    let source: array<JSON.t> = Obj.magic((json: JSON.t))
    let length = Array.length(source)
    let target = _unsafeCreateUninitializedArray(length)
    for i in 0 to length - 1 {
      let value = try decode(Array.getUnsafe(source, i)) catch {
      | DecodeError(msg) =>
        \"@@"(raise, DecodeError(msg ++ ("\n\tin array at index " ++ Int.toString(i))))
      }

      Array.setUnsafe(target, i, value)
    }
    target
  } else {
    \"@@"(raise, DecodeError("Expected array, got " ++ JSON.stringify(json)))
  }

let list = (decode, json) => array(decode, json)->List.fromArray

let pair = (decodeA, decodeB, json) =>
  if Array.isArray(json) {
    let source: array<JSON.t> = Obj.magic((json: JSON.t))
    let length = Array.length(source)
    if length == 2 {
      try (decodeA(Array.getUnsafe(source, 0)), decodeB(Array.getUnsafe(source, 1))) catch {
      | DecodeError(msg) => \"@@"(raise, DecodeError(msg ++ "\n\tin pair/tuple2"))
      }
    } else {
      \"@@"(
        raise,
        DecodeError(`Expected array of length 2, got array of length ${length->Int.toString}`),
      )
    }
  } else {
    \"@@"(raise, DecodeError("Expected array, got " ++ JSON.stringify(json)))
  }

let tuple2 = pair

let tuple3 = (decodeA, decodeB, decodeC, json) =>
  if Array.isArray(json) {
    let source: array<JSON.t> = Obj.magic((json: JSON.t))
    let length = Array.length(source)
    if length == 3 {
      try (
        decodeA(Array.getUnsafe(source, 0)),
        decodeB(Array.getUnsafe(source, 1)),
        decodeC(Array.getUnsafe(source, 2)),
      ) catch {
      | DecodeError(msg) => \"@@"(raise, DecodeError(msg ++ "\n\tin tuple3"))
      }
    } else {
      \"@@"(
        raise,
        DecodeError(`Expected array of length 3, got array of length ${length->Int.toString}`),
      )
    }
  } else {
    \"@@"(raise, DecodeError("Expected array, got " ++ JSON.stringify(json)))
  }

let tuple4 = (decodeA, decodeB, decodeC, decodeD, json) =>
  if Array.isArray(json) {
    let source: array<JSON.t> = Obj.magic((json: JSON.t))
    let length = Array.length(source)
    if length == 4 {
      try (
        decodeA(Array.getUnsafe(source, 0)),
        decodeB(Array.getUnsafe(source, 1)),
        decodeC(Array.getUnsafe(source, 2)),
        decodeD(Array.getUnsafe(source, 3)),
      ) catch {
      | DecodeError(msg) => \"@@"(raise, DecodeError(msg ++ "\n\tin tuple4"))
      }
    } else {
      \"@@"(
        raise,
        DecodeError(`Expected array of length 4, got array of length ${length->Int.toString}`),
      )
    }
  } else {
    \"@@"(raise, DecodeError("Expected array, got " ++ JSON.stringify(json)))
  }

let dict = (decode, json) =>
  if (
    typeof(json) == #object &&
      (!Array.isArray(json) &&
      !((Obj.magic(json): Null.t<'a>) === Null.null))
  ) {
    let source: Dict.t<JSON.t> = Obj.magic((json: JSON.t))
    let keys = Dict.keysToArray(source)
    let l = Array.length(keys)
    let target = Dict.make()
    for i in 0 to l - 1 {
      let key = Array.getUnsafe(keys, i)
      let value = try decode(Dict.getUnsafe(source, key)) catch {
      | DecodeError(msg) => \"@@"(raise, DecodeError(msg ++ "\n\tin dict"))
      }

      Dict.set(target, key, value)
    }
    target
  } else {
    \"@@"(raise, DecodeError("Expected object, got " ++ JSON.stringify(json)))
  }

let field = (key, decode, json) =>
  if (
    typeof(json) == #object &&
      (!Array.isArray(json) &&
      !((Obj.magic(json): Null.t<'a>) === Null.null))
  ) {
    let dict: Dict.t<JSON.t> = Obj.magic((json: JSON.t))
    switch Dict.get(dict, key) {
    | Some(value) =>
      try decode(value) catch {
      | DecodeError(msg) => \"@@"(raise, DecodeError(msg ++ ("\n\tat field '" ++ (key ++ "'"))))
      }
    | None => \"@@"(raise, DecodeError(`Expected field '${key}'`))
    }
  } else {
    \"@@"(raise, DecodeError("Expected object, got " ++ JSON.stringify(json)))
  }

let rec at = (key_path, decoder, json) =>
  switch key_path {
  | list{key} => field(key, decoder, json)
  | list{first, ...rest} => field(first, at(rest, decoder, ...), json)
  | list{} => \"@@"(raise, Invalid_argument("Expected key_path to contain at least one element"))
  }

let optional = (decode, json) =>
  try Some(decode(json)) catch {
  | DecodeError(_) => None
  }

let oneOf = (decoders, json) => {
  let rec inner = (decoders, errors) =>
    switch decoders {
    | list{} =>
      let formattedErrors = "\n- " ++ Array.join(List.toArray(List.reverse(errors)), "\n- ")
      \"@@"(
        raise,
        DecodeError(
          `All decoders given to oneOf failed. Here are all the errors: ${formattedErrors}\\nAnd the JSON being decoded: ` ++
          JSON.stringify(json),
        ),
      )
    | list{decode, ...rest} =>
      try decode(json) catch {
      | DecodeError(e) => inner(rest, list{e, ...errors})
      }
    }
  inner(decoders, list{})
}

let either = (a, b) => oneOf(list{a, b}, ...)

let withDefault = (default, decode, json) =>
  try decode(json) catch {
  | DecodeError(_) => default
  }

let map = (f, decode, json) => f(decode(json))

let andThen = (b, a, json) => b(a(json))(json)

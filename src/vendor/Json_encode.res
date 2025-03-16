type encoder<'a> = 'a => JSON.t

@val external null: JSON.t = "null"
external string: string => JSON.t = "%identity"
external float: float => JSON.t = "%identity"
external int: int => JSON.t = "%identity"
external bool: bool => JSON.t = "%identity"

let char = c => string(String.make(c))

let date = d => string(Date.toJSON(d)->Option.getUnsafe)

let nullable = (encode, x) =>
  switch x {
  | None => null
  | Some(v) => encode(v)
  }

let withDefault = (d, encode, x) =>
  switch x {
  | None => d
  | Some(v) => encode(v)
  }

external jsonDict: Dict.t<JSON.t> => JSON.t = "%identity"
let dict = (encode, d) => {
  let pairs = Dict.toArray(d)
  let encodedPairs = pairs->Array.map(((k, v)) => (k, encode(v)))
  jsonDict(Dict.fromArray(encodedPairs))
}

let object_ = (props): JSON.t => jsonDict(Dict.fromArray(props->List.toArray))

external jsonArray: array<JSON.t> => JSON.t = "%identity"
let array = (encode, l) => jsonArray(l->Array.map(x => encode(x)))
let list = (encode, x) =>
  switch x {
  | list{} => jsonArray([])
  | list{hd, ...tl} as l =>
    let a = encode(hd)->Array.make(~length=List.length(l))
    let rec fill = (i, x) =>
      switch x {
      | list{} => a
      | list{hd, ...tl} =>
        Array.setUnsafe(a, i, encode(hd))
        fill(i + 1, tl)
      }

    jsonArray(fill(1, tl))
  }

let pair = (encodeA, encodeB, (a, b)) => jsonArray([encodeA(a), encodeB(b)])
let tuple2 = pair
let tuple3 = (encodeA, encodeB, encodeC, (a, b, c)) =>
  jsonArray([encodeA(a), encodeB(b), encodeC(c)])
let tuple4 = (encodeA, encodeB, encodeC, encodeD, (a, b, c, d)) =>
  jsonArray([encodeA(a), encodeB(b), encodeC(c), encodeD(d)])

external stringArray: array<string> => JSON.t = "%identity"
external numberArray: array<float> => JSON.t = "%identity"
external boolArray: array<bool> => JSON.t = "%identity"

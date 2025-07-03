module Decode = Json_decode
module Encode = Json_encode

exception ParseError(string)

let parse = s =>
  try Some(JSON.parseOrThrow(s)) catch {
  | _ => None
  }

let parseOrRaise = s =>
  try JSON.parseOrThrow(s) catch {
  | JsExn(e) =>
    let message = switch JsExn.message(e) {
    | Some(m) => m
    | None => "Unknown error"
    }
    throw(ParseError(message))
  }

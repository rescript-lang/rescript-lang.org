/*
    This module parses ANSI encoded string into structured data.
    It is mostly build for parsing BuckleScript terminal output and
    is not implementing the whole Ansi functionality.

    See: https://en.wikipedia.org/wiki/ANSI_escape_code#Escape_sequences

    Other relevant resources:
    ----
    OCaml compiler Misc.Color encoding colors in the output printers:
    https://github.com/rescript-lang/ocaml/blob/0a3ec12fef5dbee795778a47b18024563b5e49f2/utils/misc.ml
 */

module Color = {
  type t =
    | Black // fg=30 bg=40
    | Red // fg=31 bg=41
    | Green // fg=32 bg=42
    | Yellow // fg=33 bg=43
    | Blue // fg=34 bg=44
    | Magenta // fg=35 bg=45
    | Cyan // fg=36 bg=46
    | White // fg=37 bg=47

  let toString = (c: t) =>
    switch c {
    | Black => "black"
    | Red => "red"
    | Green => "green"
    | Yellow => "yellow"
    | Blue => "blue"
    | Magenta => "magenta"
    | Cyan => "cyan"
    | White => "white"
    }
}

module Sgr = {
  // We don't encode Clear (0) here since it's a special case
  type param =
    | Bold // 1
    | Fg(Color.t) // 30 - 37
    | Bg(Color.t) // 40 - 47
    | Unknown(string)

  let paramToString = s =>
    switch s {
    | Bold => "bold"
    | Fg(c) => "Fg(" ++ (Color.toString(c) ++ ")")
    | Bg(c) => "Bg(" ++ (Color.toString(c) ++ ")")
    | Unknown(s) => "Unknown: " ++ s
    }
}

let esc = `\u001B`

let isAscii = (c: string) => RegExp.test(/[\x40-\x7F]/, c)

module Location = {
  type t = {
    input: string,
    mutable pos: int,
  }

  type loc = {
    startPos: int,
    endPos: int,
  }

  let fromString = input => {input, pos: -1}

  let isDone = p => p.pos >= String.length(p.input)

  let next = p =>
    if !isDone(p) {
      let c = String.get(p.input, p.pos + 1)->Option.getUnsafe
      p.pos = p.pos + 1
      c
    } else {
      String.get(p.input, p.pos)->Option.getUnsafe
    }

  let untilNextEsc = p => {
    let ret = ref(None)
    while !isDone(p) && ret.contents == None {
      let c = next(p)

      if c === esc {
        ret := Some()
      }
    }
    ret.contents
  }

  // Look is useful to look ahead without reading the character
  // from the stream
  let look = (p, num) => {
    let length = String.length(p.input)

    let pos = if p.pos + num >= length {
      length - 1
    } else {
      p.pos + num
    }

    String.get(p.input, pos)->Option.getUnsafe
  }
}

module Lexer = {
  open Location
  open! Sgr

  type token =
    | Text({loc: Location.loc, content: string})
    | Sgr({loc: Location.loc, raw: string, params: array<Sgr.param>})
    | ClearSgr({loc: Location.loc, raw: string})

  type state =
    | Scan
    | ReadSgr({startPos: int, content: string}) // contains collected data
    | ReadText({startPos: int, content: string})

  // Note: the acc array will be mutated in the process
  let rec lex = (~acc: array<token>=[], ~state=Scan, p: Location.t): array<token> =>
    if isDone(p) {
      acc
    } else {
      switch state {
      | Scan =>
        // Checks for the next character and does a state
        // transition according to the entity we are reading (SGR / Text)
        let c = next(p)

        let state = if c === esc {
          ReadSgr({startPos: p.pos, content: ""})
        } else {
          ReadText({startPos: p.pos, content: c})
        }
        lex(~acc, ~state, p)
      | ReadText({startPos, content}) =>
        let c = next(p)

        let endPos = p.pos - 1

        // Determine if we are keep reading text, or start read SGRs
        if c === esc {
          let token = Text({
            loc: {
              startPos,
              endPos,
            },
            content,
          })
          Array.push(acc, token)->ignore
          lex(~acc, ~state=ReadSgr({startPos: p.pos, content: c}), p)
        } else if isDone(p) {
          let token = Text({
            loc: {
              startPos,
              endPos,
            },
            content,
          })
          Array.push(acc, token)->ignore
          acc
        } else {
          let content = content ++ c
          lex(~acc, ~state=ReadText({startPos, content}), p)
        }
      | ReadSgr({startPos, content}) =>
        let c = next(p)

        // on termination
        if c !== "[" && isAscii(c) {
          let raw = content ++ c

          let loc = {startPos, endPos: startPos + String.length(raw) - 1}

          let token = switch RegExp.exec(/\[([0-9;]+)([\x40-\x7F])/, raw) {
          | Some(result) =>
            let groups = RegExp.Result.matches(result)
            switch groups[1] {
            | Some(str) =>
              switch String.split(str->Option.getUnsafe, ";") {
              | ["0"] => ClearSgr({loc, raw})
              | other =>
                let params = Array.map(other, s =>
                  switch s {
                  | "1" => Bold
                  | "30" => Fg(Black)
                  | "31" => Fg(Red)
                  | "32" => Fg(Green)
                  | "33" => Fg(Yellow)
                  | "34" => Fg(Blue)
                  | "35" => Fg(Magenta)
                  | "36" => Fg(Cyan)
                  | "37" => Fg(White)
                  | "40" => Bg(Black)
                  | "41" => Bg(Red)
                  | "42" => Bg(Green)
                  | "43" => Bg(Yellow)
                  | "44" => Bg(Blue)
                  | "45" => Bg(Magenta)
                  | "46" => Bg(Cyan)
                  | "47" => Bg(White)
                  | o => Unknown(o)
                  }
                )
                Sgr({loc, raw, params})
              }

            | None => Sgr({loc, raw, params: []})
            }
          | None => Sgr({loc, raw, params: []})
          }

          Array.push(acc, token)->ignore
          lex(~acc, ~state=Scan, p)
        } else {
          lex(~acc, ~state=ReadSgr({startPos, content: content ++ c}), p)
        }
      }
    }

  // We hide the original implementation to prevent users
  // to pass in their own `acc` array (this array is getting mutated and
  // this could cause side-effects for the consumer otherwise)
  let lex = (p: Location.t) => lex(p)
}

let parse = (input: string) => {
  let p = Location.fromString(input)
  Lexer.lex(p)
}

let onlyText = (tokens: array<Lexer.token>) => {
  open Lexer
  Array.filter(tokens, x =>
    switch x {
    | Text(_) => true
    | _ => false
    }
  )
}

module SgrString = {
  // A sgr encoded element
  open Lexer

  type t = {
    content: string,
    params: array<Sgr.param>,
  }

  let fromTokens = (tokens: array<token>): array<t> => {
    let ret = []
    let params = ref([])
    let content = ref("")

    let length = Array.length(tokens)
    for i in 0 to length - 1 {
      let token = Belt.Array.getExn(tokens, i)

      let isLast = i === length - 1

      switch token {
      | Text(data) =>
        content := content.contents ++ data.content
        if isLast && content.contents !== "" {
          let element = {content: content.contents, params: params.contents}
          Array.push(ret, element)->ignore
        }
      | Sgr(data) =>
        // merge together specific sgr params
        let (fg, bg, rest) = Array.concat(params.contents, data.params)->Array.reduce(
          (None, None, []),
          (acc, next) => {
            let (fg, bg, other) = acc
            switch next {
            | Fg(_) => (Some(next), bg, other)
            | Bg(_) => (fg, Some(next), other)
            | o =>
              if Array.find(other, o2 => o === o2) === None {
                Array.push(other, next)->ignore
              }
              (fg, bg, other)
            }
          },
        )

        if content.contents !== "" {
          let element = {content: content.contents, params: params.contents}
          Array.push(ret, element)->ignore
          content := ""
        }

        params :=
          Belt.Array.concatMany([
            Option.mapOr(fg, [], v => [v]),
            Option.mapOr(bg, [], v => [v]),
            rest,
          ])
      | ClearSgr(_) =>
        if content.contents !== "" {
          let element = {content: content.contents, params: params.contents}
          Array.push(ret, element)->ignore

          params := []
          content := ""
        }
      }
    }

    ret
  }

  let toString = (e: t): string => {
    let content = {
      open String
      replaceRegExp(e.content, /\n/g, "\\n")->replace(esc, "")
    }
    let params = Array.map(e.params, Sgr.paramToString)->Array.join(", ")

    `SgrString params: ${params} | content: ${content}`
  }
}

module Printer = {
  open Lexer

  let tokenString = (t: token): string =>
    switch t {
    | Text({content, loc: {startPos, endPos}}) =>
      let content = {
        open String
        replaceRegExp(content, /\n/g, "\\n")->replace(esc, "")
      }
      `Text "${content}" (${startPos->Int.toString} to ${endPos->Int.toString})`
    | Sgr({params, raw, loc: {startPos, endPos}}) =>
      let raw = String.replace(raw, esc, "")
      let params = Array.map(params, Sgr.paramToString)->Array.join(", ")
      `Sgr "${raw}" -> ${params} (${startPos->Int.toString} to ${endPos->Int.toString})`
    | ClearSgr({loc: {startPos, endPos}, raw}) =>
      let raw = String.replace(raw, esc, "")
      `Clear Sgr "${raw}" (${startPos->Int.toString} to ${endPos->Int.toString})`
    }

  let plainString = (tokens: array<token>): string =>
    Array.map(tokens, x =>
      switch x {
      | Lexer.Text({content}) => content
      | _ => ""
      }
    )->Array.join("")
}

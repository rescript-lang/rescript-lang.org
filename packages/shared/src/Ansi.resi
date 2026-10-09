module Color: {
  type t =
    | Black // fg=30 bg=40
    | Red // fg=31 bg=41
    | Green // fg=32 bg=42
    | Yellow // fg=33 bg=43
    | Blue // fg=34 bg=44
    | Magenta // fg=35 bg=45
    | Cyan // fg=36 bg=46
    | White // fg=37 bg=47
}

module Sgr: {
  // We don't encode Clear (0) here since it's a special case
  type param =
    | Bold // 1
    | Fg(Color.t) // 30 - 37
    | Bg(Color.t) // 40 - 47
    | Unknown(string)
}

module Location: {
  type t = {
    input: string,
    mutable pos: int,
  }

  type loc = {
    startPos: int,
    endPos: int,
  }
}

module Lexer: {
  type token =
    | Text({loc: Location.loc, content: string})
    | Sgr({loc: Location.loc, raw: string, params: array<Sgr.param>})
    | ClearSgr({loc: Location.loc, raw: string})

  type state =
    | Scan
    | ReadSgr({startPos: int, content: string}) // contains collected data
    | ReadText({startPos: int, content: string})
}

let parse: string => array<Lexer.token>

// A sgr encoded element
module SgrString: {
  open Lexer

  type t = {
    content: string,
    params: array<Sgr.param>,
  }

  let fromTokens: array<token> => array<t>
}

module Printer: {
  open Lexer

  let plainString: array<token> => string
}

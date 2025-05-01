let numeric = [
  (1, "Suspicious-looking start-of-comment mark."),
  (2, "Suspicious-looking end-of-comment mark."),
  (3, "Deprecated feature."),
  (
    4,
    "Fragile pattern matching: matching that will remain complete even if additional constructors are added to one of the variant types matched.",
  ),
  (5, "Partially applied function: expression whose result has function type and is ignored."),
  (8, "Partial match: missing cases in pattern-matching."),
  (9, "Missing fields in a record pattern."),
  (
    10,
    "Expression on the left-hand side of a sequence that doesn't have type \"unit\" (and that is not a function, see warning number 5).",
  ),
  (11, "Redundant case in a pattern matching (unused match case)."),
  (12, "Redundant sub-pattern in a pattern-matching."),
  (14, "Illegal backslash escape in a string constant."),
  (16, "Unerasable optional argument."),
  (20, "Unused function argument."),
  (21, "Non-returning statement."),
  (23, "Useless record \"with\" clause."),
  (24, "Bad module name: the source file name is not a valid ReScript module name."),
  (
    26,
    "Suspicious unused variable: unused variable that is bound with \"let\" or \"as\", and doesn't start with an underscore (\"_\") character.",
  ),
  (
    27,
    "Innocuous unused variable: unused variable that is not bound with \"let\" nor \"as\", and doesn't start with an underscore (\"_\") character.",
  ),
  (28, "Wildcard pattern given as argument to a constant constructor."),
  (29, "Unescaped end-of-line in a string constant (non-portable code)."),
  (30, "Two labels or constructors of the same name are defined in two mutually recursive types."),
  (32, "Unused value declaration."),
  (33, "Unused open statement."),
  (34, "Unused type declaration."),
  (35, "Unused for-loop index."),
  (36, "Unused ancestor variable."),
  (37, "Unused constructor."),
  (38, "Unused extension constructor."),
  (39, "Unused rec flag."),
  (41, "Ambiguous constructor or label name."),
  (43, "Nonoptional label applied as optional."),
  (44, "Open statement shadows an already defined identifier."),
  (45, "Open statement shadows an already defined label or constructor."),
  (46, "Error in environment variable."),
  (47, "Illegal attribute payload."),
  (48, "Implicit elimination of optional arguments."),
  (49, "Absent cmi file when looking up module alias."),
  (50, "Unexpected documentation comment."),
  (52, "Fragile constant pattern."),
  (53, "Attribute cannot appear in this context"),
  (54, "Attribute used more than once on an expression"),
  (56, "Unreachable case in a pattern-matching (based on type information)."),
  (57, "Ambiguous or-pattern variables under guard"),
  (59, "Assignment to non-mutable value"),
  (60, "Unused module declaration"),
  (62, "Type constraint on GADT type declaration"),
  (101, "Unused bs attributes"),
  (102, "Polymorphic comparison introduced (maybe unsafe)"),
  (103, "Fragile FFI definitions"),
  (104, "bs.deriving warning with customized message "),
  (
    105,
    "External name is inferred from val name is unsafe from refactoring when changing value name",
  ),
  (106, "Unimplemented primitive used:"),
  (107, "Integer literal exceeds the range of representable integers of type int"),
  (108, "Uninterpreted delimiters (for unicode)"),
  (109, "Toplevel expression has unit type"),
  (110, "Todo found"),
]

let letterAll = numeric->Array.map(fst)

// we keep the original variable name `letter` like in warnings.ml
let _letter = l =>
  switch l {
  | "a" => letterAll
  /* | "b" => [||] */
  | "c" => [1, 2]
  | "d" => [3]
  | "e" => [4]
  | "f" => [5]
  /* | "g" => [||] */
  /* | "h" => [||] */
  /* | "i" => [||] */
  /* | "j" => [||] */
  | "k" => [32, 33, 34, 35, 36, 37, 38, 39]
  | "l" => [6]
  | "m" => [7]
  /* | "n" => [||] */
  /* | "o" => [||] */
  | "p" => [8]
  /* | "q" => [||] */
  | "r" => [9]
  | "s" => [10]
  /* | "t" => [||] */
  | "u" => [11, 12]
  | "v" => [13]
  /* | "w" => [||] */
  | "x" => [14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 30]
  | "y" => [26]
  | "z" => [27]
  | _ => []
  }

let letterDescriptions = [("a", "All flags")]

let getDescription = (num: int): option<string> =>
  numeric->Array.find(((n, _)) => num === n)->Option.map(((_, desc)) => desc)

// returns all possible key / description pairs
let lookupAll = (): array<(string, string)> => {
  let nums = numeric->Array.map(((num, desc)) => (Int.toString(num), desc))

  Array.concat(letterDescriptions, nums)
}

// str: a...z or a string number, returns (numStr, description)
let lookup = (str: string): array<(string, string)> =>
  switch Int.fromString(str) {
  | Some(num) =>
    switch getDescription(num) {
    | Some(description) => [(str, description)]
    | None => []
    }
  | None =>
    /* str */
    /* ->Js.String2.toLowerCase */
    /* ->letter */
    /* ->Belt.Array.reduce([||], (acc, num) => { */
    /* switch (getDescription(num)) { */
    /* | Some(description) => */
    /* Js.Array2.push(acc, (Belt.Int.toString(num), description)) */
    /* ->ignore; */
    /* acc; */
    /* | None => acc */
    /* } */
    /* }); */
    let search = str->String.toLowerCase
    Array.filter(letterDescriptions, ((l, _)) => l === search)
  }

// matches all numbers that start with str
let fuzzyLookup = (str: string): array<(string, string)> => {
  let letters = Array.filter(letterDescriptions, ((l, _)) => l->String.startsWith(str))

  let numbers =
    numeric
    ->Array.filter(((n, _)) => Int.toString(n)->String.startsWith(str))
    ->Array.map(((n, desc)) => (Int.toString(n), desc))

  Array.concat(letters, numbers)
}

module Parser = {
  type token = {
    enabled: bool,
    flag: string,
  }

  exception InvalidInput(string)

  type state =
    | ParseFlag({modifier: string, acc: string})
    | ParseModifier

  let isModifier = str => str === "+" || str === "-"

  let parseExn = (input: string): array<token> => {
    let ret = []

    let pos = ref(0)

    let state = ref(ParseModifier)
    let last = String.length(input) - 1

    while pos.contents <= last {
      let cur = String.get(input, pos.contents)->Option.getUnsafe
      let newState = switch state.contents {
      | ParseModifier =>
        if cur === "+" || cur === "-" {
          ParseFlag({modifier: cur, acc: ""})
        } else {
          raise(InvalidInput("Expected '+' or '-' on pos " ++ Int.toString(pos.contents)))
        }
      | ParseFlag({modifier, acc}) =>
        let next = if pos.contents + 1 < last {
          String.get(input, pos.contents + 1)->Option.getUnsafe
        } else {
          cur
        }

        if cur->isModifier {
          raise(
            InvalidInput(
              "'+' and '-' not allowed in flag name on pos " ++ Int.toString(pos.contents),
            ),
          )
        } else if next === "+" || (next === "-" || pos.contents >= last) {
          let token = {enabled: modifier === "+", flag: acc ++ cur}
          Array.push(ret, token)->ignore
          ParseModifier
        } else {
          ParseFlag({modifier, acc: acc ++ cur})
        }
      }

      state := newState
      pos := pos.contents + 1
    }

    // Last sanity check for the edge case where there
    // might be a tangling empty flag
    switch state.contents {
    | ParseFlag({modifier, acc: ""}) =>
      raise(
        InvalidInput(
          "Expected flag name after '" ++ (modifier ++ ("' on pos " ++ Int.toString(pos.contents))),
        ),
      )
    | _ => ()
    }

    ret->Belt.SortArray.stableSortBy((v1, v2) => {
      let a = v1.flag->Int.fromString
      let b = v2.flag->Int.fromString

      compare(a, b)
    })
  }

  let parse = (input: string): result<array<token>, string> =>
    try Ok(parseExn(input)) catch {
    | InvalidInput(str) => Error(str)
    }

  /* // other will override flags within base */
  let merge = (base: array<token>, other: array<token>) => {
    let dict = Array.copy(base)->Array.map(token => (token.flag, token))->Dict.fromArray

    Array.forEach(other, token => dict->Dict.set(token.flag, token))

    Dict.valuesToArray(dict)->Belt.SortArray.stableSortBy((t1, t2) => {
      open Float
      let f1 = t1.flag
      let f2 = t2.flag
      switch (f1->fromString->Option.isNone, f2->fromString->Option.isNone) {
      | (false, false)
      | (true, true) =>
        String.localeCompare(f1, f2)->Float.toInt
      | (true, false) => -1
      | (false, true) => 1
      }
    })
  }

  // Creates a compiler compatible warning flag string
  let tokensToString = tokens => {
    tokens
    ->Array.map(token => {
      let modifier = token.enabled ? "+" : "-"
      modifier ++ token.flag
    })
    ->Array.join("")
  }
}

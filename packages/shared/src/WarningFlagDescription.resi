module Parser: {
  type token = {
    enabled: bool,
    flag: string,
  }

  let parse: string => result<array<token>, string>

  let merge: (array<token>, array<token>) => array<token>
  let tokensToString: array<token> => string
}
let lookup: string => array<(string, string)>
let lookupAll: unit => array<(string, string)>
let fuzzyLookup: string => array<(string, string)>

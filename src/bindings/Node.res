module Path = {
  @module("path") external join2: (string, string) => string = "join"
  @module("path") @variadic external join: array<string> => string = "join"
  @module("path") external basename: string => string = "basename"
  @module("path") external resolve: (string, string) => string = "resolve"
  @module("path") external extname: string => string = "extname"
  @module("path") external dirname: string => string = "dirname"
}

module URL = {
  @module("url") external fileURLToPath: string => string = "fileURLToPath"
}

module Process = {
  @scope("process") external cwd: unit => string = "cwd"
  @scope("process") external env: Dict.t<string> = "env"
  @scope("process") @val external argv: array<string> = "argv"
  @scope("process") external exit: int => unit = "exit"
}

module Fs = {
  @module("fs") external readFileSync: string => string = "readFileSync"
  @module("fs") external readFileSync2: (string, string) => string = "readFileSync"
  @module("fs") external readdirSync: string => array<string> = "readdirSync"
  @module("fs") external writeFileSync: (string, string) => unit = "writeFileSync"
  @module("fs") external appendFileSync: (string, string, string) => unit = "appendFileSync"
  @module("fs") external existsSync: string => bool = "existsSync"
  @module("fs") external mkdirSync: string => unit = "mkdirSync"
  @module("fs") external statSync: string => {.."isDirectory": unit => bool} = "statSync"
}

module Buffer = {
  type t
  @send external toString: t => string = "toString"
}

module ChildProcess = {
  type options = {maxBuffer?: float}
  @module("child_process")
  external execSync: (string, ~options: options=?) => Buffer.t = "execSync"
}

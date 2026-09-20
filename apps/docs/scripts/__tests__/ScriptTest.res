type assertion<'a>
@module("vitest") external test: (string, unit => promise<unit>) => unit = "test"
@module("vitest") @scope("test")
external for_: array<'a> => (string, 'a => promise<unit>) => unit = "for"
@module("vitest") external onTestFinished: (unit => promise<unit>) => unit = "onTestFinished"
@module("vitest") external expect: ('a, ~message: string=?) => assertion<'a> = "expect"
@send external toBe: (assertion<'a>, 'a) => unit = "toBe"
@send external toStrictEqual: (assertion<'a>, 'a) => unit = "toStrictEqual"
@send external toContain: (assertion<string>, string) => unit = "toContain"
@send external toMatch: (assertion<string>, RegExp.t) => unit = "toMatch"
@send external toThrow: (assertion<unit => 'a>, string) => unit = "toThrow"
@send @scope("rejects")
external rejectsWith: (assertion<promise<'a>>, string) => promise<unit> = "toThrow"

type buffer
type processResult = {status: Null.t<int>, stdout: string, stderr: string}
type processOptions = {cwd: string, env: Dict.t<string>, encoding: string}
type workspace = {directory: string, env: Dict.t<string>}
type compressionOptions = {level: int}
type mkdirOptions = {recursive: bool}
type removeOptions = {recursive: bool, force: bool}
type writeOptions = {mode: int}
@module("node:buffer") @scope("Buffer") external buffer: string => buffer = "from"
@get external byteLength: buffer => int = "byteLength"
@module("node:zlib") external gzip: (buffer, compressionOptions) => buffer = "gzipSync"
@module("node:os") external tmpdir: unit => string = "tmpdir"
@module("node:path") @variadic external join: array<string> => string = "join"
@module("node:fs/promises") external mkdtemp: string => promise<string> = "mkdtemp"
@module("node:fs/promises") external mkdir: (string, mkdirOptions) => promise<unit> = "mkdir"
@module("node:fs/promises") external remove: (string, removeOptions) => promise<unit> = "rm"
@module("node:fs/promises") external read: (string, @as("utf8") _) => promise<string> = "readFile"
@module("node:fs/promises") external readBuffer: string => promise<buffer> = "readFile"
@module("node:fs/promises") external write: (string, string) => promise<unit> = "writeFile"
@module("node:fs/promises")
external writeExecutable: (string, string, writeOptions) => promise<unit> = "writeFile"
@module("node:fs/promises") external readdir: string => promise<array<string>> = "readdir"
@module("node:fs") external exists: string => bool = "existsSync"
@module("node:child_process")
external spawn: (string, array<string>, processOptions) => processResult = "spawnSync"
@val @scope("process") external environment: Dict.t<string> = "env"
@val @scope("process") external executable: string = "execPath"
@val @scope("process") external cwd: unit => string = "cwd"

let withEnvironment = (env, overrides) => Dict.fromArray([...Dict.toArray(env), ...overrides])

let temporaryDirectory = async prefix => {
  let directory = await mkdtemp(join([tmpdir(), prefix]))
  onTestFinished(() => remove(directory, {recursive: true, force: true}))
  directory
}

let expectSuccess = result => expect(result.status, ~message=result.stderr)->toBe(Null.make(0))
let expectStatus = (result, status) =>
  expect(result.status, ~message=result.stderr)->toBe(Null.make(status))
let readJson = async path => JSON.parseOrThrow(await read(path))

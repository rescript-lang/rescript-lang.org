@module("./shims.mjs")
external runWithoutLogging: (unit => Promise.t<'a>) => Promise.t<'a> = "runWithoutLogging"

@module("./shims.js")
external runWithoutLogging: (unit => Promise.t<'a>) => Promise.t<'a> = "runWithoutLogging"

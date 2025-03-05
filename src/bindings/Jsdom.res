type document = {title: option<string>}
type window = {document: Dom.document}
type t = {window: window}

@module("jsdom") @new
external make: string => t = "JSDOM"

external document: t => document = "%identity"

type window = {document: DomTypes.document}
type t = {window: window}

@module("jsdom") @new
external make: string => t = "JSDOM"

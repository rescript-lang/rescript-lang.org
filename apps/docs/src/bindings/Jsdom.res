type window = {document: WebAPI.DOMAPI.document}
type t = {window: WebAPI.DOMAPI.window}

@module("jsdom") @new
external make: string => t = "JSDOM"

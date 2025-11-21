// Used for compressing / decompressing code for url sharing

type t = {
  compressToEncodedURIComponent: string => string,
  decompressFromEncodedURIComponent: string => string,
}

@module("lz-string")
external lzString: t = "default"

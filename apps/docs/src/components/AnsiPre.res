// This file was automatically converted to ReScript from 'AnsiPre.re'
// Check the output and make sure to delete the original file
open Ansi

type colorTarget =
  | Fg
  | Bg

let mapColor = (~target: colorTarget, c: Color.t): string =>
  switch (target, c) {
  | (Fg, Black) => "text-gray-100"
  | (Fg, Red) => "text-fire-70"
  | (Fg, Green) => "text-turtle-dark"
  | (Fg, Yellow) => "text-orange-dark"
  | (Fg, Blue) => "text-water-dark"
  | (Fg, Magenta) => "text-berry"
  | (Fg, Cyan) => "text-water-dark"
  | (Fg, White) => "text-gray-10"
  | (Bg, Black) => "bg-gray-100"
  | (Bg, Red) => "bg-fire"
  | (Bg, Green) => "bg-turtle-dark"
  | (Bg, Yellow) => "bg-orange-dark"
  | (Bg, Blue) => "bg-water-dark"
  | (Bg, Magenta) => "bg-berry"
  | (Bg, Cyan) => "bg-water-dark"
  | (Bg, White) => "bg-gray-10"
  }

let renderSgrString = (~key: string, sgrStr: SgrString.t): React.element => {
  let {SgrString.content: content, params} = sgrStr

  let className =
    params
    ->Array.map(p =>
      switch p {
      | Sgr.Bold => "bold"
      | Fg(c) => mapColor(~target=Fg, c)
      | Bg(c) => mapColor(~target=Bg, c)
      | _ => ""
      }
    )
    ->Array.join(" ")

  <span key className> {React.string(content)} </span>
}

@react.component
let make = (~className=?, ~children: string) => {
  let spans =
    Ansi.parse(children)
    ->SgrString.fromTokens
    ->Array.mapWithIndex((str, i) => {
      let key = Int.toString(i)
      renderSgrString(~key, str)
    })

  // Note: pre is essential here, otherwise whitespace and newlines are not respected
  <pre ?className> {React.array(spans)} </pre>
}

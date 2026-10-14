type stylesheet = {rel: string, href: string}

let links: unit => array<stylesheet>

type props = CompilerData.t

let loader: unit => promise<option<props>>

let default: unit => React.element

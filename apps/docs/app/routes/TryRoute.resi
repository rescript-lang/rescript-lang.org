type stylesheet = {rel: string, href: string}

@live
let links: unit => array<stylesheet>

type props = CompilerData.t

@live
let loader: unit => promise<option<props>>

@live
let default: unit => React.element

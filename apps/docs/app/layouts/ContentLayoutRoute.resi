type stylesheet = {rel: string, href: string}

@live
let links: unit => array<stylesheet>

/** Own content styles and runtime highlighting without adding a DOM wrapper. */
@react.component @live
let default: unit => React.element

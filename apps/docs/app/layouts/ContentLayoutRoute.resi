type stylesheet = {rel: string, href: string}

let links: unit => array<stylesheet>

/** Own content styles and runtime highlighting without adding a DOM wrapper. */
@react.component
let default: unit => React.element

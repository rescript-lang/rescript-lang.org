type stylesheet = {rel: string, href: string}

let links: unit => array<stylesheet>

/** Own homepage styles without adding a DOM wrapper. */
@react.component
let default: unit => React.element

type stylesheet = {rel: string, href: string}

@live
let links: unit => array<stylesheet>

/** Own homepage styles without adding a DOM wrapper. */
@react.component @live
let default: unit => React.element

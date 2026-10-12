type stylesheet = {rel: string, href: string}

let links: unit => array<stylesheet>

type props = {
  bundleBaseUrl: string,
  versions: array<string>,
}

let loader: unit => promise<option<props>>

let default: unit => React.element

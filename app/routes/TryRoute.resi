type props = {
  bundleBaseUrl: string,
  versions: array<string>,
}

let loader: unit => promise<props>

let default: unit => React.element

type urlResource = {
  name: string,
  keywords: array<string>,
  description: string,
  urlHref: string,
  official: bool,
}

type npmPackage = {
  name: string,
  version: string,
  keywords: array<string>,
  description: string,
  repositoryHref: Null.t<string>,
  npmHref: string,
  searchScore: float,
  maintenanceScore: float,
}

type props = {
  "packages": array<npmPackage>,
  "urlResources": array<urlResource>,
  "unmaintained": array<npmPackage>,
}

let default: props => React.element

let getStaticProps: Next.GetStaticProps.t<props, unit>

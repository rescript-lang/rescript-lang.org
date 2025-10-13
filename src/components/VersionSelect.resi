module SectionHeader: {
  @react.component
  let make: (~value: string) => Jsx.element
}
@react.component
let make: (~version: string, ~availableVersions: array<string>) => Jsx.element

module SectionHeader: {
  @react.component
  let make: (~value: string) => React.element
}

@react.component
let make: (
  ~onChange: ReactEvent.Form.t => unit,
  ~version: string,
  ~nextVersion: (string, string)=?,
  ~availableVersions: array<(string, string)>,
) => React.element

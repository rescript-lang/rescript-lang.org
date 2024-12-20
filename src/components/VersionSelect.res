@react.component
let make = (
  ~onChange,
  ~version: string,
  ~nextVersion: option<(string, string)>=?,
  ~availableVersions: array<(string, string)>,
) => {
  // array<(version, label)>
  let children = Array.map(availableVersions, ((ver, label)) => {
    <option className="py-4" key=ver value=ver> {React.string(label)} </option>
  })
  <select
    className="text-12 border border-gray-20 bg-gray-10 text-gray-80 inline-block rounded px-4 py-1 font-semibold "
    name="versionSelection"
    value=version
    onChange>
    {switch nextVersion {
    | None => React.null
    | Some((value, label)) =>
      <>
        <option disabled=true key="next-heading" className="py-4">
          {React.string("--- Next ---")}
        </option>
        <option className="py-4" key=value value> {React.string(label)} </option>
        <option disabled=true key="released-heading" className="py-4">
          {React.string("--- Released ---")}
        </option>
      </>
    }}
    {React.array(children)}
  </select>
}

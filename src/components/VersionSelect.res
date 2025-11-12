type version = {
  label: string,
  link: string,
}

let currentVersion = {label: "v12 (latest)", link: "#"}

let olderVersions = [
  {label: "v11", link: "https://v11.rescript-lang.org/docs/manual/v11.0.0/introduction"},
  {label: "v9.1 - v10.1", link: "https://v11.rescript-lang.org/docs/manual/v10.0.0/introduction"},
  {label: "v8.2 - v9.0", link: "https://v11.rescript-lang.org/docs/manual/v9.0.0/introduction"},
  {label: "v6.0 - v8.1", link: "https://v11.rescript-lang.org/docs/manual/v8.0.0/introduction"},
]

module SectionHeader = {
  @react.component
  let make = (~value) =>
    <option disabled=true key=value className="py-4"> {React.string(value)} </option>
}

// This is the current version
let version = "v12"

@react.component
let make = () => {
  let children = Array.map(olderVersions, ver => {
    <a className="py-0.5 block hover:underline" key=ver.label href=ver.link>
      {React.string(ver.label)}
    </a>
  })
  <div className="wrapper block w-full" dataTestId="version-select">
    <div id="older-versions" popover=Auto />
    <button
      className="trigger text-12 border border-gray-20 bg-gray-10 text-gray-80 inline-block rounded px-4 py-1 font-semibold whitespace-nowrap"
      name="versionSelection"
      value=version
      popoverTarget="older-versions"
    >
      {React.string(currentVersion.label)}
      <span className="pl-2">
        <svg
          className="transition-transform duration-200"
          ariaHidden=true
          xmlns="http://www.w3.org/2000/svg"
          fill="none"
          viewBox="0 0 14 8"
        >
          <path
            stroke="currentColor"
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth="2"
            d="m1 1 5.326 5.7a.909.909 0 0 0 1.348 0L13 1"
          />
        </svg>
      </span>
    </button>

    <div
      className="menu text-12 bg-gray-10 border-gray-20 border xs-rounded px-4 py-1 shadow w-full transform duration-200"
    >
      {children->React.array}
    </div>
  </div>
}

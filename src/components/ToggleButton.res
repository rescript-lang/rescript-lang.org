@react.component
let make = (~checked, ~onChange, ~children, ~isLightTheme=false) => {
  let switchThemeClass = if isLightTheme {
    "bg-gray-30 after:bg-white after:border-gray-40 border-gray-40 peer-checked:bg-sky"
  } else {
    "bg-gray-700 after:bg-white after:border-gray-300 border-gray-600 peer-checked:bg-sky"
  }

  let labelThemeClass = isLightTheme ? "text-gray-80" : "text-gray-300"

  <label className="inline-flex items-center cursor-pointer">
    <input type_="checkbox" value="" checked onChange className="sr-only peer" />
    <div
      className={`relative w-8 h-4
      rounded-full peer peer-checked:after:translate-x-full 
      peer-checked:rtl:after:-translate-x-full peer-checked:after:border-white 
      after:content-[''] after:absolute after:top-[2px] after:start-[4px] 
      after:border after:rounded-full 
      after:h-3 after:w-3 after:transition-all ` ++
      switchThemeClass}
    />
    <span className={"ms-2 text-sm " ++ labelThemeClass}> {children} </span>
  </label>
}

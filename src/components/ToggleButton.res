@react.component
let make = (~checked, ~onChange, ~children) => {
  <label className="inline-flex items-center cursor-pointer">
    <input type_="checkbox" value="" checked onChange className="sr-only peer" />
    <div
      className={`relative w-8 h-4 bg-gray-700
      rounded-full peer peer-checked:after:translate-x-full 
      rtl:peer-checked:after:-translate-x-full peer-checked:after:border-white 
      after:content-[''] after:absolute after:top-[2px] after:start-[4px] 
      after:bg-white after:border-gray-300 after:border after:rounded-full 
      after:h-3 after:w-3 after:transition-all border-gray-600 
      peer-checked:bg-sky`}
    />
    <span className={"ms-2 text-sm text-gray-300"}> {children} </span>
  </label>
}

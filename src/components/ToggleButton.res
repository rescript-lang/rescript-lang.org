@react.component
let make = (~checked, ~onChange, ~children) => {
  <label className="inline-flex items-center cursor-pointer">
    <input type_="checkbox" value="" checked onChange className="sr-only peer" />
    <div
      className={`relative w-8 h-4
      playground-toggle-track
      rounded-full peer peer-checked:after:translate-x-full 
      peer-checked:rtl:after:-translate-x-full peer-checked:after:border-white 
      peer-checked:bg-sky
      after:content-[''] after:absolute after:top-[2px] after:start-[4px] 
      after:border after:rounded-full after:h-3 after:w-3 after:transition-all`}
    />
    <span className="playground-toggle-label ms-2 text-sm"> {children} </span>
  </label>
}

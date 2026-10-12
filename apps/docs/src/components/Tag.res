// This file was automatically converted to ReScript from 'Tag.re'
// Check the output and make sure to delete the original file
type kind = [#Subtle]

@react.component
let make = (~text, ~kind=#Subtle) => {
  let className = switch kind {
  | #Subtle => "px-1 bg-gray-10 text-gray-60 font-semibold rounded text-14"
  }
  <div>
    <span className> {React.string(text)} </span>
  </div>
}

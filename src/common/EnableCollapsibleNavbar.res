/**
 * Hides the navbar when scrolling down on mobile, and causes it to reappear when scrolling back up.
 */
@jsx.component
let make = (~children, ~isEnabled) => {
  let scrollDir = Hooks.useScrollDirection()
  if isEnabled {
    <div
      className={switch scrollDir {
      | Up(_) => "group nav-appear"

      | Down(_) => "group nav-disappear"
      }}>
      children
    </div>
  } else {
    children
  }
}

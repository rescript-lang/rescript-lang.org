let scrollLockContext = React.createContext((false, (_: bool => bool) => ()))

module ScrollLockProvider = {
  let make = React.Context.provider(scrollLockContext)
}

let useScrollLock = () => React.useContext(scrollLockContext)

module Provider = {
  @react.component
  let make = (~children, ~lockState) => {
    <ScrollLockProvider value=lockState> children </ScrollLockProvider>
  }
}

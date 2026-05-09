@react.component
let default = () => {
  let location = ReactRouter.useLocation()

  <>
    <NavbarSecondary key={(location.pathname :> string)} />
    <ReactRouter.Outlet />
  </>
}

@react.component
let default = () => {
  let location = ReactRouter.useLocation()

  <>
    // This layout persists across docs route changes. Key the secondary nav by
    // pathname so its scroll-direction state cannot keep the mobile nav hidden
    // after client-side navigation.
    <NavbarSecondary key={(location.pathname :> string)} />
    <ReactRouter.Outlet />
  </>
}

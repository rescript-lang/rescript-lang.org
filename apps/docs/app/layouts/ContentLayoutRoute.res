// Route-module initialization runs before any content children render.
let () = ContentHighlighting.register(HighlightLanguages.defaultInstance)

@react.component
let default = () => <ReactRouter.Outlet />

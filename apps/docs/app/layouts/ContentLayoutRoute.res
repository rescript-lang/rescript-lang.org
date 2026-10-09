@module("../../styles/content.css?url")
external contentCss: string = "default"

type stylesheet = {rel: string, href: string}

@live
let links = () => [{rel: "stylesheet", href: contentCss}]

// Route-module initialization runs before any content children render.
let () = ContentHighlighting.register(HighlightLanguages.defaultInstance)

@react.component @live
let default = () => <ReactRouter.Outlet />

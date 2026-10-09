@module("../../styles/homepage.css?url")
external homepageCss: string = "default"

type stylesheet = {rel: string, href: string}

@live
let links = () => [{rel: "stylesheet", href: homepageCss}]

@react.component @live
let default = () => <ReactRouter.Outlet />

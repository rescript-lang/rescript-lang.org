@module("../../styles/homepage.css?url")
external homepageCss: string = "default"

type stylesheet = {rel: string, href: string}

let links = () => [{rel: "stylesheet", href: homepageCss}]

@react.component
let default = () => <ReactRouter.Outlet />

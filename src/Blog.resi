let defaultPreviewImg: string

type params
type props

type category = Official | Community | Archived

let default: props => React.element

let getStaticProps_All: Next.GetStaticProps.t<props, params>
let getStaticProps_Archived: Next.GetStaticProps.t<props, params>
let getStaticProps_Community: Next.GetStaticProps.t<props, params>

type props
type params

// TODO RR7 pass the props correctly
let make: props => React.element
let getStaticProps: Next.GetStaticProps.t<props, params>

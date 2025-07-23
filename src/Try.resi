type props = {versions: array<string>}
let default: props => React.element
let getStaticProps: Next.GetStaticProps.t<props, 'a>

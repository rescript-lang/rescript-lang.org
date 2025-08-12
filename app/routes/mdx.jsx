import { useMdxAttributes, useMdxComponent } from 'react-router-mdx/client'
import { loadMdx } from 'react-router-mdx/server'

export async function loader({ request, ...rest }) {
    const res = loadMdx(request)
    console.log(await res)
    console.log(rest)
    return res
}

export default function Route() {
    const Component = useMdxComponent()
    const attributes = useMdxAttributes()

    return (
        <section>
            <h1>{attributes.title}</h1>
            <Component />
        </section>
    )

}
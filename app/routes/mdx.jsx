import { useMdxAttributes, useMdxComponent } from 'react-router-mdx/client'
import { loadMdx } from 'react-router-mdx/server'

export async function loader({ request }) {
    return loadMdx(request)
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
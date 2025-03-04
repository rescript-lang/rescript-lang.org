import BlogRes from "src/Blog.mjs";

export { getStaticProps_Community as getStaticProps } from "src/Blog.mjs";

export default function Blog(props) {
    return <BlogRes {...props} />
}

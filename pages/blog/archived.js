import BlogRes from "src/Blog.mjs"

export { getStaticProps_Archived as getStaticProps } from "src/Blog.mjs"

export default function Blog(props) {
  return <BlogRes {...props} />
}

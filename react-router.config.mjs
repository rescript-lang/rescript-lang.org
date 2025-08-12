import { init } from "react-router-mdx/server";
const mdx = init({ paths: ["_blogposts"], aliases: ["blog"] });


export default {
    ssr: false,
    async prerender({ getStaticPaths }) {
        return [
            ...(await getStaticPaths()),
            ...(await mdx.paths())
        ]
    },

}
import { init } from "react-router-mdx/server";
const mdx = init({ paths: ["_blogposts", "docs"], aliases: ["blog", "docs"] });

export default {
  ssr: false,
  async prerender({ getStaticPaths }) {
    return [...(await getStaticPaths()), ...(await mdx.paths())];
  },
};

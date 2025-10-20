import * as fs from "node:fs";
import { init } from "react-router-mdx/server";


const mdx = init({ paths: ["_blogposts", "docs", "community", "syntax-lookup"], aliases: ["blog", "docs", "community", "syntax-lookup"] });

const { stdlibPaths } = await import("./app/routes.mjs");

export default {
  ssr: false,

  async prerender({ getStaticPaths }) {
    return [...(await getStaticPaths()), ...(await mdx.paths()), ...stdlibPaths];
  },
  buildEnd: async () => {
    fs.cpSync("./build/client", "./out", { recursive: true });
  },
};

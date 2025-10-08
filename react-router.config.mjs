import * as fs from "node:fs";
import { init } from "react-router-mdx/server";


const mdx = init({ paths: ["_blogposts", "docs"], aliases: ["blog", "docs"] });

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

import * as fs from "node:fs";
import { init } from "react-router-mdx/server";
import { Url } from "./src/common/Util.mjs";

const mdx = init({
  paths: [
    "markdown-pages/blog",
    "markdown-pages/docs",
    "markdown-pages/community",
    "markdown-pages/syntax-lookup",
  ],
  aliases: ["blog", "docs", "community", "syntax-lookup"],
});

const { stdlibPaths } = await import("./app/routes.mjs");

export default {
  ssr: false,

  async prerender({ getStaticPaths }) {
    return [
      ...(await getStaticPaths()),
      ...(await mdx.paths()).map(path => path.includes("blog") ? Url.removeDatePrefix(path) : path),
      ...stdlibPaths,
    ];
  },
  buildEnd: async () => {
    fs.cpSync("./build/client", "./out", { recursive: true });
  },
};

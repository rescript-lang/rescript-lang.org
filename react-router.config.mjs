import * as fs from "node:fs";
import { init } from "react-router-mdx/server";

const mdx = init({
  paths: [
    "markdown-pages/blog",
    "markdown-pages/docs",
    "markdown-pages/community",
    "markdown-pages/syntax-lookup",
  ],
  aliases: ["blog", "docs", "community", "syntax-lookup"],
});

const { stdlibPaths } = await import("./app/routes.jsx");

export default {
  ssr: false,

  async prerender({ getStaticPaths }) {
    return [
      ...(await getStaticPaths()),
      ...(await mdx.paths()),
      ...stdlibPaths,
    ];
  },
};

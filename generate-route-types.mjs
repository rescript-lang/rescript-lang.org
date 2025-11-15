import fs from "fs/promises";
import { init } from "react-router-mdx/server";

init({
  paths: [
    "markdown-pages/blogposts",
    "markdown-pages/docs",
    "markdown-pages/community",
    "markdown-pages/syntax-lookup",
  ],
  aliases: ["blog", "docs", "community", "syntax-lookup"],
});

const { default: routes } = await import("./app/routes.mjs");

const paths = routes.map((route) => `#"/${route.path}"`).join(" |\n");

await fs.writeFile(
  "src/Path.res",
  `type t = [
${paths}
]
`,
);

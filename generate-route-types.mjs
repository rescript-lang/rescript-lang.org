import fs from "fs/promises";
import { init } from "react-router-mdx/server";

init({ paths: ["_blogposts", "docs"], aliases: ["blog", "docs"] });

const { default: routes } = await import("./app/routes.mjs");

const paths = routes.map((route) => `#"${route.path}"`).join(" |\n");

await fs.writeFile(
  "src/Path.res",
  `type t = [
${paths}
]
`,
);

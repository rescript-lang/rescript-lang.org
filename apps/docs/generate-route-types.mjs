import fs from "fs/promises";

const { default: routes } = await import("./app/routes.mjs");

const paths = routes.map((route) => `#"/${route.path}"`).join(" |\n");

await fs.writeFile(
  "src/Path.res",
  `type t = [
#"/" |
${paths}
]
`,
);

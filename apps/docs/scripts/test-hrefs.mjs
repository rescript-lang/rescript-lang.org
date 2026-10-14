import remarkValidateLinks from "remark-validate-links";
import { remark } from "remark";
import { read } from "to-vfile";
import { reporter } from "vfile-reporter";
import * as fs from "fs/promises";
import path from "node:path";
import { apiDataDirectory } from "./api-data.mjs";

const apiDirectory = apiDataDirectory();

// API pages are generated from JSON rather than Markdown files. Match their
// actual routes instead of suppressing every warning containing "api/".
const apiPaths = new Set([
  "docs/manual/api",
  "docs/manual/api/introduction",
  ...(
    await Promise.all(
      ["stdlib", "belt", "dom"].map(async (library) => {
        const data = JSON.parse(
          await fs.readFile(path.join(apiDirectory, `${library}.json`), "utf8"),
        );
        return Object.keys(data).map((key) => `docs/manual/api/${key}`);
      }),
    )
  ).flat(),
]);

const files = new Set(
  ...[await fs.readdir("markdown-pages", { recursive: true })],
);

const markdownFolders = (
  await fs.readdir("markdown-pages", { recursive: true, withFileTypes: true })
)
  .filter((dirent) => dirent.isDirectory())
  .map((dirent) => dirent.name);

let issues = 0;

for (const file of files) {
  if (file.includes(".mdx")) {
    let result = await remark()
      .use(remarkValidateLinks)
      .process(await read("markdown-pages/" + file));

    result.messages = result.messages.filter((message) => {
      const target = message.reason.match(
        /^Cannot find (?:file `|heading for `#[^`]+` in `)(?:\.\.\/)*(docs\/manual\/api(?:\/[^`]*)?)`/,
      )?.[1];
      return !target || !apiPaths.has(target.replace(/\/$/, ""));
    });

    const log = reporter(result, { quiet: true });

    const warningMessage = log.replace(file, "");

    // Skip warnings about files that exist in public/ (served at root by Vite)
    const missingFileMatches = [
      ...warningMessage.matchAll(/`((?:\.\.\/)+.*?)`/g),
    ];
    let allMissingExistInPublic = false;
    if (missingFileMatches.length > 0) {
      allMissingExistInPublic = (
        await Promise.all(
          missingFileMatches.map(([, p]) =>
            fs.access("public/" + p.replace(/^(?:\.\.\/)+/, "")).then(
              () => true,
              () => false,
            ),
          ),
        )
      ).every(Boolean);
    }

    if (
      log &&
      !allMissingExistInPublic &&
      // When running on CI it fails to ignore the link directly to the blog root
      // https://github.com/rescript-lang/rescript-lang.org/actions/runs/19520461368/job/55882556586?pr=1115#step:6:338
      !warningMessage.includes("`../../blog`") &&
      markdownFolders.some((folder) => warningMessage.includes(`${folder}`)) &&
      !warningMessage.includes(".txt")
    ) {
      console.log(log);
      issues += 1;
    }
  }
}

console.log(
  `\n${issues > 0 ? "❌" : "✅"} Link check complete. ${issues} issues found.\n`,
);

if (process.env.CI && issues > 0) {
  process.exit(1);
} else {
  process.exit(0);
}
